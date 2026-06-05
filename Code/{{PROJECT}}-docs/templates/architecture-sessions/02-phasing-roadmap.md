# {{PROJECT}} — Phasing & Roadmap (Session 1.2)

> **How to run:** Tell your agent *"run session 1.2"*. It interviews you one decision at a
> time, then writes the Phasing & Roadmap architecture doc and updates `prompts/STEP-index.md`.
> Reads `overview.md` and the System Overview, Requirements & Non-Goals architecture doc
> (`architecture/*-system-overview.md`) first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
With *what* you're building settled in the System Overview, Requirements & Non-Goals session,
we'll split the work into phases — what the first shippable version includes and what's
deliberately deferred to later — so the build aims at a clear, bounded target.

Terminology: **Phasing & Roadmap** is the Session 1.2 process name;
`architecture/*-phasing-roadmap.md` is the **Phasing & Roadmap architecture doc** it
produces (the exact output file is named in the Output section below); the **phase plan**
is the concrete Phase-1 scope, later-phase deferrals, dependencies, and launch criteria
recorded in that doc. `prompts/STEP-index.md` is the separate living roadmap of STEPs and
status.

## Why this session matters
Mid-level developers tend to either build everything at once or never decide what comes
later — both stall projects. Deciding the **phases** up front does two things: it shrinks
the MVP to something you can actually ship, and it tells the architecture what it must
*not* foreclose. Phase 1 is your MVP; everything you're deferring is a later phase, on
purpose, recorded.

## How this session works
- One decision at a time; show options where useful; **wait** for the answer.
- Pull from `overview.md` and the System Overview, Requirements & Non-Goals architecture doc
  first; don't re-ask what's settled.
- Recommend a default for the project's stage, and flag what it rules out later.
- Push back on a Phase 1 that's too big — "smallest thing that delivers the core value."

## Decisions to make (in order)
1. **Phase 1 (MVP) definition.** The smallest version that delivers the core value *and*
   is usable/testable by a real user. What's the one-sentence goal of the MVP?
2. **In scope for Phase 1.** The capabilities that must be in the MVP (cross-check against
   the "core capabilities" from the System Overview, Requirements & Non-Goals architecture
   doc). Keep it ruthless.
3. **Deferred to later phases.** For each major thing you're *not* doing in the MVP, which
   phase it lands in and *why* it's deferred (risk, capacity, dependency, unknowns).
4. **Phase sequence & dependencies.** What must come before what? Sketch Phase 2, Phase 3
   at a high level — enough to know the direction, not a detailed plan.
5. **Launch criteria for Phase 1.** Concretely, what has to be true to call the MVP done
   and ship it? (Ties to the success criteria from the System Overview, Requirements &
   Non-Goals architecture doc.)
6. **Don't-foreclose list.** The future-phase capabilities the MVP architecture must not
   block (e.g. multi-tenant, mobile, 100× scale). These become constraints for the other
   sessions — especially the Scaling & Performance and Architecture Overview & Component
   Boundaries sessions.

## Output
Write `architecture/02-phasing-roadmap.md` — the Phasing & Roadmap architecture doc (use
`templates/architecture-doc.md`). Body:
- **Phase 1 (MVP)** — goal, in-scope capabilities, launch criteria
- **Later phases** — a short sketch of Phase 2+, each with its deferred items and rationale
- **Don't-foreclose list** — constraints the MVP must respect
- **Phase dependency notes**

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log** at
v0.1.0. Then update `prompts/STEP-index.md`: reflect the phase plan in the roadmap and mark
substep 1.2 done.

## Next
Once 1.2 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
