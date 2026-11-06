#!/usr/bin/env bash
#
# Verify the chart's image pull credential across install shapes: the Secret
# for the CARTO repositories on both registry hosts and its hook copy, their
# names on every pod, the preflight's inline credential, the support bundle
# pod's pull secret, the KOTS and existingSecret paths that render nothing,
# and the NOTES warnings.
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

# helm template skips NOTES.txt and helm install --dry-run needs a cluster, so a copy of
# the chart renders NOTES.txt into a ConfigMap.
NOTES_CHART="$WORK_DIR/notes-chart"
cp -R "$CHART_DIR" "$NOTES_CHART"
{
  echo '{{- define "test.notes" -}}'
  cat "$CHART_DIR/templates/NOTES.txt"
  echo '{{- end -}}'
  cat <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: notes-under-test
data:
  notes: {{ include "test.notes" . | toJson }}
YAML
} > "$NOTES_CHART/templates/zz-notes-under-test.yaml"

notes() { # notes <case> <helm args...>: writes the rendered NOTES ConfigMap to $WORK_DIR/<case>.notes
  local name="$1"
  shift
  helm template carto "$NOTES_CHART" -n test --show-only templates/zz-notes-under-test.yaml "$@" > "$WORK_DIR/$name.notes"
}

render default-key -f "$WORK_DIR/default-key.yaml"
# The aiProxy migration Job is the other hook that pulls a CARTO image; it needs an external database.
render ai-hook -f "$WORK_DIR/default-key.yaml" --set appConfigValues.aiFeaturesEnabled=true --set internalPostgresql.enabled=false --set externalPostgresql.host=db.example.com --set externalPostgresql.password=x
render kots -f "$WORK_DIR/default-key.yaml" --set replicated.enabled=true
render existing-secret -f "$WORK_DIR/existing-secret.yaml"
render manual-secret -f "$WORK_DIR/default-key.yaml" --set 'global.imagePullSecrets[0]=carto-registry'
render manual-secret-no-key --set 'global.imagePullSecrets[0]=carto-registry'
render checker-pull-secret -f "$WORK_DIR/default-key.yaml" --set 'tenantRequirementsChecker.image.pullSecrets[0]=checker-pull'
render mirror -f "$WORK_DIR/default-key.yaml" --set global.imageRegistry=us-docker.pkg.dev/mirror-example
render workload-identity -f "$WORK_DIR/default-key.yaml" --set commonBackendServiceAccount.enableGCPWorkloadIdentity=true
render carto-registry-override -f "$WORK_DIR/default-key.yaml" --set global.imageRegistry=us-docker.pkg.dev/carto-onprem-artifacts/example
cat > "$WORK_DIR/disconnected.yaml" <<'YAML'
appConfigValues:
  disconnected:
    enabled: true
    protocol: oidc
    spaClient:
      clientId: x
    oidc:
      issuerUrl: https://idp.example.com
      clientId: x
appSecrets:
  authApiOidcClientSecret:
    value: x
cartoSecrets:
  authApiInternalServiceToken:
    value: x
  encryptionSecretKey:
    value: x
YAML
render disconnected -f "$WORK_DIR/default-key.yaml" -f "$WORK_DIR/disconnected.yaml"
notes no-key
notes existing-secret-notes -f "$WORK_DIR/existing-secret.yaml"
notes manual-secret-notes --set 'global.imagePullSecrets[0]=carto-registry'
notes default-key-notes -f "$WORK_DIR/default-key.yaml"

python3 - "$WORK_DIR" <<'PY'
import base64, json, sys, yaml

work = sys.argv[1]
secret_name = "carto-image-pull"
hook_secret_name = "carto-image-pull-hook"
failures = []

def check(cond, msg):
    if not cond:
        failures.append(msg)

def docs(case):
    return [d for d in yaml.safe_load_all(open(f"{work}/{case}.rendered")) if d]

def all_pods(documents):
    for d in documents:
        kind = d.get("kind")
        spec = d.get("spec") or {}
        if kind in ("Deployment", "StatefulSet", "Job"):
            yield d, spec["template"]["spec"]
        elif kind == "CronJob":
            yield d, spec["jobTemplate"]["spec"]["template"]["spec"]

