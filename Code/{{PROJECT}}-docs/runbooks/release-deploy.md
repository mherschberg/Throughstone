# Runbook — Release, Deploy & Rollback

> **How to run:** This is an **operational procedure, not a STEP** (unlike the check-in). Run
> it whenever you ship a version to an environment — tell your agent *"run the release"* (or
> *"deploy the release"* / *"roll back the last release"*) and it follows this file.
>
> **Optional and yours to customize.** The method deliberately leaves CI/CD and release
> versioning to your team's existing tooling (see `collaboration.md`, *"Standard practice, not
> the method's job"*). This runbook is a **default checklist** for when you don't have a
> release process yet — and a home to write yours down when you do. Fill in your project's
> actual commands and environments; the *discipline* below — a rollback plan **before** you
> deploy, reversible migrations, a watch window — is the part worth keeping whatever your
> pipeline. The mechanism it executes was designed in the Infrastructure & Deployment
> architecture doc (`architecture/*-infrastructure-deployment.md`, deploy pipeline + rollback)
> and
> the Environments architecture doc (`architecture/*-environments.md`); point at those for the
> specifics.

## Why this runbook exists
A deploy is the riskiest routine thing a project does — it's where a green test suite still
meets production reality. The failure mode usually isn't the deploy itself; it's having **no
planned way back** when something goes wrong, so a five-minute blip becomes an outage while
someone improvises a fix under pressure. This runbook makes a release boring: decide how you'd
undo it *before* you do it, ship to a safe place first, watch, and have one clear lever to pull
if it goes bad.

## Part 1 — Before you deploy (pre-flight)
- [ ] **The change is merged and reviewed**, and the **full test suite is green** — not just the
      area you touched.
- [ ] **Version stamped.** Tag / bump the version per your scheme so what's running is identifiable.
- [ ] **Release notes drafted.** At a milestone or any release the method asks you whether to
      write them (`METHOD.md` §5, *Milestone doc review*) — if yes, draft them from
      `templates/release-notes.md` while the changes are fresh.
- [ ] **Migrations are safe to undo.** If this release changes the database schema, confirm the
      migration is **reversible or forward-compatible** (prefer expand/contract: add the new
      shape, deploy, backfill, switch, drop the old in a *later* release). A deploy you can roll
      back sitting on a schema you can't is a trap — write down the down-path explicitly.
- [ ] **Config & secrets for the target environment are in place** — from the secrets manager,
      not a checked-in file (see the Security & Threat Model architecture doc,
      `architecture/*-security-threat-model.md`, and the Infrastructure & Deployment architecture doc,
      `architecture/*-infrastructure-deployment.md`). Rotating a
      credential rather than just consuming one? That's its own procedure —
      `runbooks/secrets-rotation.md`.
- [ ] **Rollback plan confirmed.** Write down, now, exactly how you'd undo this release (Part 4)
      and what would make you do it. If you can't state it, you're not ready to deploy.

## Part 2 — Deploy
- [ ] **Ship to staging / pre-prod first** (per `architecture/*-environments.md`) and **smoke-test**
      the critical paths there before production. Skip only if the project has no such
      environment — and say so.
- [ ] **Deploy to production** via the deploy pipeline from the Infrastructure & Deployment
      architecture doc (`architecture/*-infrastructure-deployment.md`). Where the runtime
      infrastructure supports it, prefer a strategy that makes rollback cheap (blue-green /
      rolling / canary / feature-flagged).
- [ ] **Record it** — what version went out, to which environment, when, and by whom. It's the
      start of an audit trail the next check-in and any incident review will want.

## Part 3 — Verify (don't walk away)
- [ ] **Smoke-test the critical user paths** in production.
- [ ] **Watch production signals** from the Observability architecture doc
      (`architecture/*-observability.md`) for a defined window — error rates, latency, and the
      alerts you set up — before calling it done. A deploy isn't "done" at deploy; it's done
      once it's stayed healthy for a bit.
- [ ] **Health / uptime checks green.**

## Part 4 — Rollback (when verify fails)
- **Trigger.** Roll back when a pre-defined criterion hits — a failed smoke test, an error/latency
  spike, a breached SLO. Decide *fast*: rolling back and investigating later beats debugging in
  production while users are affected.
- **Mechanism.** Execute the down-path you wrote in Part 1 — redeploy the previous version,
  switch the blue-green pointer, turn the feature flag off, or revert and redeploy.
- **The migration caveat (the dangerous case).** If the release ran an *irreversible* schema or
  data migration, rolling back the code isn't enough and may corrupt data. Here a **forward fix**
  (roll forward with a patch) is often safer than a rollback — decide deliberately. This is
  exactly why Part 1 insists migrations be reversible or forward-compatible.
- **After a rollback.** A rollback means something broke in production — that's an **incident**.
  Capture what happened — symptom, trigger, what you did — and hand off to
  `runbooks/incident-postmortem.md`, which turns it into a tracked STEP (RCA → find similar →
  fix) so the real fix can't evaporate once service is restored.

## After the release
- Confirm the released version is **tagged / recorded**.
- **Prompt the user about release notes and user-facing docs** if not already done. If the user
  wants release notes, use `templates/release-notes.md`; neither release notes nor user-facing
  docs are produced by normal STEP work (`METHOD.md` §5, *Milestone doc review*).
- Note anything that should feed the next **check-in** (`runbooks/check-in.md`).
