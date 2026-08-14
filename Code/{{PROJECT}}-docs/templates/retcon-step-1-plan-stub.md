# {{PROJECT}} — STEP-1 PLAN: Retcon baseline (reverse-engineered architecture)

**Phase:** Phase 1 — (forward milestone; named at Phasing/1.2, near the end of adoption)
**Owner:** {{who is running this — retcon is single-owner / one-machine}}   <!-- solo: optional -->
**Status:** In progress        <!-- adoption is underway the moment you open the agent; the STEP-1
                                    row in prompts/STEP-index.md stays Planned (the greenfield-identical
                                    seed) until landing — that's expected, don't "fix" it: status.sh's
                                    retcon branch routes here and ignores the index during adoption. -->
**Date:** {{DATE}}
**Branch:** `step-0001-architecture`   <!-- same name in every repo this STEP touches -->
**Repos (projection):** `{{PROJECT}}-docs`, `prompts`   <!-- STEP-1 is docs-only; adopted code repos are registered in place, not rebuilt -->

> **This is a STUB that `init.sh` dropped.** It is the in-flight STEP-1 PLAN for adopting an
> existing codebase into {{PROJECT}} (**retcon**). Its substeps are the **inventory work** only.
> Once the inventory is confirmed, `RETCON-PROMPT.md` **upgrades this PLAN by addition** (see the
> marker further down) — it never rewrites what is above. A single PLAN-driven resolver runs
> throughout: resolve the lowest open substep below.

## The retcon baseline (what STEP-1 produces here)
This STEP-1 is the **reverse-engineered architecture baseline** — *descriptive* (read from the
running code), not *prescriptive* (decided, then built). The running code is the source of truth;
existing docs, memory, and original intent are secondary evidence that may be stale or wrong.

When adoption lands (after the Cross-Cutting Review), STEP-1 becomes an ordinary **`Done`** row in
`prompts/STEP-index.md` marked **RETCON**, with the scope *"Retcon baseline — reverse-engineered
from existing code; adopted {{DATE}}; forward work starts at STEP-2."* It archives greenfield-style
into `prompts/001-<milestone>/step-0001/` (the folder name converges with greenfield), and a
one-line provenance note goes in `overview.md` (*"Adopted via retcon on {{DATE}}"*).
To the resolver it is an ordinary architecture baseline needing no new logic: forward
implementation starts at **STEP-2**, and the first forward planning session inserts a **baseline
check-in** as STEP-2 — the full test suite this docs-only STEP-1 deliberately skips.

## Motivation
Bring an existing system under {{PROJECT}} so the team works the STEP method **from here on**,
without rebuilding. The deliverables are a set of {{PROJECT}}-shaped architecture docs describing
what already exists, plus the STEP process (index, registries) stood up so the next unit of work is
ordinary {{PROJECT}}. The value is a clean go-forward baseline plus the gaps/drift surfaced along
the way — not a pretty description a mature team already knows.

## Decisions already locked
- root `.throughstone/local-user.md` — read **Experience level** before user-facing questions or
  explanations, and **Communication style** before planning discussions; keep that file as the
  personal local source of truth for both values.
- **Reality is the code.** The baseline documents what the code *is*. Any divergence
  (code-internal, or code-vs-goal) is recorded as reality **plus** flagged drift/debt, settled by
  re-reading the code — not re-decided, not blanket-logged.
- **No fabricated history, no reconstructed ADRs.** Everything before adoption is prehistory: we do
  not reconstruct a STEP log or dated decision records for choices made long ago. A *forward*
  decision made **during** adoption is contemporaneous and may be a normal ADR.
- **Do it right or defer it openly.** Every area is either fully harvested (yielding a doc as thin
  or as detailed as the reality it describes) or explicitly `Coverage: deferred` with a plain
  "what's missing and why it matters" warning — never shallow-but-asserted.
- Found source docs land in `inputs/` and ride the base inputs lifecycle (point-in-time;
  `inputs/inputs-index.md` tracks what still holds vs. what observed reality has superseded).

## Substeps — the inventory work
> Free-form inventory units (not the `1.1`–`1.14` session mirror, and not parsed by `status.sh` —
> real progress lives here in the PLAN). Resolve the **lowest open** one. `RETCON-PROMPT.md` drives
> each; see it for the detail.

| # | Title | Produces | Status |
|---|-------|----------|--------|
| inv-1 | Intake | Depth dial set; rough repo/doc/resource locations, the project's lifecycle stage, and any house version convention recorded (RETCON-PROMPT.md Stage 1). | Planned |
| inv-2 | Scan & inventory | A list of every repo, doc, and resource (data stores, services, integrations, CI, deploy surfaces); each existing doc classified with a trust level. | Planned |
| inv-3 | Recon-map skeleton | A draft `reports/<date>-step-0001-recon-map.md` — inventory, stack per repo, entry points/services, data stores, integrations, existing-docs classification, test/CI presence, confidence/unknowns, and a **Coverage & Confidence** section. | Planned |
| inv-4 | Confirm the inventory ▸ checkpoint | The **user-corrected** recon map — the birth-certificate checkpoint, before anything is built on it. | Planned |
| inv-5 | Upgrade this PLAN | Mark inv-1–inv-5 `Done` (this row included); **append** (never rewrite) the per-asset substeps (`asset-N` id + Status) + the in-scope `1.1`–`1.14` sessions + the `Conditional sessions considered` table; seed `registries/risks.yml` from the confirmed map's unknowns/coverage. | Planned |

