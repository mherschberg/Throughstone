# {{PROJECT}} — Cross-Cutting Review (Session 1.14)

> **How to run:** Tell your agent *"run session 1.14"*. This is the closing pass of the
> architecture STEP. Unlike the other sessions it's a **review**, not an interview — it
> reads everything produced in STEP-1 and checks it hangs together, then fixes what doesn't.
> Reads **all** of `architecture/*` and `adr/*` plus `prompts/STEP-index.md`.

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
This is a final read-through of everything designed so far: it checks the docs agree with
each other and fixes gaps or contradictions before coding begins. (This one's a review, not
an interview.)

## Why this session matters
Each architecture doc was written in its own session, often in a cleared context. That's
good for focus but means the docs can quietly **contradict each other** or leave **gaps
between areas**. This pass catches those before they harden into code. It's the gate
between "we have a pile of docs" and "we have a coherent architecture."

## How this session works
- Read every architecture doc and ADR from STEP-1 in one pass.
- Report findings to the user, propose fixes, and — with their OK — apply them (updating the
  affected docs and bumping their version logs). Surface anything that needs a *decision*
  rather than a fix.

## What to check
1. **Consistency.** Do the docs agree? Common conflicts: the data model vs. the API/flows
   in the architecture overview; scaling assumptions vs. the chosen infrastructure; the
   backup/RPO and availability target vs. the data model's loss-tolerance decisions;
   security boundaries vs. the actual component boundaries; terms used
   differently than the glossary defines them.
2. **Completeness.** Is anything referenced but never specified? Any area that should have
   been covered for *this* project but wasn't? Any **Open Questions** still unresolved that
   would block implementation?
3. **Foreclosure check.** Walk the "Forecloses / tradeoff" entries across all docs. Does any
   MVP shortcut block a capability the phasing doc committed to a later phase? If so,
   flag it — it may need a cheaper approach now.
4. **Decision coverage.** Are the significant, contested, or deferred decisions recorded as
   **ADRs**? Write any that are missing (`templates/adr.md`).
5. **Index accuracy.** Does `prompts/STEP-index.md` match what actually got produced
   (statuses, output docs)? And does `architecture/README.md`'s index list every
   architecture doc that exists (number, title, version, status)?

## Output
- A **review summary** — write it to the STEP-1 folder
  (`Upcoming Prompts/{{PROJECT}}-STEP-1-REVIEW.md`): what was checked, findings, fixes
  applied, and any decisions still needed from the user.
- **Apply the fixes** to the affected architecture docs (bump their Version Logs); write any
  missing ADRs and add them to the `adr/README.md` registry.
- **Populate `architecture/README.md`'s index** — one row per architecture doc produced
  (number, title, current version, status). This is the first time every doc exists in one
  place, so it's where the index gets filled in.
- A consolidated **Open Questions** list carried forward into the first implementation STEP.
- Update `prompts/STEP-index.md`: mark 1.14 done and **STEP-1 complete** once the review is
  clean. STEP-1 is now ready to be archived (moved into `prompts/001-mvp/step-0001/`) per
  `prompts/README.md`.

## Next
Once the review is clean, the architecture STEP is done — mark STEP-1 **complete** and archive
it to `prompts/001-mvp/step-0001/` (`prompts/README.md`). The next action is to move into
building: **start a fresh chat** and run the **implementation planning session**
(`templates/planning-session.md`, *"run the planning session"*) — it outlines the Phase-1
implementation STEPs. See the next-action resolver (`METHOD.md` §10).

**Begin now — in this same reply.** "run session 1.14" is your go-ahead, not a request for
acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to
start. Read all the STEP-1 architecture docs and ADRs silently. Then, in this one reply:
**(1)** tell the user — in the one or two sentences from **What this session does** above —
what you're about to do (plain language); then **(2)** report your first findings (issues by
severity, anything needing the user's decision). That orientation plus the first findings is
your first reply.
