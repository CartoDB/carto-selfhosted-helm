#!/usr/bin/env python3
"""Flag chart components whose resource *limits* exceed the Gatekeeper ceiling.

CARTO self-hosted clusters (gke-infra, gke-deds, and customer installs that run
Gatekeeper/OPA) enforce a single global `container-must-have-limits` constraint.
If a component's limits go above that ceiling, the pod is rejected at admission
(`FailedCreate`) and the Deployment silently wedges at 0 replicas.

The ceiling here MUST mirror the constraint in
CartoDB/gatekeeper-selfhosted-kubernetes → gatekeeper/constraints/psp-container-limits.yaml
Bump GATEKEEPER_MAX_* (workflow env) whenever that constraint changes.

Reads chart/values.yaml, prints a human report to stdout, and (in CI) writes the
GitHub outputs `exceeds` and `report`. Never fails the build — it only notifies.
"""
import os
import sys

import yaml


def cpu_to_millis(value):
    v = str(value).strip()
    if v.endswith("m"):
        return int(float(v[:-1]))
    return int(float(v) * 1000)


def mem_to_mi(value):
    v = str(value).strip()
    units = {"Gi": 1024, "Mi": 1, "Ki": 1 / 1024, "G": 1000, "M": 1000 / 1024, "K": 1000 / (1024 * 1024)}
    for unit, factor in units.items():
        if v.endswith(unit):
            return int(float(v[: -len(unit)]) * factor)
    # bare number = bytes
    return int(int(v) / (1024 * 1024))


def walk(path, node, cap_cpu, cap_mem, maxes, offenders):
    if not isinstance(node, dict):
        return
    resources = node.get("resources")
    limits = resources.get("limits") if isinstance(resources, dict) else None
    if isinstance(limits, dict):
        cpu = cpu_to_millis(limits["cpu"]) if "cpu" in limits else 0
        mem = mem_to_mi(limits["memory"]) if "memory" in limits else 0
        maxes["cpu"] = max(maxes["cpu"], cpu)
        maxes["mem"] = max(maxes["mem"], mem)
        if cpu > cap_cpu or mem > cap_mem:
            offenders.append(
                {"component": path or "<root>", "cpu": limits.get("cpu"), "memory": limits.get("memory")}
            )
    for key, child in node.items():
        walk(f"{path}.{key}" if path else str(key), child, cap_cpu, cap_mem, maxes, offenders)


def main():
    values_path = os.environ.get("VALUES_PATH", "chart/values.yaml")
    cap_cpu = int(os.environ.get("GATEKEEPER_MAX_CPU_M", "4000"))
    cap_mem = int(os.environ.get("GATEKEEPER_MAX_MEMORY_MI", "12288"))

    with open(values_path) as fh:
        values = yaml.safe_load(fh)

    maxes = {"cpu": 0, "mem": 0}
    offenders = []
    for key, node in (values or {}).items():
        walk(str(key), node, cap_cpu, cap_mem, maxes, offenders)

    print(f"Gatekeeper ceiling: {cap_cpu}m CPU / {cap_mem}Mi memory")
    print(f"Chart max limits:   {maxes['cpu']}m CPU / {maxes['mem']}Mi memory")

    lines = []
    if offenders:
        lines.append(
            f"⚠️ {len(offenders)} chart component(s) exceed the Gatekeeper `container-must-have-limits` "
            f"ceiling of **{cap_cpu}m CPU / {cap_mem}Mi**:"
        )
        for o in offenders:
            lines.append(f"- `{o['component']}` → cpu `{o['cpu']}`, memory `{o['memory']}`")
        lines.append("")
        lines.append(
            "**Action required:** raise the ceiling in "
            "[`gatekeeper-selfhosted-kubernetes`](https://github.com/CartoDB/gatekeeper-selfhosted-kubernetes) "
            "(`gatekeeper/constraints/psp-container-limits.yaml`) and get it applied to gke-infra / gke-deds "
            "**before** this ships — otherwise the pod is rejected at admission (`FailedCreate`) on clusters "
            "that enforce Gatekeeper and the Deployment wedges at 0 replicas."
        )
    report = "\n".join(lines)
    print("\n" + (report or "✅ No component exceeds the Gatekeeper ceiling."))

    gh_out = os.environ.get("GITHUB_OUTPUT")
    if gh_out:
        with open(gh_out, "a") as fh:
            fh.write(f"exceeds={'true' if offenders else 'false'}\n")

    # Write the report to a file so CI can pass it to `gh pr comment --body-file`
    # and to Slack without shell interpolation / injection.
    report_file = os.environ.get("REPORT_FILE")
    if report_file and report:
        with open(report_file, "w") as fh:
            fh.write(report + "\n")


if __name__ == "__main__":
    sys.exit(main())
