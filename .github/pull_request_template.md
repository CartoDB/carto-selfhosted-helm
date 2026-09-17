## Summary
<!-- 1-2 sentences: WHAT changed and WHY -->
Story: [sc-XXXXX]

## What Changed
**Added:**
-

**Modified:**
-

**Removed:**
-

## Architectural Context
<!-- For large/initiative-level changes: link the EAD (Engineering Architecture Document) -->
<!-- EADs live in Google Docs - paste the full URL here -->
EAD: <!-- Google Docs link to EAD, or "N/A - small change" -->

<!-- For small changes without an EAD: explain the architectural approach and
    reasoning behind your implementation decisions (why this approach over alternatives, where was it agreed, product approved the change in X forum…) -->

**Architectural Decisions Made:**
<!-- Answer these if your change involves architecture decisions: -->
- Where the value lives: <!-- e.g., "chart value with a KOTS item", "chart-internal helper only", "hardcoded in the template" -->
- Customer-facing or not: <!-- if customer-set, it needs values.yaml + kots-config.yaml + kots-helm.yaml together -->
- Default and upgrade behaviour: <!-- what an existing install gets on upgrade if it never sets this -->
- Why this approach: <!-- Explain trade-offs, alternatives considered -->

## Review Focus Areas
<!-- Help reviewers prioritize their time -->
**Critical areas** (require thorough review):
1. [File/Component] - [What to look for]
2.

**Safe to skip**: [List files with trivial changes - formatting, config, auto-generated]

## Deployment Impact
<!-- Every change here ships to Self-Hosted; pick the install paths it reaches -->
- [ ] Pure Helm installs
- [ ] Replicated / KOTS installs (Admin Console, embedded cluster)
- [ ] Both install paths
- [ ] Not applicable (docs, CI only)

## Migration & Breaking Changes
- [ ] No migrations or breaking changes
- [ ] Existing installs change behaviour on upgrade (describe the before/after)
- [ ] Renamed or removed a chart value (back-compat alias kept?)
- [ ] Requires a customer config or infrastructure change before upgrading
- [ ] Raises `minKotsVersion` (must be called out in the release notes)

## Security Considerations
- [ ] No security impact
- [ ] Secret handling changed (`secretAssociation`, existing-secret support, mounts)
- [ ] RBAC, ServiceAccount or securityContext changed
- [ ] Network exposure changed (Service type, Ingress, egress requirements)
- [ ] Affects what preflight or support-bundle artifacts capture

## Performance Impact
<!-- If applicable: database queries, API calls, algorithm complexity, bundle size -->
- [ ] No performance impact
- [ ] Performance implications (describe below)

<!-- If performance impact: explain changes to queries, API calls, rendering, etc. -->

## Tests
- [ ] Renders on both install paths (plain Helm and `--set replicated.enabled=true`)
- [ ] Validated on a real install — new install
- [ ] Validated on a real install — upgrade from the released chart
- [ ] Chart tests / preflight specs added or updated
- [ ] Edge cases verified: [list specific scenarios]
- [ ] No tests needed (explain why)

## Dependencies
<!-- Link related PRs -->
- Depends on: #XXX
- Blocks: #XXX
- Related: #XXX
- None

## How to Validate
<!-- Step-by-step instructions for reviewers to verify this change -->
1. ...
2. ...

## Screenshots/Demos
<!-- KOTS config changes: screenshot of the Admin Console config screen -->
<!-- Template changes: the relevant rendered diff, or the before/after configmap keys -->

## AI-Generated Code Notice
<!-- If this PR contains AI-generated code (Claude Code, Copilot, etc.): -->
- [ ] This PR contains AI-generated code
- [ ] Areas requiring extra verification: [list specific concerns]
- [ ] Not applicable

## Coding Standards Compliance
<!-- Conventions live in CLAUDE.md and CONTRIBUTING.md -->
- [ ] Changes follow the repo conventions
- [ ] Chart documentation updated (via helm-readme-generator)
- [ ] Chart templates linted and validated
- [ ] Customer-set values wired end to end (`values.yaml` + `kots-config.yaml` + `kots-helm.yaml`)
- [ ] New values carry a `## @param` comment
- [ ] Version fields left to the release bot (`VERSION`, `Chart.yaml`, `chartVersion`)
- [ ] No secrets, internal hostnames/project IDs, or customer data added (public repo)

## Checklist
- [ ] PR title follows convention
- [ ] Shortcut story linked
- [ ] One issue per PR
- [ ] Appropriate labels applied (`release-changes` if install testing is needed)
- [ ] Reviewers assigned (or auto-assigned)
- [ ] AI review findings addressed (if applicable)
