# {{PROJECT}} - Incident Postmortem Report: {{INCIDENT TITLE}}

**Report date:** {{YYYY-MM-DD}}
**Report path:** `reports/incidents/{{YYYY-MM-DD}}-step-{{NNNN}}-incident-postmortem-report.md`
**Owner:** {{incident owner}}
**Incident status:** {{Open / Mitigated / Resolved / Closed}}
**Postmortem status:** Draft
**Related STEP:** STEP-{{N}}
**Related branch:** `step-{{NNNN}}-{{short-name}}`

## Incident Window

**Started:** {{timestamp/date, or "unknown"}}
**Detected:** {{timestamp/date, or "unknown"}}
**Mitigated:** {{timestamp/date, "N/A", or "unknown"}}
**Resolved:** {{timestamp/date, "N/A", or "unknown"}}
**Closed:** {{date, "N/A", or "unknown"}}

> One or two sentences in plain language: what happened, who or what was affected, and the
> current state. Keep this blameless and system-focused.

<!--
  Use this with runbooks/incident-postmortem.md. Part 1 captures the raw facts; Parts 2-4
  complete this postmortem during the Incident STEP: RCA -> find similar -> fix/harden.
  Save completed reports under reports/incidents/ and record them in that folder's index table.
  Delete sections that do not apply, and link to technical records instead of copying them.
-->

## Classification

**Customer-facing:** {{Yes / No / Unknown}}
**Revenue-impacting:** {{Yes / No / Unknown}}
**Impact level:** {{1 / 2 / 3 / 4 / 5}}
**Severity rationale:** {{why this level fits}}

| Level | Meaning |
|-------|---------|
| 1 | Minor issue with a workaround; limited inconvenience, no meaningful service degradation. |
| 2 | Minor issue with no workaround; limited scope, but affected users or teams are blocked until fixed. |
| 3 | Moderate impact; meaningful degradation, partial outage, data issue, or repeated user pain. |
| 4 | Major impact; broad outage, critical workflow broken, serious data/security concern, or high operational load. |
| 5 | Critical impact; severe business/customer harm, confirmed revenue loss, data loss/exposure, legal/compliance concern, or executive-level incident. |

## Impact

- **Affected users/customers:** {{who was affected, including approximate count if known}}
- **Affected systems:** {{services, repos, environments, integrations}}
- **Impact duration:** {{start -> end, or "unknown"}}
- **Blast radius:** {{scope of affected data, workflows, tenants, regions, or teams}}
- **Data/security/privacy exposure:** {{none / suspected / confirmed, with reference if applicable}}

## Timeline

| Time | Event | Source |
|------|-------|--------|
| {{time}} | {{what happened}} | {{alert, log, deploy, user report, operator note}} |

## Detection & Response

- **Detected by:** {{alert / log / user report / operator / other}}
- **Detection gap:** {{what should have caught this earlier, or "None identified"}}
- **Immediate mitigation:** {{rollback, feature flag, failover, manual repair, other}}
- **Recovery verification:** {{checks that proved the system was healthy again}}
- **What helped response:** {{signals, runbooks, tooling, team actions}}
- **What slowed response:** {{missing signals, unclear ownership, tooling gaps, docs gaps}}

## Root-Cause Analysis

**Symptom:** {{what users/operators saw}}

**Root cause:** {{the changeable system cause, not a person or "a bug" by itself}}

**Contributing factors:**
- {{missing test, missing guardrail, design assumption, process gap, observability gap, etc.}}

### 5 Whys

1. **Why did the symptom happen?** {{answer}}
2. **Why was that possible?** {{answer}}
3. **Why was that possible?** {{answer}}
4. **Why was that possible?** {{answer}}
5. **Why was that possible?** {{answer}}

## Similar Issue Search

| Scope searched | Pattern / query | Result |
|----------------|-----------------|--------|
| {{repo, service, table, workflow}} | {{search term, code pattern, migration shape, assumption}} | {{siblings found, or "none found"}} |

## Fixes & Hardening

- **Root-cause fix:** {{what changed}}
- **Similar issues fixed:** {{siblings fixed, or "None found"}}
- **Regression test:** {{test added or updated}}
- **Detection/alerting:** {{signal added/tuned, or "No change needed" with reason}}
- **Docs/runbooks:** {{docs updated, Version Logs bumped, runbooks improved}}

## Decisions, Risks & Follow-Ups

- **ADRs:** {{ADR created/superseded/amended, or "None"}}
- **Architecture docs:** {{docs updated, or "None"}}
- **Accepted risks/debt:** {{registries/risks.yml entry, or "None"}}
- **Follow-up STEPs:** {{STEP references, or "None"}}
- **Watch at next check-in:** {{what should be revisited, or "None"}}

## Closure Checklist

- [ ] Incident status and incident window fields are resolved where possible.
- [ ] Customer-facing, revenue-impacting, and impact level fields are resolved.
- [ ] Root cause and contributing factors are recorded.
- [ ] Similar issue search is recorded, including negative results.
- [ ] Root cause and siblings are fixed or tracked as follow-up STEPs/accepted risks.
- [ ] Regression test passes.
- [ ] Detection/docs/runbooks are updated where needed.
- [ ] Incident STEP substeps are marked Done.
- [ ] `prompts/STEP-index.md` is updated.
- [ ] `reports/incidents/README.md` is updated with this report and a short incident summary.
