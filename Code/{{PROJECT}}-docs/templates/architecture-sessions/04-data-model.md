# {{PROJECT}} — Data Model, Ownership & Retention (Session 1.4)

> **How to run:** Tell your agent *"run session 1.4"*. It interviews you one decision at a
> time, then writes the Data Model architecture doc and updates `prompts/STEP-index.md`.
> Reads `overview.md`, the System Overview, Requirements & Non-Goals architecture doc
> (`architecture/*-system-overview.md`), and
> the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`) first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
In 1.3 we set the components; now we'll work out the data each one needs and owns, how long
it's kept, and which parts are sensitive — decisions that get painful to change once code
exists.

Terminology: **Data Model, Ownership & Retention** is the Session 1.4 process name;
`architecture/*-data-model.md` is the **Data Model architecture doc** it produces (the exact
output file is named in the Output section below); **data model artifacts** are concrete
outputs governed by that doc, such as entity/relationship models, ownership tables, storage
choices, sensitive-data inventories, retention/deletion rules, and migration notes.

## Why this session matters
Data outlives code. Developers often model entities ad hoc as they build, then discover
the hard parts too late: who *owns* a piece of data when two components touch it, how long
to keep it, and what's sensitive. Getting the **entities, ownership, and retention** right
now prevents painful migrations and compliance surprises later.

## How this session works
- One decision at a time; sketch the entities and relationships; **wait** for answers.
- Recommend sensible defaults (e.g. surrogate UUID keys, a single relational DB for an
  MVP) and flag what they foreclose.
- Watch for hidden PII — push on anything that touches personal data.

## Decisions to make (in order)
1. **Core entities & relationships.** The nouns of the domain and how they relate
   (one-to-many, many-to-many). Name them deliberately and consistently — the Glossary
   session later builds glossary entries *from* these names, so pick clear ones now.
2. **Ownership / source of truth.** For each entity, which component owns it (is the
   authoritative source). Critical once more than one component reads/writes it.
3. **Storage choice(s).** Relational vs. document vs. key-value vs. blob — and whether it's
   one shared database or one per component. Default: one relational DB for an MVP unless
   there's a reason. Flag lock-in / scaling implications for the Scaling & Performance
   session.
4. **Identifiers.** Surrogate keys (UUID/auto-increment) vs. natural keys; ID format and
   whether IDs are exposed publicly.
5. **Sensitive data / PII.** What personal or sensitive data is collected, and a rough
   classification (public / internal / confidential / regulated). Feeds the Security & Threat
   Model session — and, if any of it is regulated, add the conditional Privacy/compliance
   session row (or mark the conditional `Deferred` with a revisit trigger in the STEP-1 PLAN if
   the data is planned for a later phase).
6. **Retention & deletion.** How long each data class is kept, and how deletion works
   (including user-requested deletion / "right to be forgotten" if relevant).
7. **Consistency & evolution.** Where you need strong consistency vs. where eventual is
   fine; and how schema changes/migrations will be handled.

## Output
Write `architecture/04-data-model.md` (use `templates/architecture-doc.md`). Body:
- **Entity model** — a diagram or list with relationships
- **Ownership table** — entity | owning component | notes
- **Storage** — choices + rationale
- **PII / sensitive-data table** — data class | sensitivity | retention | deletion
- **Consistency & migration notes**

Fill the **Decision Summary**, record **Open Questions** (e.g. for security/glossary entries), start
the **Version Log**. Update `prompts/STEP-index.md`: mark 1.4 done.

## Next
Once 1.4 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
