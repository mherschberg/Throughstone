# {{PROJECT}} — Test Strategy (Session 1.12)

> **How to run:** Tell your agent *"run session 1.12"*. It interviews you one decision at a
> time, then writes `architecture/12-test-strategy.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md`, the Architecture Overview doc (`architecture/*-architecture-overview.md`),
> the Data Model doc (`architecture/*-data-model.md`), the Environments doc
> (`architecture/*-environments.md`), and the Interface Contracts architecture doc
> (`architecture/*-interface-contracts.md`) first — plus any conditional-session
> doc that adds test surface (e.g. identity-auth for authn/authz flows, privacy-compliance for
> data-handling/retention, native-app for device/platform testing, or one added later), if it's
> been written.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
With the components, data, environments, and interface contracts set, we'll decide what kinds
of tests you'll write and what has to pass before code merges, so you can change things later
without fear.

## Why this session matters
Tests are what let you (and your AI agent) change code later without fear. The common
failure modes: no tests, only happy-path tests, or a slow flaky suite no one trusts.
Deciding the **test tiers, what each covers, and what gates a merge** now means quality is
built in rather than bolted on — and it's especially important in a multi-repo project
where the pieces have to work *together*.

## How this session works
- One decision at a time; **wait** for answers.
- Recommend a pragmatic default (a healthy **test pyramid**: many fast unit tests, fewer
  integration, a thin layer of end-to-end) and flag where this system needs more.
- Tie back to the components, data, environments, and interface contracts.

## Decisions to make (in order)
1. **Test tiers.** Define unit / integration / end-to-end for this project: what each
   covers and roughly the balance between them.
2. **What must be covered.** The critical paths and risky areas that must have tests (not a
   vanity coverage percentage). What's explicitly *not* worth testing heavily. As a rough guide you
   can *aim* for ~80% unit-test coverage — a suggestion to steer by, not a gate; don't chase
   the number at the expense of testing what matters.
3. **Test data & isolation.** How tests get data (fixtures/factories) and stay isolated
   (e.g. a fresh DB/schema per test run) so they don't interfere.
4. **Mocking strategy.** What to mock (external/third-party dependencies) vs. exercise for
   real (your own components, a real local DB).
5. **System / end-to-end tests.** How the whole system is tested together — important for
   multi-repo. Where do cross-repo e2e tests live (often a dedicated tests repo)?
6. **CI gates.** What must pass before code merges and before it deploys (tests, linters,
   type checks, build). Keep the gate fast enough that people don't route around it. A starter
   wiring this up ships in `templates/ci/` (a method-integrity workflow that runs
   `scripts/check.sh`, plus a per-repo test workflow to fill in) — see `templates/ci/README.md`.
   Include the contract-validation gates chosen in the Interface Contracts architecture doc where they apply.
7. **Performance / load testing.** Whether and when load tests run (ties to the targets in
   1.5).
8. **Coding standards per language.** Confirm the implementation language(s) from the
   high-level stack (the Architecture Overview stack decision). Then reconcile `coding-standards/` to that list, **one
   language at a time**:
   - **If a `coding-standards/<lang>.md` already ships** (e.g. `python.md`, `typescript.md`,
     `go.md`, `rust.md`, `dart.md`, `java.md`, `csharp.md`): tell the user it exists as a *default starting point*,
     and ask them to review it and flag anything they want changed for this project. Apply
     their edits.
   - **If there's no file for that language:** create one by copying the structure of an
     existing standard (e.g. `coding-standards/python.md`) — same sections (naming, layout,
     error handling, logging, testing) — and fill it in with the user.
   - **Prune** the default standards for languages this project won't use.
   - **`sql.md`, `shell.md`, and `api.md` are cross-cutting**, not 1.3 implementation languages:
     keep `sql.md` if the project uses a relational database, `shell.md` if it ships shell scripts
     (CI glue, dev scripts, entrypoints), and `api.md` if any boundary from the Architecture Overview doc is an HTTP/REST API
     it exposes or consumes — regardless of the language list; prune any that don't apply.
     `sql.md`'s rules are secondary to the language docs where they conflict; `api.md` is the house
     style that complements the HTTP/REST interface contract artifacts and policy from the Interface Contracts architecture doc.

## Output
Write `architecture/12-test-strategy.md` (use `templates/architecture-doc.md`). Body:
- **Test tiers** — tier | scope | tools | where it runs
- **Coverage priorities** — must-cover paths
- **Test data & isolation**, **mocking strategy**
- **System/e2e testing** (and its home in a multi-repo setup)
- **CI gates** — what blocks merge / deploy
- **Coding standards** — link the per-language file(s) in `coding-standards/` that apply

Also reconcile the `coding-standards/` directory itself (decision 8): keep and user-review
the standards for the chosen languages, add any missing ones from the existing pattern, and
delete the rest. Update the file table in `coding-standards/README.md`.

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.12 done.

## Next
Once 1.12 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
