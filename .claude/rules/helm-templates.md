---
paths:
  - "chart/templates/**"
---

# Helm templates

Read `chart/CLAUDE.md` first: component layout, `_helpers.tpl` invariants,
validators, preflights. This file is the list of mistakes that reach review.

## Go template truthiness

- Empty map, empty list and empty string are all **false** in `if`. The
  `{{- if .Values.<component>.affinity }}` pattern with an `affinity: {}`
  default correctly falls through to the preset branch. Automated review has
  claimed the opposite (#890) — don't "fix" it.
- `default list` and `default dict` are fine: a niladic function used as an
  argument is called, so `range` gets an empty list (#896, another false
  positive).
- Reading a key that has no default in `values.yaml` is a nil-pointer error
  (`nil pointer evaluating interface {}.enabled`) as soon as a customer's values
  file leaves it out. KOTS sets every key it maps, so KOTS installs hide the
  bug (sc-575799). Every key a template reads has a default in
  `chart/values.yaml`; `dig` and `default ""` are a fallback, not a substitute.

## Conditional blocks

- Before adding a block that emits a key, grep the file for that key. The
  same key emitted by two conditions renders a ConfigMap that Helm accepts and
  the API server rejects (#894, eleven files). `helm template` does not fail
  on it: render with values that enable both conditions and check the key
  appears once.
- Reuse the helper that already encodes the condition
  (`carto.trustedCACerts.enabled`, `carto.proxy.computedConnectionString`,
  `carto.featureFlags.enabled`, …) instead of re-deriving it inline (#894).
- `include` returns a string. A helper that emits `"true"` or `""` is tested
  with `{{ if (include "carto.x" .) }}`; `eq "true"` adds nothing (#896).

## Never hardcode

Registries (`carto.images.image` honours `global.imageRegistry`), ports
(`<component>.containerPorts.*`, `<component>.service.ports.*`), namespaces
(`.Release.Namespace`), provider names, hostnames. Reviewers reject each one
(#890, #938).

## Deployments

- `replicas` is omitted when `<component>.autoscaling.enabled` is set (#891).
- Deployments carry `checksum/*` pod annotations of the files they consume
  (their `configmap.yaml` and, where present, their `secret.yaml` and the
  shared `custom-feature-flags-configmap.yaml`): a new ConfigMap key rolls the
  pods on upgrade, which is intended.
- A new component needs the uniform manifest set, a helpers block, an entry
  in `carto.imagePullSecrets`, `statusInformers` in `manifests/kots-app.yaml`,
  and its enablement gate (`chart/CLAUDE.md`).

## Then

`helm template` both paths (plain and `--set replicated.enabled=true`) with
values that turn your change on.
