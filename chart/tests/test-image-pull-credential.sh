#!/usr/bin/env bash
#
# Verify the chart's image pull credential across install shapes: the hook
# Secret for both registry hostnames, its name on every pod, the preflight's
# inline credential, the support bundle's reference by name, the KOTS and
# opt-out paths that render nothing, and the NOTES warning when no key is set.
#
# Prerequisites: helm, python3 with PyYAML. Run `helm dependency update chart`
# first when charts/ is stale (CI does it once upfront).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$CHART_DIR"

# Dummy keys: the chart treats the value as an opaque JSON string.
cat > "$WORK_DIR/default-key.yaml" <<'YAML'
cartoSecrets:
  defaultGoogleServiceAccount:
    value: |
      {"type": "service_account", "private_key_id": "chart-test-default"}
YAML
cat > "$WORK_DIR/pull-key.yaml" <<'YAML'
cartoSecrets:
  imagePullServiceAccount:
    value: |
      {"type": "service_account", "private_key_id": "chart-test-pull"}
YAML
cat > "$WORK_DIR/existing-secret.yaml" <<'YAML'
cartoSecrets:
  defaultGoogleServiceAccount:
    existingSecret:
      name: my-carto-sa
      key: key.json
YAML

render() { # render <case> <helm args...>: writes $WORK_DIR/<case>.rendered
  local name="$1"
  shift
  helm template carto . -n test "$@" > "$WORK_DIR/$name.rendered"
}

notes() { # notes <case> <helm args...>: writes the rendered NOTES to $WORK_DIR/<case>.notes
  local name="$1"
  shift
  helm install carto . -n test --dry-run=client "$@" > "$WORK_DIR/$name.notes"
}

render default-key -f "$WORK_DIR/default-key.yaml"
render pull-key -f "$WORK_DIR/default-key.yaml" -f "$WORK_DIR/pull-key.yaml"
render kots -f "$WORK_DIR/pull-key.yaml" --set replicated.enabled=true
render opt-out -f "$WORK_DIR/pull-key.yaml" --set appConfigValues.imagePullCredentialEnabled=false
render manual-secret -f "$WORK_DIR/pull-key.yaml" --set 'global.imagePullSecrets[0]=carto-registry'
notes no-key
notes existing-secret -f "$WORK_DIR/existing-secret.yaml"
notes opt-out-notes --set appConfigValues.imagePullCredentialEnabled=false
notes pull-key-notes -f "$WORK_DIR/pull-key.yaml"

python3 - "$WORK_DIR" <<'PY'
import base64, json, sys, yaml

work = sys.argv[1]
secret_name = "carto-image-pull"
failures = []

def check(cond, msg):
    if not cond:
        failures.append(msg)

def docs(case):
    return [d for d in yaml.safe_load_all(open(f"{work}/{case}.rendered")) if d]

def pod_specs(documents):
    """Yield the pods that run a CARTO image (the bundled PostgreSQL pulls from Docker Hub)."""
    for d in documents:
        kind = d.get("kind")
        spec = d.get("spec") or {}
        if kind in ("Deployment", "StatefulSet", "Job"):
            pod = spec["template"]["spec"]
        elif kind == "CronJob":
            pod = spec["jobTemplate"]["spec"]["template"]["spec"]
        else:
            continue
        containers = (pod.get("containers") or []) + (pod.get("initContainers") or [])
        if any("carto-onprem-artifacts" in c.get("image", "") for c in containers):
            yield d, pod

def pull_secret_names(pod_spec):
    return [s["name"] for s in pod_spec.get("imagePullSecrets") or []]

def chart_secret(documents):
    found = [d for d in documents if d.get("kind") == "Secret" and d["metadata"]["name"] == secret_name]
    return found[0] if found else None

def troubleshoot_spec(documents, label_kind, key):
    for d in documents:
        if d.get("kind") == "Secret" and d["metadata"].get("labels", {}).get("troubleshoot.sh/kind") == label_kind:
            return yaml.safe_load(d["stringData"][key])
    raise SystemExit(f"no troubleshoot {label_kind} Secret rendered")

