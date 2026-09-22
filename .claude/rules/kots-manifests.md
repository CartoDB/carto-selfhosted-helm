---
paths:
  - "manifests/**"
---

# KOTS manifests

Read `manifests/CLAUDE.md` first: what each file is, when an
`appConfigValues` parameter needs a KOTS field, the three secret origins.
This file is the list of mistakes that reach review.

- A `kots-config.yaml` item without a `kots-helm.yaml` mapping is a knob that
  does nothing, and the customer never finds out. Add both, together; use
  `optionalValues[]` for conditionals.
- Hidden or `when:`-gated items keep the value they last had. Gating a feature
  behind a license field in the UI is not enough: the chart-side helper must
  check the license or enable flag too, or a customer who once enabled it
  keeps it after the license changes (#890).
- Never rename or remove an item or `ConfigOption` name. Existing installs
  reference them, and a `ConfigOptionEquals` against a name that no longer
  exists evaluates to false silently — the UI branch just disappears
  (sc-575813).
- A new component needs a `statusInformers` entry in `kots-app.yaml`, or the
  Admin Console reports the wrong app status.
- This layer sets every chart value it maps, so it masks missing defaults in
  `chart/values.yaml`. Test the Helm-only path too (`make template`).
- Secrets: infra secrets are `type: RandomString` and `hidden`; license-driven
  values come from `LicenseFieldValue`; customer secrets are `type: password`
  mapped to `appSecrets.*`. Never a value, not even a placeholder — this file
  set ships to every customer.
- `embbeded-cluster.yaml` is misspelled on purpose. Don't rename it.
- Templating: `repl{{ … }}` for a whole value, `'{{repl … }}'` inline in a
  quoted string. `ConfigOption`, `ConfigOptionEquals`, `LicenseFieldValue` and
  `Distribution` are the functions in use — copy an existing item.

Then `make kots`. The script prints `✗` for a reference to an undefined
option; treat that as a failure even though it exits 0 today (sc-575813).
Install-test a UI change through the `release-changes` label (per-branch
Replicated channel) before merging.
