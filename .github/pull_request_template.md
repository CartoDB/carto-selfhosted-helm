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
- Sync vs Async: <!-- e.g., "Sync endpoint - simple CRUD, responds <1s" or "Async subscriber - bulk import, emits event" -->
- Communication pattern: <!-- e.g., "REST endpoint", "PubSub subscriber", "Event-driven" -->
- Data access: <!-- e.g., "Query with tenant filter", "New repository method" -->
- Why this approach: <!-- Explain trade-offs, alternatives considered -->

## Review Focus Areas
<!-- Help reviewers prioritize their time -->
**Critical areas** (require thorough review):
1. [File/Component] - [What to look for]
2.

**Safe to skip**: [List files with trivial changes - formatting, config, auto-generated]

## Deployment Impact
- [ ] SaaS only
- [ ] Selfhosted only
- [ ] Both SaaS and Selfhosted
- [ ] Not applicable (docs, tests only)

## Migration & Breaking Changes
- [ ] No migrations or breaking changes
- [ ] Database migration (backward compatible?)
- [ ] API contract change (versioned?)
- [ ] Configuration change (env-specific handling?)

## Security Considerations
- [ ] No security impact
- [ ] Auth/authorization changes
- [ ] New API endpoints exposed
- [ ] Data exposure or multi-tenant isolation changes

## Performance Impact
<!-- If applicable: database queries, API calls, algorithm complexity, bundle size -->
- [ ] No performance impact
- [ ] Performance implications (describe below)

<!-- If performance impact: explain changes to queries, API calls, rendering, etc. -->

## Tests
- [ ] Unit tests added/updated (coverage: XX%)
- [ ] Integration tests added/updated
- [ ] E2E tests added/updated
- [ ] Selfhosted validation done
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
<!-- If UI changes: attach before/after screenshots or video demo -->
<!-- If backend/API: provide curl examples or API response samples -->

## AI-Generated Code Notice
<!-- If this PR contains AI-generated code (Claude Code, Copilot, etc.): -->
- [ ] This PR contains AI-generated code
- [ ] Areas requiring extra verification: [list specific concerns]
- [ ] Not applicable

## Coding Standards Compliance
- [ ] Changes follow team coding standards
- [ ] No violations of deprecated patterns (e.g., no new Redux Sagas)
- [ ] Backend: layer separation respected (middlewares → services → data layer)
- [ ] Backend: new/modified tests are black-box (test behavior, not implementation)

## Checklist
- [ ] PR title follows convention
- [ ] Shortcut story linked
- [ ] One issue per PR
- [ ] Appropriate labels applied
- [ ] Reviewers assigned (or auto-assigned)
- [ ] AI review findings addressed (if applicable)
