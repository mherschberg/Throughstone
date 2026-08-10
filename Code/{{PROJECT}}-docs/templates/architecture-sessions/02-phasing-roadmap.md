# {{PROJECT}} — Phasing & Roadmap (Session 1.2)

> **How to run:** Tell your agent *"STEP-1.2"* or *"session 1.2"*; a leading *"Run"* and
> `: Phasing & Roadmap` are optional (but the label helps chat titles). It interviews you one decision at a
> time, then writes the Phasing & Roadmap architecture doc and updates `prompts/STEP-index.md`.
> Reads `overview.md` and the System Overview, Requirements & Non-Goals architecture doc
> (`architecture/*-system-overview.md`) first.
> **Calibrate to the local user profile.** Check the **Experience level** in root `.throughstone/local-user.md`: at Level 1-2 (no/basic coding background) explain each question's *what* and *why* in plain language - leading with a recommended default - before asking, and skip bare jargon. If the file is missing, ask the two local-profile questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, then continue. Also check **Communication style** there and use it as the default level of detail; an explicit style request in chat overrides it for this session only. At any level, treat any confusion or request to clarify - in any words, not just those - as a cue to explain plainly, and tell the user up front they can ask. (See `METHOD.md` §4, "Calibrating to the user's experience level".)

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
Phase 1 to something you can actually ship, and it tells the architecture what it must
*not* foreclose. Phase 1 is your first milestone — often an MVP, but it may be a POC, a
prototype, or a full v1; everything you're deferring is a later phase, on purpose, recorded.

## How this session works
- One decision at a time; show options where useful; **wait** for the answer.
- Pull from `overview.md` and the System Overview, Requirements & Non-Goals architecture doc
  first; don't re-ask what's settled.
- Recommend a default for the project's stage, and flag what it rules out later.
- Push back on a Phase 1 that's too big — the smallest cut that delivers on its chosen goal.

## Decisions to make (in order)
1. **Phase 1 definition.** What Phase 1 is, and its one-sentence goal. For an **MVP** (the
   common first milestone) that's the smallest version that delivers the core value *and* is
   usable/testable by a real user; a POC, prototype, or full v1 is scoped to that milestone's
   goal instead. What's the one-sentence goal of Phase 1?
2. **In scope for Phase 1.** The capabilities that must be in Phase 1 (cross-check against
   the "core capabilities" from the System Overview, Requirements & Non-Goals architecture
   doc). Keep it ruthless.
3. **Deferred to later phases.** For each major thing you're *not* doing in Phase 1, which
   phase it lands in and *why* it's deferred (risk, capacity, dependency, unknowns).
4. **Phase sequence & dependencies.** What must come before what? Sketch Phase 2, Phase 3
   at a high level — enough to know the direction, not a detailed plan.
5. **Launch criteria for Phase 1.** Concretely, what has to be true to call Phase 1 done
   and ship it? (Ties to the success criteria from the System Overview, Requirements &
   Non-Goals architecture doc.)
6. **Don't-foreclose list.** The future-phase capabilities the Phase-1 architecture must not
   block (e.g. multi-tenant, mobile, 100× scale). These become constraints for the other
   sessions — especially the Scaling & Performance and Architecture Overview & Component
   Boundaries sessions.

## Output
Write `architecture/02-phasing-roadmap.md` — the Phasing & Roadmap architecture doc (use
`templates/architecture-doc-template.md`). Body:
- **Phase 1** — goal, in-scope capabilities, launch criteria
- **Later phases** — a short sketch of Phase 2+, each with its deferred items and rationale
- **Don't-foreclose list** — constraints Phase 1 must respect
- **Phase dependency notes**

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log** at
v0.1.0. Then update `prompts/STEP-index.md`: reflect the phase plan in the roadmap and mark
substep 1.2 done.

## Next
Once 1.2 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep with a descriptive first message. For
a numbered core session, use `Run STEP-1.N: <Session label from the index>` (for example,
`Run STEP-1.3: Architecture Overview & Component Boundaries`). For a lettered conditional
session, use `Run STEP-1.Xa: <Conditional session label>` and the invocation by name from
that conditional's template. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "STEP-1.N" or "session N.M", with or without a leading "Run" and with or without the session label, is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read root `.throughstone/local-user.md`, `overview.md` (plus anything relevant in `inputs/` and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the profile's experience level. That orientation plus the first question is your entire first reply — nothing more.
