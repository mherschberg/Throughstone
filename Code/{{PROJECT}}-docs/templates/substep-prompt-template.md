# {{PROJECT}} — STEP-{{N.M}}: {{SUBSTEP TITLE}}

> **How to run:** Tell your agent *"run substep {{N.M}}"* (or *"read and run this file"*).
> A substep is self-contained — it must be executable cold in a fresh chat. Write it so
> nothing depends on the conversation that produced it.
>
> *(For the architecture STEP-1, use the interview-style session format instead — see
> `templates/architecture-sessions/01-system-overview.md`. This template is for normal
> implementation substeps.)*

## Context
<!-- Where this sits: the STEP it belongs to (link the PLAN), what came before, what this
     substep is responsible for. Enough that a fresh agent understands without history. -->

## Read these first
<!-- Start from the main docs this substep depends on, then follow the indexes to find
     anything else relevant — don't try to read everything. The indexes point the way:
       - overview.md                — project brief + user's experience level; calibrate
                                      user-facing explanations/questions to it
       - architecture/README.md     — the architecture docs (what the system is)
       - adr/README.md              — the decision records (why it's that way)
       - coding-standards/README.md — the per-language standards
       - registries/repos.yml       — the repo inventory; each repo's own README is its "about"
       - registries/risks.yml       — accepted risks/debt with owners and revisit triggers
     List the specific files this substep depends on below — including the README of each
     repo this substep touches, read before you work in it. For any substep that adds or
     changes an API/interface surface (an endpoint, request/response shape, event, webhook,
     CLI contract, library public API, or import/export format), include
     the Interface Contracts architecture doc (`architecture/*-interface-contracts.md`) and any
     interface contract artifact it names; include
     coding-standards/api.md for HTTP/REST endpoints so the house style — timestamps,
     pagination, errors, versioning — stays consistent across endpoints. For security-sensitive
     work — auth/AuthZ, secrets, sensitive data, public attack surface, dependency/security
     controls, or accepted security risk — include the Security & Threat Model architecture doc
     (`architecture/*-security-threat-model.md`) and relevant `registries/risks.yml` rows.
     Do not include `runbooks/security-review.md`, S0/S1/S2 checklists, or security report
     templates in normal implementation substeps; those belong only to explicit Security
     Baseline, Security Review, or Security Audit STEPs. -->
- overview.md
- architecture/NN-…
- ADR-XXXX-…
- coding-standards/…  (include coding-standards/api.md for HTTP/REST API-touching substeps)
- <repo>/README.md  (for each repo this substep touches)

## Scope
<!-- What this substep owns, and — just as important — what it does NOT touch. -->

## Your task
<!-- The concrete work, broken into clear deliverables with expected outputs. -->

## Verification
<!-- How to prove it's done and correct: tests to write/run, commands, checks. -->
- **If this substep writes or changes code, write the tests that cover it** — not just the
  happy path. (Default; override only for a genuinely code-free substep, e.g. docs/config,
  and say why.)
<!-- Kinds of cases to consider — cover the ones that apply, prune the rest:
     - Happy path — the expected, valid case.
     - Empty / zero / null / missing input — empty collections & strings, 0, null/None,
       absent optional fields.
     - Boundary values — min/max, first/last, off-by-one, size/length limits, overflow.
     - Invalid / malformed input — wrong type, bad format, out-of-range — rejected cleanly.
     - Error paths — failures surface correctly (right exception / error code / message);
       partial work rolls back.
     - Edge cases in logic — unusual-but-valid combinations, ordering, duplicates, conflicts.
     - State & side effects — data persisted/updated correctly, no unintended mutation,
       cleanup on failure.
     - Concurrency & idempotency (where relevant) — repeated / parallel / out-of-order calls.
     - External-dependency failure (where relevant) — timeouts / unavailable deps handled
       (mock at the boundary).
     - Security / authorization (where relevant) — unauthenticated / unauthorized access denied.
     - Regression — when fixing a bug, add a test that reproduces it so it can't return. -->
- **Run the relevant tests before marking this substep done** — at minimum the tests that
  exercise the code you touched. They must pass.

## Keeping the docs true  (always)
<!-- The architecture docs are the source of truth for the design. Implementation drifts
     from them unless you actively reconcile. -->
If your work **changes an architecture decision** (the data model, a boundary, a chosen
technology, a scaling/security assumption, anything an `architecture/*` doc states), don't
just change the code:
- **Small/clarifying change:** update the affected `architecture/NN-*.md` and **bump its
  Version Log** (see `METHOD.md` §6).
- **Significant or contested change:** write an **ADR** (`templates/adr-template.md`) and update the
  doc to match. If it overturns a settled assumption, consider **re-running** the relevant
  architecture session (`METHOD.md` §4).
- **New code, even when it overturns nothing:** adding a component, repo, or public surface,
  or coining a domain term, can outdate a doc that's still "correct." Update whatever's now
  stale: the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`) and `registries/repos.yml` for new
  components/repos (a brand-new repo also gets a stamped **README whose Overview explains what
  it is**); the **interface contract artifact** named in the Interface Contracts architecture doc
  (`architecture/*-interface-contracts.md`) when you add or
  change an endpoint, event, webhook, CLI contract, library public API, or import/export format;
  the repo **README** when setup/run/test changes; the Glossary architecture doc
  (`architecture/*-glossary.md`) for new domain terms.
- **Accepted risk or debt:** if this substep consciously defers a security control,
  dependency fix, incident follow-up, operational weakness, or other tech debt, add or update
  `registries/risks.yml` with severity, owner, and revisit trigger. The register is an index:
  reference the architecture decision/section, ADR, issue/follow-up STEP, incident report, or
  check-in report that carries the details. If no such source exists, create it first, then add
  the register row.
- **Secrets** stay out of the repo — local values live in the gitignored `.env` /
  `.secrets/` (see `architecture/*-security-threat-model.md` and the Environments
  architecture doc, `architecture/*-environments.md`); commit only `.env.example`.

Leaving the doc stale is a defect, not a follow-up.

## Definition of done
- [ ]
- [ ]
- [ ] Code this substep wrote or changed is covered by tests, and the relevant tests pass.
      <!-- default; drop only for a genuinely code-free substep -->
- [ ] New/changed classes, functions, and methods carry docstrings (see
      `coding-standards/README.md`).
- [ ] Any architecture decision this substep changed is reflected in the docs (Version Log
      bumped) or recorded in an ADR — and any new component, repo, or domain term is reflected
      in the relevant doc (overview / `repos.yml` / Glossary architecture doc).
- [ ] Any accepted risk or deferred technical debt created or changed by this substep is
      recorded in `registries/risks.yml` or explicitly marked not applicable.

## Next
When this substep is done, update its status in the STEP PLAN, then tell the user the next
action: the next open substep — *"run substep N.M"*, in a **fresh chat** — or, if this was
the last substep, the STEP's review. (`METHOD.md` §10.)
