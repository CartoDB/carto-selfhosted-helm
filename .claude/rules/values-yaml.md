---
paths:
  - "chart/values.yaml"
  - "chart/README.md"
---

# values.yaml and the generated README

`chart/README.md` is generated from the `## @param` comments in
`chart/values.yaml` by readme-generator-for-helm (pinned in the `Makefile`).
Never edit the README by hand: run `make readme` and commit the result, or the
CI drift check fails.

## Documenting a parameter

- Every key gets `## @param <full.dotted.path> <description>` on the line
  above it — the full path from the root, not the relative key.
- `## @section <Title>` starts a table; each component has one.
- `## @skip <path>` keeps a key out of the README (the `lifecycleHooks`
  objects); `## @extra <path> <description>` documents a path with no literal
  key (the `appSecrets.<name>` parents).
- The generator fails on an undocumented key (`Missing metadata for key`) and
  on a comment whose path doesn't exist (`Metadata provided for non existing
  key`). Fix the comment, don't add a `@skip`.

## Where a parameter goes

Placement is by what the parameter configures — `appConfigValues` (app
behaviour the customer sets), `cartoConfigValues` (CARTO-managed wiring) or a
component block (that pod's shape). `chart/CLAUDE.md` has the rule and the
precedents. The reviewers' recurring question is "does this need to be a
parameter at all?": derive it in the template when the customer would never
set it (#890).

## Values

- Secret defaults stay `""`. Never a realistic-looking placeholder, not even
  in a comment: this repository is public.
- Image registries use the `*defaultRegistry` YAML anchor, never a literal
  (#917).
- Every key a template reads needs a default here; a missing one is a
  nil-pointer error for pure-Helm installs (sc-575799).
- `resources` changes (`Mi`, `m`) trigger a CI comment and need the public
  docs updated, a release-notes ticket, and product told (#892).
- A customer-set parameter is only done with its KOTS field in
  `manifests/kots-config.yaml` + `manifests/kots-helm.yaml`, or a stated reason
  it stays Helm-only (`manifests/CLAUDE.md` has the two checkable cases).

## Navigating 7,000+ lines

`grep -n '^## @section' chart/values.yaml` is the table of contents; then
`grep -n '@param <path>'`. Component blocks are uniform, so a key's shape in
`mapsApi` is its shape everywhere.
