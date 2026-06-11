# CLAUDE.md

This file provides architectural and reasoning context for Claude Code (claude.ai/code) when working in this repository. It focuses on **why and how to think** about changes here — not what commands to type.

For contribution process (Git setup, commit signing, generating chart docs, linting, branching, merging), see [`CONTRIBUTING.md`](./CONTRIBUTING.md). For the full chart parameter surface, see the auto-generated [`chart/README.md`](./chart/README.md).

> **One caveat about `CONTRIBUTING.md`:** it still describes a `stable` branch. The repo actually develops on **`main`** — follow `main`. Everything else in `CONTRIBUTING.md` is current.

## What this repository is

It packages **CARTO Self-Hosted** as a **Helm chart**, shipped to customers through two distribution paths:

1. **Pure Helm** — the customer applies the chart directly (`helm install carto ./chart -f values.yaml`).
2. **Replicated / KOTS** — the same chart is wrapped by Replicated (`manifests/kots-*.yaml`) for the KOTS Admin Console and embedded-cluster (single-VM) installs.

This is a *deployment* repo, not an application repo: the container images come from CARTO's cloud-native services. What lives here is the contract between a customer's cluster and those images — values, templates, validation, and the KOTS translation layer.

**The single most important principle:** the **Helm chart is the source of truth**, and **KOTS only translates customer input into chart values**. Every change must work in *both* distribution paths. A change that only works via Helm, or only via KOTS, is a half-finished change.

## The mental model: the values flow

Almost everything you do here is a point on one pipeline. Internalize it before editing:

```
KOTS Admin Console UI
        │   manifests/kots-config.yaml     (UI groups + items; RandomString secrets; license fields)
        ▼
   KOTS → chart translation
        │   manifests/kots-helm.yaml       (ConfigOption → chart values; conditional optionalValues[])
        ▼
   Helm defaults
        │   chart/values.yaml              (full parameter surface; drives chart/README.md)
        ▼
   Templates
        │   chart/templates/<component>/*  (configmap, deployment, hpa, ingress, pdb, service, secret)
        ▼
   Kubernetes resources
```

The consequence that trips people up: **a single new tunable usually has to be added in several places at once.** A typical new value needs a default in `chart/values.yaml` (with a `## @param` doc comment), template wiring where it's consumed, a UI control in `kots-config.yaml` if the customer should set it, and the mapping in `kots-helm.yaml`. Add validation in `_validators.tpl` if misconfiguration should fail loudly, and a preflight in `_commonChecks.tpl` if a broken environment should block install.

Ship those together. A KOTS config change without the chart-side wiring (or the reverse) silently ships a value that does nothing — the customer thinks they configured something, and nothing changed.

## Where the important logic lives

- `chart/templates/_helpers.tpl` — `fullname`/`baseUrl` helpers and the **`secretAssociation`** map (ENV var → values path). A new secret env var that isn't added here lands in the Secret resource but is never referenced — the service starts without its credential.
- `chart/templates/_validators.tpl` — early-failing template guards (Postgres / Redis / Proxy / log level / ServiceAccount). False positives block *all* installs; false negatives let broken environments through. Treat changes here as high-blast-radius.
- `chart/templates/_commonChecks.tpl` — preflight collectors/analyzers and support-bundle definitions, rendered into `templates/preflight.yaml` and `templates/support-bundle.yaml`.
- `manifests/kots-helm.yaml` — the translation layer, and the easiest place to break a customer: a typo silently drops their value, and it selects per-distribution behavior (GKE managed certs, EKS NLB SSL, AKS, OpenShift) via `optionalValues[].when`.
- `manifests/kots-config.yaml` — the KOTS UI and the source of auto-generated secrets.
- `manifests/embbeded-cluster.yaml` — embedded-cluster (k0s) config. **The filename is misspelled on purpose** — it's referenced by CI/Replicated tooling. Don't "fix" it.

**Components** (each a directory under `chart/templates/`): `accounts-www`, `ai-api`, `aiproxy`, `cdn-invalidator-sub`, `gateway`, `http-cache`, `import-api`, `import-worker`, `lds-api`, `maps-api`, `notifier`, `public-events-api`, `redis` (legacy), `valkey` (current cache), `router`, `sql-worker`, `workspace-api`, `workspace-subscriber`, `workspace-www`.

## Security posture: why "be conservative" is the default

A self-hosted product runs on the **customer's** infrastructure, with the customer's data, in clusters you will never see. They cannot roll back quickly and you cannot redeploy for them. A bad default doesn't cause one incident — it ships to every customer who upgrades. That asymmetry is why the rules below lean strict.

