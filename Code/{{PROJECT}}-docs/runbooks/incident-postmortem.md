# Runbook — Incident Response & Postmortem

> **How to run:** Two modes, run in sequence.
> - **An incident is happening right now** → this is an **operational procedure**: tell your
>   agent *"run the incident runbook"* and follow **Part 1** to stabilize and capture the facts.
> - **Then the durable follow-up is a STEP** (like the check-in): Part 1 ends by reserving an
>   **Incident STEP** whose three substeps — RCA, find-similar, fix — *are* **Parts 2–4 below**.
>   Its PLAN is thin and points here; you don't author substep prompts for it (the same special
>   case as the check-in STEP — see `prompts/README.md`). Record the substeps' status in the
>   index/PLAN like any other STEP.
>
> An "incident" is any unplanned production failure or near-miss worth not repeating — an
> outage, data loss/corruption, a security event, a bad deploy. Small ones get a light touch;
> the structure scales down.

## Why this runbook exists
When something breaks in production, two different jobs get confused under pressure and one
always loses. The first is **stop the bleeding** — restore service now. The second is **make
sure it can't happen again** — and *that's* the one that quietly gets skipped once the fire's
out and everyone's relieved. This runbook separates them: Part 1 handles the emergency; Parts
2–4 become a tracked STEP so the real fix can't evaporate. It is **blameless** — the goal is
the cause in the *system*, never who typed the command.

## Part 1 — Respond & capture  *(operational — do this now)*
1. **Stabilize first.** Restore service before you investigate — most often by rolling back the
   last release (`runbooks/release-deploy.md`, Part 4), failing over, or disabling the bad path
   (a feature flag). Mitigation beats diagnosis while users are affected.
2. **Confirm recovery.** Verify the critical paths work again and the alerts that fired have
   cleared (`architecture/10-observability.md`).
3. **Capture the facts while fresh** — a rough **timeline** (when it started, when it was
   noticed, what you did, when it resolved), the **symptom and blast radius** (who/what was
   affected, any data touched), and the alerts/logs that caught it (or *should* have). Don't
   diagnose yet — just record. This is the raw material for the RCA.
4. **Open the Incident STEP.** Reserve a STEP number and branch per the recipe
   (`prompts/README.md`); its substeps are Parts 2–4. Park the captured timeline in the STEP
   folder. Then hand off to that STEP — the emergency is over; the rest is deliberate work.

> **Security incidents** that exposed data or credentials also start a **breach-notification**
> clock from your privacy/security work (`architecture/06-security-threat-model.md`, and the
> privacy-compliance doc if you have one). That obligation is not optional and runs independently
> of this runbook — handle it in parallel with Part 1.

## Part 2 — Root-cause analysis (RCA)  *(substep N.1)*
Get past the symptom to the **cause in the system**. Ask *why* repeatedly (5 Whys) until you
reach something you can actually change — usually not "the code had a bug" but the missing test,
the missing guardrail, the missing alert, or the design assumption that didn't hold. Name the
**contributing factors**, not a single culprit. Write a short **postmortem** into the Incident
STEP folder: the timeline (from Part 1), the root cause, contributing factors, and what made it
easier or harder to detect and recover. If the RCA overturns a recorded decision, write an
**ADR** (`templates/adr.md`); if it shows a doc was wrong, that's a fix for Part 4.

## Part 3 — Find similar issues  *(substep N.2)*
The bug you saw is an *instance of a class*. Before fixing, **hunt the class**: search the
codebase for the same pattern elsewhere — the same unchecked input, the same missing timeout,
the same migration shape, the same assumption — across **all repos**, not just the file that
broke. List every sibling you find. This is the step that turns one fix into "this whole
category can't bite us again," and it's the one most often skipped. Record what you searched for
and what you found — including "searched X, found none," which is a real result, not a blank.

## Part 4 — Fix & harden  *(substep N.3)*
Fix the root cause **and** every sibling found in Part 3, in this STEP. Then close the loop so
the *next* one is caught sooner and cheaper:
- **A regression test** that fails on the original bug and passes after the fix.
- **Detection** — if nothing alerted (or it alerted too late), add or tune the signal
  (`architecture/10-observability.md`) so this class trips an alarm next time.
- **Docs / runbooks** — fix any doc the RCA found wrong (bump its Version Log); if the response
  itself was clumsy, improve the relevant runbook so the next responder has it easier.
- Anything too large to fix safely here becomes its own **follow-up STEP**, listed for the index.

## Output
- A **postmortem** in the Incident STEP folder: timeline, root cause, contributing factors, the
  similar issues found (Part 3), and the fixes/hardening applied (Part 4).
- Any **ADRs** for decisions the RCA changed; any **doc fixes** (Version Logs bumped); any
  **follow-up STEPs** filed in `prompts/STEP-index.md`.
- Mark the Incident STEP's substeps and the STEP **Done**; note anything to watch at the next
  **check-in** (`runbooks/check-in.md`).
