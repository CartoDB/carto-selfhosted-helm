# CLAUDE.md

Guidance for Claude Code working in this repository.

This repo packages CARTO Self-Hosted as a **Helm chart** distributed in two ways:

1. **Pure Helm** — customer applies the chart directly (`helm install carto ./chart -f values.yaml`).
2. **Replicated / KOTS** — the same chart is wrapped by Replicated (`manifests/kots-*.yaml`) for the KOTS Admin Console and embedded-cluster (single-VM) installations.

Every change must work in **both** distribution paths. The Helm chart is the source of truth; KOTS only translates customer config into chart values.

---

## 1. Repo map

```
chart/                       Helm chart — source of truth
  Chart.yaml                 chart version, deps (bitnami/common, bitnami/postgresql, replicated)
  values.yaml                full parameter surface; drives auto-generated chart/README.md
  templates/<component>/     per-component manifests (configmap, deployment, hpa, ingress, pdb, service, secret)
  templates/_helpers.tpl     fullname, baseUrl, secretAssociation map (ENV → values path)
  templates/_validators.tpl  early-failing template guards (Postgres / Redis / Proxy / log level / ServiceAccount)
  templates/_commonChecks.tpl preflight & support-bundle collectors and analyzers
  templates/preflight.yaml   troubleshoot.sh preflight Secret
  templates/support-bundle.yaml troubleshoot.sh support bundle Secret
  templates/pre-upgrade-check-versions-job.yaml  upgrade-time version compatibility check
  charts/                    bundled deps (.tgz) — do NOT edit by hand, run `helm dep update`

manifests/                   Replicated / KOTS layer
  kots-app.yaml              KOTS Application kind + statusInformers
  kots-config.yaml           KOTS Admin Console UI (groups → items, secrets via RandomString, license fields)
  kots-helm.yaml             KOTS HelmChart v2 — translates ConfigOption → chart values; the heart of the layer
  kots-lint-config.yaml      KOTS lint rules
  embbeded-cluster.yaml      Embedded Cluster (k0s) config — note the typo in the filename, do not "fix" it
  carto-*.tgz                packaged chart snapshot for KOTS

scripts/test-kots-config.sh  render kots-config.yaml against test variables for [gke|eks|aks|all]
tools/                       customer-facing helpers
  carto-download-customer-package.sh
  carto-support-tool.sh
doc/                         customer-facing customization docs
.github/                     CI, renovate, release actions
```

**Components** (each directory under `chart/templates/`):
`accounts-www`, `ai-api`, `aiproxy`, `cdn-invalidator-sub`, `gateway`, `http-cache`, `import-api`, `import-worker`, `lds-api`, `maps-api`, `notifier`, `public-events-api`, `redis` (legacy), `valkey` (current cache), `router`, `sql-worker`, `workspace-api`, `workspace-subscriber`, `workspace-www`.

---

## 2. The values flow — understand this before editing

```
KOTS UI  ─────────►  kots-config.yaml  (groups + items + RandomString-generated secrets)
                            │
                            ▼
                    kots-helm.yaml      (translate ConfigOption → chart values; conditional overrides via optionalValues[])
                            │
                            ▼
                    chart/values.yaml   (Helm defaults; full parameter surface)
                            │
                            ▼
                    chart/templates/<component>/*.yaml
                            │
                            ▼
                    Kubernetes resources
```

**Every new feature touches multiple layers.** A new tunable typically requires:
1. Default in `chart/values.yaml` with a `## @param` doc comment (drives chart README).
2. Template wiring in `chart/templates/<component>/configmap.yaml` (or wherever consumed).
3. KOTS UI control in `manifests/kots-config.yaml` (if the customer should set it).
4. KOTS-to-chart mapping in `manifests/kots-helm.yaml` (`appConfigValues:` / `optionalValues[]`).
5. Validation in `chart/templates/_validators.tpl` if misconfiguration must fail loudly.
6. Preflight check in `_commonChecks.tpl` if missing/broken environment will block install.

Ship those together. A KOTS config change without the chart-side wiring (or vice versa) ships a half-feature.

---

## 3. Validation

PR CI is thin — don't assume it catches your change. On a pull request only two workflows run:
- `lint-codebase.yaml` — super-linter (YAML/MD/shell) **+ helm-readme-generator drift check**.
- `security-gitleaks.yml` — gitleaks secret scan.

Everything else (`trivy-security-scanning.yaml`, `check-helm-chart-resources.yaml`) triggers on **push to `main`**, i.e. *after* merge — not on your PR. And `helm lint`, `helm template`, and KOTS rendering are **not in CI at all**. So a broken template or a `kots-helm.yaml` typo passes PR CI green and only surfaces at customer install time.

