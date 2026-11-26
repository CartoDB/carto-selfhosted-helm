#!/usr/bin/env bash
#
# Verify the leftover checker pod analyzer against real pod JSON: in both the
# preflight and the support-bundle spec it must warn on a leftover checker pod,
# pass on a clean namespace, and stay silent when the pods collector wrote no file.
#
# Prerequisites: helm, kubectl support-bundle, python3 with PyYAML. Run
# `helm dependency update chart` first when charts/ is stale (CI does it once).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$CHART_DIR"

helm template carto . -n test > "$WORK_DIR/default.rendered"
helm template carto . -n test --set replicated.enabled=true > "$WORK_DIR/kots.rendered"

python3 - "$WORK_DIR" <<'PY'
import json, os, subprocess, sys, tarfile, yaml

work = sys.argv[1]
CHECK = "No checker pod left from an earlier run"
CHECKER = "tenant-requirements-check"
SPECS = (("carto-preflight-config", "preflight.yaml"), ("carto-support-bundle", "support-bundle-spec"))
failures = []

def check(cond, msg):
    if not cond:
        failures.append(msg)

def docs(case):
    with open(f"{work}/{case}.rendered") as f:
        return [d for d in yaml.safe_load_all(f) if d]

def troubleshoot_spec(case, name, key):
    # By name: on KOTS the Replicated subchart renders its own Secret with the same label.
    for d in docs(case):
        if d.get("kind") == "Secret" and d["metadata"]["name"] == name:
            return yaml.safe_load(d["stringData"][key])
    raise SystemExit(f"{case}: no {name} Secret rendered")

def leftover_analyzers(case, name, key):
    return [a["textAnalyze"] for a in troubleshoot_spec(case, name, key)["spec"]["analyzers"] if a.get("textAnalyze", {}).get("checkName") == CHECK]

# support-bundle analyze rejects kind: Preflight, so each analyzer goes into its own SupportBundle.
spec_files = {}
for case in ("default", "kots"):
    for name, key in SPECS:
        found = leftover_analyzers(case, name, key)
        check(len(found) == 1, f"{case}: {name} has {len(found)} leftover checker pod analyzers")
        if len(found) == 1:
            path = f"{work}/{case}-{name}.json"
            with open(path, "w") as f:
                json.dump({"apiVersion": "troubleshoot.sh/v1beta2", "kind": "SupportBundle", "metadata": {"name": "leftover-pod"}, "spec": {"analyzers": [{"textAnalyze": found[0]}]}}, f)
            spec_files[(case, name)] = path

# Pods come from the rendered collector so the fixture follows the chart.
run_pod = next(c["runPod"] for c in troubleshoot_spec("default", "carto-support-bundle", "support-bundle-spec")["spec"]["collectors"] if c.get("runPod", {}).get("collectorName") == CHECKER)

def pod(name, phase):
    return {"kind": "Pod", "apiVersion": "v1", "metadata": {"name": name, "namespace": "test"}, "spec": run_pod["podSpec"], "status": {"phase": phase}}

# The release pod reuses the checker podSpec, so its container names are near misses a substring match would flag.
PODS = {
    "leftover": [pod("carto-workspace-api-5d8f9c7b6-x2k4p", "Running"), pod(run_pod["name"], "Pending")],
    "clean": [pod("carto-workspace-api-5d8f9c7b6-x2k4p", "Running")],
    "nofile": None,
}

def bundle(case, items):
    root = f"{work}/bundle-{case}/fixture"
    os.makedirs(f"{root}/cluster-resources/pods", exist_ok=True)
    with open(f"{root}/version.yaml", "w") as f:
        f.write('apiVersion: troubleshoot.sh/v1beta2\nkind: SupportBundle\nspec:\n  version: "test-fixture"\n')
    if items is not None:
        with open(f"{root}/cluster-resources/pods/test.json", "w") as f:
            json.dump({"kind": "PodList", "apiVersion": "v1", "metadata": {"resourceVersion": "1"}, "items": items}, f, indent=2)
    tgz = f"{work}/{case}.tar.gz"
    with tarfile.open(tgz, "w:gz") as tar:
        tar.add(root, arcname="fixture")
    return tgz

BUNDLES = {case: bundle(case, items) for case, items in PODS.items()}

def results(case, spec_file):
    proc = subprocess.run(["kubectl", "support-bundle", "analyze", "--bundle", BUNDLES[case], "--output", "json", spec_file], capture_output=True, text=True)
    check(proc.returncode == 0, f"{case}: analyze failed for {spec_file}: {proc.stderr.strip()}")
    if proc.returncode:
        return []
    return [r for r in json.loads(proc.stdout) if r.get("Title") == CHECK]

for case, want in (("leftover", "warn"), ("clean", "pass"), ("nofile", "none")):
    for (render, name), spec_file in spec_files.items():
        got = results(case, spec_file)
        where = f"{case} bundle with the {render} {name} analyzer"
        if want == "none":
            check(got == [], f"{where}: {len(got)} results, want none")
            continue
        check(len(got) == 1, f"{where}: {len(got)} results, want 1")
        if len(got) != 1:
            continue
        if want == "warn":
            check(got[0].get("IsWarn") is True, f"{where}: not a warning: {got[0]}")
            check(f"kubectl delete pod {CHECKER} -n test" in got[0].get("Message", ""), f"{where}: message lacks the delete command: {got[0].get('Message')}")
        else:
            check(got[0].get("IsPass") is True, f"{where}: not a pass: {got[0]}")

if failures:
    print("\n".join("FAIL " + f for f in failures))
    sys.exit(1)
print("checker leftover pod analyzer: all checks passed")
PY
