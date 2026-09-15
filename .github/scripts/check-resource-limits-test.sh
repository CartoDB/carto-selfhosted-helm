#!/usr/bin/env bash
# Self-test for check-resource-limits.sh. Without this, a later "simplification" of
# the unit normalization could stop catching offenders and nothing would notice.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="${SCRIPT_DIR}/check-resource-limits.sh"
FIXTURE="${SCRIPT_DIR}/testdata/resource-limits-fixture.yaml"

failures=0

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

output=$(MAX_CPU_M=4000 MAX_MEMORY_MI=12288 "$CHECK" "$FIXTURE" 2>&1)
status=$?

# The fixture is deliberately over the ceiling, so a passing check means the guard is broken.
if [ "$status" -eq 0 ]; then
  fail "fixture has offenders but the check exited 0 — the guard does not fail builds"
fi

# Every shape that must be reported.
for key in overCpuMillis overCpuBareCores overMemoryGi overMemoryMi nestedList.sidecars.0; do
  if ! grep -q "  ${key}: " <<<"$output"; then
    fail "expected offender '${key}' was not reported"
  fi
done

# Every shape that must stay silent: unset/null limits must not crash or false-positive,
# and a value exactly at the ceiling is allowed.
for key in requestsOnly nullLimits emptyLimits atCeiling bareCoresUnder; do
  if grep -q "  ${key}: " <<<"$output"; then
    fail "'${key}' must not be flagged but was"
  fi
done

# A ceiling above everything in the fixture must pass, proving the comparison is
# actually driven by MAX_* and not hardcoded.
if ! MAX_CPU_M=100000 MAX_MEMORY_MI=100000 "$CHECK" "$FIXTURE" >/dev/null 2>&1; then
  fail "fixture should pass when the ceiling is raised above every entry"
fi

if [ "$failures" -ne 0 ]; then
  echo
  echo "check-resource-limits.sh self-test: ${failures} failure(s)"
  echo "--- check output against the fixture ---"
  echo "$output"
  exit 1
fi

echo "check-resource-limits.sh self-test: all assertions passed."
