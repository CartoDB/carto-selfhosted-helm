#!/usr/bin/env bash
#
# Verify the chart's image pull credential across install shapes: the hook
# Secret for both registry hostnames, its name on every pod, the preflight's
# inline credential, the support bundle pod's pull secret, the KOTS and
# existingSecret paths that render nothing, and the NOTES warnings.
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
render existing-secret -f "$WORK_DIR/existing-secret.yaml"
render manual-secret -f "$WORK_DIR/pull-key.yaml" --set 'global.imagePullSecrets[0]=carto-registry'
# Values from an older chart (helm upgrade --reuse-values) lack the new key.
render pull-value-removed -f "$WORK_DIR/default-key.yaml" --set cartoSecrets.imagePullServiceAccount=null
notes no-key
notes existing-secret-notes -f "$WORK_DIR/existing-secret.yaml"
notes manual-secret-notes --set 'global.imagePullSecrets[0]=carto-registry'
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
    # By name: on KOTS the Replicated subchart renders its own Secret with the same label.
    name = {"preflight": "carto-preflight-config", "support-bundle": "carto-support-bundle"}[label_kind]
    for d in documents:
        if d.get("kind") == "Secret" and d["metadata"]["name"] == name:
            return yaml.safe_load(d["stringData"][key])
    raise SystemExit(f"no {name} Secret rendered")

def collectors(spec):
    out = {}
    for c in spec["spec"]["collectors"]:
        for kind in ("runPod", "registryImages"):
            if kind in c:
                out[kind] = c[kind]
    return out

def check_collectors(case, documents, credential):
    preflight = collectors(troubleshoot_spec(documents, "preflight", "preflight.yaml"))
    bundle = collectors(troubleshoot_spec(documents, "support-bundle", "support-bundle-spec"))
    for name, spec in (("preflight", preflight), ("support bundle", bundle)):
        check(spec["registryImages"].get("imagePullSecret") == {"name": "carto-registry"}, f"{case}: {name} registryImages imagePullSecret changed")
    inline = preflight["runPod"].get("imagePullSecret")
    bundle_pod_secrets = pull_secret_names(bundle["runPod"]["podSpec"])
    if credential:
        check(inline and "data" in inline and "name" not in inline, f"{case}: preflight runPod does not carry an unnamed inline credential: {inline}")
        check(bundle["runPod"].get("imagePullSecret") is None, f"{case}: support bundle runPod has a collector imagePullSecret")
        check(secret_name in bundle_pod_secrets, f"{case}: support bundle runPod pod does not list {secret_name}")
        check(secret_name not in pull_secret_names(preflight["runPod"]["podSpec"]), f"{case}: preflight runPod pod lists {secret_name}")
    else:
        check(inline is None, f"{case}: preflight runPod has an imagePullSecret")
        check(secret_name not in bundle_pod_secrets, f"{case}: support bundle runPod pod lists {secret_name}")

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
    pods = list(pod_specs(documents))
    check(len(pods) >= 10, f"{case}: only {len(pods)} pods run a CARTO image; the selection is broken")
    for d, pod in pods:
        check(secret_name in pull_secret_names(pod), f"{case}: {d['kind']}/{d['metadata']['name']} lacks {secret_name}")
    check_collectors(case, documents, credential=True)

def expect_no_credential(case):
    documents = docs(case)
    check(chart_secret(documents) is None, f"{case}: {secret_name} Secret rendered")
    pods = list(pod_specs(documents))
    check(len(pods) >= 10, f"{case}: only {len(pods)} pods run a CARTO image; the selection is broken")
    for d, pod in pods:
        check(secret_name not in pull_secret_names(pod), f"{case}: {d['kind']}/{d['metadata']['name']} lists {secret_name}")
    check_collectors(case, documents, credential=False)

expect_credential("default-key", "chart-test-default")
expect_credential("pull-key", "chart-test-pull")
expect_credential("pull-value-removed", "chart-test-default")
expect_no_credential("kots")
expect_no_credential("existing-secret")

manual = docs("manual-secret")
for d, pod in pod_specs(manual):
    names = pull_secret_names(pod)
    check("carto-registry" in names and secret_name in names, f"manual-secret: {d['kind']}/{d['metadata']['name']} has {names}")

def read_notes(case):
    return open(f"{work}/{case}.notes").read()

warning = "CARTO IMAGE PULL CREDENTIAL MISSING"
check(warning in read_notes("no-key") and "customer package" in read_notes("no-key"), "no-key: NOTES does not ask for the customer package")
existing = read_notes("existing-secret-notes")
check(warning in existing and "global.imagePullSecrets" in existing, "existing-secret: NOTES does not ask for global.imagePullSecrets")
check(warning not in read_notes("manual-secret-notes"), "manual-secret: NOTES warns")
check(warning not in read_notes("pull-key-notes"), "pull-key: NOTES warns")

if failures:
    print("\n".join("FAIL " + f for f in failures))
    sys.exit(1)
print("image pull credential: all checks passed")
PY
