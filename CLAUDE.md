# CLAUDE.md

Context for working in this repo. Focus is **how the pieces fit and where things bite** — not commands.

- Process (Git setup, doc generation, linting, branching, merging): [`CONTRIBUTING.md`](./CONTRIBUTING.md) — but note it says `stable`; the repo actually develops on **`main`**.
- Full chart parameter list: the auto-generated [`chart/README.md`](./chart/README.md).

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
  Chart.yaml                 chart version + appVersion + deps
  templates/<component>/*    per-component manifests (configmap, deployment, hpa, ingress, pdb, service, secret)
  templates/_helpers.tpl     fullname/baseUrl + secretAssociation map (ENV → values path)
  templates/_validators.tpl  early-fail guards (Postgres / Redis / Proxy / log level / ServiceAccount)
  templates/_commonChecks.tpl  preflight + support-bundle collectors/analyzers
manifests/                   Replicated / KOTS layer
  kots-config.yaml           KOTS UI (groups/items, RandomString secrets, license fields)
  kots-helm.yaml             ConfigOption → chart values translation (the heart of the layer)
  kots-app.yaml              KOTS app + statusInformers
  embbeded-cluster.yaml      embedded-cluster (k0s) config — filename misspelled on purpose, don't rename
scripts/test-kots-config.sh  render the KOTS config for gke|eks|aks|all
doc/                         customer-facing customization docs
```

Components (dirs under `chart/templates/`): `accounts-www`, `ai-api`, `aiproxy`, `cdn-invalidator-sub`, `gateway`, `http-cache`, `import-api`, `import-worker`, `lds-api`, `maps-api`, `notifier`, `public-events-api`, `redis` (legacy), `valkey` (current cache), `router`, `sql-worker`, `workspace-api`, `workspace-subscriber`, `workspace-www`.

## The values flow — internalize this

```
kots-config.yaml   (KOTS UI: items + RandomString secrets)
   └─► kots-helm.yaml   (ConfigOption → chart values; optionalValues[] conditionals)
        └─► chart/values.yaml   (Helm defaults)
             └─► chart/templates/<component>/*   (consume the value)
                  └─► Kubernetes resources
```

**A single new tunable usually has to land in several places at once:** a default in `values.yaml` (with a `## @param` comment), the template wiring, a UI control in `kots-config.yaml` (if the customer sets it), and the mapping in `kots-helm.yaml` — plus `_validators.tpl` if misconfiguration should fail loudly, or `_commonChecks.tpl` if a broken environment should block install. Ship them together: a KOTS change without the chart wiring (or the reverse) ships a value that does nothing, and the customer never knows.

## Where it bites

- **`_helpers.tpl#secretAssociation`** maps ENV var → values path. Add a secret env var here or it lands in the Secret but is never referenced — the service starts with no credential.
- **`kots-helm.yaml`** is the easiest place to break a customer: a typo silently drops their value. It also selects per-platform behavior (GKE managed certs, EKS NLB SSL, AKS, OpenShift) via `optionalValues[].when` — extend the existing patterns, don't invent new ones.
- **`_validators.tpl` / `_commonChecks.tpl`** are high blast radius: a false positive blocks *every* install, a false negative lets broken environments through.
- **Image registry is indirected.** Customer images come from `registry.self-hosted.carto.com` (→ `gcr.io/carto-onprem-artifacts`), with air-gapped installs swapping a local registry via the `HasLocalRegistry` ternary. **Never hardcode `gcr.io/carto-artifacts`** — that's the SaaS-only registry.
- **TLS/ingress has two paths:** `router` (NGINX, default) and `gateway` (Gateway API, opt-in). Top-level `tlsCerts:` is deprecated — use `router.tlsCertificates` / `gateway.tlsCertificates`. `onlyRunRouter: true` bypasses backends — test only, never production.
- **PodDisruptionBudgets** follow their own pattern (empty `labels:`, a `matchLabels` selector on `app.kubernetes.io/name`) — don't copy the HPA/Deployment labeling.
- **Deleting/renaming is dangerous.** Removing a `ConfigOption` from `kots-config.yaml` breaks upgrades for existing installs (deprecate with `hidden: true` for a release instead). A new component without a `kots-app.yaml#statusInformers` entry shows as "missing" in the KOTS UI forever. One instance per cluster/namespace — no multi-tenancy, no hardcoded namespaces.

## Secrets

Three origins, handled differently — keep them separate:
- **Auto-generated** (`databaseEncryptionKey`, `jwtEncryptionKey`, `litellmMasterKey`, internal Redis/Varnish passwords, …): `RandomString` in `kots-config.yaml`, marked `hidden`.
- **License-driven** (`LicenseFieldValue`): don't surface as user inputs.
- **Customer-provided**: `kots-config.yaml#type: password` → `kots-helm.yaml#appSecrets.*` → chart Secret.

Never commit a secret, not even a realistic-looking placeholder — it runs on customer infrastructure you'll never see, and a bad default ships to everyone who upgrades.

## Versioning

Releases are automated (GitHub release tags → `official-release.yaml` → Replicated channels; `:rocket:` commits + `release-autotag.yaml` bump app versions). You won't run these by hand. What you *do* own is keeping these in sync — they drift silently:

- `chart/Chart.yaml#version` **must equal** `manifests/kots-helm.yaml#spec.chart.chartVersion`.
- `chart/Chart.yaml#appVersion` is mirrored by `VERSION` at the repo root.
- Bumping `appVersion`? Check whether `pre-upgrade-check-versions-cm.yaml` (the compatibility matrix) needs updating too.

## Validating a change

PR CI is thin — only `lint-codebase.yaml` (super-linter **+ helm-readme-generator drift check**) and `security-gitleaks.yml` run on a PR. Trivy and the resource-change check run **post-merge** on `main`; `helm lint`, `helm template`, and KOTS rendering are **not in CI at all**. So a broken template or a `kots-helm.yaml` typo passes PR CI green and only surfaces at install time.

Render it yourself before pushing — `helm template` both the plain and `--set replicated.enabled=true` paths, and `./scripts/test-kots-config.sh all` for KOTS-layer changes. The one PR check you'll hit routinely: **edit `chart/values.yaml` → regenerate `chart/README.md`** (commands in `CONTRIBUTING.md`), or the drift check blocks the PR.

## Conventions

Branching, signing, squash-merge, and "who pushes merges" are in `CONTRIBUTING.md`. Repo-specific bits worth knowing:
- **Conventional commits**, scoped to what you touched (common scopes: `chart`, `selfhosted`, `aiproxy`, `router`, `workspace-api`, `ci`); add `[sc-XXXXXX]` when there's a Shortcut story.
- Branch off `main`; use `sc-<id>/` in the branch name to auto-link the PR. Open PRs as **draft**.
- The **`release-changes`** label publishes the branch's chart to a per-branch Replicated dev channel, so a test license can install your branch via KOTS; removing the label or closing the PR tears it down.

## Before you open a PR

1. Renders in **both** paths (`helm template` plain + `--set replicated.enabled=true`)?
2. New tunable wired through **every layer** (`values.yaml` + template + `kots-config.yaml` + `kots-helm.yaml`)?
3. New secret added to `_helpers.tpl#secretAssociation`?
4. Changed `values.yaml` → regenerated `chart/README.md`?
5. Version bump → paired files moved together?
6. Deleting/renaming a `ConfigOption`, component, or `statusInformer` — did you account for existing installs?
