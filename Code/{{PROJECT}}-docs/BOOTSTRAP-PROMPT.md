# Bootstrap Prompt

**Hand this to your AI agent to start the project.** Open the workspace folder in your
agent and say: *"Read `Code/{{PROJECT}}-docs/BOOTSTRAP-PROMPT.md` and
`Code/{{PROJECT}}-docs/overview.md`, and let's begin."*

> Paths below are relative to the workspace root (the folder containing `Code/` and
> `prompts/`).

---

You are helping the user start a new software project, architecture-first. Your job in
this kickoff is to turn their 1–2 page idea into a planned project: a roadmap, an
architecture STEP, and the prompts to execute it. You will write actual code *later* — not
in this kickoff.

## Read first
1. `Code/{{PROJECT}}-docs/METHOD.md` — the methodology you must follow (tiers,
   architecture-first, the doc genres, sessions, naming). Internalize it.
2. `Code/{{PROJECT}}-docs/overview.md` — the user's project idea. Your starting point.

If `overview.md` is still the empty template (the common case right after `init.sh`),
**don't make the user fill it in alone.** Ask them to describe the idea in a sentence or two
right here in the chat — or to expand on the one-line description `init.sh` already captured
(it's in the *What is {{PROJECT}}* section of `Code/{{PROJECT}}-docs/AGENTS.md`) — then
**draft the first paragraph or two yourself and write them into
`Code/{{PROJECT}}-docs/overview.md`** for their review. (If they'd rather paste or point you
at a longer brief they already have, use that instead.)

## Work through these stages, pausing at each checkpoint

The user may be a less-experienced developer. **Guide, don't assume.** Recommend sensible
defaults, explain tradeoffs in plain language, and ask before moving on. Stage 0 establishes
the user's experience level — calibrate every stage to it (see §4 of `METHOD.md`).

### Stage 0 — Interview  ▸ checkpoint
**Ask this first, before any other question:** *how much experience does the user have
building a software project like this?* — Level **1** (no coding experience), **2** (basic
coding experience), or **3** (senior developer or above). Record their answer in
`overview.md` under *Your experience level*. This single answer **calibrates the rest of the
interview and every later architecture session**: at Level 1–2, explain each question's
*what* and *why* in plain language, lead with a recommended default, and avoid unexplained
jargon (scaling, threat model, environments …); at any level, treat any sign of confusion
or request to clarify — however worded — as a cue to explain plainly. **When you record the
level, tell the user in plain terms they can ask you to explain any question at any time** —
don't make them discover it. (See `METHOD.md` §4.)

Then read `overview.md` and fill the gaps a brief usually misses. Ask about: who uses it and
who else is affected; expected scale now vs. in a year; hard constraints (regulatory,
budget, timeline, team, existing systems); data sensitivity; integrations; and — most
importantly — what's **explicitly out of scope**. Keep it conversational, a few questions
at a time. When you have enough, summarize your understanding back and offer to write it
into `Code/{{PROJECT}}-docs/overview.md`. **Wait for confirmation.**

### Stage 1 — Roadmap  ▸ checkpoint
Propose:
- The **Phase plan** — what Phase 1 (the MVP) includes and, deliberately, excludes; a
  rough sketch of later phases for things being deferred. (This is a sketch to align on
  direction; the Phasing & Roadmap session formalizes the phase plan.)
- **STEP-1 (architecture)** as the first and — for now — the *only* STEP in the index.
Record **only STEP-1's row** in `prompts/STEP-index.md` (already seeded from
`Code/{{PROJECT}}-docs/templates/step-index-seed.md` by `init.sh` — fill in that row).
**Don't add implementation STEP rows yet** — those are outlined later by the planning
session, after STEP-1's review passes (`METHOD.md` §2). **Wait for the user to confirm
scope** before continuing.

### Stage 2 — STEP-1 PLAN  ▸ checkpoint
STEP-1 is **architecture-first: design docs + ADRs, no code.** Decide which architecture
sessions apply (see the core set in `METHOD.md` §4). For the **conditional** sessions, make an
*explicit* call on **each one** — never leave a conditional simply unconsidered: fill in the
**Conditional sessions considered** table in the PLAN, marking every conditional **Include**
(→ the substep it becomes, e.g. `1.6a`) or **N/A** (with a one-line reason). Decide each from
its trigger: the Architecture Overview & Component Boundaries client-surfaces question for **Native app**; the auth posture for
**Identity/auth**; and personal or regulated data (PII, health/financial/children's, or a
regime like GDPR/HIPAA/PCI) for **Privacy/compliance**. A skipped conditional must leave a
recorded reason, so a future reader sees a decision rather than an accident. Keep the core
sessions unless their own session instructions explicitly say to mark them `N/A` (for example,
the UI / Design System session when there is no styled UI). Write
`Upcoming Prompts/{{PROJECT}}-STEP-1-PLAN.md` (from
`Code/{{PROJECT}}-docs/templates/step-plan.md`) listing the chosen sessions as substeps,
the locked decisions, and the definition of done. **Wait for confirmation.**

### Stage 3 — Substep prompts  ▸ checkpoint
For STEP-1, the substep prompts already exist as the session files in
`Code/{{PROJECT}}-docs/templates/architecture-sessions/`. Confirm the mapping (substep 1.1
→ session 01, etc.) in the PLAN and the index. (For later, non-architecture STEPs, you'll
author substep prompts from `Code/{{PROJECT}}-docs/templates/substep-prompt.md`.)

**Then close out the kickoff:** flip the kickoff gate by editing the
`<!-- PROJECT-STATUS: not-started -->` line near the top of
`Code/{{PROJECT}}-docs/overview.md` to `<!-- PROJECT-STATUS: kickoff-complete -->`. This is
what tells future sessions to resume from `prompts/STEP-index.md` instead of re-running this
kickoff. **Then stop.**

### Execution (after kickoff)
The user drives from here, one session at a time:
> run session 1.1

Each session interviews the user and writes its architecture doc + any ADRs, then updates
`prompts/STEP-index.md`. Encourage the user to clear the chat between sessions — state
lives on disk. When all architecture sessions are done, run the substep labeled
**Cross-Cutting Review**.

Then move from architecture into building: tell the agent *"run the planning session"*
(`Code/{{PROJECT}}-docs/templates/planning-session.md`). It outlines **all** the Phase-1
**implementation STEPs** (a couple of sentences each) into `prompts/STEP-index.md` — the
bridge from design to code. You then build them one at a time; each STEP's detailed PLAN is
written when you start it.

At any point — including a brand-new chat — the next action is derivable from
`prompts/STEP-index.md` via the **next-action resolver** (`METHOD.md` §10); each session and
STEP also ends by naming it. So *"what do I do next?"* is always answerable from disk.

## Rules
- **No application code during the architecture STEP.** Output is Markdown docs + ADRs.
- **One decision/question cluster at a time.** Don't dump a wall of questions.
- **Calibrate to the recorded experience level** (Stage 0; `overview.md`). At Level 1–2,
  explain what you're asking and why before asking it; at any level, treat any sign of
  confusion or request to clarify — however worded — as a cue to explain plainly, and tell
  the user up front they can ask.
- **Record decisions.** Significant choices become ADRs
  (`Code/{{PROJECT}}-docs/templates/adr.md`); the current design lives in architecture docs
  (`Code/{{PROJECT}}-docs/templates/architecture-doc.md`).
- **Keep the index current.** `prompts/STEP-index.md` is the source of truth for status.
