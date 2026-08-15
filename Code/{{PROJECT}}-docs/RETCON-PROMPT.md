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
- **Stage 3 — Harvest→confirm** (`1.1`…`1.13`) — for each in-scope architecture session: read its
  template as reference data, draft an answer to every decision **from the running code**, confirm
  those answers with the user, and write the clean `architecture/` doc. Below.
- **Stage 4 — Cross-Cutting Review + land** (`1.14`) — reconcile everything against the code, then
  land the baseline. *Forthcoming in the next build increment; until it lands, Stages 1–3 are the
  resolvable work.*

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

**Deferring is a real choice, so present it as one.** Whenever you escalate, say plainly what
deferring costs before the user answers: this area of the baseline stays incomplete, and forward work
that leans on it is less reliable until someone backfills it. Name the area and the risk in ordinary
terms — *"I'd be describing 40 of ~600 tables; anything we build on the other 560 is guesswork until
we go back"* — not a procedural note about coverage fields. A user who defers with that in front of
them has made an engineering trade; one who defers after "shall I mark this deferred?" has been
walked past a decision.

Each deferral then carries that warning forward at two more moments — **in the doc**, where the
`Coverage:` line says what is missing and why it matters, and **later**, through a `risks.yml` row
that the periodic check-in re-surfaces. Keep it proportionate: loud at the choice and whenever
someone starts building on the area, quiet-but-present elsewhere. A warning repeated everywhere
becomes noise, and noise is how a deferral turns into a silent gap.

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
resumed agent finds `inv-5` still open, the upgrade was interrupted — re-run it **idempotently**,
reconciling each block **row by row** rather than treating a present table header as a complete block
(an earlier run may have written a header and some rows but not all): append an `asset-N` row for
**every** frozen recon-map Inventory asset that lacks one; append any missing **session** row so the
table holds the full fixed `1.1`–`1.14` set (a dropped tail would silently skip the Cross-Cutting
Review); append any missing **conditional** row from the seeded set, plus the lettered session row
each `Include` needs; and add any `risks.yml` row not already present. Then mark `inv-5` **Done**. (`inv-1`…`inv-4` are already `Done` from as-you-go
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

  **Write the rows in run order, and float Phasing (`1.2`) to the end** — after `1.13`, immediately
  before `1.14`. Every other session has an as-built half to harvest; Phasing is purely forward
  (*what comes next*), so running it in numeric position would ask you to plan a roadmap before the
  system it plans for has been described. Floated, it runs on the finished descriptive set. The
  numbers don't change — `1.2` is still `1.2`, and its doc is still `architecture/02-*` — only its
  position in this table does, and this table is what the harvest walks.
- **The `Conditional sessions considered` table** — mirror the `Conditional sessions considered`
  table greenfield authors from `templates/step-plan-template.md` (its columns and its seeded rows),
  but decide each row from **code-visible surfaces**: a client/mobile surface →
  `conditional-native-app`, any authentication → `conditional-identity-auth`, PII →
  `conditional-privacy-compliance`. Seed now; refine as sessions harvest.

  **Every `Include` also gets a lettered row in the session table above** — `1.6a`, `1.7b`, … placed
  next to the core session that owns it, with the same Status column, and named in the conditional
  table's decision cell so the two agree. Without that row nothing ever resolves it: Stage 3 walks
  the session table, and `prompts/STEP-index.md` — where greenfield puts the lettered substep — is
  held at its seed until landing. Assign its output-doc number by the rule in that conditional's own
  template, and follow the Conditional-sessions note in `templates/step-index-seed.md` when landing
  puts the row into the index. A conditional included *later*, as a session harvests, gets its row
  the same way at that moment.

**Seed `registries/risks.yml` from the confirmed map.** Give each genuinely-risky item the map
surfaces — in **Confidence & Unknowns**, **Coverage & Confidence**, **Tests & CI** (e.g. no tests or
an empty CI gate on a shipped system), or anywhere else — a `risks.yml` row with a revisit trigger,
so the check-in re-surfaces it. **Write rows into the file's own `risks:` list, in the shape its
commented example documents** (`id`, `status`, `title`, `category`, `severity`, `owner`, `opened`,
`source`, `description`, `impact`, `mitigation`, `revisit_trigger`, `refs`) — the file ships as
`risks: []` with that example beneath it. Nothing validates this registry mechanically, so a row
invented in a different shape stays broken until a human reads it. During adoption the risk lives in `risks.yml` **only** — do
**not** add a `Planned` backfill STEP to `prompts/STEP-index.md`; the index stays at its greenfield
seed until the baseline lands (see *How this prompt works*), when a deferred area becomes ordinary
forward work like any other risk. **One edit to the index is allowed before landing** — floated `1.2`
fills the `{{PHASE_1_NAME}}` placeholder in its `## Phase 1 — …` heading (Stage 3), because landing
reads the archive folder name from that heading. No row, status, or STEP is touched.

**Resolution order.** Resolve the **lowest-open `asset-N`** per-asset substep first; only when every
`asset-N` is `Done` does the next action become the first architecture session — the **first open row
in the session table**, read top to bottom, which starts at `1.1` (Stage 3). So the next action now
is the first per-asset substep, `asset-1`.

### The per-asset substeps (depth)
Resolve each in turn — the **lowest-open `asset-N`** (Status ≠ `Done`); mark its row `Done` once the
asset is recorded. Reading one asset at a time keeps even a 20-repo system legible.

- **Per repo** — register it in `registries/repos.yml` (a row: real `location`, `type`, and
  `throughstone: managed`), stamp a Throughstone README from `templates/repo-readme-template.md`, and
  record a short per-repo note (stack, entry points, role) in that README — its living home, which the
  owning `architecture/` docs deepen later (never back into the frozen recon map). Register repos
  **in place** by their real location; never relocate the user's code.
- **Per doc-set** — copy the found source docs into `inputs/` and add each one's
  `inputs/inputs-index.md` row(s) (`Live`), per the base inputs lifecycle (point-in-time; the code
  wins on conflict). Their
  classification and trust already live in the frozen recon map — don't restate them. That is the
  whole Stage-2 deliverable for a doc-set: **land and record, nothing more.** Architecture-grade docs
  (a finished design doc, a protocol/API spec) get *lifted* into `architecture/` by their owning
  session in Stage 3 (*The existing docs this session owns*) — not here, because which session owns a
  document only becomes clear once that session is reading its area against the code.
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
(`1.1`) — **Stage 3**, below.

## Stage 3 — Harvest→confirm the architecture sessions  (`1.1`…`1.13`)

Greenfield runs each of these sessions as an **interview**: it asks you every decision, because
nothing exists yet to read. Adoption inverts it — the answers are already in the running code, so
this stage **drafts them from reality first and then confirms them with you**. That is the whole
point of retcon, and it is why the session templates are used here as *reference data* rather than
run: their decision lists say what an area must settle, and your code says how this system settled it.

### Resolving and tracking sessions
**Resolve the first open row** in the PLAN's session table — reading top to bottom, the first whose
Status is not `Done`, `N/A`, or `Deferred` — and run the loop below for it. **Table order, not
session number, is what governs**: `inv-5` wrote the rows in run order, which floats Phasing (`1.2`)
to the end (see below). The table holds the fixed `1.1`–`1.14` set **and the lettered rows for any
conditional the map included** (`1.6a`, `1.7b`, …), so a conditional is resolved in place like any
other session.

**Run them strictly serially — harvest, confirm, and write one session before starting the next.**
Do **not** batch: harvesting several sessions up front and confirming them later looks more efficient
— the unattended reading happens in one pass, the user's time arrives in one block — **but** it
sends the work out of sequence, and the rework costs more than the batching saves. A sheet drafted
before its upstream sessions are confirmed rests on answers the user has not corrected yet, so one
correction at `1.3` quietly invalidates drafted rows in every later sheet: each has to be re-read
against the code and re-confirmed with the user, and any it slips past surfaces at the Cross-Cutting
Review as a contradiction to adjudicate there instead. Serial harvesting means each session reads its
predecessors' **confirmed** docs, so the review inherits the contradictions the *system* has, not
ones this process introduced. It is also how greenfield runs its sessions, which is the baseline
this adoption has to end up equivalent to.

**Track it across sittings.** A session is the largest unit in this stage — a full harvest plus a
real conversation, easily more than one chat. So flip the row to **`In progress`** when you start it,
and to **`Done`** when its doc is written; those are the same values the `inv-N` and `asset-N`
tables use.

**Resuming an `In progress` session: read its sheet, never restart it.** The sheet in
`Upcoming Prompts/retcon/` is the state — its **`Status`** (`Harvested` vs `Confirmed`) says which
half you were in, and its **`Confirm`** column says which rows you had already walked with the user.
Continue from the first unfilled row. **Never overwrite an existing sheet**: a re-harvest throws away
the user's confirmations, which are the expensive part.

**A session whose area doesn't exist.** Some sessions carry their own applicability note (the UI
session on an API-only system, for instance). Don't invent a doc for an area the code doesn't have,
and don't quietly skip it either: record **`N/A`** (structurally inapplicable) or **`Deferred`** (may
arrive later) on the row, with a one-line reason drawn from the code — "no client surface in any
adopted repo", not "not needed". Both are ordinary substep statuses in this method, so landing
carries them into the index unchanged. If it's a conditional, mirror the same disposition in the
PLAN's *Conditional sessions considered* table.