def collector_secrets(spec):
    out = {}
    for c in spec["spec"]["collectors"]:
        for kind in ("runPod", "registryImages"):
            if kind in c:
                out[kind] = c[kind].get("imagePullSecret")
    return out

def expect_credential(case, key_id):
    documents = docs(case)
    secret = chart_secret(documents)
    check(secret is not None, f"{case}: no {secret_name} Secret")
    if secret is None:
        return
    ann = secret["metadata"].get("annotations", {})
    check(ann.get("helm.sh/hook") == "pre-install,pre-upgrade", f"{case}: Secret is not a pre-install/pre-upgrade hook")
    check(int(ann.get("helm.sh/hook-weight", "0")) < -10, f"{case}: Secret hook weight does not run before the other hooks")
    check(ann.get("helm.sh/hook-delete-policy") == "before-hook-creation", f"{case}: wrong hook delete policy")
    check(secret["type"] == "kubernetes.io/dockerconfigjson", f"{case}: wrong Secret type")
    config = json.loads(base64.b64decode(secret["data"][".dockerconfigjson"]))
    check(sorted(config["auths"]) == ["gcr.io", "us-docker.pkg.dev"], f"{case}: auths hosts are {sorted(config['auths'])}")
    for host, entry in config["auths"].items():
        check(entry["username"] == "_json_key", f"{case}: {host} username")
        check(json.loads(entry["password"])["private_key_id"] == key_id, f"{case}: {host} uses the wrong key")
        check(base64.b64decode(entry["auth"]).decode() == "_json_key:" + entry["password"], f"{case}: {host} auth does not match")
    for d, pod in pod_specs(documents):
        check(secret_name in pull_secret_names(pod), f"{case}: {d['kind']}/{d['metadata']['name']} lacks {secret_name}")
    preflight = collector_secrets(troubleshoot_spec(documents, "preflight", "preflight.yaml"))
    for kind, ips in preflight.items():
        check(ips and "data" in ips and ips["name"] != secret_name, f"{case}: preflight {kind} does not carry the credential inline")
    bundle = collector_secrets(troubleshoot_spec(documents, "support-bundle", "support-bundle-spec"))
    for kind, ips in bundle.items():
        check(ips == {"name": secret_name}, f"{case}: support bundle {kind} imagePullSecret is {ips}")

def expect_no_credential(case, registry_secret):
    documents = docs(case)
    check(chart_secret(documents) is None, f"{case}: {secret_name} Secret rendered")
    for d, pod in pod_specs(documents):
        check(secret_name not in pull_secret_names(pod), f"{case}: {d['kind']}/{d['metadata']['name']} lists {secret_name}")
    preflight = collector_secrets(troubleshoot_spec(documents, "preflight", "preflight.yaml"))
    check(preflight.get("registryImages") == {"name": registry_secret}, f"{case}: preflight registryImages is {preflight.get('registryImages')}")
    check(preflight.get("runPod") is None, f"{case}: preflight runPod has an imagePullSecret")

expect_credential("default-key", "chart-test-default")
expect_credential("pull-key", "chart-test-pull")
expect_no_credential("kots", "carto-registry")
expect_no_credential("opt-out", "carto-registry")

manual = docs("manual-secret")
for d, pod in pod_specs(manual):
    names = pull_secret_names(pod)
    check("carto-registry" in names and secret_name in names, f"manual-secret: {d['kind']}/{d['metadata']['name']} has {names}")

warning = "CARTO IMAGE PULL CREDENTIAL MISSING"
check(warning in open(f"{work}/no-key.notes").read(), "no-key: NOTES has no warning")
existing = open(f"{work}/existing-secret.notes").read()
check(warning in existing and "global.imagePullSecrets" in existing, "existing-secret: NOTES does not ask for global.imagePullSecrets")
check(warning not in open(f"{work}/opt-out-notes.notes").read(), "opt-out: NOTES warns")
check(warning not in open(f"{work}/pull-key-notes.notes").read(), "pull-key: NOTES warns")

if failures:
    print("\n".join("FAIL " + f for f in failures))
    sys.exit(1)
print("image pull credential: all checks passed")
PY
