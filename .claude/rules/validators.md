---
paths:
  - "chart/templates/_validators.tpl"
  - "chart/templates/NOTES.txt"
---

# `_validators.tpl` — fail-fast config guards

Each guard is a `{{- define "carto.validateValues.<thing>" }}` that returns a
human message **only when misconfigured** (empty otherwise). Grep
`carto.validateValues.` for the current set; the pattern, with representative
examples:

- `redis` — internal disabled *and* no `externalRedis.host` (skipped in
  `onlyRunRouter` mode).
- `postgresql` — internal disabled *and* no `externalPostgresql.host`.
- `proxy` — both `externalProxy.sslCA` *and* `externalProxy.sslCAConfigmap.name`
  set (pick one).
- `logLevel` — `appConfigValues.logLevel` outside the allowed set.
- `serviceAccount` — a Pod Identity feature on (GCP Workload Identity, AWS EKS
  Pod Identity) but no `commonBackendServiceAccount` configured.

The aggregator **`carto.validateValues`** includes each guard, drops the empty
results, joins the rest, and if anything remains calls Helm's built-in **`fail`**
— which aborts `helm template`/`install`. **It's invoked from `NOTES.txt`**, so
the validation fires as part of normal render; there's no separate step. (One TLS
validator, `carto.tlsCerts.duplicatedValueValidator`, is instead called *inline
inside* `carto.tlsCerts.secretName`, so it only fires if a template actually uses
that helper.)

**To add one:** write `carto.validateValues.<thing>` returning a message on the
bad condition, then `append` its include into the `$messages` list in
`carto.validateValues`. Mind the blast radius in both directions: a condition
that's **too broad blocks every install** (non-recoverable for customers); **too
narrow lets broken config ship** and fails cryptically at runtime. Validators
catch *config-time* mistakes only — environment problems belong in preflights
(`_commonChecks.tpl`).