def images(pod_spec):
    return [c.get("image", "") for c in (pod_spec.get("containers") or []) + (pod_spec.get("initContainers") or [])]

def pod_specs(documents):
    """Yield the pods that run a CARTO image (the bundled PostgreSQL pulls from Docker Hub)."""
    for d, pod in all_pods(documents):
        if any("carto-onprem-artifacts" in image for image in images(pod)):
            yield d, pod

def pull_secret_names(pod_spec):
    return [s["name"] for s in pod_spec.get("imagePullSecrets") or []]

def hook_annotations(d):
    return {k: v for k, v in (d["metadata"].get("annotations") or {}).items() if k.startswith("helm.sh/hook")}

def credential_name(d):
    """The chart Secret a pod pulls with: hooks run before the release Secret exists."""
    return hook_secret_name if hook_annotations(d) else secret_name

def chart_secret(documents, name=secret_name):
    found = [d for d in documents if d.get("kind") == "Secret" and d["metadata"]["name"] == name]
    return found[0] if found else None

def auths(secret):
    return json.loads(base64.b64decode(secret["data"][".dockerconfigjson"]))["auths"]

def troubleshoot_spec(documents, label_kind, key):
    # By name: on KOTS the Replicated subchart renders its own Secret with the same label.
    name = {"preflight": "carto-preflight-config", "support-bundle": "carto-support-bundle"}[label_kind]
    for d in documents:
        if d.get("kind") == "Secret" and d["metadata"]["name"] == name:
            return yaml.safe_load(d["stringData"][key])
    raise SystemExit(f"no {name} Secret rendered")

CHECKER = "tenant-requirements-check"

def collectors(spec):
    """Map each runPod by its collectorName, plus the registryImages collector."""
    out = {}
    for c in spec["spec"]["collectors"]:
        if "runPod" in c:
            out[c["runPod"]["collectorName"]] = c["runPod"]
        if "registryImages" in c:
            out["registryImages"] = c["registryImages"]
    return out

def check_collectors(case, documents, credential, pull_secrets=()):
    """The checker pod lists the global and checker pull secrets; the chart credential travels inline in the preflight and as the release Secret in the support bundle."""
    preflight = collectors(troubleshoot_spec(documents, "preflight", "preflight.yaml"))
    bundle = collectors(troubleshoot_spec(documents, "support-bundle", "support-bundle-spec"))
    for name, spec in (("preflight", preflight), ("support bundle", bundle)):
        check(spec["registryImages"].get("imagePullSecret") == {"name": "carto-registry"}, f"{case}: {name} registryImages imagePullSecret changed")
        check([k for k in spec if k != "registryImages"] == [CHECKER], f"{case}: {name} runPods are {[k for k in spec if k != 'registryImages']}")
    inline = preflight[CHECKER].get("imagePullSecret")
    preflight_pod_secrets = pull_secret_names(preflight[CHECKER]["podSpec"])
    bundle_pod_secrets = pull_secret_names(bundle[CHECKER]["podSpec"])
    check(bundle[CHECKER].get("imagePullSecret") is None, f"{case}: support bundle {CHECKER} has a collector imagePullSecret")
    check(preflight_pod_secrets == list(pull_secrets), f"{case}: preflight {CHECKER} pod lists {preflight_pod_secrets}, want {list(pull_secrets)}")
    if credential:
        check(inline and "data" in inline and "name" not in inline, f"{case}: preflight {CHECKER} does not carry an unnamed inline credential: {inline}")
        check(bundle_pod_secrets == list(pull_secrets) + [secret_name], f"{case}: support bundle {CHECKER} pod lists {bundle_pod_secrets}, want {list(pull_secrets) + [secret_name]}")
    else:
        check(inline is None, f"{case}: preflight {CHECKER} has an imagePullSecret")
        check(bundle_pod_secrets == list(pull_secrets), f"{case}: support bundle {CHECKER} pod lists {bundle_pod_secrets}, want {list(pull_secrets)}")

