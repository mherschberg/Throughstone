# Retcon Prompt — adopt an existing codebase

**You are routed here automatically.** When `PROJECT-STATUS: retcon`, `AGENTS.md` and `status.sh`
send a fresh agent here instead of the greenfield kickoff (`BOOTSTRAP-PROMPT.md`). This is the
retcon counterpart to that kickoff.

> Paths below are relative to the workspace root (the folder containing `Code/` and `prompts/`).

---

You are bringing an **existing, running system** under {{PROJECT}} — *adopting* it, not designing it
from scratch. The deliverable of this STEP-1 is a **reverse-engineered architecture baseline**: a set
of {{PROJECT}}-shaped docs that describe what already exists, plus the STEP process (index,
registries) stood up, so the next unit of work is ordinary {{PROJECT}}. You will not rewrite the
user's code — you will read it.

**Reality is the code.** The baseline documents what the code *is*. Existing docs, memory, and
original intent are secondary evidence that may be stale — settle every divergence by re-reading the
code, recording reality *plus* any drift/debt, never re-deciding. **No fabricated history, no
reconstructed ADRs** (a *forward* decision made during adoption may be a normal ADR).

## How this prompt works — one resolver

Retcon runs like greenfield: the next action is always derivable from disk. There is **one
PLAN-driven resolver** — this prompt — reading the in-flight **STEP-1 PLAN** at
`Upcoming Prompts/{{PROJECT}}-STEP-1-PLAN.md` (a stub `init.sh` seeded; its substeps are the
inventory work). **Resolve the lowest open substep** and do it — that is your next action, mid-inventory
included, in a fresh chat or a resumed one.

The substeps run in two stages:

- **Stage 1 — Intake** (`inv-1`) — below.
- **Stage 2 — Map + plan** (`inv-2`…`inv-5`) — scan and inventory, draft the recon map, the user
  confirms it, then upgrade this PLAN by addition (the per-asset substeps + the `1.1`–`1.14` sessions
  + the conditional table). *Instructions land with the next build increment; until then, Stage 1 is
  the resolvable work.*

When the baseline lands (after the Cross-Cutting Review), STEP-1 becomes an ordinary `Done` row marked
**RETCON**, `PROJECT-STATUS` flips to `kickoff-complete`, and from that instant this is ordinary
{{PROJECT}} — resume from `prompts/STEP-index.md` via `status.sh`.

## Read first
1. `Code/{{PROJECT}}-docs/METHOD.md` — the methodology (doc genres, sessions, naming). Internalize it.
2. `Code/{{PROJECT}}-docs/overview.md` — what the user says this system is.
3. `Upcoming Prompts/{{PROJECT}}-STEP-1-PLAN.md` — the in-flight PLAN you resolve; read its
   *Decisions already locked* and *Ground rules*.
4. `Code/{{PROJECT}}-docs/templates/reports/recon-map-report-template.md` — the artifact Stage 2 produces.

## Stage 0 — Calibrate  ▸ checkpoint

Calibrate every interaction to the active user's local profile in root `.throughstone/local-user.md`
(**Experience level**, **Communication style**; `METHOD.md` §4). If the file is missing, ask the two
local-profile questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, and continue. Retcon is
**single-owner / one-machine** — do not set up multi-contributor state.

## Stage 1 — Intake  (resolves `inv-1`)  ▸ checkpoint

A short, upfront conversation to frame the adoption. Recommend defaults; keep it brief — you inventory
precisely in Stage 2.

**1. Where things are.** Ask roughly where the repos, docs, and resources live (paths, URLs, hosts),
and who is available to answer questions about them. You only need the rough edges here.

**2. Lifecycle / release stage** → sets the **`Release stage / launch target`** line in `overview.md`.
Ask where the system is in its life: pre-launch, shipped (in production), or mature. Record a short
prose descriptor (e.g. "public GA", "internal alpha — ~20 users"). This is an **engineering
calibration** input — how much robustness and polish the architecture owes its audience — *not* the
doc `Status`, and *not* a marketing plan.

**3. House version convention** → sets **`Version`** on the baseline docs. Ask whether the project has
a version scheme to respect (calendar, product-line, semantic, or none). Record it, and apply it when
Stage 2/3 write docs.

**4. Depth dial.** Existing systems can be huge, so agree how thoroughly to read a **fat payload** — a
single decision that spans a large set: hundreds of data entities, dozens of services or endpoints, a
sprawling table or integration list. "Depth" is how completely you **enumerate and verify** such a
set — *not* which sessions run (**every core session runs regardless**; the dial never skips a
session). The two poles:

- **Full** — enumerate every item and confirm it. Right when the set is small enough, or load-bearing
  enough, to be worth reading end to end.
- **Bounded** — confirm the *completeness claim* ("these are all the entities"), the outliers and
  load-bearing items individually, and a stratified spot-check of the uncertain ones; enumerate to a
  stated depth and mark the rest `Coverage: deferred` with a plain "what's missing and why it matters."
  Never shallow-but-asserted.

You can't calibrate this precisely up front, and you don't need to: set a **default posture** here
(lean thorough, or be economical when payloads are enormous), then make the real depth call **per fat
payload** as you meet it in Stage 2/3 — a 30-table schema and a 2,000-table one get different answers
under the same posture. When a payload would blow the budget, **escalate — ask the user** to go deeper
or defer; that human check is the actual control, not a silent cap. Record the posture, and record
each concrete depth call in the recon map's Coverage & Confidence section.

> **Keep the three axes separate — do not cross-wire them.** Lifecycle → the `overview.md`
> release-stage line. House convention → **`Version`**. Doc **`Status`** is neither: it is set later,
> per doc, from how settled the harvested reality is (a confirmed as-built doc is typically
> **`Current`**, whether or not the product has shipped).

**Record + advance.** Write the release-stage descriptor into `overview.md`. Record the depth-dial
setting, the version convention, and the rough locations as a short **Intake results (`inv-1`)** note
in the PLAN, so Stage 2 reads them. Mark `inv-1` **Done** in the PLAN's substep table, then resolve
the next open substep. **Checkpoint:** play the intake back to the user before moving on.

## Stage 2 — Map + plan  (`inv-2`…`inv-5`)

*Forthcoming in the next build increment.* Scan and inventory every repo/doc/resource, classify each
existing doc with a trust level, draft the recon map from the template above, let the user confirm it
(the birth-certificate checkpoint), then upgrade this PLAN **by addition** — mark `inv-2`…`inv-5`
`Done` and append the per-asset substeps, the in-scope `1.1`–`1.14` sessions, and the `Conditional
sessions considered` table. Until it lands, resolve Stage 1.