- **Secrets have three origins, handled differently.** Auto-generated infra secrets come from `RandomString` in `kots-config.yaml` (`databaseEncryptionKey`, `jwtEncryptionKey`, `litellmMasterKey`, internal Redis/Varnish passwords, …) and are `hidden`. License-driven secrets come from `LicenseFieldValue` (don't surface them as user inputs). Customer-provided secrets flow `kots-config.yaml#type: password` → `kots-helm.yaml#appSecrets.*` → chart Secret. Never commit a secret, not even a realistic-looking placeholder.
- **Image registry is indirected.** Customer images come from `registry.self-hosted.carto.com` (Replicated proxy → `gcr.io/carto-onprem-artifacts`), and air-gapped installs swap in a local registry via the `HasLocalRegistry` ternary in `kots-helm.yaml`. **Never hardcode `gcr.io/carto-artifacts`** — that's the SaaS-only registry.
- **Identity is per-platform.** GCP Workload Identity (`enableGoogleWorkloadIdentity`), AWS EKS Pod Identity (`awsEksPodIdentityBucketsEnabled`, preferred over IAM users), OpenShift random UIDs (require disabling pod/container security contexts). Extend the existing `optionalValues` patterns rather than inventing new ones, and prefer the keyless option.
- **TLS/ingress has two paths:** `router` (NGINX, default) and `gateway` (Gateway API, opt-in). Legacy top-level `tlsCerts:` is **deprecated** in favor of `router.tlsCertificates` / `gateway.tlsCertificates`. `onlyRunRouter: true` is an ingress-test mode that bypasses backends — never production.
- **One instance per cluster/namespace.** There is no chart-level multi-tenancy — don't add cross-instance lookups, shared state, or hardcoded namespaces.

### Require a second reviewer when a change touches:
- `manifests/kots-helm.yaml` (the translation) or `_helpers.tpl#secretAssociation` — silent data loss / missing credentials.
- `_validators.tpl` or `_commonChecks.tpl` — blocks or wrongly passes every install.
- `manifests/kots-app.yaml#statusInformers` — KOTS UI reports wrong app status if it drifts from the chart.
- `chart/templates/router/` or `chart/templates/gateway/` — public-facing.
- A PodDisruptionBudget — match the existing PDB pattern (empty `labels:`, a `matchLabels` selector on `app.kubernetes.io/name`), **not** the HPA/Deployment labeling.
- Bumping `replicated`, `bitnami/common`, `bitnami/postgresql`, or `embedded-cluster` versions (read the changelog for advisories).

## Versioning model

Releases are automated — GitHub release tags drive `official-release.yaml` (publishing to the Replicated `Release candidates` / `Stable` channels), and `:rocket:` commits plus `release-autotag.yaml` handle app-version bumps. You won't run these by hand.

What you *do* own is keeping the version files in sync when a change requires a bump — they drift apart easily and the failure is silent:
- `chart/Chart.yaml#version` — Helm chart SemVer; **must equal** `manifests/kots-helm.yaml#spec.chart.chartVersion`.
- `chart/Chart.yaml#appVersion` — the cloud-native app version, mirrored by `VERSION` at the repo root.
- `manifests/kots-app.yaml#spec.minKotsVersion` — minimum supported KOTS Admin Console version.

When bumping `appVersion`, check whether `pre-upgrade-check-versions-cm.yaml` (the compatibility matrix consumed by `pre-upgrade-check-versions-job.yaml`) also needs updating — don't ship a version-skew break.

## How to validate — and what CI does *not* catch

CI on a pull request is thin. Only two workflows run on a PR:
- `lint-codebase.yaml` — super-linter **+ the helm-readme-generator drift check** (this *will* fail you).
- `security-gitleaks.yml` — secret scan.

Everything else — the Trivy IaC scan and the resource-change check — runs on **push to `main`**, i.e. *after* merge. And `helm lint`, `helm template`, and KOTS rendering are **not in CI at all**. The practical upshot: a broken template or a `kots-helm.yaml` typo passes PR CI green and only surfaces at a customer's install. So render it yourself before pushing — `helm template` both the plain and `--set replicated.enabled=true` paths, and run `./scripts/test-kots-config.sh all` for any KOTS-layer change. (`CONTRIBUTING.md` has the exact lint and readme-generator commands.)

The one CI hard-fail you'll hit routinely: **edit `chart/values.yaml` → regenerate `chart/README.md`.** When you change resource `requests`/`limits`, the post-merge `check-helm-chart-resources.yaml` Slacks `#selfhosted-internal` — update the deployment-resources docs to match.

## Development workflow

- Branch from and merge to `main`. Branch prefixes: `feature/`, `bugfix/` (or `fix/`), `chore/`, `revert/` — append `sc-<id>/` when there's a Shortcut story (it auto-links the PR).
- **Conventional commits**, scoped to what you touched — common scopes seen in `git log`: `chart`, `selfhosted`, `aiproxy`, `router`, `workspace-api`, `ci`. The `[sc-XXXXXX]` suffix is preferred when a story exists.
- **Open PRs as draft;** mark ready only when complete. Fill the PR template, cover deployment impact, be terse.
- **Squash on merge**, and **sync with `main` first** (fast-forward requires it). "Who pushes the changes, merges the changes" — the author merges after approval.
- The **`release-changes`** label publishes the branch's chart to a per-branch Replicated dev channel (`branch-changes-release.yaml`), so a test license can install your branch via KOTS; removing the label or closing the PR tears it down.
- Never force-push or amend pushed commits without explicit approval.

## Useful skills (CARTO-internal)

| Skill | When |
|---|---|
| `/carto-selfhosted-deploy-assist` | deploy a fresh install / test a PR / upgrade an existing cluster |
| `/carto-selfhosted-troubleshooter` | trace a config value end-to-end, diagnose a preflight or import failure, analyze a support bundle |
| `/code-review` | review chart/manifest changes on a PR before merge |

## Questions to ask before a change

1. **Does this work in both distribution paths?** Render plain Helm *and* the KOTS path before pushing.
2. **Did I touch every layer of the values flow?** A new value usually needs `values.yaml` + template + `kots-config.yaml` + `kots-helm.yaml` together.
3. **If I added a secret, is it in `_helpers.tpl#secretAssociation`?**
4. **If I changed `values.yaml`, did I regenerate `chart/README.md`?**
5. **If I bumped a version, did the paired files move together** (`Chart.yaml#version` ↔ `kots-helm.yaml#chartVersion`; `appVersion` ↔ `VERSION`)?
6. **Am I about to delete or rename something?** Removing a `ConfigOption` from `kots-config.yaml` breaks upgrades for existing installs (deprecate with `hidden: true` for a release instead); a new component without a `statusInformers` entry shows as "missing" in the KOTS UI forever.

Every change ships to customers running on their own infrastructure. They cannot quickly roll back, and we cannot quickly redeploy. Measure twice, cut once.