PULL_CHECK_PATH = "ImageRegistryValidator.Check_CARTO_images_registry_authentication.status"
PULL_CHECK_KEY_FILE = "/usr/src/certs/gcp-default-service-account/image-pull-check-key.json"

def env(container):
    return {e["name"]: e.get("value") for e in container.get("env") or []}

def check_pull_key_check(case, documents, key_id=None):
    """The checker gets the chart key and its own image only when it can probe a CARTO repository; the analyzer warns."""
    for kind, key in (("preflight", "preflight.yaml"), ("support-bundle", "support-bundle-spec")):
        spec = troubleshoot_spec(documents, kind, key)
        pod = collectors(spec)[CHECKER]["podSpec"]
        init_env, main_env = env(pod["initContainers"][0]), env(pod["containers"][0])
        analyzers = [a["jsonCompare"] for a in spec["spec"]["analyzers"] if a.get("jsonCompare", {}).get("path") == PULL_CHECK_PATH]
        if key_id is None:
            check("IMAGE_PULL_CHECK_KEY__FILE_CONTENT" not in init_env and "IMAGE_PULL_CHECK_IMAGE" not in main_env and not analyzers, f"{case}: {kind} wires the image pull key check")
            continue
        content = init_env.get("IMAGE_PULL_CHECK_KEY__FILE_CONTENT")
        check(content and json.loads(base64.b64decode(content))["private_key_id"] == key_id, f"{case}: {kind} image pull key check does not get the chart key")
        check(init_env.get("IMAGE_PULL_CHECK_KEY__FILE_PATH") == PULL_CHECK_KEY_FILE == main_env.get("IMAGE_PULL_CHECK_KEY_FILE"), f"{case}: {kind} image pull key check paths differ")
        check(main_env.get("IMAGE_PULL_CHECK_IMAGE") == pod["containers"][0]["image"], f"{case}: {kind} image pull key check probes {main_env.get('IMAGE_PULL_CHECK_IMAGE')}")
        check(len(analyzers) == 1 and [next(iter(o)) for o in analyzers[0]["outcomes"]] == ["pass", "warn"], f"{case}: {kind} image pull key check analyzers are {analyzers}")

def expect_credential(case, key_id):
    documents = docs(case)
    secret = chart_secret(documents)
    hook_secret = chart_secret(documents, hook_secret_name)
    check(secret is not None, f"{case}: no {secret_name} Secret")
    check(hook_secret is not None, f"{case}: no {hook_secret_name} Secret")
    if secret is None or hook_secret is None:
        return
    check(not hook_annotations(secret), f"{case}: {secret_name} is a hook: {hook_annotations(secret)}")
    check(secret["type"] == "kubernetes.io/dockerconfigjson", f"{case}: wrong Secret type")
    check(hook_secret["type"] == secret["type"] and hook_secret["data"] == secret["data"], f"{case}: {hook_secret_name} differs from {secret_name}")
    ann = hook_annotations(hook_secret)
    check(ann.get("helm.sh/hook") == "pre-install,pre-upgrade", f"{case}: {hook_secret_name} is not a pre-install/pre-upgrade hook")
    check(ann.get("helm.sh/hook-delete-policy") == "hook-succeeded,before-hook-creation,hook-failed", f"{case}: {hook_secret_name} delete policy is {ann.get('helm.sh/hook-delete-policy')}")
    config = auths(secret)
    check(sorted(config) == ["gcr.io/carto-onprem-artifacts", "us-docker.pkg.dev/carto-onprem-artifacts"], f"{case}: auths keys are {sorted(config)}")
    for key, entry in config.items():
        check(entry["username"] == "_json_key", f"{case}: {key} username")
        check(json.loads(entry["password"])["private_key_id"] == key_id, f"{case}: {key} uses the wrong key")
        check(base64.b64decode(entry["auth"]).decode() == "_json_key:" + entry["password"], f"{case}: {key} auth does not match")
    pods = list(pod_specs(documents))
    hook_pods = [d for d, _ in pods if hook_annotations(d)]
    check(len(pods) >= 10 and hook_pods, f"{case}: {len(pods)} pods run a CARTO image, {len(hook_pods)} of them hooks; the selection is broken")
    for d in hook_pods:
        check(int(ann["helm.sh/hook-weight"]) < int(hook_annotations(d)["helm.sh/hook-weight"]), f"{case}: {hook_secret_name} does not run before {d['kind']}/{d['metadata']['name']}")
    for d, pod in pods:
        names = pull_secret_names(pod)
        check(credential_name(d) in names and len(set(names) & {secret_name, hook_secret_name}) == 1, f"{case}: {d['kind']}/{d['metadata']['name']} has {names}")
    check_collectors(case, documents, credential=True)