Render it yourself before pushing — nothing on the PR does:

```bash
cd chart
helm dep update
helm lint .
helm template . -f values.yaml                     # render and eyeball output
helm template . --set replicated.enabled=true      # also render the Replicated path
```

For a KOTS-layer change (`kots-config.yaml` / `kots-helm.yaml`), also render the KOTS path — no CI check covers it:

```bash
./scripts/test-kots-config.sh all                  # gke / eks / aks / all
```

The one thing PR CI *will* fail you on: **edit `chart/values.yaml` → regenerate `chart/README.md`** (helm-readme-generator), or the drift check blocks the PR. (Resource `requests`/`limits` changes are flagged by `check-helm-chart-resources.yaml`, but only post-merge on `main` — update the deployment-resources docs when you touch sizing.)

---

## 4. Branching & commits

**Default branch is `main`.** (CONTRIBUTING.md still references `stable` — that's outdated.)

Branch names:
- `feature/<short-description>` or `feature/sc-<id>/<short-description>`
- `bugfix/<short-description>` or `bugfix/sc-<id>/<short-description>` (also `fix/...`)
- `chore/<short-description>`
- `revert/<short-description>`

**Conventional commits** (observed in `git log`):
```
fix(chart): correct HealthCheckPolicy spec for GKE gateway [sc-548219]
feat(selfhosted): replace Redis with Valkey in Helm charts [sc-540814]
chore(sc-522397): remove staging environment references from kots-config
```

Common scopes: `chart`, `selfhosted`, `aiproxy`, `router`, `workspace-api`, `public-events-api`, `ci`. The `[sc-XXXXXX]` suffix is preferred when there is a Shortcut story.

`:rocket:` commits are automated app-version bumps (see §6) — don't author them by hand.

---

## 5. Pull requests

- **Always open as draft** (per `CONTRIBUTING.md`). Mark ready only when work is complete.
- Fill `.github/pull_request_template.md`: scope, benefits, drawbacks, related issues. Be terse but cover deployment impact.
- **Squash on merge.** Single-commit PRs go through verbatim; multi-commit PRs use the PR title as the squash message — keep it descriptive.
- **Sync with `main` before merging** (squash + fast-forward requires it).
- "Who pushes the changes, merges the changes" — author merges after approval.
- Never force-push without explicit approval. Never amend pushed commits.

### The `release-changes` label
Adding the **`release-changes`** label (or pushing to a labeled PR) triggers `branch-changes-release.yaml`, which publishes the chart to a **Replicated dev channel** named after the branch. This lets you assign the channel to a customer/test license to install your branch via KOTS. The bot comments the channel name on the PR.

Removing the label or closing the PR triggers `branch-changes-delete.yaml` to clean up the channel.

---

## 6. Versioning

Releases themselves are automated (GitHub release tags → `official-release.yaml` publishes to the Replicated `Release candidates` / `Stable` channels; `:rocket:` commits and `release-autotag.yaml` handle app-version bumps). You won't run these by hand — they're here for context.

What you *do* need to get right when a change requires a version bump is keeping these files in sync:
- `chart/Chart.yaml#version` — Helm chart SemVer (e.g. `1.249.1`). Bump on every release.
- `chart/Chart.yaml#appVersion` — CARTO app version (e.g. `2026.3.10`). Tracks the cloud-native app release.
- `VERSION` (repo root) — mirrors `appVersion` for tooling.
- `semver.yaml` — drives auto-tagging on pushes to `main`.
- `manifests/kots-helm.yaml#spec.chart.chartVersion` — must match `Chart.yaml#version`. **Bump them together.**
- `manifests/kots-app.yaml#spec.minKotsVersion` — minimum KOTS Admin Console version supported.

**Embedded cluster:** `manifests/embbeded-cluster.yaml` pins `version: <ec-version>+k8s-<k8s-version>`. Renovate manages bumps (`Update dependency replicatedhq/embedded-cluster from …`).

---

## 7. CI workflows

CI workflows live in `.github/workflows/` — read them on demand rather than relying on a table here. Only two run on a PR: `lint-codebase.yaml` (super-linter + helm-readme-generator drift check) and `security-gitleaks.yml` (secret scan). The rest trigger on push to `main` or on release events — Trivy scanning and the resource-change check (post-merge), the `release-changes` branch channel, official releases, auto-tagging, and Renovate.

---

## 8. Security

A self-hosted product runs on the **customer's** infrastructure with the customer's data. Misconfigured defaults end up in production at companies you've never heard of. Be conservative.

### 8.1 Secrets
- **Never commit secrets.** Trivy IaC scan covers config, but secrets in YAML strings would be detected by upstream Replicated lint and gitleaks. Don't even put placeholders that look like real keys.
- KOTS auto-generates non-customer secrets via `RandomString` in `manifests/kots-config.yaml`:
  - `autogeneratedVarnishDebugSecret`, `autogeneratedVarnishPurgeSecret`, `autogeneratedInternalRedisPassword`, `autogeneratedInstanceId`, `databaseEncryptionKey`, `jwtEncryptionKey`, `litellmMasterKey`, `litellmSaltKey`.
  - Mark these `hidden: true`, `readonly: false`. The customer must not be able to read or rotate them through the UI without intent.
- License-driven secrets come from `LicenseFieldValue` (e.g. `cartoFeaturesFlagSdkKey`, `geminiApiKey`, `vitallyToken`). Don't surface them as user inputs.
- Customer-provided secrets (Google Maps API key, BigQuery OAuth, AWS keys, Azure storage) flow `kots-config.yaml#type: password` → `kots-helm.yaml#appSecrets.*` → chart Secret resource. Confirm the path end-to-end.
- The chart maps env-var names to values paths in `_helpers.tpl#secretAssociation`. New secret env var → add to that map.

### 8.2 Image registry & supply chain
- Customer images are pulled from `registry.self-hosted.carto.com` (Replicated proxy → `gcr.io/carto-onprem-artifacts`). Air-gapped customers use a local registry — `kots-helm.yaml` switches via `HasLocalRegistry | ternary LocalRegistryHost ...`. **Don't hardcode `gcr.io/carto-artifacts`** (that's the SaaS-only registry).
- The KOTS Admin Console and embedded cluster are pinned versions in `manifests/embbeded-cluster.yaml` and `manifests/kots-app.yaml#minKotsVersion`. Renovate bumps them; review the changelog for security advisories before merging.
- The Trivy IaC scan (`trivy-security-scanning.yaml`) runs on push to `main` and on a weekday cron — **not on PRs** — and is CRITICAL-only with `ignore-unfixed`. It won't gate your PR, so run `trivy config chart --severity HIGH,CRITICAL` locally if a change touches security-relevant config.

