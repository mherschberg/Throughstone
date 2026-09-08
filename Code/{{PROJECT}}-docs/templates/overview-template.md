# {{PROJECT}} — Project Overview

<!-- PROJECT-STATUS: not-started -->
<!-- ^ Kickoff gate (do not delete this line). `init.sh` seeds it as "not-started". The agent
     flips it to "kickoff-complete" at the end of the bootstrap (BOOTSTRAP-PROMPT.md). While it
     reads "not-started", opening this project in an AI agent starts the kickoff interview
     automatically; once "kickoff-complete", agents resume from prompts/STEP-index.md instead. -->

<!-- NEXT-CHECK-IN: STEP-20 -->
<!-- ^ When the next Check-in STEP is due: a STEP number (STEP-45) or a date (2026-11-15).
     Whoever schedules a check-in writes it here, and each check-in sets the next one before it
     closes. `status.sh` reports it as due once it is reached, and keeps saying so until you move
     it. Move it whenever you like — it is a plan, not a rule. See METHOD.md §5. -->

> This is the template for your project brief. `init.sh` creates
> `Code/{{PROJECT}}-docs/overview.md` from it — **open that copy and fill it in** (1–2
> pages). It's the seed your agent uses to kick off the project. You don't need every
> answer — the architecture sessions draw the rest out of you. Write what you know; leave a
> `?` where you're unsure.
>
> **Already have design material** — a product spec, prior architecture or protocol docs, UI
> designs? Put the actual documents in `inputs/` (see `inputs/README.md`); the sessions read
> from there too, so you don't need to restate them here.

## In one sentence
<!-- What is this, for whom? e.g. "A scheduling assistant that negotiates meeting times
     between busy professionals on their behalf." -->

## The problem
<!-- What problem does this solve? Who has it today, and how do they cope without you?
     Why is now the time to build it? -->

## Who it's for
<!-- Primary users (1–3 personas). Anyone else affected: admins, operators, compliance,
     your customers' customers. -->

## What it does (core capabilities)
<!-- The must-haves for a first usable version. Bullet list. Keep it to the essentials. -->
-
-
-

## What it does NOT do (for now)
<!-- Deliberately out of scope. Helps avoid scope creep. Split "not yet" vs "never". -->
-
-

## Scale & shape
<!-- Roughly how many users / requests / records at launch? In a year? Is it a web app,
     a mobile/desktop app, an API/service, a CLI, or several? Who hosts it? -->

## Release stage / launch target
<!-- Optional. How widely and to whom this first release ships — pre-launch / internal
     alpha / closed (invite-only) beta / public beta / GA. An engineering calibration input
     (how much robustness and polish the architecture owes its audience), not a marketing
     plan, and distinct from the Phase-1 milestone's scope name. A short prose descriptor:
     e.g. "internal alpha", "closed beta — ~50 invited users", "public GA". Leave blank if
     you're unsure — most new builds start pre-launch. -->

## Constraints & must-haves
<!-- Regulatory or compliance needs, budget, timeline, team size & skills, languages or
     platforms you're committed to, systems you must integrate with or can't change. -->

## Sensitive data & risk
<!-- Does it handle anything sensitive (personal data, payments, credentials, health)?
     Anything that absolutely must not fail or leak? (It's fine to say "nothing special.") -->

## Known unknowns
<!-- The questions you don't yet have answers to. These become things the sessions explore. -->
-
-

## Anything else
<!-- Prior art, inspirations, a rough sketch, links, a competitor you're reacting to.
     Have actual documents — specs, prior architecture/protocol docs, UI designs? Put them
     in `inputs/` rather than pasting them here (see `inputs/README.md`). -->
