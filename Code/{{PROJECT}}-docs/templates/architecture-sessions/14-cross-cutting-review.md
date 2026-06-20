# {{PROJECT}} — Cross-Cutting Review (Session 1.14)

> **How to run:** Tell your agent *"run session 1.14"*. This is the closing pass of the
> architecture STEP. Unlike the other sessions it's a **review**, not an interview — it
> reads everything produced in STEP-1 and checks it hangs together, then fixes what doesn't.
> Reads **all** of `architecture/*`, `adr/*`, and
> `templates/architecture-sessions/conditional-*.md`, plus the STEP-1 PLAN and
> `prompts/STEP-index.md`.

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
This is a final read-through of everything designed so far: it checks the docs agree with
each other and fixes gaps or contradictions before coding begins. (This one's a review, not
an interview.)

Terminology: **Cross-Cutting Review** is the Session 1.14 process name; the
`Upcoming Prompts/{{PROJECT}}-STEP-1-REVIEW.md` **review doc** is its summary artifact. This
session does not produce a numbered architecture doc; it reconciles existing architecture docs,
fills the architecture index, may write missing ADRs, and may carry open questions into the
first implementation STEP.

## Why this session matters
Each architecture doc was written in its own session, often in a cleared context. That's
good for focus but means the docs can quietly **contradict each other** or leave **gaps
between areas**. This pass catches those before they harden into code. It's the gate
between "we have a pile of docs" and "we have a coherent architecture."

## How this session works
- Run the **conditional-session gate first**. If it finds an applicable session that has not
  been completed, stop this review, slot and run that session, then restart the Cross-Cutting
  Review from the beginning so the new architecture decisions are included.
- Read every architecture doc and ADR from STEP-1 in one pass.
- Report findings to the user, propose fixes, and — with their OK — apply them (updating the
  affected docs and bumping their version logs). Surface anything that needs a *decision*
  rather than a fix.

## What to check
1. **Conditional-session gate.** Enumerate every
   `templates/architecture-sessions/conditional-*.md` file — do not use a hard-coded topic
   list. For each template, read its applicability rule and invocation, then compare that
   rule with `overview.md`, the STEP-1 PLAN's *Conditional sessions considered* table, and
   the architecture docs and ADRs produced so far. Every template must have an explicit row
   in the PLAN. Confirm that the row says one of these:
   - `Include`, with a lettered substep whose session and output doc are complete; or
   - `Deferred` / `N/A`, with a reason or revisit trigger that is still valid.

   If a template has no PLAN row, add one and decide it from the facts now. If a conditional
   applies but is missing, incomplete, or has an invalidated reason, set its PLAN row to
   `Include`; add or reactivate the same lettered substep in both the STEP-1 PLAN's substep
   list and `prompts/STEP-index.md`, near its owning core session; and assign the output-doc
   number using the rule in its template. Leave this Cross-Cutting Review open. Tell the user
   to start a fresh chat and use the exact invocation from that conditional's template.
   **Stop the review here.** After the conditional session is complete, the next action is to
   run this Cross-Cutting Review again **from the beginning**, because the new doc may change
   any cross-cutting finding. Do not mark 1.14 or STEP-1 `Done` until every discovered
   conditional is resolved.
2. **Consistency.** Do the docs agree? Common conflicts: the data model vs. the API/flows
   in the Architecture Overview architecture doc; scaling assumptions vs. the chosen infrastructure; the
   backup/RPO and availability target vs. the data model's loss-tolerance decisions;
   security boundaries vs. the actual component boundaries; terms used
   differently than the Glossary architecture doc defines them.
3. **Completeness.** Is anything referenced but never specified? Any area that should have
   been covered for *this* project but wasn't? Any **Open Questions** still unresolved that
   would block implementation?
4. **Foreclosure check.** Walk the "Forecloses / tradeoff" entries across all docs. Does any
   MVP shortcut block a capability the Phasing & Roadmap architecture doc committed to a later phase? If so,
   flag it — it may need a cheaper approach now.
5. **Decision coverage.** Are the significant, contested, or deferred decisions recorded as
   **ADRs**? Write any that are missing (`templates/adr.md`).
6. **Index accuracy.** Does `prompts/STEP-index.md` match what actually got produced
   (statuses, output docs)? And does `architecture/README.md`'s index list every
   architecture doc that exists (number, title, version, status)?

## Output
- A **review summary** — write it to the STEP-1 folder
  (`Upcoming Prompts/{{PROJECT}}-STEP-1-REVIEW.md`): what was checked, findings, fixes
  applied, the disposition of every discovered conditional-session template, and any
  decisions still needed from the user.
- **Apply the fixes** to the affected architecture docs (bump their Version Logs); write any
  missing ADRs and add them to the `adr/README.md` registry.
- **Populate `architecture/README.md`'s index** — one row per architecture doc produced
  (number, title, current version, status). This is the first time every doc exists in one
  place, so it's where the index gets filled in.
- A consolidated **Open Questions** list carried forward into the first implementation STEP.
- Update `prompts/STEP-index.md`: mark substep 1.14 `Done` and mark the STEP-1 row `Done`
  once the review is clean. STEP-1 is now ready to be archived (moved into
  `prompts/001-mvp/step-0001/`) per `prompts/README.md`.

## Next
Once the review is clean, the architecture STEP is done — mark the STEP-1 row `Done` and archive
it to `prompts/001-mvp/step-0001/` (`prompts/README.md`). The next action is to move into
building: **start a fresh chat** and run the **implementation planning session**
(`templates/planning-session.md`, *"run the planning session"*) — it outlines the Phase-1
implementation STEPs. See the next-action resolver (`METHOD.md` §10).

**Begin now — in this same reply.** "run session 1.14" is your go-ahead, not a request for
acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to
start. Read all the STEP-1 architecture docs and ADRs, every `conditional-*.md` template,
the STEP-1 PLAN, and `prompts/STEP-index.md` silently. Run the conditional-session gate
before the rest of the review. Then, in this one reply: **(1)** tell the user — in the one or
two sentences from **What this session does** above — what you're about to do (plain
language); then **(2)** report the gate result and your first findings (issues by severity,
anything needing the user's decision). That orientation plus the first findings is your
first reply.
