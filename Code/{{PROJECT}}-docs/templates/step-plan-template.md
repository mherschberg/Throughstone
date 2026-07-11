# {{PROJECT}} — STEP-{{N}} PLAN: {{STEP TITLE}}

**Phase:** {{e.g. Phase 1 — MVP}}
**Owner:** {{who is running this STEP}}        <!-- one owner for the whole STEP and all its substeps; also shown in prompts/STEP-index.md; solo: optional -->
**Status:** Planned        <!-- Planned → In progress → Done; or Deferred / Abandoned (see METHOD.md §1) -->
**Date:** {{DATE}}
**Branch:** `step-{{NNNN}}-{{short-name}}`   <!-- same name in every repo this STEP touches -->
**Repos (projection):** {{repos + merge order}}   <!-- same label as prompts/STEP-index.md; lists repos + merge order; powers the overlap warning -->

> One-paragraph statement of what this STEP delivers and why it comes now.

## Motivation
<!-- Why this STEP exists. What it unblocks. Where it sits in the arc of the project. -->

## Decisions already locked
<!-- Decisions from prior STEPs/ADRs that this STEP must respect. Reference by ADR number
     or architecture doc. Carrying these forward keeps a shared mental model. -->
- root `.throughstone/local-user.md` — read **Experience level** before user-facing
  questions or explanations, and read **Communication style** before planning discussions;
  keep that file as the personal local source of truth for both values.
- `registries/risks.yml` — review relevant accepted risks/debt before planning work that
  touches their area.
- The Test Strategy architecture doc (`architecture/*-test-strategy.md`) — use it to decide
  which test tiers this STEP must add or update and which command or CI gate proves the STEP
  is done.
- For security-sensitive feature work, reference the Security & Threat Model architecture doc
  (`architecture/*-security-threat-model.md`) and relevant risk rows. Do not pull in
  `runbooks/security-review.md`, S0/S1/S2 checklists, or security report templates unless this
  STEP is explicitly a Security Baseline, Security Review, or Security Audit STEP.
- ADR-XXXX — …
- architecture/NN-… — …

## Substeps

| # | Title | Produces | Depends on | Open questions |
|---|-------|----------|------------|----------------|
| {{N}}.1 |  |  |  |  |
| {{N}}.2 |  |  |  |  |

<!-- For the architecture STEP, substeps are the sessions in
     templates/architecture-sessions/ (1.1 → session 01, etc.). For later STEPs, each
     substep gets a prompt authored from templates/substep-prompt-template.md. A Check-in STEP is
     thin: no prompts are authored — its two substeps are doc-drift/conditional-coverage
     reconciliation (N.1) and the full test run (N.2) defined in runbooks/check-in.md; this
     PLAN just points there. A late conditional-session follow-up STEP is also thin: its
     one substep points directly to the applicable conditional-*.md template and records the
     exact by-name invocation plus the assigned output-doc number; title its index row
     "Conditional session: <topic>" so the resolver prioritizes it. An Incident STEP is also
     thin: no prompts are authored — its substeps are
     RCA (N.1), find similar (N.2), and fix/harden (N.3) defined in
     runbooks/incident-postmortem.md; its durable postmortem report starts from
     templates/reports/incidents/incident-postmortem-report-template.md and is saved under
     reports/incidents/. -->

## Test plan
<!-- Required for any STEP that writes or changes code. Use the Test Strategy architecture doc
     to choose the applicable tiers; prune rows that do not apply and add project-specific ones
     where needed. Every code-changing substep should either appear here or state why tests are
     not applicable. Choose the run timing deliberately: either per substep, a dedicated final
     verification substep, or another stated gate. -->

| Test tier / surface | Substep(s) | Tests to create or update | Run timing | Command / gate | Notes |
|---------------------|------------|---------------------------|------------|----------------|-------|
| Unit | {{N}}.? |  | Per substep / final verification |  |  |
| Integration / data | {{N}}.? |  | Per substep / final verification |  |  |
| API / contract | {{N}}.? |  | Per substep / final verification |  |  |
| End-to-end / user flow | {{N}}.? |  | Per substep / final verification |  |  |
| Security / authorization | {{N}}.? |  | Per substep / final verification |  |  |
| Performance / load | {{N}}.? |  | Per substep / final verification |  |  |

