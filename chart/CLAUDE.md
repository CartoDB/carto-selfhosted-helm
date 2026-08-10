# chart/ — the Helm chart (source of truth)

Each subdirectory under `templates/` is one component, and they are uniform:
the same handful of manifests (configmap, deployment, hpa, ingress, pdb,
service, secret) per component. `valkey` is the current cache; `redis` is the
legacy name kept for backward compatibility — **don't rename it**, it breaks
existing installs (the `carto.redis.*` helpers resolve to Valkey on purpose).

## Where a new `values.yaml` parameter goes

Placement is by **what the parameter configures**, not by how many templates
read it — several `appConfigValues`/`cartoConfigValues` keys already have
exactly one consumer (`ldsGeocodingProvider`, `defaultDoLocation.*`) and stay
in the shared block anyway.

- **`appConfigValues`** — CARTO application/business behavior the *customer*
  sets: feature toggles, storage/bucket config, provider selection (LDS/AT/DO
  defaults), engine tuning for an app-level feature (e.g.
  `appConfigValues.duckdb.*` for the import/export transfer engine).
- **`cartoConfigValues`** — the same shape, but for wiring the customer
  normally never touches (Auth0, CARTO's own GCP project IDs, LaunchDarkly,
  feature-flag overrides) — changing it can break the install.
- **A component's own block** (`importWorker:`, `mapsApi:`, …) — only that
  component's Kubernetes deployment shape: image, resources, probes,
  replicaCount, security context, affinity/scheduling, service, PDB,
  sidecars/extraVolumes — or a setting that's conceptually process/pod sizing
  for *that* pod. `<component>.defaultNodeProcessMaxOldSpace` (Node heap size)
  is the precedent: it stays local in every one of the 10 components that have
  it, because it's runtime sizing for that pod, not app behavior — true even
  where it's no longer literally computed as a percentage of that pod's own
  `resources.limits.memory` (`importWorker` decoupled the two once DuckDB
  started allocating memory outside the V8 heap; the heap knob stayed put,
  only the DuckDB memory/thread/spill knobs moved to `appConfigValues.duckdb`).

`router.nginxConfig.*` and `aiApi.customHeaders` predate this rule and are
app-behavior knobs sitting in a component block anyway — legacy, not
precedent to copy.

**Corollary — whole-component enablement.** Whether an optional component
deploys at all follows the same split: customer-facing feature components
(`httpCache`, `publicEventsApi`, `aiApi`, `aiProxy`, `cdnInvalidatorSub`) are
gated by an `appConfigValues.*Enabled` boolean plus `not
cartoConfigValues.onlyRunRouter` — never a self `<component>.enabled` field.
The exception is infra swap-components choosing between CARTO's bundled
instance and a customer's own: `internalRedis.enabled`,
`internalPostgresql.enabled`, and `gateway.enabled` gate themselves, because
swapping infrastructure backends is that component's own concern, not an
app-feature decision.

## Feature flags vs `appConfigValues.*Enabled` toggles

Two different mechanisms gate behavior — pick by axis of control, not by
where the value happens to live:

- **`cartoConfigValues.featureFlagsOverrides`** (LaunchDarkly-backed, see
  `cartoConfigValues.launchDarklyClientSideId`) is CARTO's staged-rollout
  mechanism. The test for wiring a new component into it is a fact about that
  component's *code*, not about `values.yaml`: does its backend actually call
  the internal `FeatureFlagsClient`? If yes, wire the same four pieces every
  already-wired component has — the `CARTO_FEATURE_FLAGS_FILE_PATH` env var, a
  `feature-flags` volume mount, the volume itself, and a
  `checksum/feature-flags-config` pod annotation — gated on
  `carto.featureFlags.enabled`. Don't wire infra (`router`, `httpCache`,
  `gateway`) or third-party images (`aiProxy`/LiteLLM) that don't consume the
  flag file — an unused mount just adds a spurious restart trigger. The chart
  can also auto-derive an override from deployment config (an S3-compatible
  `appConfigValues.s3Endpoint` auto-enables a storage-related flag) — still
  CARTO's mechanism, just reacting to the customer's config instead of a human
  toggling LaunchDarkly.
- **`appConfigValues.*Enabled` booleans** are the customer's permanent,
  structural choice — does this install have this component/route at all —
  set once at install, not staged or gradually rolled out.

Wiring a new backend feature and unsure which one: staged rollout across the
fleet → feature flag; a customer's install-time decision → `appConfigValues`.

## `_helpers.tpl` invariants

Per-component helpers are uniform (`carto.<component>.fullname`,
`.configmapName`, `.secretName`, `.image`…) — grep `carto.<component>.` rather
than trusting any list written here.

- **Never hardcode an image registry.** `carto.images.image` builds
  `registry/repo:tag` and lets `global.imageRegistry` override *every*
  component's registry — that single global is how air-gapped installs
  redirect images. Hardcoding a registry (especially a SaaS-only one) breaks
  that. `carto.imagePullSecrets` aggregates every component image; add a
  component but forget it there and the image has no pull secret.
