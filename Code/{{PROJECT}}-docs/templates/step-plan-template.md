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
- `overview.md` — read **Your experience level** before user-facing questions or
  explanations, and read **Planning communication style** before planning discussions; keep
  that file as the single source of truth for both values.
- `registries/risks.yml` — review relevant accepted risks/debt before planning work that
  touches their area.
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
     runbooks/incident-postmortem.md; its durable postmortem starts from
     templates/incident-postmortem-template.md. -->

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
- **Calibrate communication from `overview.md`.** Substep prompts should read the recorded
  **Your experience level** and adjust explanations/questions accordingly. STEP planning
  should use the saved **Planning communication style** as the default verbosity. Don't copy
  either value into this PLAN.
- **Plan interactively.** Before this PLAN is finalized, confirm scope with the user and ask
  clarifying questions for ambiguous requirements, sequencing, dependencies, ownership, or
  repo boundaries. When a planning decision is needed, offer appropriate options with brief
  pros and cons. Respect the saved planning style while still asking the questions needed to
  make the STEP coherent.
- **Tests ship with the code.** Every substep that writes or changes code also writes the
  tests for it and runs the relevant tests before it's done (see
  `templates/substep-prompt-template.md`). Override per substep only with a stated reason.
- **Code is documented as it's written.** Every class, function, and method gets a docstring;
  comment the *why* of non-obvious logic (see `coding-standards/README.md`).
- **Accepted risks stay visible.** If this STEP accepts a risk or defers tech debt, add or
  update `registries/risks.yml` with severity, owner, and revisit trigger. Reference an
  architecture decision/section, ADR, issue/follow-up STEP, incident report, or check-in report
  instead of duplicating detail; create that source first if it doesn't already exist.

## Definition of done
<!-- Concrete, checkable criteria for the whole STEP. -->
- [ ]
- [ ]
- [ ] All unit tests pass at the end of this STEP — ideally the full suite (unit +
      integration/e2e). <!-- the default bar; narrow or widen with a stated reason -->
- [ ] STEP review passed; prompts/STEP-index.md updated; STEP archived to prompts/.
<!-- The "STEP review" is your team's standard PR / code review (a standard-practice gate the
     method doesn't redefine — see runbooks/collaboration.md), plus the doc-drift check from
     templates/substep-prompt-template.md ("Keeping the docs true"). Exceptions: STEP-1's review is the
     Cross-Cutting Review; a Check-in STEP is itself the review (runbooks/check-in.md); an
     Incident STEP closes by completing the postmortem and output checklist in
     runbooks/incident-postmortem.md. -->
