# {{PROJECT}} — Scaling & Performance (Session 1.5)

> **How to run:** Tell your agent *"run session 1.5"*. It interviews you one decision at a
> time, then writes the Scaling & Performance architecture doc and updates
> `prompts/STEP-index.md`.
> Reads `overview.md`, the Phasing & Roadmap architecture doc (`architecture/*-phasing-roadmap.md`),
> the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`), and the Data Model
> architecture doc (`architecture/*-data-model.md`) first — plus any
> conditional-session doc relevant to scale (e.g. native-app for offline/sync load, identity-auth,
> or one added later), if it's been written.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
With the components and data in place, we'll make sure the simple first version won't quietly
block the growth you'll want later — without over-building for scale you don't have yet.

Terminology: **Scaling & Performance** is the Session 1.5 process name;
`architecture/*-scaling-performance.md` is the **Scaling & Performance architecture doc** it
produces (the exact output file is named in the Output section below); **performance artifacts**
are concrete outputs governed by that doc, such as load profiles, performance targets,
bottleneck/scaling decisions, caching and async plans, load-test inputs, and don't-foreclose
mitigations.

## Why this session matters
The goal here is **not** to build for scale you don't have — it's to make sure the MVP,
built for a handful of users, doesn't quietly *block* the scale you'll want later. The
classic trap: a shortcut that's invisible at 5 users (in-memory state, one big sync
request, a single database doing everything) and a rewrite at 5,000. We decide which
shortcuts are fine and which to avoid cheaply now.

## How this session works
- One decision at a time; **wait** for answers.
- For each decision, recommend the **simplest thing that works for the MVP**, then state
  explicitly whether it forecloses future scaling and the cheapest way to avoid that.
- Use real numbers from the user, not guesses.

## Decisions to make (in order)
1. **Load now vs. later.** Expected users/requests/data at launch, and a realistic figure
   in ~12 months (or a 100× "what if it works" number). Both, concretely.
2. **Performance targets.** For the few operations that matter, target latency/throughput
   (e.g. "search returns in <300ms", "ingest 1M events/day"). Skip the rest.
3. **State.** Which components are stateless (easy to scale horizontally) and which hold
   state (sessions, caches, queues, the DB). State is what makes scaling hard — name it.
4. **First bottleneck.** Under growth, what breaks first — the database, a single process,
   a third-party rate limit? Be specific; it's where future effort goes.
5. **Scaling strategy.** Vertical (bigger box) vs. horizontal (more boxes); what can scale
   independently. For an MVP, vertical is often fine — *if* the design stays
   horizontally-scalable when needed.
6. **Caching & async.** Where caching helps (and how it's invalidated); what heavy work
   can move to a queue/background job instead of blocking a request.
7. **Don't-foreclose review.** Walk the MVP shortcuts (single DB, in-memory state,
   synchronous calls, sticky sessions). For each: does it block horizontal scaling later,
   and is there a cheap way to keep the door open now (e.g. externalize session state,
   keep handlers stateless, put an abstraction at the boundary)?

## Output
Write `architecture/05-scaling-performance.md` — the Scaling & Performance architecture doc
(use `templates/architecture-doc.md`). Body:
- **Load profile** — now vs. projected
- **Performance targets** — operation | target
- **Stateful vs. stateless** components
- **Bottlenecks & scaling strategy**
- **Caching & async** plan
- **Don't-foreclose** table — shortcut | blocks scaling? | cheap mitigation now

Fill the **Decision Summary** (the "Forecloses" column is the point of this doc), record
**Open Questions**, start the **Version Log**. Update `prompts/STEP-index.md`: mark 1.5 done.

## Next
Once 1.5 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
