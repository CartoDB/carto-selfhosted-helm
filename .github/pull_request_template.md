<!--
Keep it short. Delete any section that does not apply instead of leaving it
blank. Everything here is public: no secrets, internal hostnames, project IDs
or customer data (see CLAUDE.md). Shortcut IDs are fine, full URLs are not.
-->

## Summary
<!-- 1-2 sentences: what changed and why -->

Story: [sc-XXXXXX]

## Decisions
<!-- Answer the ones that apply; delete the rest -->
- Where the value lives: <!-- values.yaml + KOTS item / values.yaml only (why no KOTS field?) / chart-internal helper / hardcoded -->
- Upgrade behaviour: <!-- what an existing install gets on upgrade if it never sets this -->
- Alternatives considered: <!-- and where the approach was agreed, if it was -->

## Install paths affected
- [ ] Pure Helm
- [ ] Replicated / KOTS (Admin Console, embedded cluster)
- [ ] Both
- [ ] Not applicable (docs, CI, tests)

## Breaking changes and upgrades
- [ ] None
- [ ] Existing installs change behaviour on upgrade (describe the before/after)
- [ ] Renamed or removed a chart value or KOTS `ConfigOption` (back-compat kept?)
- [ ] Requires a customer config or infrastructure change before upgrading
- [ ] Raises `minVersion` / `minKotsVersion` (call it out in the release notes)
- [ ] Changes default `resources` (public docs + release-notes ticket needed)

## Security
- [ ] No security impact
- [ ] Secret handling changed (`secretAssociation`, existing-secret support, mounts) — ask for a second reviewer
- [ ] RBAC, ServiceAccount or securityContext changed
- [ ] Network exposure changed (Service type, Ingress, egress requirements)
- [ ] Changes what preflights or the support bundle capture

## Validation
- [ ] Lints and renders on both install paths (plain Helm and `--set replicated.enabled=true`)
- [ ] `chart/README.md` regenerated (if `chart/values.yaml` changed)
- [ ] Install-tested through the `release-changes` channel: <!-- channel name -->
- [ ] Upgrade-tested from the released chart
- [ ] Not needed (explain why)

<!-- How to validate: steps for the reviewer, or the rendered diff / Admin Console screenshot for KOTS changes -->

## Review focus
<!-- Where to look hard, and what is safe to skip (generated README, formatting) -->

## AI-generated code
- [ ] This PR contains AI-generated code — areas needing extra verification: <!-- list -->
- [ ] Not applicable
