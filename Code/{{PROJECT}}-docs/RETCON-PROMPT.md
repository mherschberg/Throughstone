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
included, in a fresh chat or a resumed one. **Mark each substep `Done` in the PLAN the moment its work
completes, before resolving the next** — that as-you-go marking is what makes "the lowest open substep"
land on the right next action after any interruption.

The work runs in stages, each a set of PLAN substeps:

- **Stage 1 — Intake** (`inv-1`) — frame the adoption. Below.
- **Stage 2 — Map + plan** (`inv-2`…`inv-5`, then the per-asset substeps) — scan and inventory, draft
  the recon map, the user confirms it, upgrade this PLAN by addition, then document each asset. Below.
- **Stage 3 — Harvest→confirm** the architecture sessions `1.1`–`1.13`, then the Cross-Cutting
  Review (`1.14`) and land. *Forthcoming in the next build increment; until it lands, Stages 1–2 are
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

**Record + advance.** Record **all four** intake answers — the rough locations, the lifecycle/release
stage, the version convention, and the depth-dial posture — into the stub's **Intake results (`inv-1`)**
note in the PLAN, so Stage 2 reads one working note instead of three files. Two of them also go to a
permanent home: write the release-stage descriptor into `overview.md` now, and the depth-dial posture
seeds the recon map's Coverage & Confidence at `inv-3`. Mark `inv-1` **Done** in the PLAN's substep
table, then resolve the next open substep. **Checkpoint:** play the intake back to the user before
moving on.

## Stage 2 — Map + plan  (`inv-2`…`inv-5`, then the per-asset substeps)

Stage 2 turns intake into the confirmed **recon map** and the real STEP-1 PLAN. Resolve these
substeps in order; each is a substep in the PLAN.

### `inv-2` — Scan & inventory (breadth)
Walk the locations from intake and produce a flat list of **every** repo, doc, and resource — data
stores, services, integrations, CI, deploy surfaces, environments, observability. Classify each existing doc (architecture / API
spec / ADR-shaped / runbook / design note / other) and give it a **trust level** (high / medium / low
/ stale) against what the code shows. This is breadth — list and classify, don't deep-read yet. Read
everything as **reference data**; the code is the source of truth. Mark `inv-2` **Done** once the list
is complete.

### `inv-3` — Draft the recon map
Copy `templates/reports/recon-map-report-template.md` to `reports/YYYY-MM-DD-step-0001-recon-map.md`
and fill every section from the scan: inventory, stack per repo, entry points/services, data stores,
integrations, existing-docs classification + trust, tests/CI, and the confidence/unknowns. Stamp the
front matter too — **Reviewed commit(s)** (the `repo@sha` state this map describes) and **Depth dial**
— so the snapshot is pinned to an exact point in time. Set the **Coverage & Confidence** section from
intake — the depth-dial posture and any areas you are already choosing to bound. Write the **Summary**
last — a few sentences on what the system is, the shape of the inventory, and the biggest unknowns.
Leave `Status: Draft`. Mark `inv-3` **Done** once the draft is written.

### `inv-4` — Confirm the recon map  ▸ checkpoint
**Detect, then confirm.** Present the draft and let the user correct it — this is the one hard gate,
the birth-certificate checkpoint, before anything is built on the map. What the gate locks is the
**Inventory — the complete list of assets**; that "we now have the whole list" is the clean point the
rest of Stage 2 scopes from. On sign-off, stamp `Status: Confirmed on <date>`: the **confirmed
Inventory is frozen — never rewritten** (an asset discovered later is a recorded finding, not a silent
edit). The per-asset **detail is not frozen** — it deepens later in the living docs (repo READMEs,
`architecture/`), and some exploration is deliberately deferred for weeks or months via the depth dial
(`Coverage: deferred` → `risks.yml` → the check-in backfill). If the user can't yet confirm an area,
mark it bounded/deferred in Coverage & Confidence rather than guessing it into fact. Once the map is
confirmed and frozen, mark `inv-4` **Done**.

### `inv-5` — Upgrade this PLAN by addition
The confirmed map now fixes both the asset list and which sessions apply. Edit
`Upcoming Prompts/{{PROJECT}}-STEP-1-PLAN.md`: **append at the END of the PLAN (after Definition of
done) — never rewrite the seed above.** Do the appends *first*, then mark `inv-5` **Done** last, as
the completion flag. If a
resumed agent finds `inv-5` still open, the upgrade was interrupted — re-run it **idempotently**:
append only the blocks (asset table, `1.1`–`1.14` sessions, conditional table, `risks.yml` rows) not
already present, then mark `inv-5` **Done**. (`inv-1`…`inv-4` are already `Done` from as-you-go
marking.) The appends:

- **Per-asset substeps** — the confirmed **Inventory** (from the recon map) projected into work
  units: one **row per asset**, tracked in their own appended table (its own columns — not
  the `inv-N` table's — but the same `Planned` · `In progress` · `Done` Status convention, so a
  resumed agent can tell which are left). Number them `asset-1`, `asset-2`, … in discovery order — one
  per **repo**, one per **doc-set** (related docs grouped), one per **resource**:

  | # | Asset | Kind | Status |
  |---|-------|------|--------|
  | `asset-1` | {{name}} | repo / doc-set / resource | Planned |

  This is a **tracker, not a second catalog** — no Location/Notes column: the breadth detail
  (location, role, notes) stays in the recon map's frozen Inventory, and the deliverable each substep
  produces lands in its living home — `repos.yml`, the repo README, or an `architecture/` / `inputs/`
  doc (see below) — never in the cell.
- **The in-scope architecture sessions `1.1`–`1.14`** — the STEP-1 substep mirror, in their own
  appended table with the **same `Planned` · `In progress` · `Done` Status convention** as the
  `inv-N` and `asset-N` tables, so a resumed agent resolves the lowest-open session across a chat
  boundary. Session progress lives **here in the PLAN**: during adoption `prompts/STEP-index.md` is
  held at its greenfield seed (see the risks.yml paragraph below), so it cannot track which session is
  done. `1.1`–`1.13` run the harvest→confirm wrapper (Stage 3); `1.14` is the Cross-Cutting Review +
  land, not a harvest.

  | Substep | Session | Status |
  |---------|---------|--------|
  | `1.1` | {{session name}} | Planned |
- **The `Conditional sessions considered` table** — mirror the `Conditional sessions considered`
  table greenfield authors from `templates/step-plan-template.md` (its columns and its seeded rows),
  but decide each row from **code-visible surfaces**: a client/mobile surface →
  `conditional-native-app`, any authentication → `conditional-identity-auth`, PII →
  `conditional-privacy-compliance`. Seed now; refine as sessions harvest. (If an included conditional
  later earns a lettered `1.Xa` STEP-index row + doc number, follow the Conditional-sessions note in
  `templates/step-index-seed.md` for that.)

**Seed `registries/risks.yml` from the confirmed map.** Give each genuinely-risky item the map
surfaces — in **Confidence & Unknowns**, **Coverage & Confidence**, **Tests & CI** (e.g. no tests or
an empty CI gate on a shipped system), or anywhere else — a `risks.yml` row with a revisit trigger,
so the check-in re-surfaces it. During adoption the risk lives in `risks.yml` **only** — do
**not** add a `Planned` backfill STEP to `prompts/STEP-index.md`; the index stays at its greenfield
seed until the baseline lands (see *How this prompt works*), when a deferred area becomes ordinary
forward work like any other risk.

**Resolution order.** Resolve the **lowest-open `asset-N`** per-asset substep first; only when every
`asset-N` is `Done` does the lowest open substep become the first architecture session — the
**lowest-open `1.N`** (Status ≠ `Done`), starting at `1.1` (Stage 3). So the next action now is the
first per-asset substep, `asset-1`.

### The per-asset substeps (depth)
Resolve each in turn — the **lowest-open `asset-N`** (Status ≠ `Done`); mark its row `Done` once the
asset is recorded. Reading one asset at a time keeps even a 20-repo system legible.

- **Per repo** — register it in `registries/repos.yml` (a row: real `location`, `type`, and
  `throughstone: managed`), stamp a Throughstone README from `templates/repo-readme-template.md`, and
  record a short per-repo note (stack, entry points, role) in that README — its living home, which the
  owning `architecture/` docs deepen later (never back into the frozen recon map). Register repos
  **in place** by their real location; never relocate the user's code.
- **Per doc-set** — save found source docs into `inputs/` (they ride the base inputs lifecycle:
  point-in-time, the code wins on conflict) and write the Throughstone-shaped doc as a **pointer**
  where that fits. Architecture-grade docs get *lifted* into `architecture/` by their owning session
  later — that wiring is Stage 3; here, just land and classify them.
- **Per resource** — every non-repo, non-doc asset the inventory found gets a substep, feeding the
  session that will own it (record enough for its harvest to pick up): data stores → `1.4`; API /
  interface surfaces (HTTP/RPC endpoints, published contracts) → `1.11`; other runnable surfaces
  (workers, cron jobs, CLIs, functions) → `1.3`; external integrations → `1.11`; infrastructure /
  deploy surfaces / CI-CD pipeline → `1.8`; CI test gates (suites/coverage that block merge) → `1.12`;
  environments → `1.9`; observability → `1.10`. Routing names a **primary** home, not an exclusive one
  — a resource may feed more than one session (an endpoint informs both `1.3` and `1.11`); the substep
  just records it where its harvest will look first. **When in doubt, give it its own substep** — a
  human can merge or dismiss one that turns out not to matter, but a resource with no substep is easily
  forgotten. Group many-of-a-kind (e.g. 40 endpoints) into one substep to stay legible; never silently
  drop a kind.

When the per-asset substeps are done, the lowest open substep is the first architecture session
(`1.1`) — **Stage 3, the per-session harvest→confirm wrapper** (RETCON-PROMPT's second half).
*Forthcoming in the next build increment; until it lands, Stage 2 is the resolvable work.*
