#!/usr/bin/env bash
#
# Unit-level render contract for the redaction machinery. The behavioral test
# (test-redactors.sh) runs the real redact engine but only exercises the
# Redactor extracted from the support-bundle Secret — the preflight Secret
# ships its own copy of the same include, and a broken indent or dropped
# include there would leak credentials from preflight bundles with every
# behavioral test still green. This test pins the rendered shape of BOTH
# Secrets, on both install paths, without needing a cluster or the
# troubleshoot CLI.
#
# Contract:
#   1. The support-bundle Secret (label troubleshoot.sh/kind: support-bundle)
#      embeds a multi-doc spec: kind SupportBundle + standalone kind Redactor.
#   2. The preflight Secret (label troubleshoot.sh/kind: preflight) embeds
#      kind Preflight + the same standalone Redactor.
#   3. Both Redactor docs carry the identical rule-name list (same include).
#   4. Every rule has at least one removal (regex, yamlPath or values); every
#      regex compiles and contains a (?P<mask>…) group — mask is what
#      troubleshoot replaces with ***HIDDEN***, so a regex rule without one
#      redacts nothing it intends to.
#
# Prerequisites: helm, python3 with PyYAML.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"
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

  python3 - "$WORK_DIR/rendered-$MODE.yaml" "$MODE" <<'PY'
import re, sys, yaml

path, mode = sys.argv[1], sys.argv[2]
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
pf = redactor_from_secret(docs, 'carto-preflight-config', 'preflight', 'preflight.yaml', 'Preflight')

def rule_names(r):
    return [x.get('name') for x in r['spec']['redactors']] if r else []

sb_rules, pf_rules = rule_names(sb), rule_names(pf)
if sb and pf and sb_rules != pf_rules:
    failures.append(f"rule lists diverge: support-bundle={sb_rules} preflight={pf_rules}")

checked = 0
for rule in (sb['spec']['redactors'] if sb else []):
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
print(f"OK    [{mode}] {len(sb_rules)} rules, {checked} regexes, preflight/support-bundle in sync")
PY
done

echo "PASS"
