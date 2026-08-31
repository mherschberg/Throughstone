# {{PROJECT}} — Architecture Overview & Component Boundaries (Session 1.3)

> **How to run:** Tell your agent *"STEP-1.3"* or *"session 1.3"*; a leading *"Run"* and
> `: Architecture Overview & Component Boundaries` are optional (but the label helps chat titles). It interviews you one decision at a
> time, then writes the Architecture Overview architecture doc and updates `prompts/STEP-index.md`.
> Reads `overview.md`, the System Overview, Requirements & Non-Goals architecture doc
> (`architecture/*-system-overview.md`), and
> the Phasing & Roadmap architecture doc (`architecture/*-phasing-roadmap.md`) first.
> **Have existing architecture docs, system diagrams, or a protocol/API spec?** Put them in `inputs/` (or share them in chat and I'll save copies there); I'll design from them rather than starting cold. These are point-in-time inputs: I read the live ones (not `inputs/archive/`), and where an `architecture/` doc already covers the same ground, that doc wins.
> **Calibrate to the local user profile.** Check the **Experience level** in root `.throughstone/local-user.md`: at Level 1-2 (no/basic coding background) explain each question's *what* and *why* in plain language - leading with a recommended default - before asking, and skip bare jargon. If the file is missing, ask the two local-profile questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, then continue. Also check **Communication style** there and use it as the default level of detail; an explicit style request in chat overrides it for this session only. At any level, treat any confusion or request to clarify - in any words, not just those - as a cue to explain plainly, and tell the user up front they can ask. (See `METHOD.md` §4, "Calibrating to the user's experience level".)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Now that the scope and phases are set, we'll shape the system into its main components and
decide how they talk to each other, so the parts stay separable instead of tangling into one
big blob.

Terminology: **Architecture Overview & Component Boundaries** is the Session 1.3 process name;
`architecture/*-architecture-overview.md` is the **Architecture Overview architecture doc** it
produces (the exact output file is named in the Output section below); **component boundaries**
are the concrete separations, data handoffs, and contract candidates recorded in that doc.

## Why this session matters
This is where the system gets its shape. Developers who skip it end up with a "big ball of
mud" — everything tangled, no clear ownership, impossible to change safely. Drawing
**components and the boundaries between them** now is what lets the system grow without
rewrites. This session also decides the **client surfaces**, which determines whether the
UI / Design System session and the conditional Native-app session apply.

## How this session works
- One decision at a time; sketch a simple diagram when it clarifies; **wait** for answers.
- Recommend a default (for most first releases: a **modular monolith**, not microservices) and
  say what it forecloses.
- Keep it high-level — responsibilities and boundaries, not class-level detail.

## Decisions to make (in order)
1. **Client surfaces.** What does the user interact with: web app / mobile (iOS, Android) /
   desktop / CLI / API-only / several? **Record this** — it gates the UI / Design System session and the
   Native-app session. (e.g. "API + web admin" → UI yes, native no.)
2. **Top-level components.** List the major pieces (services, apps, libraries, jobs). Give
   each a **single-sentence responsibility**. Resist splitting too finely.
3. **Architecture style.** Modular monolith vs. separate services vs. serverless. Default
   to the simplest that fits; only split into services where you have a real reason
   (independent scaling, separate teams, isolation). Flag what the choice forecloses.
4. **Boundaries & contract candidates.** For each boundary between components: what crosses it (an
   API call? an event/queue? a shared DB — usually avoid), sync vs async, who owns the data
   on each side. *(Plain terms: a boundary is an **API** when the handoff crosses a network —
   one service calling another, or an outside client calling yours — not a plain in-process
   function call within one program. Its **contract** is the agreed shape of that call, written
   as a machine-readable file — **OpenAPI** for REST/HTTP, a **GraphQL** schema, or
   **protobuf**/gRPC — so both sides build against one spec instead of guessing from prose.)*
   Identify which boundaries probably need formal contracts and the likely style, but leave the
   final contract policy, source of truth, artifact locations, and update rules to the Interface
   Contracts session, after data/security/privacy choices and the Observability architecture
   doc are known.
5. **Key flows.** Walk through 1–2 important end-to-end scenarios and how components
   collaborate to serve them. This validates the boundaries.
6. **High-level tech stack.** Languages/frameworks per component (detail lands in repo READMEs
   and the Test Strategy session). Note anything already constrained. The language(s) you
   name here drive which **coding standards** apply — the Test Strategy session reconciles
   `coding-standards/` to this list and records the result in the Test Strategy architecture doc
   (reviewing the ones that ship, creating any that don't).
7. **Build vs. buy.** For major capabilities (auth, payments, search, email, etc.), what
   you'll build vs. use a managed service for. Flag anything that becomes a hard dependency.

## Output
Write `architecture/03-architecture-overview.md` (use `templates/architecture-doc-template.md`). Body:
- **Client surfaces** (the recorded answer + what it gates)
- **Component diagram** (ASCII) + a **component table**: name | responsibility | tech
- **Repos** — one entry per repository the project has: its role, the slice it owns, and where its
  detail lives (its own README). Each entry pairs with that repo's `registries/repos.yml` row, and
  `runbooks/register-repo.md` maintains both rather than either being written by hand.
- **Boundaries & contract candidates** table — boundary | what crosses it | sync/async |
  data owner | likely contract style | notes for the Interface Contracts session
- **Key flows** (numbered walk-throughs)
- **Build vs. buy** notes

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. **If this
document already exists, complete it rather than overwrite it** — registering a repository creates
it, with its Repos section, when nothing else has yet — so keep the Repos entries already recorded
and *add* a Version Log line rather than starting one. Update
`prompts/STEP-index.md`: mark 1.3 done; then, **based on the client-surfaces answer** — if
there's no styled UI, **mark the UI / Design System row `Deferred` or `N/A`** (keep the row, per
the resolver's "skip any `Deferred`/`N/A`" rule in `METHOD.md` §10; use `Deferred` when a UI may
arrive later, `N/A` when this project has no UI by design). If there's a mobile/desktop app,
**add the Native-app conditional row** (e.g. `1.7a`); otherwise record the Native-app decision in
the STEP-1 PLAN's Conditional sessions considered table. Don't delete the seeded UI / Design
System row.

## Next
Once 1.3 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep with a descriptive first message. For
a numbered core session, use `Run STEP-1.N: <Session label from the index>` (for example,
`Run STEP-1.4: Data Model, Ownership & Retention`). For a lettered conditional session, use
`Run STEP-1.Xa: <Conditional session label>` and the invocation by name from that
conditional's template. This session may have marked the UI / Design System row `N/A` or
added a Native-app row, so trust the index. See the next-action resolver in `METHOD.md` §10.

**If you were sent here to run this session, begin now — in this same reply.** "STEP-1.N" or "session N.M", with or without a leading "Run" and with or without the session label, is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read root `.throughstone/local-user.md`, `overview.md` (plus anything relevant in `inputs/` and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the profile's experience level. That orientation plus the first question is your entire first reply — nothing more. **If you were not sent here to run it — you are reading this file to harvest its decisions from existing code, to check whether a conditional applies, or to review coverage — this paragraph is not addressed to you.** Use the file as reference material and follow whatever sent you here.