def expect_no_credential(case, pull_secrets=()):
    documents = docs(case)
    for name in (secret_name, hook_secret_name):
        check(chart_secret(documents, name) is None, f"{case}: {name} Secret rendered")
    pods = list(pod_specs(documents))
    check(len(pods) >= 10, f"{case}: only {len(pods)} pods run a CARTO image; the selection is broken")
    for d, pod in pods:
        check(not set(pull_secret_names(pod)) & {secret_name, hook_secret_name}, f"{case}: {d['kind']}/{d['metadata']['name']} lists a chart Secret")
    check_collectors(case, documents, credential=False, pull_secrets=pull_secrets)

expect_credential("default-key", "chart-test-default")
expect_credential("ai-hook", "chart-test-default")
expect_no_credential("kots")
expect_no_credential("existing-secret")
expect_no_credential("manual-secret-no-key", pull_secrets=("carto-registry",))
check_collectors("checker-pull-secret", docs("checker-pull-secret"), credential=True, pull_secrets=("checker-pull",))

# A mirror keeps the chart's Secret, whose keys match no mirror image even on a CARTO host.
mirror = docs("mirror")
mirror_secret = chart_secret(mirror)
check(mirror_secret is not None, "mirror: no Secret rendered")
mirror_images = [i for _, pod in all_pods(mirror) for i in images(pod) if i.startswith("us-docker.pkg.dev/mirror-example/")]
check(len(mirror_images) >= 10, f"mirror: only {len(mirror_images)} images use the mirror; the selection is broken")
if mirror_secret is not None:
    check(not any(i.startswith(key + "/") for i in mirror_images for key in auths(mirror_secret)), "mirror: a credential key matches a mirror image")
check_collectors("mirror", mirror, credential=True)

manual = docs("manual-secret")
for d, pod in pod_specs(manual):
    names = pull_secret_names(pod)
    check("carto-registry" in names and credential_name(d) in names, f"manual-secret: {d['kind']}/{d['metadata']['name']} has {names}")
check_collectors("manual-secret", manual, credential=True, pull_secrets=("carto-registry",))

for case in ("default-key", "manual-secret", "workload-identity", "carto-registry-override"):
    check_pull_key_check(case, docs(case), key_id="chart-test-default")
for case in ("kots", "existing-secret", "manual-secret-no-key", "mirror", "disconnected"):
    check_pull_key_check(case, docs(case))
# Under Workload Identity the checker gets the key only for the image pull check.
wi_init = env(collectors(troubleshoot_spec(docs("workload-identity"), "preflight", "preflight.yaml"))[CHECKER]["podSpec"]["initContainers"][0])
check("DEFAULT_SERVICE_ACCOUNT_KEY__FILE_CONTENT" not in wi_init, "workload-identity: the checker gets the default service account key")

def read_notes(case):
    return yaml.safe_load(open(f"{work}/{case}.notes"))["data"]["notes"]

warning = "CARTO IMAGE PULL CREDENTIAL MISSING"
check(warning in read_notes("no-key") and "customer package" in read_notes("no-key"), "no-key: NOTES does not ask for the customer package")
existing = read_notes("existing-secret-notes")
check(warning in existing and "global.imagePullSecrets" in existing, "existing-secret: NOTES does not ask for global.imagePullSecrets")
check(warning not in read_notes("manual-secret-notes"), "manual-secret: NOTES warns")
check(warning not in read_notes("default-key-notes"), "default-key: NOTES warns")

if failures:
    print("\n".join("FAIL " + f for f in failures))
    sys.exit(1)
print("image pull credential: all checks passed")
PY
