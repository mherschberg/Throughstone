# {{PROJECT}} — Glossary (Session 1.13)

> **How to run:** Tell your agent *"run session 1.13"*. It works through the project's terms
> with you, then writes the Glossary architecture doc and updates `prompts/STEP-index.md`.
> Reads `overview.md` and **all** the architecture docs produced so far.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Drawing on everything designed so far, we'll pin down the precise meaning of the project's key
terms, so everyone — and every future session — uses them the same way.

Terminology: **Glossary** is the Session 1.13 process name;
`architecture/*-glossary.md` is the **Glossary architecture doc** it produces (the exact
output file is named in the Output section below); **glossary entries** are the concrete term
definitions, acronyms, disambiguations, and naming notes recorded in that doc.

## Why this session matters
Every project develops its own vocabulary, and when the same word means different things to
different people (or the AI agent), bugs and confusion follow. A glossary pins down the
**precise meaning of each domain term** so everyone — and every future session — uses
language the same way. It's short, but it prevents a lot of drift.

## How this session works
- This is more harvesting than interviewing: **read the architecture docs written so far**
  and pull out the terms that need definition, then confirm/refine each with the user.
- **Sweep *every* file in `architecture/`, whatever its number — don't stop at this session's
  own number.** New sessions get added over time, both standard and conditional, and their
  docs are numbered as they're slotted in; conditional-session docs in particular land *after*
  the standard range, so a sweep that assumes a fixed upper bound will miss them. Glob the
  directory, not a numbered range. Conditional docs tend to carry the most specialized
  vocabulary — for the conditionals that ship today, e.g. *JWT / refresh token / scope*
  (identity-auth), *data subject / DPA / sub-processor / retention window* (privacy-compliance),
  *deep link / push token / platform entitlement* (native-app) — but treat that as illustrative:
  scan whatever docs exist for new domain terms and acronyms, including any added later.
- Flag **ambiguous or overloaded words** — terms used loosely that need a single agreed
  meaning (e.g. "user" vs. "account" vs. "member"; "job" vs. "task").
- Keep definitions tight and align entity names with the Data Model architecture doc.

## What to produce (work through these)
1. **Domain terms.** The nouns and concepts specific to this project, each with a one- to
   two-sentence definition.
2. **Entities.** The data model entities, defined consistently.
3. **Acronyms & abbreviations** used across the docs.
4. **Disambiguations.** Words that have been used loosely — pick one meaning and note what
   each is *not*.
5. **Naming conventions.** A short pointer to how things are named (services, entities, IDs)
   — consistent with `METHOD.md` §8.

## Output
Write `architecture/13-glossary.md` — the Glossary architecture doc (use
`templates/architecture-doc-template.md`). Body:
- An **alphabetical term table** — Term | Definition | Notes / "not to be confused with"
- A short **naming conventions** note

Mark it as **living** — it grows as new terms appear in later STEPs. Fill the **Version
Log**; record any unresolved naming questions in **Open Questions**. Update
`prompts/STEP-index.md`: mark 1.13 done.

## Next
Once 1.13 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session 1.13" is your go-ahead, not a request for
acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to
start. Read `overview.md` and all the architecture docs silently. Then, in this one reply:
**(1)** tell the user — in the one or two sentences from **What this session does** above —
what you're about to do (plain language); then **(2)** immediately present the first batch of
terms you've gathered (with proposed plain-language definitions) for them to confirm or
correct. That orientation plus the first batch is your entire first reply — nothing more.
