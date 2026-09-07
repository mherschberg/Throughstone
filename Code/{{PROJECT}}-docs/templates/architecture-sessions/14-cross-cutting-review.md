# {{PROJECT}} — Cross-Cutting Review (Session 1.14)

> **How to run:** Tell your agent *"STEP-1.14"* or *"session 1.14"*; a leading *"Run"* and
> `: Cross-Cutting Review` are optional (but the label helps chat titles). This is the closing pass of the
> architecture STEP. Unlike the other sessions it's a **review**, not an interview — it
> reads everything produced in STEP-1 and checks it hangs together, then fixes what doesn't.
> Reads root `.throughstone/local-user.md`, **all** of `architecture/*`, `adr/*`, and
> `templates/architecture-sessions/conditional-*.md`, plus the STEP-1 PLAN and
> `prompts/STEP-index.md`. If the local profile is missing, ask the two local-profile
> questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, then continue.

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

## Decisions to make (in order)

> Each item below is a check, not a decision this session makes on its own. A check may surface
> something that needs the user's decision — record it as a finding and take it to the session or
> ADR that owns it. (Every session template uses this heading, so anything reading a session file
> finds its work list in the same place.)

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
   any cross-cutting finding. Use a descriptive first message when telling the user to run
   the conditional, e.g. `Run STEP-1.Xa: <Conditional session label>` plus the invocation by
   name from that conditional's template. Do not mark 1.14 or STEP-1 `Done` until every
   discovered conditional is resolved.
2. **Consistency.** Do the docs agree? Common conflicts: the data model vs. the API/flows
   in the Architecture Overview architecture doc; scaling assumptions vs. the chosen infrastructure; the
   backup/RPO and availability target vs. the data model's loss-tolerance decisions;
   security boundaries vs. the actual component boundaries; terms used
   differently than the Glossary architecture doc defines them.

   **Where code already exists, settle the conflict against the code rather than by re-deciding
   it.** The code is authoritative for what the system *does*; the docs stay authoritative for
   what it is *meant* to do. Read the code, then classify each conflict:
   - **A doc got it wrong** — one doc misread code that is itself consistent. An ordinary doc
     fix: no decision to take to the user, and no risk row, because nothing is left behind.
   - **Both patterns really are in the code.** Record both, and file a `registries/risks.yml`
     row with a revisit trigger so each check-in re-reads it. If the user decides now which one
     the project converges on, write that decision up as an ADR.
   - **Intent vs. reality** — a doc states a design the code contradicts. If the intent was
     never a decision this project took, the architecture docs record what is built and the
     intent becomes forward work, with a `registries/risks.yml` row so the gap is re-read at
     each check-in rather than widening unwatched. If the doc records a decision the project
     *did* take and the code drifted from it, the code is the defect — file a bug rather than
     rewriting the doc to bless the drift (`runbooks/check-in.md`).

   The classification turns on what the doc meant, which you often cannot tell from the doc
   alone. Where you cannot, treat it as intent vs. reality and file the row: an extra row the
   next check-in closes costs little, and an intention deleted by a doc fix is not recoverable.
   Being unsure what the *code* does is the opposite case — re-read it before filing a risk, and
   never record debt for our own misreading.
3. **Completeness.** Is anything referenced but never specified? Any area that should have
   been covered for *this* project but wasn't? Any **Open Questions** still unresolved that
   would block implementation?
4. **Foreclosure check.** Walk the "Forecloses / tradeoff" entries across all docs. Does any
   Phase-1 shortcut block a capability the Phasing & Roadmap architecture doc committed to a later phase? If so,
   flag it — it may need a cheaper approach now. Then ask the same question of the architecture
   as a whole: does it, as designed or as already built, support what that doc commits to later,
   or is rework needed before that phase starts? Record required rework as forward STEPs or risks.
5. **Decision coverage.** Are the significant, contested, or deferred decisions recorded as
   **ADRs**? Write any that are missing (`templates/adr-template.md`). A decision made *during*
   this review is contemporaneous — it gets an ordinary ADR like any other. **What you must not
   do is reconstruct history:** where a choice was made before the project kept ADRs and nobody
   available knows why, record what was chosen in the architecture doc and leave it there. An
   ADR is a dated record of *why*, and a guessed rationale is worse than no ADR at all.
6. **Index accuracy.** Does `prompts/STEP-index.md` match what actually got produced
   (statuses, output docs)? And does `architecture/README.md`'s index list every
   architecture doc that exists (number, title, version, status)?

## Output
- A **review summary** — write it to the STEP-1 folder
  (`Upcoming Prompts/{{PROJECT}}-STEP-1-REVIEW.md`): what was checked, findings, fixes
  applied, any `registries/risks.yml` rows filed, the disposition of every discovered
  conditional-session template, and any decisions still needed from the user.
- **Apply the fixes** to the affected architecture docs (bump their Version Logs); write any
  missing ADRs and add them to the `adr/README.md` registry.
- **Populate `architecture/README.md`'s index** — one row per architecture doc produced
  (number, title, current version, status). This is the first time every doc exists in one
  place, so it's where the index gets filled in.
- A consolidated **Open Questions** list carried forward into the first implementation STEP.
- Update `prompts/STEP-index.md`: mark substep 1.14 `Done` and mark the STEP-1 row `Done`
  once the review is clean. STEP-1 is now ready to be archived: take the phase-folder name from
  the `## Phase 1 — <name>` heading in `prompts/STEP-index.md` (kebab-case the name — e.g. `MVP`
  → `mvp`, `POC` → `poc`), create the Phase-1 folder `prompts/001-<phase-name>/` with a
  `README.md` from `templates/phase-readme-template.md` (this is its first STEP, so the folder
  doesn't exist yet), then move the STEP-1 files into `prompts/001-<phase-name>/step-0001/` —
  all per `prompts/README.md`.

## Next
Once the review is clean, the architecture STEP is done — mark the STEP-1 row `Done` and archive
it to the Phase-1 folder `prompts/001-<phase-name>/step-0001/` (created from the `## Phase 1 — <name>`
index heading — see the Output section and `prompts/README.md`). The next action is to move into
building: **start a fresh chat** and run the **implementation planning session**
(`templates/planning-session.md`, *"Run planning session: Phase-1 implementation roadmap"*) — it outlines the Phase-1
implementation STEPs. See the next-action resolver (`METHOD.md` §10).

**If you were sent here to run this session, begin now — in this same reply.** "STEP-1.14" or
"session 1.14", with or without a leading "Run" and with or without ": Cross-Cutting Review",
is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't
recap this file, don't ask whether to start. Read root `.throughstone/local-user.md`, all the
STEP-1 architecture docs and ADRs, every `conditional-*.md` template, the STEP-1 PLAN, and
`prompts/STEP-index.md` silently. If the profile is missing, ask the two local-profile
questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, then continue. Run the
conditional-session gate before the rest of the review. Then, in this one reply: **(1)** tell
the user — in the one or two sentences from **What this session does** above — what you're
about to do, calibrated to the local profile; then **(2)** report the gate result and your
first findings (issues by severity, anything needing the user's decision). That orientation
plus the first findings is your first reply. **If you were not sent here to run it — you are
reading this file to harvest its decisions from existing code, to check whether a conditional
applies, or to review coverage — this paragraph is not addressed to you.** Use the file as
reference material and follow whatever sent you here.