`1.14` is the Cross-Cutting Review + land, not a harvest — see the note at the end of this stage.

### 1. Read the session file as reference data
Open `templates/architecture-sessions/NN-<topic>.md` (or the `conditional-*.md` the PLAN's conditional
table included) and take from it:

- **`## Decisions to make (in order)`** — the work list. Every session template uses that heading,
  whatever its items are called in the notes beneath it. This is what your pre-answer sheet's rows
  come from.
- **`## Output`** — what the resulting `architecture/` doc must contain, and its number/filename.
- **`## How this session works`** and the framing sections — the *lens* the session applies. Keep it;
  a harvest that ignores the lens produces a description, not an architecture doc.

**Do not run the session.** Its closing paragraph is addressed to an agent that was *sent to run*
that session, and says so; you are reading the file to harvest it, so that paragraph is not your
instruction. Two more things belong to the interview,
not to you: its **`## Next`** hand-off (the resolver here is this PLAN, not the STEP index) and any
instruction to mark a substep `Done` in `prompts/STEP-index.md` — during adoption the index is held
at its greenfield seed, and session progress lives in the PLAN (step 5 below).

### 2. Pick the shape — as-built, or forward-intent
Most sessions are **as-built**: the code already answers them (component boundaries, data model,
interface contracts, infrastructure, environments, observability, tests). Harvest, then confirm.

