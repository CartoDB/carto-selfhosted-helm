#!/usr/bin/env bash
# Flag chart components whose resources.limits exceed the container-limit ceiling
# admitted on CARTO-managed clusters. A component above the ceiling is rejected at
# admission and its Deployment sits at 0 replicas, so this has to fail at PR time.
#
# Ceiling source of truth (keep the defaults below in sync with it):
# https://github.com/CartoDB/gatekeeper-selfhosted-kubernetes/blob/main/gatekeeper/constraints/psp-container-limits.yaml
#
# Usage: check-resource-limits.sh <values-file>
# Env:   MAX_CPU_M (default 4000), MAX_MEMORY_MI (default 12288)
set -euo pipefail

VALUES_FILE="${1:?usage: check-resource-limits.sh <values-file>}"
MAX_CPU_M="${MAX_CPU_M:-4000}"
MAX_MEMORY_MI="${MAX_MEMORY_MI:-12288}"

# `..` descends into lists as well as maps, so sidecars/initContainers are covered.
# Absent or null limits render as the string "null", which awk coerces to 0 — below
# any ceiling, so unset limits are silently skipped rather than crashing the check.
offenders=$(
  yq -r '.. | select(type == "!!map" and has("resources"))
         | [(path | join(".")), .resources.limits.cpu, .resources.limits.memory]
         | @tsv' "$VALUES_FILE" |
    awk -F'\t' -v max_cpu="$MAX_CPU_M" -v max_mem="$MAX_MEMORY_MI" '
      { cpu = $2; mem = $3
        if (cpu ~ /m$/) sub(/m$/, "", cpu); else cpu *= 1000
        if (mem ~ /Gi$/) { sub(/Gi$/, "", mem); mem *= 1024 } else sub(/Mi$/, "", mem)
        if (cpu + 0 > max_cpu || mem + 0 > max_mem) print "  " $1 ": cpu=" $2 " memory=" $3 }'
)

if [ -n "$offenders" ]; then
  echo "Resource limits above the admission ceiling (${MAX_CPU_M}m CPU / ${MAX_MEMORY_MI}Mi) in ${VALUES_FILE}:"
  echo "$offenders"
  echo
  echo "To raise the ceiling: edit gatekeeper/constraints/psp-container-limits.yaml in"
  echo "https://github.com/CartoDB/gatekeeper-selfhosted-kubernetes, get it applied to the"
  echo "CARTO-managed clusters, then bump MAX_CPU_M / MAX_MEMORY_MI in the caller — in the"
  echo "same PR that raises the component's limits."
  exit 1
fi

echo "All resources.limits in ${VALUES_FILE} are within ${MAX_CPU_M}m CPU / ${MAX_MEMORY_MI}Mi."