### 8.3 TLS & ingress
- Two paths to expose the platform: **router** (NGINX, default) and **gateway** (Kubernetes Gateway API, opt-in via `gateway.enabled`).
- Legacy `tlsCerts:` in values is **deprecated** in favor of `router.tlsCertificates` and `gateway.tlsCertificates`. Don't add new uses.
- `manifests/kots-helm.yaml` selects the right service annotations per K8s distribution (GKE managed certs, EKS NLB SSL, AKS, OpenShift). When adding a new distribution path, follow the existing `optionalValues[].when` pattern — never short-circuit security defaults.
- The router can run alone (`onlyRunRouter: true`) for ingress testing — that mode bypasses backend services and is **not** suitable for production.

### 8.4 Identity & access
- **GCP Workload Identity:** `enableGoogleWorkloadIdentity=1` switches `commonBackendServiceAccount` to use GKE Workload Identity (no JSON key). Customer must create the K8s SA themselves to allow preflights to run pre-install.
- **AWS IAM:** `awsEksPodIdentityBucketsEnabled` for EKS Pod Identity; otherwise IAM users with `appSecrets.aws*`. EKS Pod Identity is preferred — surface it in the UI when adding new AWS-touching features.
- **OpenShift:** non-root random UIDs require `podSecurityContext.enabled: false` and `containerSecurityContext.enabled: false` on every component. The pattern is in `kots-helm.yaml#optionalValues` — extend it for any new component.
- The chart creates one `commonBackendServiceAccount` and one `cartoCommonServiceAccount`; do not create per-component service accounts unless absolutely necessary, and only with explicit infra-team review.

### 8.5 Validation, preflights, support
- Add hard validations to `chart/templates/_validators.tpl` for misconfigurations that would silently break runtime. Pattern: `define "carto.validateValues.<thing>"` returning a message; chained from a top-level validator helper.
- Add preflight collectors/analyzers to `chart/templates/_commonChecks.tpl` for environment requirements that should block install (Postgres reachability, Redis/Valkey, storage class, DNS, version skew). They render into `templates/preflight.yaml` and `templates/support-bundle.yaml`.
- Bumping `appVersion` may require updating `pre-upgrade-check-versions-cm.yaml` (compat matrix consumed by `pre-upgrade-check-versions-job.yaml`). Don't ship a version-skew break.

