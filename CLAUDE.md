# CLAUDE.md

## ⚠️ PUBLIC repository — information disclosure rules

Everything pushed here is world-readable the moment it lands: code, comments,
commit messages, branch names, PR titles and bodies, and these CLAUDE.md files
themselves.

Before writing **any** name, value, URL, or process detail, apply one test:
**is it already public in this repo?** (`git grep` it). If it isn't, and it
comes from CARTO's internal world, leave it out or genericize it.

Never write:

- **Secrets — real or realistic-looking.** A placeholder like
  `jwtApiSecret: "8f3a2c91e0b4..."` gets copy-pasted and triggers scanners;
  defaults in `values.yaml` are empty strings, keep it that way.
- **Internal infrastructure names**: GCP project IDs, cluster or hostnames, IPs.
  A debug crumb like `# tested on gke_carto-internal-x_us-east1` is a leak.
- **Anything from a customer**: company names, tenant IDs, domains, support
  bundle contents, their `values.yaml`. Not in code, not in PR bodies, not in
  test fixtures.
- **Internal URLs**: Slack channels or archive links, Shortcut story URLs,
  internal dashboards or wiki pages.
- **Internal-only tooling or process** that isn't observable from this repo's
  own files and workflows.

Fine, because it is already public here or established practice:

- `registry.self-hosted.carto.com` and the default image registries/repos in
  `chart/values.yaml` and `manifests/kots-helm.yaml`.
- Short Shortcut refs `[sc-XXXXXX]` in commit messages and PR titles — the ID
  only, never the full URL.
- Links to public docs (`docs.carto.com`).

## What this repo is

A **Helm chart** that deploys CARTO Self-Hosted, shipped two ways:

1. **Pure Helm** — `helm install carto ./chart -f values.yaml`.
2. **Replicated / KOTS** — the same chart wrapped by `manifests/kots-*.yaml`
   for the KOTS Admin Console and embedded-cluster (single-VM) installs.

Container images come from CARTO's application services; what lives here is
values, templates, validation, and the KOTS translation layer.

**Two rules everything follows:** the Helm chart is the **source of truth**,
and KOTS only **translates** customer input into chart values. A change must
work in *both* paths — Helm-only or KOTS-only is half done.

Subtree specifics live next to the code and load on demand:
[`chart/CLAUDE.md`](./chart/CLAUDE.md) (templates, helpers, validators,
preflights) and [`manifests/CLAUDE.md`](./manifests/CLAUDE.md) (KOTS layer).
Process detail (git setup, doc generation, linting, branching) is in
[`CONTRIBUTING.md`](./CONTRIBUTING.md). Full chart params are in the generated
[`chart/README.md`](./chart/README.md).

## The values flow

```
manifests/kots-config.yaml   (KOTS UI: items + RandomString secrets)
   └─► manifests/kots-helm.yaml   (ConfigOption → chart values)
        └─► chart/values.yaml   (Helm defaults)
             └─► chart/templates/<component>/*   (consume the value, usually via _helpers.tpl)
                  └─► Kubernetes resources
```

The most common change here is wiring an env var. Plain config → the
component's `configmap.yaml` and done. **Customer-set** → also `values.yaml`
(with a `## @param` comment), `kots-config.yaml`, and `kots-helm.yaml`, shipped
together. **Secret** → the `secretAssociation` machinery (see
`chart/CLAUDE.md`).

## Versioning

Version fields (`VERSION`, `Chart.yaml#version`/`appVersion`/`minVersion`,
`kots-helm.yaml#chartVersion`) are **bot-driven**: the release pipeline opens a
`:rocket: Update to …` PR that sets them all atomically. **Don't bump them by
hand.** The only exception is a chart-only hotfix with no app release — then
keep `Chart.yaml#version` == `kots-helm.yaml#spec.chart.chartVersion` yourself
and leave the rest alone. `minVersion` semantics are in `chart/CLAUDE.md`.

## Validating a change

CI is the gate — push and track it. The one thing CI won't fix for you: if you
change `chart/values.yaml`, regenerate `chart/README.md` (commands in
`CONTRIBUTING.md`) or the drift check blocks the PR. For a quick local sanity
check, `helm template` both paths: plain and `--set replicated.enabled=true`.

## Conventions

- **Conventional commits**, scoped to what you touched (common scopes:
  `chart`, `selfhosted`, `router`, `ci`).
- Branch off `main`; use `sc-<id>/` in the branch name to auto-link the
  Shortcut story. Open PRs as **draft**.
- The **`release-changes`** PR label publishes the branch's chart to a
  per-branch Replicated dev channel for install testing; removing the label or
  closing the PR tears it down.

Every change ships to customers running on their own infrastructure. They
cannot quickly roll back, and we cannot quickly redeploy. Measure twice, cut
once.
