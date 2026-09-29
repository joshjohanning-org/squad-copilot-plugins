# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Architecture, scope, and triage | lead | Design proposals, trade-offs, issue triage, breaking changes |
| Feature and bug implementation | developer | New endpoints, UI changes, bug fixes, refactoring |
| Tests and quality | tester | Test plans, unit/integration tests, bug reproduction |
| Code review | reviewer | Pull request review, maintainability, performance pitfalls |
| Security | security | Auth, secrets, dependencies, threat modeling |
| Documentation | docs | READMEs, API docs, ADRs, runbooks |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Lead |
| `squad:{name}` | Pick up issue and complete the work | Named member |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it — analyzing content, assigning the right `squad:{member}` label, and commenting with triage notes.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the "inbox" — untriaged issues waiting for Lead review.

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** When the developer builds a feature, spawn the tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. The Lead handles all `squad` (base label) triage.
8. **Security-sensitive changes** (auth, secrets, permissions, dependencies) always include the security agent.

## Work Type → Agent

| Work Type | Primary | Secondary |
|-----------|---------|----------|
| Architecture and planning | lead | reviewer |
| Feature implementation | developer | tester |
| Bug fix | developer | tester |
| Testing | tester | developer |
| Code review | reviewer | security |
| Security | security | reviewer |
| Documentation | docs | lead |