### 8.6 Deletion & multi-tenancy
- This chart deploys **one** CARTO instance per cluster/namespace. There is no multi-tenancy at the chart level — don't add cross-instance lookups, shared state, or hardcoded namespace references.
- Embedded-cluster customers run a full k0s + KOTS bundle. Anything that mutates host state must go through KOTS `unsupportedOverrides` — not arbitrary Helm hooks.

### 8.7 Review focus — require second eyes when:
- Touching `manifests/kots-helm.yaml` (the values translation) — a typo silently drops a customer value.
- Touching `_helpers.tpl#secretAssociation` — a missing entry leaves a service without its secret at runtime.
- Touching `_validators.tpl` or `_commonChecks.tpl` — false positives block all installs; false negatives let broken environments through.
- Adding/removing components in `manifests/kots-app.yaml#statusInformers` — KOTS UI shows wrong status if it drifts from the chart.
- Anything under `chart/templates/router/` or `chart/templates/gateway/` — public-facing.
- Bumping `replicated`, `bitnami/common`, `bitnami/postgresql`, or `embedded-cluster` versions.
- Adding/modifying PodDisruptionBudgets — match the existing PDB pattern (empty `labels:`, a `matchLabels` selector on `app.kubernetes.io/name`), not the HPA/Deployment labeling.

---

## 9. Useful skills (CARTO-internal)

| Skill | When |
|---|---|
| `/carto-selfhosted-deploy-assist` | deploy a fresh install / test a PR / upgrade an existing cluster |
| `/carto-selfhosted-troubleshooter` | trace a config value end-to-end, diagnose a preflight or import failure, analyze a support bundle |
| `/code-review` | review chart/manifest changes on a PR before merge |

---

## 10. Common pitfalls (real, recurring)

1. **Updated `chart/values.yaml` but forgot `chart/README.md`.** CI fails on drift. Always re-run `helm-readme-generator`.
2. **Updated `chart/Chart.yaml#version` but forgot `manifests/kots-helm.yaml#spec.chart.chartVersion`.** KOTS Admin Console serves the wrong chart. Bump them together.
3. **Added a value to `chart/values.yaml` but forgot the KOTS mapping.** Default applies, customer thinks they're configuring it, nothing changes. Wire `kots-helm.yaml#appConfigValues` or `optionalValues[]`.
4. **Missing entry in `_helpers.tpl#secretAssociation`.** Secret lands in the Secret resource but no env var references it; the service starts without a credential.
5. **Hardcoded image registry as `gcr.io/carto-artifacts`.** That's SaaS — customer images come from `registry.self-hosted.carto.com` proxying `gcr.io/carto-onprem-artifacts`. Use the `HasLocalRegistry` ternary.
6. **Resource bumps without comms.** `check-helm-chart-resources.yaml` will Slack `#selfhosted-internal` and PR-comment a warning. Ack it and update the deployment-resources doc.
7. **Renaming `manifests/embbeded-cluster.yaml`.** It's misspelled but referenced in CI/Replicated tooling — leave it alone unless coordinating a rename across all consumers.
8. **Adding a deployment without `manifests/kots-app.yaml#statusInformers`.** The KOTS Admin Console reports the app as "missing" or "in progress" forever.
9. **Removing/renaming a `ConfigOption` in `kots-config.yaml`.** Existing installs read it from saved config — KOTS upgrade fails. Add new keys; deprecate old ones with `hidden: true` for at least one release.
10. **Putting customer secrets in `optionalValues[].when` conditions.** `when:` is rendered into Replicated bundles — keep secret comparisons via `ConfigOptionEquals`/`empty` only, never embed the secret value.

---

## Final rules of engagement

- **Both distribution paths must work** — pure Helm and Replicated/KOTS. Test rendering in both.
- **The Helm chart is the source of truth.** KOTS only translates input.
- **Ask before destructive actions** (force-push, deleting branches, deleting Replicated channels, mutating release tags).
- **Never force-push** without explicit approval. Never skip hooks. Never amend pushed commits.
- **Prefer editing existing files over creating new ones.** Don't write planning / status / summary docs unless asked.
- **Minimal change scope.** A bug fix doesn't need adjacent cleanup. A new feature doesn't need a new abstraction.

Every change ships to customers running on their own infrastructure. They cannot quickly roll back, and we cannot quickly redeploy. Measure twice, cut once.
