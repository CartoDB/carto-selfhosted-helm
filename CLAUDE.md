# CLAUDE.md

Context for working in this repo. Focus is **how the machinery actually works and where it bites** — not commands.

Process detail (Git setup, doc generation, linting, merging) lives in [`CONTRIBUTING.md`](./CONTRIBUTING.md) — note it still says `stable`, but the repo develops on **`main`**. Full chart params are in the generated [`chart/README.md`](./chart/README.md). The release/versioning chain — and how it's driven from cloud-native — is its own section below.

## What this repo is

A **Helm chart** that deploys CARTO Self-Hosted, shipped two ways:

1. **Pure Helm** — `helm install carto ./chart -f values.yaml`.
2. **Replicated / KOTS** — the same chart wrapped by `manifests/kots-*.yaml` for the KOTS Admin Console and embedded-cluster (single-VM) installs.

It's a *deployment* repo — the container images come from CARTO's cloud-native services; what lives here is values, templates, validation, and the KOTS translation layer.

**Two rules everything follows:** the Helm chart is the **source of truth**, and KOTS only **translates** customer input into chart values. A change must work in *both* paths — Helm-only or KOTS-only is half done.

## Repo map

```
chart/                       the chart — source of truth
  values.yaml                full parameter surface; drives chart/README.md
  Chart.yaml                 version, appVersion, deps, minVersion annotation
  templates/<component>/*     per-component manifests (configmap, deployment, hpa, ingress, pdb, service, secret)
  templates/_helpers.tpl     naming, images, the secretAssociation map + secret-injection helpers
  templates/_validators.tpl  early-fail config guards, aggregated and invoked from NOTES.txt
  templates/_commonChecks.tpl  troubleshoot.sh collectors + analyzers shared by preflight & support bundle
  templates/preflight.yaml / support-bundle.yaml   the two troubleshoot.sh Secrets
  templates/pre-upgrade-check-versions-*.yaml      version-skew gate (Helm pre-upgrade hook)
  templates/NOTES.txt        post-install notes — also where validators fire
manifests/                   Replicated / KOTS layer
  kots-config.yaml           KOTS UI (groups/items, RandomString secrets, license fields)
  kots-helm.yaml             ConfigOption → chart values translation (the heart of the layer)
  kots-app.yaml              KOTS app + statusInformers
  embbeded-cluster.yaml      embedded-cluster (k0s) config — filename misspelled on purpose, don't rename
scripts/test-kots-config.sh  render the KOTS config for gke|eks|aks|all
doc/                         customer-facing customization docs
```

