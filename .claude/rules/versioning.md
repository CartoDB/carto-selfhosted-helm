---
paths:
  - "VERSION"
  - "chart/Chart.yaml"
  - "manifests/kots-helm.yaml"
  - "chart/templates/pre-upgrade-check-versions-*.yaml"
---

# Versioning

**Normally you don't touch these by hand.** The numbers originate in cloud-native:
the chart's app version *is* the CARTO cloud-native release version. When
cloud-native cuts a self-hosted release (RC or stable), it opens a bot PR here
(titled `:rocket: Update to <chartVersion>-<appVersion>`) that sets all the
version fields atomically:

| File / field | Value |
|---|---|
| `VERSION` (repo root) | release version, e.g. `2026.5.14` (or `…-rc.8`) |
| `chart/Chart.yaml#appVersion` | same as `VERSION` |
| `chart/Chart.yaml#version` | chart SemVer, e.g. `1.266.1` |
| `manifests/kots-helm.yaml#spec.chart.chartVersion` | equals chart version |
| `chart/Chart.yaml#annotations.minVersion` | oldest upgradeable-from version |

`appVersion` and `minVersion` are *not* decisions made in this repo.

**The only time you edit versions by hand** is an out-of-band chart-only change
(a chart hotfix with no cloud-native bump). Then keep the trio in lockstep
yourself — `Chart.yaml#version` == `kots-helm.yaml#spec.chart.chartVersion` — and
leave `appVersion` / `VERSION` / `minVersion` alone unless you mean to move them.

## Version-skew gate (`pre-upgrade-check-versions-*.yaml`)

Stops a customer upgrading from a too-old release. `Chart.yaml` carries an
`annotations.minVersion` (e.g. `"2025.9.1"`) = the **oldest prior CARTO version
allowed to upgrade to this chart**. Two Helm **`pre-upgrade`/`pre-install`
hooks**, gated by `upgradeCheck.enabled`: a ConfigMap (hook-weight `-10`) ships a
`check-version.sh`, and a Job (weight `-5`, `backoffLimit: 0`) runs it, comparing
`minVersion` against the installed `customerPackageVersion` via `sort -V`.
Mismatch → job fails → **the whole upgrade aborts before any resource changes**.

`appVersion` (what you're upgrading *to*) and `minVersion` (oldest you can upgrade
*from*) are independent. When bumping `appVersion`, only raise `minVersion` if
there's a real breaking reason — raising it too far strands customers on recent
versions. (Note `customerPackageVersion` is injected externally, not defaulted in
`values.yaml`; empty → cryptic failure.)
