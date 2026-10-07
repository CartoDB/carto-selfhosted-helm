---
paths:
  - "chart/templates/**"
---

# Helm templates

Read `chart/CLAUDE.md` first: component layout, `_helpers.tpl` invariants,
validators, preflights.

## Go template truthiness

- **DO NOT** change `{{- if .Values.<component>.affinity }}` with an
  `affinity: {}` default. Empty map, empty list and empty string are all
  false in `if`, so it falls through to the preset branch as intended.
- **DO NOT** replace `default list` or `default dict`. A niladic function used
  as an argument is called, so `range` gets an empty list.
- **DO** give every key a template reads a default in `chart/values.yaml`.
  A missing key is a nil-pointer error (`nil pointer evaluating
  interface {}.enabled`) for any values file that leaves it out; KOTS sets
  every key it maps, so only pure-Helm installs break. `dig` and `default ""`
  are a fallback, not a substitute.

## Conditional blocks

- **DO** grep the file for a key before adding a block that emits it. The
  same key emitted by two conditions renders a ConfigMap that Helm accepts and
  the API server rejects, and `helm template` does not fail on it: render with
  values that enable both conditions and check the key appears once.
- **DO** reuse the helper that already encodes a condition
  (`carto.trustedCACerts.enabled`, `carto.proxy.computedConnectionString`,
  `carto.featureFlags.enabled`, …). **DO NOT** re-derive it inline.
- **DO** test a helper that emits `"true"` or `""` with
  `{{ if (include "carto.x" .) }}`. `include` returns a string; **DO NOT** add
  `eq "true"`.

## Never hardcode

**DO NOT** hardcode registries (`carto.images.image` honours
`global.imageRegistry`), ports (`<component>.containerPorts.*`,
`<component>.service.ports.*`), namespaces (`.Release.Namespace`), provider
names or hostnames.

## Deployments

- **DO** omit `replicas` when `<component>.autoscaling.enabled` is set.
- **DO** keep the `checksum/*` pod annotations of the files a Deployment
  consumes (its `configmap.yaml` and, where present, its `secret.yaml` and the
  shared `custom-feature-flags-configmap.yaml`). A new ConfigMap key rolling
  the pods on upgrade is intended.
- **DO** give a new component the uniform manifest set, a helpers block, an
  entry in `carto.imagePullSecrets`, `statusInformers` in
  `manifests/kots-app.yaml`, and its enablement gate (`chart/CLAUDE.md`).

## Then

`helm template` both paths (plain and `--set replicated.enabled=true`) with
values that turn your change on.
