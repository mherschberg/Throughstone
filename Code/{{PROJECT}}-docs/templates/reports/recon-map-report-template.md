# {{PROJECT}} — STEP-0001 Recon Map

**Date:** {{YYYY-MM-DD}}
**Report path:** `reports/{{YYYY-MM-DD}}-step-0001-recon-map.md`
**STEP:** STEP-1 — retcon baseline (reverse-engineered architecture)
**Status:** {{Draft → Confirmed on YYYY-MM-DD}}   <!-- Draft while the agent fills it in; on the
                                         user's sign-off, set "Confirmed on <date>" — the dated
                                         birth-certificate checkpoint. -->
**Depth dial:** {{how hard fat payloads are pushed this run — e.g. "enumerate fully" or
                 "enumerate entities to depth N, defer the rest" — set at intake, §Coverage below}}
**Reviewed commit(s):** {{repo@sha list — the exact state this map describes}}
**Runbook:** `RETCON-PROMPT.md`

<!-- This is the recon map: the point-in-time "birth certificate" of an existing system as it was
     found at adoption. It is retcon's STEP-1 discovery artifact — essentially a check-in run against
     empty docs — so it lives here as a report, not as a living architecture doc.

     TWO RULES:
     1. The USER CORRECTS IT before anything is built on it (Status: Draft → Confirmed). Detect,
        then confirm — propose the inventory and let the user fix it. Editing is expected here, and
        ONLY here: while it is Draft.
     2. ONCE CONFIRMED IT IS FROZEN — never rewritten (confirmation seals it, and stamps the date).
        Later reality-drift is the living docs' job (architecture/, registries/), not an edit to this
        snapshot.

     WHAT IT FEEDS (it is a seed, not a living artifact): the confirmed map seeds `registries/repos.yml`
     (one row per repo), the thin `architecture/` docs the sessions harvest, and — from Confidence &
     Unknowns below — `registries/risks.yml`. Session harvests read the CONFIRMED map (plus the
     per-asset docs), never each other's sheets, which is what lets them run independently.

     Fill every section from the running code (the source of truth); existing docs, memory, and
     original intent are secondary evidence that may be stale. Where a section does not apply, keep
     the heading and write "None found" — an explicit empty is a finding, a missing section is a gap. -->

## Inventory

Every repo, doc, and resource discovered — the breadth pass. One row per asset.

| Asset | Kind | Location | Notes |
|-------|------|----------|-------|
| {{name}} | {{repo / doc / data store / service / integration / CI / deploy surface / other}} | {{path / URL / host}} | {{one line — role, ownership, anything notable}} |

## Stack Per Repo

| Repo | Languages | Frameworks / runtimes | Build / package manager | Notes |
|------|-----------|-----------------------|-------------------------|-------|
| {{repo}} | {{langs}} | {{frameworks, runtime versions}} | {{tool}} | {{monorepo? generated code? notable pins}} |

## Entry Points & Services

Runnable surfaces: HTTP/RPC services, background workers/jobs, scheduled tasks, CLIs, functions.

| Surface | Repo | Kind | How it runs | Notes |
|---------|------|------|-------------|-------|
| {{name}} | {{repo}} | {{service / worker / cron / CLI / function}} | {{entry command / trigger}} | {{ports, public/internal, framework}} |

## Data Stores

Databases, caches, queues, object stores, search indexes — anything that holds state.

| Store | Kind | Owner (repo/service) | Notes |
|-------|------|----------------------|-------|
| {{name}} | {{relational / document / cache / queue / blob / search}} | {{who reads/writes}} | {{engine + version, schema location, migrations}} |

## Integrations

External and third-party services this system depends on or is called by.

| Integration | Direction | Purpose | Notes |
|-------------|-----------|---------|-------|
| {{name}} | {{outbound / inbound / both}} | {{what it's used for}} | {{auth style, SDK/API, criticality}} |

## Existing Docs — Classification & Trust

Every found doc: what it is, how far to trust it against the code, and its disposition. Found
source docs land in `inputs/` and ride the base inputs lifecycle (point-in-time; the code wins on
any conflict — see `inputs/inputs-index.md`).

| Doc | Classification | Trust | Disposition |
|-----|----------------|-------|-------------|
| {{path / title}} | {{architecture / API spec / ADR-shaped / runbook / design note / other}} | {{high / medium / low / stale}} | {{ingest / point-at / summarize / flag stale — superseded by observed reality}} |

## Tests & CI

Presence and shape of the safety net per repo — not a quality verdict, just what exists.

| Repo | Test suites | CI | Deploy surface | Notes |
|------|-------------|----|----------------|-------|
| {{repo}} | {{frameworks, rough coverage if visible / none found}} | {{provider + config path / none}} | {{how it ships / none}} | {{gaps worth flagging}} |

## Confidence & Unknowns

What is still uncertain after the breadth pass — open questions, low-confidence reads, and areas
not yet opened. Genuinely-risky unknowns are pushed to `registries/risks.yml` with a revisit
trigger; the check-in re-surfaces them.

| Unknown / low-confidence area | Why it matters | Confidence | Next move |
|-------------------------------|----------------|------------|-----------|
| {{area}} | {{what leans on it}} | {{low / medium}} | {{harvest in session N / risks.yml row / ask user}} |

## Coverage & Confidence

The frozen, dated record of how thoroughly this run read the system — the run-level "skimmed ≠
covered" ledger (the first of three altitudes; the others are `registries/risks.yml` and each
doc's `Coverage` / `Status`). Never asserted-but-shallow: an area is either read or listed here as
deferred, with a plain "what's missing and why it matters."

- **Depth-dial setting:** {{the fat-payload depth chosen at intake, and why}}
- **Deferred fat-payload areas:** {{each area enumerated only to a stated depth — what's covered, what's
  left, and why it matters until backfilled; "None" if the run enumerated everything}}
- **Aggregate confidence:** {{overall read — high where the code is clear, called out where it isn't}}

## Summary

{{A few sentences: what this system is, the shape of the inventory (N repos, key services/stores),
the biggest unknowns, and the state of this map (drafted / confirmed by the user on {{date}}).
This is the baseline the harvest sessions build on.}}