Some decisions have **no as-built answer** because they are about intent rather than structure —
what the system should become, what is deliberately out of scope, what the next milestone is. Those
get a **near-normal interview**: ask the user directly, exactly as greenfield would, and record the
answer as a forward decision.

**ADRs: never assumed, sometimes asked for.** Several session templates tell a greenfield run to
write an ADR for a significant or contested choice. Do **not** follow that for anything you harvested:
the choice was made long before adoption, and writing it up now would fabricate a decision record
with a date and a rationale nobody stated. As-built decisions live in the doc's **Decision Summary**
table, which is where a reader expects "this is how it is" rather than "this is when we chose it."

The exception is **user-directed**: if, during adoption, the user *makes* a decision or tells you
that a decision was made and what drove it, that is contemporaneous or first-hand testimony, not
reconstruction, and it may become a normal ADR. Say so explicitly and get approval before writing —
something like *"that sounds like a decision worth recording as an ADR — want me to write one?"* —
and take a no gracefully; the answer still lands in the Decision Summary either way. The line is
**user-directed vs. agent-assumed**, not old vs. new.

The test is per decision, not per session: **can the running code answer this?** A single session
usually mixes both — the Security session harvests the auth mechanism from the code and asks you
about the acceptable-risk posture. Never interview what the code can answer; never guess what only a
human can.

