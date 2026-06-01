# {{PROJECT}} — Architecture Overview & Component Boundaries (Session 1.3)

> **How to run:** Tell your agent *"run session 1.3"*. It interviews you one decision at a
> time, then writes `architecture/03-architecture-overview.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md` and `architecture/01-*`, `02-*` first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Now that the scope and phases are set, we'll shape the system into its main components and
decide how they talk to each other, so the parts stay separable instead of tangling into one
big blob.

## Why this session matters
This is where the system gets its shape. Developers who skip it end up with a "big ball of
mud" — everything tangled, no clear ownership, impossible to change safely. Drawing
**components and the boundaries between them** now is what lets the system grow without
rewrites. This session also decides the **client surfaces**, which determines whether the
UI session (1.7) and the conditional Native-app session apply.

## How this session works
- One decision at a time; sketch a simple diagram when it clarifies; **wait** for answers.
- Recommend a default (for most MVPs: a **modular monolith**, not microservices) and say
  what it forecloses.
- Keep it high-level — responsibilities and boundaries, not class-level detail.

## Decisions to make (in order)
1. **Client surfaces.** What does the user interact with: web app / mobile (iOS, Android) /
   desktop / CLI / API-only / several? **Record this** — it gates session 1.7 (UI) and the
   Native-app session. (e.g. "API + web admin" → UI yes, native no.)
2. **Top-level components.** List the major pieces (services, apps, libraries, jobs). Give
   each a **single-sentence responsibility**. Resist splitting too finely.
3. **Architecture style.** Modular monolith vs. separate services vs. serverless. Default
   to the simplest that fits; only split into services where you have a real reason
   (independent scaling, separate teams, isolation). Flag what the choice forecloses.
4. **Boundaries & contracts.** For each boundary between components: what crosses it (an
   API call? an event/queue? a shared DB — usually avoid), sync vs async, who owns the data
   on each side. *(Plain terms: a boundary is an **API** when the handoff crosses a network —
   one service calling another, or an outside client calling yours — not a plain in-process
   function call within one program. Its **contract** is the agreed shape of that call, written
   as a machine-readable file — **OpenAPI** for REST/HTTP, a **GraphQL** schema, or
   **protobuf**/gRPC — so both sides build against one spec instead of guessing from prose.)*
   For any boundary that's an **API**, decide that its contract is a
   **versioned artifact** — an OpenAPI / GraphQL schema / protobuf file in the owning repo,
   not just prose — since it's what other components build against and the thing most likely
   to break them when it drifts.
5. **Key flows.** Walk through 1–2 important end-to-end scenarios and how components
   collaborate to serve them. This validates the boundaries.
6. **High-level tech stack.** Languages/frameworks per component (detail lands in the
   repo/test-strategy session 1.11). Note anything already constrained. The language(s) you
   name here drive which **coding standards** apply — session 1.11 reconciles
   `coding-standards/` to this list (reviewing the ones that ship, creating any that don't).
7. **Build vs. buy.** For major capabilities (auth, payments, search, email, etc.), what
   you'll build vs. use a managed service for. Flag anything that becomes a hard dependency.

## Output
Write `architecture/03-architecture-overview.md` (use `templates/architecture-doc.md`). Body:
- **Client surfaces** (the recorded answer + what it gates)
- **Component diagram** (ASCII) + a **component table**: name | responsibility | tech
- **Boundaries & contracts** table — and for each API boundary, where its spec lives (the
  versioned OpenAPI / GraphQL / protobuf artifact that is the contract of record)
- **Key flows** (numbered walk-throughs)
- **Build vs. buy** notes

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.3 done; then, **based on the client-surfaces answer** — if
there's no styled UI, **mark the core UI row (1.7) `N/A`** (keep the row, per the resolver's
"skip any `N/A`" rule in `METHOD.md` §10); if there's a mobile/desktop app, **add the
Native-app conditional row** (e.g. `1.7a`). Don't delete the seeded 1.7 row.

## Next
Once 1.3 is marked done, the next action is the lowest open STEP-1 substep — normally **1.4 (Data model, ownership & retention)**. Tell the user to **start a fresh chat** and run it (*"run session 1.4"*); if the index shows a different next open substep (this session may have **marked the UI 1.7 row `N/A` or added a Native-app row**), run that instead. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