- **Secret injection is a framework, not a one-off.**
  `carto._utils.secretAssociation` maps `ENV_VAR: <group>.<field>` into
  `values.yaml` (`cartoSecrets.*` = CARTO-internal, `appSecrets.*` =
  customer-provided). `generateSecretObjects` (called from each component's
  `secret.yaml`) writes the value into the chart Secret when there's no
  `existingSecret.name`; `generateSecretDefs` (called from `deployment.yaml`)
  emits the env entry either way. A new secret needs the map entry, the
  `values.yaml` field, **and both call sites** — miss one and either the
  autogenerated or the customer-supplied path silently goes missing. **The map
  is hand-maintained and unvalidated**: a typo in the values path renders an
  empty env var with no error. This is the most common "service starts without
  its credential" bug — changes here deserve a second reviewer.
- **Three separate secret mechanisms — don't conflate them.** A field's own
  `.existingSecret.name`/`.key` (nested inside `appSecrets.<field>` /
  `cartoSecrets.<field>`) only affects that one env var via the
  `secretAssociation` map above. A *component's* top-level
  `<component>.existingSecret` is unrelated: it redirects that component's
  whole generated Secret (`envFrom.secretRef.name`) to a customer-managed one,
  independent of which individual fields are set — same shape as
  `<component>.existingConfigMap`. Database credentials
  (`internalPostgresql`/`externalPostgresql`/`externalRedis`,
  `cartoSecrets.redisPassword`) sit outside `secretAssociation` entirely, on
  an older `existingSecret`/`existingSecretPasswordKey` convention — don't
  expect them in the map. `extraEnvVarsSecret`/`extraEnvVarsCM` is a third,
  generic escape hatch for arbitrary customer-supplied env vars, unrelated to
  both.
- **`nodeOptions` assume `Mi`.** The Node.js `--max-old-space-size` helpers
  parse the memory limit only when its unit is `Mi`; anything else silently
  falls back to the default instead of erroring.
- **TLS secret names are content-hashed** (`<release>-tls-<hash>`), so a cert
  change forces a rollout — intended. The top-level `tlsCerts.*` helpers are
  **deprecated** in favor of `router.tlsCertificates` /
  `gateway.tlsCertificates`; don't add new uses.
- `carto.*.passwordChecksum` helpers are cache-busters surfaced as pod
  annotations so a rotated password restarts the pods.

## `_validators.tpl` — fail-fast config guards

Each guard is `carto.validateValues.<thing>` returning a message **only when
misconfigured**; the aggregator `carto.validateValues` joins non-empty results
and calls Helm's `fail`. It's invoked from `NOTES.txt`, so validation fires on
every render — no separate step. Grep `carto.validateValues.` for the current
set.

To add one: write the guard, `append` its include into `$messages` in the
aggregator. Mind the blast radius both ways — too broad **blocks every
customer install**; too narrow ships broken config that fails cryptically at
runtime. Validators catch *config-time* mistakes only; environment problems
belong in preflights.

## Preflights & support bundle (`_commonChecks.tpl`)

Both `preflight.yaml` and `support-bundle.yaml` render a Secret embedding a
[troubleshoot.sh](https://troubleshoot.sh) spec, sharing collectors/analyzers
from `_commonChecks.tpl`. Preflights run **before** install and **block** it,
so they can only test the *environment* (the app doesn't exist yet); the
support bundle is post-hoc diagnostics and never blocks.

The engine is one pod (`tenant-requirements-check`) that runs the checks and
writes JSON; analyzers assert `…<Validator>.<Check>.status == "passed"`. The
check logic itself lives in the external checker image — in this repo you only
extend the validator/check dict and wire inputs through the checker's env
blocks (files go through the `THING__FILE_CONTENT`/`THING__FILE_PATH`
init-container convention; large CA bundles are chunked `…_01`, `…_02`).

Gotchas:

- A collector with no analyzer collects data nobody reads.
- **The checker pod holds real customer secrets — never let a check echo them
  into its `.info` message**; that string surfaces in preflight output and
  support bundles that customers share.
- Everything runs in `.Release.Namespace` — never hardcode a namespace.
- `onlyRunRouter` (ingress-only test mode) deploys no backends — account for
  it in checks and validators.
- `jsonCompare` messages mix two templating layers (outer Helm `{{ }}`
  emitting an inner troubleshoot.sh `{{ }}` string) — easy to mis-escape.

## Upgrade version-skew gate

`Chart.yaml#annotations.minVersion` is the **oldest prior CARTO version allowed
to upgrade to this chart**. Two pre-upgrade hooks
(`pre-upgrade-check-versions-*.yaml`, gated by `upgradeCheck.enabled`) compare
it against the installed `customerPackageVersion`; a mismatch fails the Job and
aborts the upgrade before any resource changes. `minVersion` (oldest you can
come *from*) and `appVersion` (what you're going *to*) are independent — only
raise `minVersion` for a real breaking reason, or you strand customers.
