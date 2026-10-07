---
paths:
  - "chart/values.yaml"
  - "chart/README.md"
---

# values.yaml and the generated README

`chart/README.md` is generated from the `## @param` comments in
`chart/values.yaml` by readme-generator-for-helm. **DO NOT** edit the README
by hand: regenerate it (commands in `CONTRIBUTING.md`) and commit the result,
or the CI drift check fails.

## Documenting a parameter

- **DO** put `## @param <full.dotted.path> <description>` on the line above
  every key — the full path from the root, not the relative key.
- `## @section <Title>` starts a table; each component has one.
- `## @skip <path>` keeps a key out of the README (the `lifecycleHooks`
  objects); `## @extra <path> <description>` documents a path with no literal
  key (the `appSecrets.<name>` parents).
- The generator fails on an undocumented key (`Missing metadata for key`) and
  on a comment whose path doesn't exist (`Metadata provided for non existing
  key`). **DO** fix the comment; **DO NOT** add a `@skip` to silence it.

## Where a parameter goes

Placement is by what the parameter configures — `appConfigValues` (app
behaviour the customer sets), `cartoConfigValues` (CARTO-managed wiring) or a
component block (that pod's shape). `chart/CLAUDE.md` has the rule and the
precedents. **DO NOT** add a parameter the customer would never set; derive
the value in the template instead.

## Values

- **DO** keep secret defaults `""`. **DO NOT** write a realistic-looking
  placeholder, not even in a comment: this repository is public.
- **DO** use the `*defaultRegistry` YAML anchor for image registries, never a
  literal.
- **DO** give every key a template reads a default here; a missing one is a
  nil-pointer error for pure-Helm installs.
- **DO** pair a `resources` change (`Mi`, `m`) with a public docs update, a
  release-notes ticket, and a heads-up to product. CI comments on it.
- **DO** ship a customer-set parameter with its KOTS field in
  `manifests/kots-config.yaml` + `manifests/kots-helm.yaml`, or state why it
  stays Helm-only (`manifests/CLAUDE.md` has the two checkable cases).

## Navigating 7,000+ lines

`grep -n '^## @section' chart/values.yaml` is the table of contents; then
`grep -n '@param <path>'`. Component blocks are uniform, so a key's shape in
`mapsApi` is its shape everywhere.
