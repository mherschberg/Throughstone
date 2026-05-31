# {{PROJECT}} — Glossary (Session 1.12)

> **How to run:** Tell your agent *"run session 1.12"*. It works through the project's terms
> with you, then writes `architecture/12-glossary.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md` and **all** the architecture docs produced so far.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Drawing on everything designed so far, we'll pin down the precise meaning of the project's key
terms, so everyone — and every future session — uses them the same way.

## Why this session matters
Every project develops its own vocabulary, and when the same word means different things to
different people (or the AI agent), bugs and confusion follow. A glossary pins down the
**precise meaning of each domain term** so everyone — and every future session — uses
language the same way. It's short, but it prevents a lot of drift.

## How this session works
- This is more harvesting than interviewing: **read the architecture docs written so far**
  and pull out the terms that need definition, then confirm/refine each with the user.
- Flag **ambiguous or overloaded words** — terms used loosely that need a single agreed
  meaning (e.g. "user" vs. "account" vs. "member"; "job" vs. "task").
- Keep definitions tight and align entity names with the data model (1.4).

## What to produce (work through these)
1. **Domain terms.** The nouns and concepts specific to this project, each with a one- to
   two-sentence definition.
2. **Entities.** The data-model entities (from 1.4), defined consistently.
3. **Acronyms & abbreviations** used across the docs.
4. **Disambiguations.** Words that have been used loosely — pick one meaning and note what
   each is *not*.
5. **Naming conventions.** A short pointer to how things are named (services, entities, IDs)
   — consistent with `METHOD.md` §8.

## Output
Write `architecture/12-glossary.md` (use `templates/architecture-doc.md`). Body:
- An **alphabetical term table** — Term | Definition | Notes / "not to be confused with"
- A short **naming conventions** note

Mark it as **living** — it grows as new terms appear in later STEPs. Fill the **Version
Log**; record any unresolved naming questions in **Open Questions**. Update
`prompts/STEP-index.md`: mark 1.12 done.

## Next
Once 1.12 is marked done, the next action is the lowest open STEP-1 substep — normally **1.13 (Cross-cutting review)**. Tell the user to **start a fresh chat** and run it (*"run session 1.13"*); if the index shows a different next open substep (sessions can be skipped or added), run that instead. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session 1.12" is your go-ahead, not a request for
acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to
start. Read `overview.md` and all the architecture docs silently. Then, in this one reply:
**(1)** tell the user — in the one or two sentences from **What this session does** above —
what you're about to do (plain language); then **(2)** immediately present the first batch of
terms you've gathered (with proposed plain-language definitions) for them to confirm or
correct. That orientation plus the first batch is your entire first reply — nothing more.
