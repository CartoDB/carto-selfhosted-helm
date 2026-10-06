#!/usr/bin/env bash
#
# Unit-level render contract for the redaction machinery. The behavioral test
# (test-redactors.sh) runs the real redact engine but only exercises the
# Redactor extracted from the support-bundle Secret. KOTS Admin Console bundles
# never see that Secret's Redactor — they use the release-level copy in
# manifests/kots-redactor.yaml — so a drift between the two would leak
# credentials from KOTS bundles with every behavioral test still green. This
# test pins the rendered shape on both install paths, without needing a
# cluster or the troubleshoot CLI.
#
# Contract:
#   1. The support-bundle Secret (label troubleshoot.sh/kind: support-bundle)
#      embeds a multi-doc spec: kind SupportBundle + standalone kind Redactor.
#   2. That Redactor carries the expected context-first rule list.
#   3. manifests/kots-redactor.yaml carries exactly the same rules.
#   4. Every rule has at least one removal (regex, yamlPath or values); every
#      regex compiles and contains a (?P<mask>…) group — mask is what
#      troubleshoot replaces with ***HIDDEN***, so a regex rule without one
#      redacts nothing it intends to.
#
# Prerequisites: helm, python3 with PyYAML.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
KOTS_REDACTOR="$(dirname "$CHART_DIR")/manifests/kots-redactor.yaml"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

cd "$CHART_DIR"

# helm dep update is intentionally NOT run here — CI does it once upfront so
# the test stays fast. Local users should run it manually if charts/ is stale.
for MODE in default replicated; do
  if [ "$MODE" = "replicated" ]; then
    helm template carto . -n test --set replicated.enabled=true > "$WORK_DIR/rendered-$MODE.yaml"
  else
    helm template carto . -n test > "$WORK_DIR/rendered-$MODE.yaml"
  fi

  python3 - "$WORK_DIR/rendered-$MODE.yaml" "$MODE" "$KOTS_REDACTOR" <<'PY'
import re, sys, yaml

path, mode, kots_path = sys.argv[1], sys.argv[2], sys.argv[3]
failures = []

# Select the release's own Secret by exact name — in replicated mode the SDK
# subchart ships its own (Redactor-free) secret under the same discovery
# label, so label alone is ambiguous. The label is asserted, not selected on:
# discovery depends on it.
def redactor_from_secret(docs, name, label, key, expected_kind):
    for d in docs:
        if not d or d.get('kind') != 'Secret':
            continue
        if d.get('metadata', {}).get('name') != name:
            continue
        if d.get('metadata', {}).get('labels', {}).get('troubleshoot.sh/kind') != label:
            failures.append(f"{name}: missing discovery label troubleshoot.sh/kind={label}")
        spec_text = d.get('stringData', {}).get(key)
        if spec_text is None:
            failures.append(f"{name}: stringData key '{key}' missing")
            return None
        subs = [s for s in yaml.safe_load_all(spec_text) if s]
        kinds = [s.get('kind') for s in subs]
        if expected_kind not in kinds:
            failures.append(f"{name}: embedded spec lacks kind {expected_kind} (found {kinds})")
        redactors = [s for s in subs if s.get('kind') == 'Redactor']
        if not redactors:
            failures.append(f"{name}: no standalone kind: Redactor doc (inline spec.redactors is silently ignored)")
            return None
        return redactors[0]
    failures.append(f"no Secret named {name} in rendered output")
    return None

docs = list(yaml.safe_load_all(open(path)))
sb = redactor_from_secret(docs, 'carto-support-bundle', 'support-bundle', 'support-bundle-spec', 'SupportBundle')
sb_rules = sb['spec']['redactors'] if sb else []

expected_rules = [
    'api-key-json-fields',
    'http-auth-header-values',
    'replicated-license-entitlement-values',
    'tenant-requirements-check-env-values',
]
sb_names = [x.get('name') for x in sb_rules]
if sb and sb_names != expected_rules:
    failures.append(f"unexpected redactor rules: expected={expected_rules} actual={sb_names}")

kots = yaml.safe_load(open(kots_path))
if kots.get('kind') != 'Redactor':
    failures.append(f"{kots_path}: expected kind Redactor, found {kots.get('kind')}")
elif sb and kots['spec']['redactors'] != sb_rules:
    failures.append("manifests/kots-redactor.yaml rules diverge from the chart's support-bundle Redactor")

checked = 0
for rule in sb_rules:
    removals = rule.get('removals', {})
    if not any(removals.get(k) for k in ('regex', 'yamlPath', 'values')):
        failures.append(f"rule '{rule.get('name')}' has no removals (regex/yamlPath/values)")
    for entry in removals.get('regex', []):
        pattern = entry.get('redactor', '')
        try:
            re.compile(pattern)
        except re.error as e:
            failures.append(f"rule '{rule.get('name')}' regex does not compile: {e}")
        if '(?P<mask>' not in pattern:
            failures.append(f"rule '{rule.get('name')}' regex lacks the (?P<mask>…) group")
        checked += 1

for f in failures:
    print(f"FAIL  [{mode}] {f}")
if failures:
    sys.exit(1)
print(f"OK    [{mode}] {len(sb_rules)} rules, {checked} regexes, chart/KOTS redactors in sync")
PY
done

echo "PASS"