Each subdirectory under `chart/templates/` is a component (`ls chart/templates/` for the current set — they map to CARTO's cloud-native services plus the cache: `valkey` is current, `redis` is the legacy name kept for compatibility). They're uniform — every component carries the same handful of manifests (configmap, deployment, hpa, ingress, pdb, service, secret) and the same helper triad (see the `_helpers.tpl` deep-dive).

## The values flow — internalize this

```
kots-config.yaml   (KOTS UI: items + RandomString secrets)
   └─► kots-helm.yaml   (ConfigOption → chart values; optionalValues[] conditionals)
        └─► chart/values.yaml   (Helm defaults)
             └─► chart/templates/<component>/*   (consume the value, usually via _helpers.tpl)
                  └─► Kubernetes resources
```

**A single new tunable usually has to land in several places at once:** a default in `values.yaml` (with a `## @param` comment), the template wiring, a UI control in `kots-config.yaml` (if the customer sets it), and the mapping in `kots-helm.yaml` — plus a validator in `_validators.tpl` if misconfiguration should fail loudly, or a preflight in `_commonChecks.tpl` if a broken environment should block install. Ship them together: a KOTS change without the chart wiring (or the reverse) ships a value that does nothing, and the customer never knows.

---

# Subsystem deep-dives

## `_helpers.tpl` — the chart's standard library

Almost entirely `{{- define "carto.*" }}` blocks. Everything is **per-component and uniform**: each component has the same triad of helpers — `carto.<component>.fullname`, `.configmapName`, `.secretName`, plus `.image`, and (for Node.js services) `.nodeOptions`. So to find how a component is named or where its config comes from, grep `carto.<component>.`.

**Naming.** `carto.<component>.fullname` = `{{ include "common.names.fullname" . }}-<component>`, truncated to 63 chars. Everything keys off this — Service/Deployment names, the `app.kubernetes.io/name` selector, ConfigMap/Secret names (which return `existingConfigMap`/`existingSecret` if the customer set one, else the fullname).

**Images & the registry indirection.** `carto.images.image` (the universal builder) takes a component's image config and produces `registry/repo:tag`, coalescing the tag from `imageRoot.tag` or `.Chart.AppVersion`. The key line: **if `.global.imageRegistry` is set it overrides the per-component registry** — that single global is how air-gapped/local-registry installs redirect *every* image. This is why you must **never hardcode `gcr.io/carto-artifacts`** (SaaS-only); customer images come from `registry.self-hosted.carto.com` (→ `gcr.io/carto-onprem-artifacts`), and the global override swaps in a private registry. `carto.imagePullSecrets` aggregates *every* component image — add a component but forget it here and that image has no pull secret.

### Secret injection — the part reviewers care about most

This is a small framework, not a one-off. Four helpers plus one map:

- **`carto._utils.secretAssociation`** (the map) — a YAML block of `ENV_VAR_NAME: <valuesGroup>.<field>`, e.g. `IMPORT_JWT_SECRET: cartoSecrets.jwtApiSecret`, `BIGQUERY_OAUTH2_CLIENT_SECRET: appSecrets.bigqueryOauth2ClientSecret`. Left = the env var the container reads; right = the path into `values.yaml` (`cartoSecrets.*` = CARTO-internal, `appSecrets.*` = customer-provided).
- **`generateSecretObjects` / `generateSecretObject`** — consumed by each component's **`secret.yaml`**. Walks the map, and for each var whose `values.yaml` entry has an **empty `existingSecret.name`**, base64-encodes the value into the Secret resource.
- **`generateSecretDefs` / `generateSecretDef`** — consumed by each component's **`deployment.yaml`**. Emits the container `env:` entry. For a customer-provided `existingSecret.name`, it emits a `valueFrom.secretKeyRef` pointing at the external Secret instead of the in-chart one.

The two helpers are **mirror images**: `Objects` writes the value when there is *no* existing secret; `Defs` wires the env var either way. A component needs **both** call sites (its `secret.yaml` *and* `deployment.yaml`) or one path — autogenerated or customer-supplied — silently goes missing.

**To add a secret env var:** (1) add `MY_ENV: appSecrets.myField` (or `cartoSecrets.*`) to `secretAssociation`; (2) add `myField` (with `value` / `existingSecret.{name,key}`) to the matching group in `values.yaml`; (3) make sure the consuming component's `secret.yaml` and `deployment.yaml` include the var. **The map is hand-maintained and unvalidated** — a typo in the values path renders an empty env var with no error. This is the single most common "service starts without its credential" bug, and why touching `secretAssociation` warrants a second reviewer.

### Helper gotchas

- **Node.js `nodeOptions` assume `Mi`.** `carto.<component>.nodeOptions` parses the memory limit to compute `--max-old-space-size`; if the unit isn't `Mi` (e.g. someone writes `1G`), it silently falls back to a default instead of erroring.
- **TLS secret names are content-hashed.** `carto.router.tlsCertificates.secretName` → `<release>-tls-<hash>`, so changing a cert changes the name and forces a rollout (intended). The legacy top-level `tlsCerts.*` helpers are **deprecated** in favor of `router.tlsCertificates` / `gateway.tlsCertificates` — don't add new uses.
- **`carto.redis.*` is Valkey.** The `redis` helper names are kept for backward compatibility but resolve to the Valkey dependency. Don't "rename to fix it" — it breaks existing installs.
- **Postgres/Redis password checksums** (`carto.*.passwordChecksum`) are SHA256 cache-busters surfaced as pod annotations so a rotated password triggers a restart.

## `_validators.tpl` — fail-fast config guards

Each guard is a `{{- define "carto.validateValues.<thing>" }}` that returns a human message **only when misconfigured** (empty otherwise). Grep `carto.validateValues.` for the current set; the pattern, with representative examples:

- `redis` — internal disabled *and* no `externalRedis.host` (skipped in `onlyRunRouter` mode).
- `postgresql` — internal disabled *and* no `externalPostgresql.host`.
- `proxy` — both `externalProxy.sslCA` *and* `externalProxy.sslCAConfigmap.name` set (pick one).
- `logLevel` — `appConfigValues.logLevel` outside the allowed set.
- `serviceAccount` — a Pod Identity feature on (GCP Workload Identity, AWS EKS Pod Identity) but no `commonBackendServiceAccount` configured.

The aggregator **`carto.validateValues`** includes each guard, drops the empty results, joins the rest, and if anything remains calls Helm's built-in **`fail`** — which aborts `helm template`/`install`. **It's invoked from `NOTES.txt`**, so the validation fires as part of normal render; there's no separate step. (One TLS validator, `carto.tlsCerts.duplicatedValueValidator`, is instead called *inline inside* `carto.tlsCerts.secretName`, so it only fires if a template actually uses that helper.)

**To add one:** write `carto.validateValues.<thing>` returning a message on the bad condition, then `append` its include into the `$messages` list in `carto.validateValues`. Mind the blast radius in both directions: a condition that's **too broad blocks every install** (non-recoverable for customers); **too narrow lets broken config ship** and fails cryptically at runtime. Validators catch *config-time* mistakes only — environment problems belong in preflights below.

## `_commonChecks.tpl` + preflight/support-bundle — environment checks

This is the [troubleshoot.sh](https://troubleshoot.sh) framework. Both `preflight.yaml` and `support-bundle.yaml` render a **Kubernetes Secret** whose `stringData` embeds a troubleshoot.sh spec as a string, discovered by the label `troubleshoot.sh/kind: preflight` (or `support-bundle`). Both pull their shared collectors/analyzers from `_commonChecks.tpl`.

- **Preflight** = runs **before** install, **blocks** it on failure. Pre-install, the app pods don't exist yet — so preflights can only test the *environment*.
- **Support bundle** = post-hoc **diagnostics**, never blocks. It includes the same environment checks *plus* cluster info, namespaced pod logs, and pod-status analyzers (CrashLoopBackOff, ImagePullBackOff, Pending, …).

**The engine is one pod.** The main collector (`carto.replicated.commonChecks.collectors`) launches a `tenant-requirements-check` pod from the `tenant-requirements-checker` image. An **init container unpacks secrets/certs from env vars into files** (the `THING__FILE_CONTENT` / `THING__FILE_PATH` convention; large Postgres CA bundles are chunked into `…_01`, `…_02`, … to dodge the env-var size limit, then reassembled). The pod runs the checks and writes a JSON log; the **analyzers read that JSON**.

**The verdict pattern.** `_commonChecks.tpl` builds a dict of `Validator → [Check names]`, then loops it into one `jsonCompare` analyzer per check that asserts `…<Validator>.<Check>.status == "passed"`, surfacing the pod's own `.info` string as the message. Checks in the **optional list** (TomTom, TravelTime connectivity) emit **`warn` instead of `fail`** so they don't block. Several validators are **conditional**: the Redis check only exists when `internalRedis.enabled=false`; certificate checks only when a cert is provided; feature-flag check only when overrides are set.

**What's actually checked** (environment, blocking unless noted): Postgres reachability / UTF8 encoding / permissions / version / optional SSL cert; cache (Redis/Valkey) reachability + multi-DB support + optional TLS; object storage (GCS/S3/Azure) assets+temp bucket read/write; Google service-account validity (when not using Workload Identity); egress to CARTO auth, PubSub, GCS, release channels, image registry (+ optional TomTom/TravelTime); PubSub publish/consume; feature-flag JSON validity; provided TLS certs. **Cluster-level analyzers** (K8s version floor, container runtime, supported distribution, minimum CPU/RAM, Gateway API CRD when `gateway.enabled` — exact thresholds in `_commonChecks.tpl`) run **only when `replicated.platformDistribution != ""`**.

**To add an environment check:** the actual logic lives in the external `tenant-requirements-checker` image (it must emit `{Validator:{Check:{status,info}}}` JSON). In *this* repo you extend the validator/check dict in `_commonChecks.tpl` (conditionally if needed) and, if the check needs new inputs, add them to the checker's `customerValues` / `customerSecrets` env blocks (wiring files through the init-container convention). A support-bundle-only collector is just an extra `collectors:` entry in `support-bundle.yaml` (+ an analyzer if you want a verdict).

**Gotchas:** a collector with no analyzer collects data nobody reads; the checker pod holds real secrets, so never let a check echo them into its `.info`; everything runs in `.Release.Namespace` — **never hardcode a namespace**; **ingress-only test mode (`onlyRunRouter`) deploys no backends** — account for it when adding preflights; the `registryImages` analyzer is currently commented out (upstream Replicated bug); and `jsonCompare` messages mix two templating layers (outer Helm `{{ }}` emitting an inner troubleshoot.sh `{{ }}` string) — easy to mis-escape.

## Version-skew gate (`pre-upgrade-check-versions-*.yaml`)

Stops a customer upgrading from a too-old release. `Chart.yaml` carries an `annotations.minVersion` (e.g. `"2025.9.1"`) = the **oldest prior CARTO version allowed to upgrade to this chart**. Two Helm **`pre-upgrade`/`pre-install` hooks**, gated by `upgradeCheck.enabled`: a ConfigMap (hook-weight `-10`) ships a `check-version.sh`, and a Job (weight `-5`, `backoffLimit: 0`) runs it, comparing `minVersion` against the installed `customerPackageVersion` via `sort -V`. Mismatch → job fails → **the whole upgrade aborts before any resource changes**.

`appVersion` (what you're upgrading *to*) and `minVersion` (oldest you can upgrade *from*) are independent. When bumping `appVersion`, only raise `minVersion` if there's a real breaking reason — raising it too far strands customers on recent versions. (Note `customerPackageVersion` is injected externally, not defaulted in `values.yaml`; empty → cryptic failure.)

---

## Secrets — the three origins

Keep them separate; they're wired differently:
- **Auto-generated** infra secrets (`databaseEncryptionKey`, `jwtEncryptionKey`, `litellmMasterKey`, internal Redis/Varnish passwords, …): `RandomString` in `kots-config.yaml`, `hidden`.
- **License-driven** (`LicenseFieldValue`): never surfaced as user inputs.
- **Customer-provided**: `kots-config.yaml#type: password` → `kots-helm.yaml#appSecrets.*` → the chart Secret (via the `secretAssociation` machinery above).

Never commit a secret, not even a realistic placeholder — it runs on customer infrastructure you'll never see, and a bad default ships to everyone who upgrades.

## Release & versioning flow

**You almost never bump versions in this repo by hand** — cloud-native's release pipeline writes them for you. Understanding the chain matters more than the files.

**The numbers originate in cloud-native.** The chart's app version *is* the CARTO cloud-native release version. When cloud-native cuts a self-hosted release (RC or stable), its `selfhosted-release-create-downstream-repositories` workflow opens a bot PR here — author `supercartofante`, titled `:rocket: Update to <chartVersion>-<appVersion>` (e.g. `1.266.1-2026.5.14`) — that sets **all** the version fields atomically:

| File / field | Value | Decided by |
|---|---|---|
| `VERSION` (repo root) | release version, e.g. `2026.5.14` (or `2026.5.14-rc.8`) | cloud-native release |
| `chart/Chart.yaml#appVersion` | same as `VERSION` | cloud-native release |
| `chart/Chart.yaml#version` | chart SemVer, e.g. `1.266.1` | computed by cloud-native |
| `manifests/kots-helm.yaml#spec.chart.chartVersion` | equals chart version | cloud-native (kept in lockstep) |
| `chart/Chart.yaml#annotations.minVersion` | oldest upgradeable-from version | cloud-native's `onprem/MIN_VERSION` |

So `appVersion` and `minVersion` are *not* decisions made in this repo. The PR title encodes both numbers: `<chartVersion>-<appVersion>`.

**What merging that PR sets off (this repo's automation):**

1. Merging to `main` changes `VERSION` → `release-autotag.yaml` creates a GitHub tag/release **named after the chart version**. If `appVersion` matches the RC pattern (`…-rc.N`) it's a **prerelease**, otherwise a full **release**.
2. The release event → `official-release.yaml`:
   - **prereleased** → appends `-beta` to the chart version + `kots-helm` chartVersion, publishes to the Replicated **`Release candidates`** channel.
   - **released** → publishes to **`Stable`** and Slacks `#carto-selfhosted`.
3. Separately, *every* push to `main` → `release-dedicateds-changes.yaml` publishes the chart to the **`Dedicateds`** channel (dev trigger); and any PR with the **`release-changes`** label gets its own per-branch dev channel for test installs.

**The only time you edit versions by hand** is an out-of-band chart-only change (a chart hotfix with no cloud-native bump). Then keep the trio in lockstep yourself — `Chart.yaml#version` == `kots-helm.yaml#spec.chart.chartVersion` — and leave `appVersion` / `VERSION` / `minVersion` alone unless you mean to move them. Nothing in CI verifies the version fields agree; the only related guard is the helm-readme drift check.

## Validating a change

PR CI is thin — only `lint-codebase.yaml` (super-linter **+ helm-readme-generator drift check**) and `security-gitleaks.yml` run on a PR. Trivy and the resource-change check run **post-merge** on `main`; `helm lint`, `helm template`, and KOTS rendering are **not in CI at all**. So a broken template or a `kots-helm.yaml` typo passes PR CI green and only surfaces at install time.

Render it yourself before pushing — `helm template` both the plain and `--set replicated.enabled=true` paths, and `./scripts/test-kots-config.sh all` for KOTS-layer changes. The one PR check you'll hit routinely: **edit `chart/values.yaml` → regenerate `chart/README.md`** (commands in `CONTRIBUTING.md`), or the drift check blocks the PR.

## Conventions

Branching, signing, squash-merge, and "who pushes merges" are in `CONTRIBUTING.md`. Repo-specific bits worth knowing:
- **Conventional commits**, scoped to what you touched (common scopes: `chart`, `selfhosted`, `aiproxy`, `router`, `workspace-api`, `ci`); add `[sc-XXXXXX]` when there's a Shortcut story.
- Branch off `main`; use `sc-<id>/` in the branch name to auto-link the PR. Open PRs as **draft**.
- The **`release-changes`** label publishes the branch's chart to a per-branch Replicated dev channel, so a test license can install your branch via KOTS; removing the label or closing the PR tears it down.

## When blocked by CartoDB permissions

If a tool fails because the user lacks access (e.g., `gh` push returns 403, an internal app rejects auth, a SaaS account is missing, a Claude rate-limit error fires), don't stop work — invoke the org-wide `carto-it-request` skill (from the `CartoDB/carto-skills` plugin marketplace). It handles the full range of `#it-issues` request types (GitHub access, GCP/BigQuery IAM, Claude quota, SaaS OAuth, dev DB credentials, signatures), drafting either a draft PR against the right Terraform file in `CartoDB/carto-infrastructure` (when the resource is IaC-managed) or a structured ticket in `#it-issues` matching the IT Helpdesk triage form. The skill's resource catalog lives at `plugins/infrastructure/skills/carto-it-request/references/it-resource-registry.md` in carto-skills.

Use `#devops-issues` (not the IT Helpdesk) for infrastructure/DevOps requests.

## Before you open a PR

1. Renders in **both** paths (`helm template` plain + `--set replicated.enabled=true`)?
2. New tunable wired through **every layer** (`values.yaml` + template + `kots-config.yaml` + `kots-helm.yaml`)?
3. New secret in both `secretAssociation` *and* the consuming `secret.yaml` + `deployment.yaml`?
4. Misconfiguration that should fail loudly → a `_validators.tpl` guard? Broken environment that should block install → a `_commonChecks.tpl` preflight?
5. Changed `values.yaml` → regenerated `chart/README.md`?
6. Version bump → paired files moved together; `minVersion` still correct?
7. Deleting/renaming a `ConfigOption`, component, `statusInformer`, or PDB — accounted for existing installs and the per-resource labeling pattern?

Every change ships to customers running on their own infrastructure. They cannot quickly roll back, and we cannot quickly redeploy. Measure twice, cut once.
