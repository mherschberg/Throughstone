# Runbook — Secrets Rotation

> **How to run:** This is an **operational procedure, not a STEP** (like the release runbook),
> with two modes:
> - **Scheduled rotation** → run the checklist (**Part 1**) on a cadence: it rides naturally on
>   the **check-in** (`runbooks/check-in.md`, every ~10–20 STEPs), and on each secret's own
>   expiry/rotation interval. Tell your agent *"rotate the secrets."*
> - **Suspected leak / exposure** → an exposed credential is an emergency: run **Part 2** *now*.
>   Tell your agent *"we may have leaked a secret"* (or *"rotate this credential"*).
>
> **Optional and yours to customize.** Like the release and dependency runbooks, this leaves the
> specific tooling to your stack (Vault, AWS/GCP Secrets Manager, Doppler, SOPS, `age`,
> cloud-native KMS, your CI's secret store…). The *discipline* below — know what you hold, rotate
> on a cadence with no downtime, revoke first on exposure — is the durable part; fill in your
> project's actual commands and stores. It operationalizes the **secrets & data protection**
> posture set in `architecture/*-security-threat-model.md`.

## Why this runbook exists
Secrets are time-bombs: every API key, TLS cert, signing key, and database credential is a
live grant that someone, someday, will copy into a log, paste into a ticket, bake into an
image, or leave in a repo. Long-lived, never-rotated credentials are one of the most common
ways a small mistake becomes a breach — the exposure and the discovery can be months apart, and
a key that never changes is a key that's still valid years after it leaked. Rotation is the
discipline that bounds that blast radius: it makes "this secret might be compromised" a routine,
low-drama operation instead of a crisis, and it proves you can actually replace a credential
*before* the day you must.

## Part 1 — Scheduled rotation (on a cadence)
- [ ] **Know what you hold.** Keep an inventory of the project's secrets — what each is, **who
      owns it**, where it lives, and its rotation interval. Secrets live in a real secrets
      manager, **never in code or the repo** (the threat model's §5 rule; local dev uses a
      gitignored `.env` / `.secrets/`, committing only `.env.example`). You can't rotate what you
      can't list.
- [ ] **Set a cadence per secret class.** Rotate on an interval matched to risk — short-lived
      tokens often (or make them auto-expiring), long-lived API keys and DB credentials on a
      defined schedule, certificates before expiry. Prefer mechanisms that **rotate themselves**
      (short-TTL/dynamic credentials, auto-renewed certs) over a calendar reminder a human owns.
- [ ] **Rotate with no downtime — overlap, don't cut over.** The safe shape is **two valid
      secrets at once**: issue the new one, deploy it to every consumer, verify everything works
      on the new value, *then* revoke the old. A hard swap — kill the old key before the new one
      is everywhere — is a self-inflicted outage. (Same expand/contract instinct as a reversible
      migration in `release-deploy.md`.)
- [ ] **Update every consumer, in every environment.** Find *all* the places that hold the
      secret — services, CI/CD, infra-as-code, backups, partner integrations — and update them
      per environment (`architecture/*-environments.md`). A missed consumer is exactly what
      breaks at revoke time.
- [ ] **Verify, then revoke the old.** Confirm the critical paths work on the new secret, then
      **revoke/delete the old value** so a leaked copy is now worthless. A rotation that leaves
      the old key valid hasn't actually reduced risk.
- [ ] **Update the docs/inventory.** Record what was rotated and when, and bump any expiry the
      inventory tracks — so the next rotation (and the next check-in) starts from the truth.

## Part 2 — Suspected leak or exposure  *(emergency — do this now)*
A secret in a log, a screenshot, a public repo, a former contributor's laptop, or a breached
third party is **assumed compromised** — treat possible exposure as exposure.
1. **Revoke first.** Invalidate the exposed credential *before* you investigate — the opposite
   order from a scheduled rotation. A still-valid leaked key is an open door; close it, then ask
   how it got open. If revoking outright would cause an outage, issue the replacement and cut
   consumers over as fast as Part 1 allows, but treat the old one as burning.
2. **Rotate the replacement** through the Part 1 steps (issue → distribute → verify), then ensure
   the compromised value is fully dead everywhere.
3. **Assess the blast radius.** What could the holder of that secret reach, and for how long was
   it exposed? Check access logs for use you didn't make. If the secret guards anything sensitive
   or there's any sign of misuse, **this is an incident** → switch to
   `runbooks/incident-postmortem.md` (Part 1 to stabilize; the RCA → find-similar → fix STEP to
   make sure the *class* of leak — e.g. secrets in logs — can't recur).
4. **Purge the source.** Scrub the exposure where you can (rotate, don't just delete: a secret
   committed to git history or shipped in an image is already harvested — assume it's public and
   rely on the revoke, not the deletion).

## Output / record
Most of this is action, not documents — but leave a trail:
- **Rotation log** — what was rotated and when — in the inventory and noted for the next
  **check-in** (`runbooks/check-in.md`).
- **A leak becomes an incident record** via `runbooks/incident-postmortem.md`, with a
  *find-similar* pass for the same exposure class elsewhere.
- **Standing policies as ADRs** — e.g. "rotate production credentials every N days," "no
  long-lived keys where dynamic credentials are available," "secrets only from the manager" — so
  the rule outlives the person who set it.