### 3. Harvest — draft every answer from reality
Copy `templates/retcon-preanswer-sheet.md` to `Upcoming Prompts/retcon/<N.N>-<session>.md` — **unless
a sheet for this session already exists, in which case continue it** (see *Resuming* above) — and
fill one row per decision: the **drafted answer**, its **provenance** (every source that informed it — a
code path, a doc in `inputs/` with its trust level, the user's memory, or `inferred` / `unknown`),
and your **confidence**. Read the code; use the confirmed recon map and the per-asset notes for
orientation. This step is **human-free** — the one exception is a payload too big to enumerate under
the depth-dial posture, where you stop and escalate rather than silently sampling: state the cost of
deferring, in this system's terms, and let the user choose (Stage 1, *Deferring is a real choice*).

Add rows the template never listed when the system raises decisions the generic list didn't foresee.
Mark a decision `unknown` rather than inventing an answer: an honest gap survives the confirm pass,
a plausible fabrication may not.

### 4. Confirm with the user  ▸ checkpoint
Walk **every** row, proportionate to **confidence × consequence**: a high-confidence from-code
answer gets a fast "this is what the code does — right?", while a low-confidence or load-bearing one
gets a real discussion. Harvest and confirm normally run back to back, so nothing has moved in
between — but when a session is **resumed after a gap**, reconcile the sheet against any
`architecture/` doc confirmed since you drafted it first, and raise the conflict rather than quietly
picking a side.

Record each outcome in the sheet's **Confirm** column: *confirmed as-is*, *corrected: …*, or
*deferred*. Never leave a row unwalked.

**Deferring here works like deferring at the depth dial** (Stage 1): say what it costs before the
user chooses, then carry the warning into the doc's `Coverage:` line and — when the gap is genuinely
risky rather than merely incomplete — a `registries/risks.yml` row with a revisit trigger, so the
periodic check-in re-surfaces it (in that file's documented row shape, as at `inv-5`). During adoption the risk lives in `risks.yml` only: do **not** add
a backfill STEP to `prompts/STEP-index.md`, which is held at its greenfield seed until the baseline
lands, at which point a deferred area becomes ordinary forward work like any other risk.

### 5. Write the clean doc, then mark the session `Done`
Write the `architecture/` doc the session's `## Output` section names, from
`templates/architecture-doc-template.md` — so it carries **`Version`**, **`Status`**, and a
**`Version Log`** (`check.sh` check 4 requires all three; a doc written freehand fails the baseline's
own check). `Version` follows the house convention recorded at intake — and where intake recorded
**none**, keep the template's starting `v0.1.0` rather than inventing a higher number: the doc is new
even though the system is not, and a bigger version implies a revision history these docs deliberately
don't claim. `Status` reflects how settled the harvested reality is — a confirmed as-built doc is
normally **`Current`**, whether or not the product has shipped.

Where step 4 deferred something, add a `Coverage:` line **as a header field** (the template's comment
shows where) — and **never a bare `deferred`**. It reads as one sentence: what is missing, how big it
is, and what it means for someone building on this doc. *"`Coverage: deferred` — 40 of ~600 tables
enumerated; the rest are named but their columns and relations are unread, so anything designed
against them needs checking first."* A reader who meets that line months later can tell whether it
blocks them; a bare word tells them nothing and gets ignored.

Follow the session's `Output` section for the body, the doc number, and its filename — with the two
carve-outs already stated: no `prompts/STEP-index.md` bookkeeping, and **no ADR for a harvested
decision** (only a user-directed one, with their approval).

The doc states **what the system is**. Provenance and confidence stay in the sheet and never leak
into it: no "harvested from", no per-sentence sourcing, no confidence hedges. Drift and debt the
harvest surfaced *are* content — record them as reality plus a flagged gap, with a `risks.yml` row.

Then mark the session's row `Done` in the PLAN and resolve the next open row. Leave the sheet in
place — it is transient scratch, discarded when STEP-1 lands, not archived as history.

### The existing docs this session owns
Stage 2 copied every found document into `inputs/` and gave it an `inputs-index.md` row — *landed and
recorded, nothing more*. Acting on one is this session's job, for the documents covering its area.
The base inputs lifecycle already says how (`inputs/README.md`); adoption only adds *when*, and one
rule of precedence.

- **The code still wins.** An input is secondary evidence, whatever its trust level in the recon map.
  Where it disagrees with what you read in the code, the code is the answer — and the disagreement
  itself is **content**: record the reality, and flag the doc as stale in that respect. Do not quietly
  average the two, and do not "fix" the input.
- **A finished, authoritative doc gets lifted** — a protocol or API spec, an interface contract, a
  design doc that is still true. Copy it into `architecture/` (whole-file, or a light reformat to fit
  the doc conventions) rather than leaving `architecture/` pointing at `inputs/`; from then on the
  `architecture/` copy is the living version and the original stays in `inputs/` as provenance. Two
  practical consequences: a lifted doc that takes a numbered `architecture/NN-*.md` slot **needs the
  `Version` / `Status` / `Version Log` header** like any other architecture doc (`check.sh` check 4
  reads every numbered doc, however it got there), and a large external standard you don't own is the
  case where you **reference instead of lift**, per the same base rule.
- **A PRD, prior design doc, or research note is synthesized, not lifted** — you read it, and what
  survives appears in the doc you write. The input doesn't come across verbatim.
- **Update the ledger either way.** Flip that input's `inputs-index.md` row to record what
  `architecture/` has now superseded and what still holds, so a later session builds on current
  material rather than re-reading a stale seed.
- **Don't retire anything yourself.** A fully-superseded input is a *candidate* for `inputs/archive/`
  — say so and let the user decide, exactly as the periodic check-in does. Retiring is a move, never
  an edit or a delete, and never automatic.

### Four sessions need a word about the float
Floating Phasing changes what three earlier sessions can read, and gives Phasing itself a different
job. Nothing about their templates changes — these are the notes the wrapper adds when it runs them.

- **`1.3` Architecture Overview and `1.5` Scaling & Performance** canonically read the Phasing doc,
  which doesn't exist yet. Harvest both from the code, and treat their forward *"don't foreclose the
  roadmap"* input as **moot** here: this system already made its choices, and a foreclosure you find
  is an as-built fact to record, not a decision to steer. Carry the question of whether those choices
  still fit the roadmap to `1.14`, where the now-written Phasing doc can be read against them. `1.5`
  also loses its usual growth input from Phasing, so **ask the user directly** what growth to expect
  — that one is forward-intent, and only they can answer it.
- **`1.13` Glossary** canonically reads *all* the architecture docs produced so far, and under the
  float that set excludes Phasing. That's fine and deliberate: the Glossary's job here is the
  **as-built vocabulary**, which is complete without it. Phasing's forward-milestone terms fold in at
  `1.14`, whose Consistency check already flags Glossary drift — so no term is lost, and the Glossary
  isn't blocked waiting on a doc about the future.
- **`1.2` Phasing itself** runs last, on the finished descriptive set, and is a **forward-intent
  session end to end** — there is no as-built half to harvest, so run it as a near-normal interview
  (step 2). Two things make it more than an ordinary session under adoption. It names the **forward
  milestone**: what this system's next release-level milestone is, given everything the baseline just
  described. And it fills the **`{{PHASE_1_NAME}}` placeholder** in `prompts/STEP-index.md`'s
  `## Phase 1 — {{PHASE_1_NAME}}` heading — the one edit to that file adoption makes before landing,
  because the heading is where landing reads the archive folder name (`prompts/001-<phase-name>/`).
  Leaving the placeholder unresolved would strand the baseline at archive time.

> `1.14`'s side of this — reconciling Phasing against `1.3`/`1.5` once all three exist, and turning
> foreclosure into gap analysis — belongs to the Cross-Cutting Review, in the increment below.

> **When you reach `1.14` and Stage 4 is not present in this prompt, STOP.** Report that the
> architecture baseline (Stages 1–3) is complete — every in-scope session harvested, confirmed, and
> written — and that the Cross-Cutting Review and the baseline land are pending a future build
> increment, then wait. Do **not** improvise the land: leaving `PROJECT-STATUS: retcon` in place and
> the STEP index at its seed is the correct, resumable state.