## Conditional sessions considered  <!-- STEP-1 (architecture) only; delete this section for other STEPs -->
<!-- Every conditional-*.md session file gets a row and an EXPLICIT decision, never a silent
     omission. The current set is seeded below; add a row for any newly discovered template.
     Name the session that owns the decision, then mark each one Include (with the substep it
     became), Deferred (with a revisit trigger), or N/A (with a one-line reason). A skipped or
     deferred conditional must leave a recorded reason here so a future reader sees a decision,
     not an accident. See METHOD.md §4 and the conditional-*.md session files. -->

| Conditional session | Owning session | Decision | Substep / reason / revisit trigger |
|---------------------|----------------|----------|------------------------------------|
| Native app (mobile / desktop) | 1.3 Architecture Overview | Include / Deferred / N/A | {{e.g. 1.7a, or "N/A — web-only per 1.3"}} |
| Identity & auth | 1.6 Security & Threat Model | Include / Deferred / N/A | {{e.g. 1.6a, or "Deferred — no accounts/login until Phase 2; revisit before login"}} |
| Privacy, compliance & data governance | 1.4 Data Model / 1.6 Security | Include / Deferred / N/A | {{e.g. 1.6b, or "N/A — no personal/regulated data"}} |

## Open questions
<!-- Things still undecided at the start of this STEP. Mark Q1, Q2, … with owner. -->

## Ground rules
<!-- The working agreement for this STEP. e.g. "no code in this STEP", commit discipline,
     what 'done' means for a substep, review gates. -->
- **Calibrate communication from root `.throughstone/local-user.md`.** Substep prompts
  should read the recorded **Experience level** and adjust explanations/questions
  accordingly. STEP planning should use the saved **Communication style** as the default
  verbosity. If the file is missing, ask the two local-profile questions from
  `BOOTSTRAP-PROMPT.md` Stage 0, create it, and continue. An explicit style request in chat
  overrides the profile for this session only. Don't copy either value into this PLAN.
- **Plan interactively.** Before this PLAN is finalized, confirm scope with the user and ask
  clarifying questions for ambiguous requirements, sequencing, dependencies, ownership, or
  repo boundaries. When a planning decision is needed, offer appropriate options with brief
  pros and cons. Respect the saved communication style while still asking the questions
  needed to make the STEP coherent.
- **Tests ship with the code.** Every substep that writes or changes code also writes or updates
  the relevant tests for it (unit, integration, API/contract, e2e, security/authorization,
  migration/data, performance, or project-specific). The PLAN chooses whether tests run as each
  substep completes or in a dedicated final verification substep; either way, the named test
  command or CI gate must pass before the STEP is Done. Override per substep only with a stated
  reason.
- **Code is documented as it's written.** Every class, function, and method gets a docstring;
  comment the *why* of non-obvious logic (see `coding-standards/README.md`).
- **Accepted risks stay visible.** If this STEP accepts a risk or defers tech debt, add or
  update `registries/risks.yml` with severity, owner, and revisit trigger. Reference an
  architecture decision/section, ADR, issue/follow-up STEP, incident report under
  `reports/incidents/`, or check-in report under `reports/` instead of duplicating detail; create
  that source first if it doesn't already exist.

## Definition of done
<!-- Concrete, checkable criteria for the whole STEP. -->
- [ ]
- [ ]
- [ ] The STEP test plan is complete: each code-changing substep either added/updated its
      relevant tests or records why tests were not applicable.
- [ ] All tests named in the STEP test plan pass at the end of this STEP — ideally the full
      suite (unit + integration/API/e2e/security as applicable). <!-- the default bar; narrow
      or widen with a stated reason -->
- [ ] STEP review passed; prompts/STEP-index.md updated; STEP archived to prompts/.
      <!-- For a Check-in STEP, the completed report is saved under reports/, not in the
           archived STEP folder. -->
<!-- The "STEP review" is your team's standard PR / code review (a standard-practice gate the
     method doesn't redefine — see runbooks/collaboration.md), plus the doc-drift check from
     templates/substep-prompt-template.md ("Keeping the docs true"). Exceptions: STEP-1's review is the
     Cross-Cutting Review; a Check-in STEP is itself the review (runbooks/check-in.md); an
     Incident STEP closes by completing the postmortem report, reports/incidents/README.md row,
     and output checklist in runbooks/incident-postmortem.md. -->
