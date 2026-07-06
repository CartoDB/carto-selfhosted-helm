# manifests/ — the Replicated / KOTS layer

This layer only **translates** customer input into chart values — the chart
under `chart/` is the source of truth. Logic belongs in the chart; if you find
yourself encoding behavior here that the chart doesn't have, stop.

- `kots-config.yaml` — the KOTS Admin Console UI: groups/items, `RandomString`
  secrets, license fields.
- `kots-helm.yaml` — the heart of the layer: `ConfigOption` → chart values
  (`optionalValues[]` for conditionals). A UI item without a mapping here is a
  knob that does nothing — and the customer never finds out.
- `kots-app.yaml` — app metadata + `statusInformers`. Add/remove a component →
  update the informers, or the Admin Console reports a wrong app status.
- `embbeded-cluster.yaml` — embedded-cluster (k0s) config. The filename **is
  misspelled on purpose** — external references depend on it, don't rename.

`scripts/test-kots-config.sh` renders the KOTS config for `gke|eks|aks|all` —
the quick local check after touching these files.

## Secrets — three origins, wired differently

- **Auto-generated** infra secrets: `type: RandomString`, `hidden`, in
  `kots-config.yaml`.
- **License-driven** (`LicenseFieldValue`): never surfaced as user inputs.
- **Customer-provided**: `kots-config.yaml#type: password` →
  `kots-helm.yaml#appSecrets.*` → the chart's `secretAssociation` machinery
  (see `chart/CLAUDE.md`).

**Never commit a secret value, not even a realistic placeholder** — this file
set ships to every customer on upgrade.

## Removing or renaming is the dangerous direction

Existing installs reference `ConfigOption` keys, components, and informers by
name. Deleting or renaming one must account for customers upgrading from any
version since the one that introduced it — a missing `ConfigOption` at upgrade
time breaks the Admin Console config screen.