### Intake results (inv-1)
<!-- WHAT THIS IS. The record of the four framing answers RETCON-PROMPT.md's Stage 1 (Intake)
     collects before any scanning. Stage 1 fills these in place (replacing the {{placeholders}});
     Stage 2 reads them — the locations tell it where to scan, the version convention tells it how to
     stamp each doc's Version, and the depth posture is its default when it meets a fat payload.

     Leave the placeholders until inv-1 runs. Two of the four are ALSO written to their permanent
     homes — release stage to overview.md, the depth posture to the recon map's Coverage & Confidence
     section — but they are echoed here so Stage 2 reads one working note instead of three files. This
     block is the only free-text the agent adds above the marker; everything else above is init.sh's
     seed, and the upgrade (inv-5) only appends below the marker. -->
- **Locations:** {{repos / docs / resources — rough paths, URLs, hosts; and who can answer questions
  about each}}
- **Lifecycle / release stage:** {{pre-launch / shipped / mature — a short prose descriptor, e.g.
  "public GA" or "internal alpha, ~20 users"; also written to `overview.md`}}
- **House version convention:** {{the scheme docs should respect — calendar / product-line / semantic
  / none; note per-repo if the repos differ}}
- **Depth-dial posture:** {{the default for how hard to push fat payloads — Full (enumerate & confirm
  everything) or economical when payloads are enormous; refined per fat payload in Stage 2/3, with the
  human escalation as the real control}}

<!-- ═══════════════════════════════════════════════════════════════════════════════
     Everything ABOVE is the seed init.sh dropped. Once the inventory is CONFIRMED
     (substep inv-4), RETCON-PROMPT.md UPGRADES this PLAN BY ADDITION — it does not rewrite
     the above (the only in-place fill-ins there are Stage 1's Intake-results values and
     flipping a substep's Status to Done). It marks inv-1–inv-5 Done and APPENDS, below this line:
       • the per-asset substeps — one row per repo/doc-set/resource in their own
         `# | Asset | Kind | Status` table (`asset-N` ids; same Status tracking as the inv-N
         table above), each documenting one asset so nothing is lost (a repo is not a 1.N
         session); resolve the lowest-open `asset-N` before 1.1;
       • the in-scope architecture sessions 1.1–1.14 (1.1–1.13 harvest→confirm; 1.14 is the
         Cross-Cutting Review + land, not a harvest);
       • the `Conditional sessions considered` table — seeded from code-visible surfaces
         (client surfaces, PII, auth) and refined as sessions harvest, exactly as
         greenfield seeds-then-refines it;
       • `registries/risks.yml` rows seeded from the confirmed map's Confidence & Unknowns /
         Coverage & Confidence (genuinely-risky items only; STEP-index stays at its seed).
     That upgraded PLAN — at this same path, Upcoming Prompts/{{PROJECT}}-STEP-1-PLAN.md —
     is the STEP-1 PLAN the Cross-Cutting Review's Check 1 and every future check-in read.
     See RETCON-PROMPT.md.
     ═══════════════════════════════════════════════════════════════════════════════ -->

## Ground rules
- **Calibrate communication from root `.throughstone/local-user.md`.** If it's missing, ask the two
  local-profile questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, and continue. Don't copy
  either value into this PLAN.
- **STEP-1 is docs-only — no application code.** Retcon may create Markdown and scaffolding
  (a Throughstone-shaped README per adopted repo, `registries/` rows, `architecture/` docs), but never
  rewrites the user's codebase. It adopts the existing one.
- **Detect-then-confirm.** Propose an inventory; let the user correct it. Existing repos are
  registered **in place** by their real `location` (not relocated).
- **Confirm every decision** proportionate to confidence × consequence — a `from-code` answer gets
  a fast "right?"; a low-confidence, load-bearing one gets a real discussion.
- **Accepted risks / deferrals stay visible.** Push unknowns and `Coverage: deferred` areas to
  `registries/risks.yml` with a revisit trigger; the check-in re-surfaces them.

## Definition of done (inventory phase)
- [ ] inv-1–inv-4 complete: intake recorded, everything inventoried, the recon map drafted and
      **confirmed by the user**.
- [ ] inv-5 complete: this PLAN upgraded by addition — per-asset substeps (`asset-N` id + Status) + the
      in-scope 1.1–1.14 sessions + the `Conditional sessions considered` table appended; inv-1–inv-5
      marked `Done`; `registries/risks.yml` seeded from the confirmed map (STEP-index untouched).
- [ ] Next action is the lowest open **appended** substep (the per-session harvest→confirm wrapper).
      The overall STEP-1 baseline lands later, after the Cross-Cutting Review (see the retcon
      baseline note above).
