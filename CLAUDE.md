# CLAUDE.md

> ⚠️ **PUBLIC REPOSITORY.** Everything committed here is world-readable. Never add
> secrets (not even placeholders), internal hostnames/IPs, customer data, internal
> Slack channels, ticket links, or internal-only tooling/process. Write for an
> outside reader of a Helm chart. When in doubt, leave it out.

How this repo's machinery works and where it bites. Process detail (git setup,
doc generation, linting, merging) lives in [`CONTRIBUTING.md`](./CONTRIBUTING.md)
— note it still says `stable`, but the repo develops on **`main`**. Full chart
params are in the generated [`chart/README.md`](./chart/README.md).

Subsystem deep-dives (helpers, validators, preflights, versioning) live in
`.claude/rules/` and load on demand when you touch the matching files.

## What this repo is

A **Helm chart** that deploys CARTO Self-Hosted, shipped two ways:

1. **Pure Helm** — `helm install carto ./chart -f values.yaml`.
2. **Replicated / KOTS** — the same chart wrapped by `manifests/kots-*.yaml` for
   the KOTS Admin Console and embedded-cluster (single-VM) installs.

Container images come from CARTO's cloud-native services; what lives here is
values, templates, validation, and the KOTS translation layer.

**Two rules everything follows:** the Helm chart is the **source of truth**, and
KOTS only **translates** customer input into chart values. A change must work in
*both* paths — Helm-only or KOTS-only is half done.

## Repo map

```
chart/                       the chart — source of truth
  values.yaml                full parameter surface; drives chart/README.md
  Chart.yaml                 version, appVersion, deps, minVersion annotation
  templates/<component>/*     per-component manifests (configmap, deployment, hpa,
                              ingress, pdb, service, secret) — uniform across components
  templates/_helpers.tpl       naming, images, the secretAssociation map
  templates/_validators.tpl    fail-fast config guards (fired from NOTES.txt)
  templates/_commonChecks.tpl  preflight/support-bundle collectors & analyzers
manifests/                   Replicated / KOTS layer
  kots-config.yaml           KOTS UI (groups/items, RandomString secrets, license fields)
  kots-helm.yaml             ConfigOption → chart values translation (the heart of the layer)
  kots-app.yaml              KOTS app + statusInformers
  embbeded-cluster.yaml      embedded-cluster (k0s) config — filename misspelled on purpose, don't rename
scripts/test-kots-config.sh  render the KOTS config for gke|eks|aks|all
doc/                         customer-facing customization docs
```

Each subdirectory under `chart/templates/` is a component (`ls chart/templates/`
for the current set — they map to CARTO's cloud-native services plus the cache:
`valkey` is current, `redis` is the legacy name kept for compatibility, don't
rename it). They're uniform — every component carries the same handful of
manifests (configmap, deployment, hpa, ingress, pdb, service, secret).

## The values flow

```
kots-config.yaml   (KOTS UI: items + RandomString secrets)
   └─► kots-helm.yaml   (ConfigOption → chart values; optionalValues[] conditionals)
        └─► chart/values.yaml   (Helm defaults)
             └─► chart/templates/<component>/*   (consume the value, usually via _helpers.tpl)
                  └─► Kubernetes resources
```

## The most common change: add/wire an env var

By far the most frequent change in this repo. Most env vars are **plain config**
→ add them to the component's `configmap.yaml`. That's the whole change.

It only spreads to other layers when the value is **customer-set**: then it also
needs a default in `values.yaml` (with a `## @param` comment), a UI control in
`kots-config.yaml`, and the mapping in `kots-helm.yaml`. Ship those together — a
KOTS change without the chart wiring (or the reverse) ships a value that does
nothing and the customer never knows.

If the value is a **secret**, it goes through the `secretAssociation` machinery
instead (see the helpers rule — loads when you touch `_helpers.tpl` /
`secret.yaml` / `deployment.yaml`).

## Secrets

Three origins, wired differently:
- **Auto-generated** infra secrets (`databaseEncryptionKey`, `jwtEncryptionKey`,
  `litellmMasterKey`, internal Redis/Varnish passwords, …): `RandomString` in
  `kots-config.yaml`, `hidden`.
- **License-driven** (`LicenseFieldValue`): never surfaced as user inputs.
- **Customer-provided**: `kots-config.yaml#type: password` →
  `kots-helm.yaml#appSecrets.*` → the chart Secret (via `secretAssociation`).

**Never commit a secret, not even a realistic placeholder** — it ships to every
customer on upgrade and runs on infrastructure you'll never see.

## Versioning

Version files (`VERSION`, `Chart.yaml#version`/`appVersion`/`minVersion`,
`kots-helm.yaml#chartVersion`) are **bot-driven** — cloud-native's release
pipeline opens a bot PR that sets them atomically. **Don't bump them by hand.** The only exception — a rare chart-only hotfix — is covered in the
versioning rule (loads when you touch those files).

## Validating a change

CI is the gate. Push and track it. The one thing CI won't fix for you: if you
change `chart/values.yaml`, regenerate `chart/README.md` (commands in
`CONTRIBUTING.md`) or the drift check blocks the PR.

For a quick local sanity check on template edits, `helm template` the plain and
`--set replicated.enabled=true` paths — but it's optional, not a required ritual.

## Conventions

Branching, signing, squash-merge, and "who pushes merges" are in `CONTRIBUTING.md`.
Repo-specific bits:
- **Conventional commits**, scoped to what you touched (common scopes: `chart`,
  `selfhosted`, `aiproxy`, `router`, `workspace-api`, `ci`); add `[sc-XXXXXX]`
  when there's a Shortcut story.
- Branch off `main`; use `sc-<id>/` in the branch name to auto-link the PR. Open
  PRs as **draft**.
- The **`release-changes`** label publishes the branch's chart to a per-branch
  Replicated dev channel, so a test license can install your branch via KOTS;
  removing the label or closing the PR tears it down.

## Before you open a PR

1. Renders in **both** paths (`helm template` plain + `--set replicated.enabled=true`)?
2. Customer-set tunable wired through **every layer** (`values.yaml` + template +
   `kots-config.yaml` + `kots-helm.yaml`)?
3. New secret in both `secretAssociation` *and* the consuming `secret.yaml` +
   `deployment.yaml`?
4. Changed `values.yaml` → regenerated `chart/README.md`?
5. New/modified **PDB** → follows the project's labeling pattern (empty `labels:`
   + `matchLabels` on `app.kubernetes.io/name`), *not* the HPA labeling?
6. Deleting/renaming a `ConfigOption`, component, `statusInformer`, or PDB —
   accounted for existing installs?

Every change ships to customers running on their own infrastructure. They cannot
quickly roll back, and we cannot quickly redeploy. Measure twice, cut once.
