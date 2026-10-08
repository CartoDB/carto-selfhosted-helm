---
paths:
  - "manifests/**"
---

# KOTS manifests

Read `manifests/CLAUDE.md` first: what each file is, when an
`appConfigValues` parameter needs a KOTS field, the three secret origins.

- **DO** add a `kots-config.yaml` item and its `kots-helm.yaml` mapping
  together; use `optionalValues[]` for conditionals. An item without a mapping
  is a knob that silently does nothing.
- **DO** make the chart-side helper check the license or enable flag too when
  a feature is gated behind a license field in the UI. Hidden or
  `when:`-gated items keep the value they last had, so a UI gate alone leaves
  the feature on after the license changes.
- **DO NOT** rename or remove an item or `ConfigOption` name. Existing
  installs reference them, and a `ConfigOptionEquals` against a missing name
  evaluates to false silently, so the UI branch disappears.
- **DO** add a `statusInformers` entry in `kots-app.yaml` for a new component,
  or the Admin Console reports the wrong app status.
- **DO** test the Helm-only path too (`helm template`). This layer sets every
  chart value it maps, so it masks missing defaults in `chart/values.yaml`.
- **DO** use `type: RandomString` + `hidden` for infra secrets,
  `LicenseFieldValue` for license-driven values, and `type: password` mapped
  to `appSecrets.*` for customer secrets. **DO NOT** set a secret value, not
  even a placeholder: this file set ships to every customer.
- **DO NOT** rename `embbeded-cluster.yaml`; it is misspelled on purpose.
- **DO** use `repl{{ … }}` for a whole value and `'{{repl … }}'` inline in a
  quoted string. `ConfigOption`, `ConfigOptionEquals`, `LicenseFieldValue` and
  `Distribution` are the functions in use — copy an existing item.

Then `scripts/test-kots-config.sh all`, and treat any `✗` (a reference to an
undefined option) as a failure regardless of the exit code. Install-test a UI
change through the `release-changes` label (per-branch Replicated channel)
before merging.
