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

**Permission, not forgiveness — for the intake.** Adoption is **additive**. Nearly everything it
produces is new and lands where nothing was — the `architecture/` baseline, the STEP process, the
registries, the recon map — so that ordinary {{PROJECT}} can run from here forward. The intake is not
a pass over the team's prior work: their code is read and never rewritten, and what they already have
stays theirs. The few places where the two would meet are handled the same way every time — **ask,
and wait for a yes**, for that file, in that repo, with the exact text in front of them. A repo's
README, its licensing, its CI, its remote, its visibility: there is a rule below for each, and those
rules are this principle applied, not the extent of it. **When you meet something you did not create
and nothing here says what to do, ask** — never act now and explain after. You are moving quickly
through a codebase someone else built and still runs, describing it rather than working on it, and
nothing has been agreed yet; the question costs a message, and the change nobody agreed to costs
their trust in the whole baseline.

**This is the posture of the adoption, and it ends when the baseline lands.** It is not a permanent
stance toward these repos, and it is not a mode the project carries around afterwards. Adopting a
legacy system is precisely so that {{PROJECT}} can change it — once STEP-1 is `Done` and
`PROJECT-STATUS` flips, forward STEPs implement against the baseline and edit these repos like any
others, under the ordinary method. Do not carry this restraint past the land, and do not read it back
into `METHOD.md`: what it governs is a point-in-time intake, taken before there is an architecture to
work from or a single agreement in place.

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
2. `Code/{{PROJECT}}-docs/overview.md` — normally still the blank template at this point: adoption
   skips the kickoff interview that fills it, and the brief is written later, by `1.1`, the first
   architecture session (Stage 3). The one-line description the user gave `init.sh` is in this docs
   hub's `AGENTS.md` (*What is {{PROJECT}}*) — read that for the seed, and read `overview.md` for
   the release-stage line once Stage 1 has written it.
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
and fill every section from the scan: inventory, stack per repo (including each repo's licensing
**as found** — recorded, never set — and whether its README says what the repo is *within the
system*), entry points/services, data stores,
integrations, existing-docs classification + trust, tests/CI, and the confidence/unknowns. Propose a
**Scope** for each Inventory row (`adopt` unless the code says otherwise) — the user settles it at
`inv-4`; a draft proposal is not the decision. Stamp the
front matter too — **Reviewed commit(s)** (the `repo@sha` state this map describes) and **Depth dial**
— so the snapshot is pinned to an exact point in time. Set the **Coverage & Confidence** section from
intake — the depth-dial posture and any areas you are already choosing to bound. Write the **Summary**
last — a few sentences on what the system is, the shape of the inventory, and the biggest unknowns.
Leave `Status: Draft`. Mark `inv-3` **Done** once the draft is written.

### `inv-4` — Confirm the recon map  ▸ checkpoint
**Detect, then confirm.** Present the draft and let the user correct it — this is the one hard gate,
the birth-certificate checkpoint, before anything is built on the map. What the gate locks is the
**Inventory — the complete list of assets**; that "we now have the whole list" is the clean point the
rest of Stage 2 scopes from.

**Complete is not the same as in scope, so settle both here.** A breadth scan of a real account
turns up things that shouldn't be adopted — an abandoned service, a dead prototype, a repo another
team owns. Walk the Inventory with the user and set each row's **Scope**: `adopt`, or
`excluded — <reason>`. Excluded rows stay in the map (found-and-dismissed is a finding, and it stops
the next scan from re-raising them); only `adopt` rows become work at `inv-5`. Ask rather than
assume — "still in use?" is a question the code often can't answer. On sign-off, stamp `Status: Confirmed on <date>`: the **confirmed
Inventory is frozen — never rewritten** (an asset discovered later is a recorded finding, not a silent
edit). The per-asset **detail is not frozen** — it deepens later in the living docs (repo READMEs,
`architecture/`), and some exploration is deliberately deferred for weeks or months via the depth dial
(`Coverage: deferred` → `risks.yml` → the check-in backfill). If the user can't yet confirm an area,
mark it bounded/deferred in Coverage & Confidence rather than guessing it into fact.

**Answer the project-license question here.** `init.sh --mode=existing` left it open on purpose:
at install time nobody had read the codebase, so the question had nothing to answer it from, and
`.throughstone/project-license` holds `Unset`. Now it does — **Stack Per Repo** has each adopted
repo's licensing as found, and the user is already reading the map. So ask once, with that in
front of them: *what licenses this documentation hub and anything the method creates later?*
Offer what the repos say as the default — if they agree on one license, propose it; if they carry
several, or none states anything, say so and ask. Be explicit that the answer covers **this
method's own material and nothing else**: it is not applied to the adopted repos, which keep the
licensing their owners set. Then run it in once:

```
Code/{{PROJECT}}-docs/scripts/set-project-license.sh <mit|bsd-3|apache-2.0|private> [--holder "<name>"]
```

That writes the posture, the docs hub's canonical `LICENSE` for an open-source answer, and the
`LICENSING.md` and inventory rows for the repos `init.sh` created — the files it left saying the
license had not been chosen yet. Commit the result in each repo it touched. It answers the
question once and refuses to change an answer already given; if the user supplied `--license` at
install time there is nothing open, and the helper will say so. If the user would rather decide
later, that is a fine answer too — the posture stays `Unset`, and nothing needs it until the
project creates its first repo, which is where `apply-project-license.sh` will ask for it.

**Then say once where their own repos don't match, and stop.** This is the moment for it: the
answer is fresh and the licensing column is on screen. Name them plainly — *"you chose MIT;
`billing-api` is Apache-2.0 (LICENSE) and `legacy-etl` states nothing"* — and leave it there.
Nothing is reconciled and nothing is written into those repos: the choice just made covers this
method's material, not theirs. What comes of it is the user's call on their own code. Say it here
so the per-repo substeps don't have to raise it eight more times; if every repo already matches,
say nothing at all rather than reporting a clean comparison nobody asked for.

**Say what the docs column adds up to, too.** The **Docs (as found)** column has just recorded, per
repo, whether it explains its place in the system — so give the user the shape of it in one line
before Stage 2 starts working through them: *"11 of your 14 repos have a README that doesn't say
what it is within the system; 3 have none at all."* That is the whole of it here. **Do not turn it
into a gate** — do not ask now whether they want READMEs touched, and do not collect a blanket yes.
Each repo's addition is proposed with its own text when its substep comes up, because the text is
what they are agreeing to and none of it is written yet. This line exists so that when those
proposals start arriving they are expected and their number is known, rather than appearing one at
a time from nowhere. If they decline early on, `METHOD.md` §7 lets that decline stand for the rest.

Once the map is confirmed and frozen, mark `inv-4` **Done**.

### `inv-5` — Upgrade this PLAN by addition
The confirmed map now fixes both the asset list and which sessions apply. Edit
`Upcoming Prompts/{{PROJECT}}-STEP-1-PLAN.md`: **append at the END of the PLAN (after Definition of
done) — never rewrite the seed above.** Do the appends *first*, then mark `inv-5` **Done** last, as
the completion flag. If a
resumed agent finds `inv-5` still open, the upgrade was interrupted — re-run it **idempotently**,
reconciling each block **row by row** rather than treating a present table header as a complete block
(an earlier run may have written a header and some rows but not all): append an `asset-N` row for
**every** frozen recon-map Inventory asset marked `adopt` that lacks one — and none for an
`excluded` row, in either the first run or a re-run; append any missing **session** row so the
table holds the full fixed `1.1`–`1.14` set (a dropped tail would silently skip the Cross-Cutting
Review); append any missing **conditional** row from the seeded set, plus the lettered session row
each `Include` needs; and add any `risks.yml` row not already present. Then mark `inv-5` **Done**. (`inv-1`…`inv-4` are already `Done` from as-you-go
marking.) The appends:

- **Per-asset substeps** — the confirmed **Inventory** (from the recon map), its `adopt` rows
  projected into work
  units: one **row per adopted asset**, tracked in their own appended table (its own columns — not
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
  `inv-N` and `asset-N` tables, so a resumed agent resolves the right session across a chat boundary
  (Stage 3 gives the two-step rule: an `In progress` row first, then table order). Session progress lives **here in the PLAN**: during adoption `prompts/STEP-index.md` is
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
  but decide each row from **code-visible surfaces**, scoped as tightly as the rows themselves: a
  **mobile or desktop app** — a shipped client binary, not a web front end →
  `conditional-native-app`; **user accounts, login, or access control** — not a service-to-service
  key → `conditional-identity-auth`; **personal or regulated data** → `conditional-privacy-compliance`.
  A styled web UI with none of those is a `1.7` question, not a conditional — the same line `1.3`
  draws. Seed now; refine as sessions harvest. Each false `Include` costs a whole harvest session
  and a row nobody later deletes, so decide it, don't hedge it.

  **Every `Include` also gets a lettered row in the session table above** — `1.6a`, `1.7b`, … placed
  next to the core session that owns it, with the same Status column, and written into the
  conditional table's **`Substep / reason / revisit trigger`** cell (the `Decision` cell holds
  `Include` / `Deferred` / `N/A` and nothing else) so the two agree. Without that row nothing ever resolves it: Stage 3 walks
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
invented in a different shape stays broken until a human reads it.

**What `source` and `refs` point at here.** That file's recording rule wants every row anchored to a
durable artifact that carries the detail, and tells you to *create* one first if none exists —
naming an ADR or a follow-up STEP among the options. Adoption has neither available: no ADR for
anything harvested, and no new row in `prompts/STEP-index.md`. It doesn't need them, because the
artifact already exists. For a row seeded here, it is the **confirmed recon map** —
`reports/<date>-step-0001-recon-map.md`, plus the section that surfaced the item (Confidence &
Unknowns, Coverage & Confidence, Tests & CI) — which is a dated report under `reports/`, exactly the
genre that rule's last clause allows. For a row opened later, at a session's confirm pass, it is the
`architecture/` doc that session writes, plus its `Coverage:` line (Stage 3, step 4). Write no ADR
and no STEP to satisfy the registry. During adoption the risk lives in `risks.yml` **only** — do
**not** add a `Planned` backfill STEP to `prompts/STEP-index.md`; the index stays at its greenfield
seed until the baseline lands (see *How this prompt works*), when a deferred area becomes ordinary
forward work like any other risk. **One edit to the index is allowed before landing** — floated `1.2`
fills the `{{PHASE_1_NAME}}` placeholder in its `## Phase 1 — …` heading (Stage 3), because landing
reads the archive folder name from that heading. No row, status, or STEP is touched.

**Resolution order.** Resolve the **lowest-open `asset-N`** per-asset substep first; only when every
`asset-N` is `Done` does the next action become the first architecture session — the **first open row
in the session table**, read top to bottom, which starts at `1.1` (Stage 3). So the next action now
is the first per-asset substep, `asset-1`.

That rule describes the hand-off **out of Stage 2**, and it does not send the resolver backwards
later. Once Stage 3 has started, an `asset-N` row appended mid-stage — a harvest found an asset the
map missed (Stage 3, *An asset the harvest finds that the map missed*) — does **not** outrank the
session in flight: an `In progress` session finishes first, and the late asset is worked at the next
session boundary. Stage 3's two-step rule governs from `1.1` onward.

### The per-asset substeps (depth)
Resolve each in turn — the **lowest-open `asset-N`** (Status ≠ `Done`); mark its row `Done` once the
asset is recorded. Reading one asset at a time keeps even a 20-repo system legible.

- **Per repo** — register it in `registries/repos.yml` (a row: real `location`, `type`,
  `throughstone: managed`, and `license:` — see below) and **augment** its README (below).
  Record a short per-repo note (stack, entry points, role) in the repo's `architecture/` docs and
  its inventory row as they are written — never back into the frozen recon map. Register repos
  **in place** by their real location; never relocate the user's code.
  **Where a README already exists, augment it; never stamp over it.** The rule keys on whether
  that file is there, not on the fact that the repo was adopted — where an adopted repo has **no**
  README there is nothing to preserve, so offer to write one from the template. That is the one
  file; adopting a repo scaffolds nothing else in it. Most do have one, though, and it is usually
  the repo's most-read file — so `templates/repo-readme-template.md` is **not** copied in
  (`METHOD.md` §7: a repo registered in place is augmented, not stamped). Everything in that
  template except the role one-liner is something a running system already documents — setup,
  tests, configuration — written by the people who operate it; re-deriving it from your code read
  would replace what is accurate with what is inferred. What these repos usually lack is the one
  thing adoption is producing: the repo's place in the system. So add exactly that, as a short
  `## Role in {{PROJECT}}` section — the one-liner, two or three sentences on the slice of the
  system this repo owns, and links to its `architecture/` doc and the docs hub — and change
  nothing else. **Show the user the exact text and where it will go, and wait for a yes** before
  writing into a repo they own. **A no is a complete answer, not a gap:** the same information is
  already in the recon map, the repo's `architecture/` doc, and its `repos.yml` row, so record
  that the repo documents itself and move on.
  **On a yes, commit it on a branch and stop.** The yes was about the text, not about how that
  change should reach their trunk — this is a running system with a review process you did not
  design. So make a branch in that repo, commit **only the file you proposed** (name it; never
  `git add -A`, which would sweep up whatever they had in progress), tell them the branch and the
  commit, and stop there. **Never push, open a pull request, or merge**, and never commit onto
  whatever branch happens to be checked out — on an adopted repo that is usually `main`. If the
  working tree already has uncommitted changes to that file, say so and leave it rather than
  committing around them (`METHOD.md` §7). Writing a repo's README from the template where it had
  none is the same: that one file, on a branch, committed and left — and **not** an
  `ARCHITECTURE.md` alongside it. The template calls for one in a repo with real internal
  complexity **that this method created**, and adoption creates none: these repos have the
  complexity and other people own them. So an adopted repo's internal design is written up in the
  docs hub's `architecture/`, never as a second new file at its root. Where a repo already has an
  `ARCHITECTURE.md` of its own, that is theirs — read it, link it from the `Role` section if it
  helps, and leave it alone.
  **And a no can stand for the rest.** This same proposal reaches the same people once per repo,
  which in a fourteen-repo system is fourteen times — so on a decline, ask whether it covers this
  repo or all of them, and where it is standing, stop proposing and record the remaining repos as
  documenting themselves (`METHOD.md` §7). Ask that once. It runs one way: a yes is never carried
  forward, because the next repo's text is its own proposal and they haven't seen it.
  Which repos need what is already known — the map's **Docs (as found)** column recorded it at
  `inv-3` and `inv-4` said the shape out loud — so this arrives expected rather than as a surprise
  fourteen times over.
  **Never install CI into an adopted repo.** `templates/ci/code-repo-ci.yml` is the gate for a repo
  the method creates, and it is failing-until-configured by design — so dropping it into a running
  system either replaces the workflow that gates their merges or fails every build until someone
  deletes it. These repos already have CI; the recon map's **Tests & CI** section recorded what
  each one runs, and session `1.12` writes that up. Bringing a repo onto the standard gate is a
  change its owners decide on later, not a side effect of adoption.
  **Never touch an adopted repo's remote, and never change its visibility.** Every repo here
  already lives somewhere and is already private or public — both somebody's decision, made before
  this project existed. So create no remote for it, repoint no existing one, and
  **change no repository's visibility, in either direction, for any reason.** Adoption has no
  business doing it: nothing here needs a remote created, and a repo's audience is not something a
  scan can infer.
  Put the URL it already has in its `remote:` field so `scripts/setup-workspace.sh` can find it,
  and leave the repo alone (`METHOD.md` §7). **If the user asks for a repo to be published, that is
  an explicit go-ahead for that repo and nothing else** — never a standing one, never extended to a
  sibling, and worth confirming once more before it happens, because publishing a repository hands
  its entire history to forks, caches, and crawlers and making it private again retrieves none of
  it. Adoption is the exact circumstance where this matters most: you are working across a stranger's
  private codebase, at speed, with more repos in flight than anyone is tracking closely.
  **Place the Throughstone notice only if something Throughstone-authored landed.** If the README
  addition was accepted, that section is BSD-3-Clause scaffold material, so run
  `scripts/apply-project-license.sh --notice-only <repo-path>` — it writes `LICENSE-THROUGHSTONE`
  and a `LICENSING.md` scoped to that material, disclaiming the rest of the repo, and never a
  project `LICENSE`. Do **not** run the helper without that flag; it will refuse, and correctly.
  If the user declined the README addition, nothing Throughstone-authored is in the repo and
  nothing is owed — placing a notice for absent material would only confuse a later reader.
  **Never license an adopted repo.** Every repo here is registered in place, so its licensing is
  its owner's and the method only records it — the same rule that leaves its README augmented and
  its CI alone (`METHOD.md` §7: a repo the method did not create keeps what it already has).
  Concretely: do **not** run
  `scripts/apply-project-license.sh` against any of these repos — it will refuse one that states
  its own terms, and the ones it would not refuse are exactly the repos that would silently gain a
  `LICENSE` and a `LICENSING.md` claiming it over code you did not write. Recording it **is** the
  work here, in two places with two jobs: the recon map's **Stack Per Repo** row already captured
  it at `inv-3` as part of the frozen point-in-time snapshot, and this row's `license:` field is
  the **living** copy that stays current as the repo changes. Copy it across as found — same
  identifier, same source file, `none stated` where the repo says nothing — rather than
  re-deriving it, so the two records can't disagree from the day they are written.
  **A repo whose licensing differs from the project's is recorded, not reconciled.** The project's
  license — chosen at `inv-4` — governs this method's own artifacts, the docs hub and anything it
  later creates. The adopted repos are not measured against it and never take it. Any divergence
  was already named once at `inv-4`, when the user chose with the map's licensing column in front
  of them; do not re-raise it here, repo by repo, and do not open a finding or a risk row for it.
  Several adopted repos legitimately carrying several different licenses is a normal inventory,
  and a repo with no `LICENSE` at all is the ordinary state of private code, not a gap. Write the
  row and move on. If the user asks for a repo's licensing to be changed, that is their act on
  their repo: propose the exact file and wait for a yes, the same as any other write into a repo
  this method did not create.
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
Resolve the next session from the PLAN's session table in two steps, in this order:

1. **An `In progress` row wins, wherever it sits.** It means a session was started and interrupted,
   and its sheet is sitting half-walked in `Upcoming Prompts/retcon/` — finish that one (see
   *Resuming* below).
2. **Otherwise take the first open row** — reading top to bottom, the first whose Status is not
   `Done`, `N/A`, or `Deferred`.

The order matters because rows can appear **above** the session you are working on: a conditional
included late (PII surfacing at `1.10`, say) gets its lettered row next to the core session that owns
it, which by then is already `Done` and sits higher in the table. On the plain top-to-bottom rule a
resumed chat would jump to that new row and strand the half-harvested session below it, whose sheet
holds confirmations the user already gave. Finish the started one, then let table order take over.

**Table order, not session number, is what governs** the second step: `inv-5` wrote the rows in run
order, which floats Phasing (`1.2`) to the end (see below). The table holds the fixed `1.1`–`1.14`
set **and the lettered rows for any conditional the map included** (`1.6a`, `1.7b`, …), so a
conditional is resolved in place like any other session.

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
`Upcoming Prompts/retcon/` is the state — its **`Status`** says which half you finished (`Harvested`
once every row has a drafted answer, `Confirmed` once the confirm pass has walked every row; still
the unfilled placeholder means the harvest itself was interrupted), and its **`Confirm`** column says
which rows you had already walked with the user. Continue from the first unfilled row. **Never
overwrite an existing sheet**: a re-harvest throws away the user's confirmations, which are the
expensive part.

**A session whose area doesn't exist.** Some sessions carry their own applicability note (the UI
session on an API-only system, for instance). Don't invent a doc for an area the code doesn't have,
and don't quietly skip it either: record **`N/A`** (structurally inapplicable) or **`Deferred`** (may
arrive later) on the row, with a one-line reason drawn from the code — "no client surface in any
adopted repo", not "not needed". Both are ordinary substep statuses in this method, so landing
carries them into the index unchanged. If it's a conditional, mirror the same disposition in the
PLAN's *Conditional sessions considered* table.

**An asset the harvest finds that the map missed.** Expect this: `inv-2` was a breadth scan, and a
harvest reads its area far deeper, so `1.4` turns up an unlisted datastore or `1.8` a third deploy
target. The confirmed Inventory is frozen — **do not edit it** — but a found asset is not a
bookkeeping curiosity either. A repo that never reaches `registries/repos.yml` is missing from the
baseline itself. So:

- **Tell the user when you meet it**, at the confirm pass for the session that found it. This is a
  correction to the birth certificate they signed, and it is their call whether it is in scope at all
  (an abandoned service in the same account may not be).
- **If they adopt it, append an `asset-N` row** to the per-asset table — continuing the numbering,
  never renumbering — and do that asset's ordinary per-asset work: the `repos.yml` row and README
  note for a repo, the `inputs/` copy and ledger row for a doc, the routing note for a resource. **If
  they exclude it**, it gets no row and no work; record it as a one-line note beside the per-asset
  table (*"found at `1.8`: staging-2 deploy target, excluded — decommissioned"*), the same
  found-and-dismissed record an `excluded` Inventory row carries, since the frozen map can't take it.
- **Do it once the session in flight is `Done`**, not by interrupting it. The "every `asset-N` before
  the first session" rule describes the hand-off out of Stage 2; a late one slots in at the next
  session boundary, which keeps the serial rule intact.
- **Add a `registries/risks.yml` row** the first time it happens, with a revisit trigger — the
  confirmed inventory turned out not to be exhaustive, the frozen map can't say so itself, and the
  check-in is what re-surfaces it. One row for the pattern, not one per asset.

Where the discovery changes what the doc you are writing says, that is ordinary content: record the
reality, and flag the gap.

`1.14` is the Cross-Cutting Review + land, not a harvest — see the note at the end of this stage.

**Some sessions carry an extra note.** The loop below is the same for every session, but a few need
something it alone doesn't give them — a brief to fill, a session whose procedure assumes nothing
exists yet, or a consequence of running Phasing last. Those notes are the subsections that follow
the loop; **check whether the row you just resolved has one before you start it.**

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
instruction. Its **`## Next`** hand-off isn't either — the resolver here is this PLAN, not the STEP
index.

**And leave `prompts/STEP-index.md` alone entirely.** During adoption the index is held at its
greenfield seed and all session progress lives in the PLAN (step 5 below), so *every* index
instruction a session template carries is redirected here — not just the familiar "mark this substep
`Done`." These are the shapes the session files ask for today, and every one of them lands in the
PLAN instead — a session that asks for something not listed here is redirected the same way:

| The session says | You do this instead |
|------------------|---------------------|
| mark my substep `Done` (every session) — or `Deferred` (`1.6`) | flip the row in the PLAN's **session table** |
| note the open questions carried forward (`1.1`) | nothing goes in the index — they belong in the **Open Questions** table of the `architecture/` doc you are writing, which the doc template already carries |
| mark *another* session's row `Deferred` / `N/A` (`1.3` dispositions the UI / Design System row) | flip **that session's** row in the PLAN's session table, with the one-line reason from the code, exactly as *A session whose area doesn't exist* above describes — then mirror it in the *Conditional sessions considered* table if it is a conditional |
| add a lettered conditional row, e.g. `1.7a` (`1.3`) | append the lettered row to the PLAN's session table (see `inv-5`), and record the decision in the PLAN's *Conditional sessions considered* table |
| reflect the phase plan in the roadmap (`1.2`) | the phase plan is the **`architecture/02-*` doc's** content; the index gets nothing but the `{{PHASE_1_NAME}}` fill described under the float below |

The single exception in the whole adoption is that `{{PHASE_1_NAME}}` fill — the phase name, and the
scaffolding comment beneath it, and nothing else. No row, no status, no STEP, and no other part of
the file is touched before landing — landing is what reconciles the index, in one pass, against the
PLAN it can then trust.

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
Copy `templates/retcon-preanswer-sheet.md` to `Upcoming Prompts/retcon/<substep>-<session>.md` —
**unless a sheet for this session already exists, in which case continue it** (see *Resuming*
above) — and
fill one row per decision: the **drafted answer**, its **provenance** (every source that informed it — a
code path, a doc in `inputs/` with its trust level, the user's memory, or `inferred` / `unknown`),
and your **confidence**. Read the code; use the confirmed recon map and the per-asset notes for
orientation. This step is **human-free** — the one exception is a payload too big to enumerate under
the depth-dial posture, where you stop and escalate rather than silently sampling: state the cost of
deferring, in this system's terms, and let the user choose (Stage 1, *Deferring is a real choice*).

Name the sheet from the substep id exactly as its row in the PLAN carries it — a lettered
conditional keeps its letter (`1.7b-native-app.md`), the same way `prompts/README.md` names a
substep prompt `STEP-N.M-PROMPT.md` and treats a fractional substep like `5a` as an ordinary id.

Add rows the template never listed when the system raises decisions the generic list didn't foresee.
Mark a decision `unknown` rather than inventing an answer: an honest gap survives the confirm pass,
a plausible fabrication may not.

When every row has a drafted answer, **stamp the sheet `Status: Harvested`** before you go to the
user. That stamp is what a resumed chat reads to tell a finished harvest from an interrupted one.

### 4. Confirm with the user  ▸ checkpoint
Walk **every** row, proportionate to **confidence × consequence**: a high-confidence from-code
answer gets a fast "this is what the code does — right?", while a low-confidence or load-bearing one
gets a real discussion. Harvest and confirm normally run back to back, so nothing has moved in
between — but when a session is **resumed after a gap**, reconcile the sheet against any
`architecture/` doc confirmed since you drafted it first, and raise the conflict rather than quietly
picking a side.

Record each outcome in the sheet's **Confirm** column: *confirmed as-is*, *corrected: …*, or
*deferred* — as you walk each row, not in a batch afterwards, so an interrupted confirm pass leaves
an honest record of where it stopped. Never leave a row unwalked. Once every row has an outcome,
**stamp the sheet `Status: Confirmed`**.

**Deferring here works like deferring at the depth dial** (Stage 1): say what it costs before the
user chooses, then carry the warning into the doc's `Coverage:` line and — when the gap is genuinely
risky rather than merely incomplete — a `registries/risks.yml` row with a revisit trigger, so the
periodic check-in re-surfaces it (in that file's documented row shape, and pointing at the artifacts
named at `inv-5`).

**A deferral taken here is not a harvested decision, and it is not automatically an ADR.** It is a
live choice the user makes during adoption, so the no-reconstructed-ADRs rule doesn't apply to it —
but its record is the `Coverage:` line plus the `risks.yml` row, and that is normally the whole
record. Some session templates say otherwise: `1.6` Security asks you to capture every contested or
deferred decision as an ADR, "deferrals especially". Under adoption, treat that the way step 2 treats
any user-directed decision — propose it, don't assume it (*"want me to record that deferral as an
ADR?"*), and take a no gracefully. The `Coverage:` line and the risk row are written either way.

During adoption the risk lives in `risks.yml` only: do **not** add a backfill STEP to
`prompts/STEP-index.md`, which is held at its greenfield seed until the baseline lands, at which
point a deferred area becomes ordinary forward work like any other risk.

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
shows where and gives the shape) — one sentence saying what is missing, how big it is, and what it
means for someone building on this doc, **never a bare `deferred`**. That is the ordinary rule for
the field (`METHOD.md` §6), not an adoption one; it just carries more weight here, because a
baseline read out of a large existing system defers more than a greenfield one does.

Follow the session's `Output` section for the body, the doc number, and its filename — with the two
carve-outs already stated: **no edit to `prompts/STEP-index.md`**, whichever of its edits that
section asks for (step 1), and **no ADR for a harvested decision** (only a user-directed one, with
their approval).

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

The recon map already classified each document and recorded a **Disposition** for it. Those words
map onto the rules below: *ingest* → **lift** or **adopt**, *point-at* → **reference**, *summarize* →
**synthesize**, *flag stale* → record the drift as content. The map named the intent; these bullets
say what it means in practice.

- **The code still wins.** An input is secondary evidence, whatever its trust level in the recon map.
  Where it disagrees with what you read in the code, the code is the answer — and the disagreement
  itself is **content**: record the reality, and flag the doc as stale in that respect. Do not quietly
  average the two, and do not "fix" the input.
- **A finished, authoritative doc gets lifted** — a protocol or API spec, an interface contract, a
  design doc that is still true. Copy it into `architecture/` (whole-file, or a light reformat to fit
  the doc conventions) rather than leaving `architecture/` pointing at `inputs/`; from then on the
  `architecture/` copy is the living version and the original stays in `inputs/` as provenance. Three
  practical consequences. Every `architecture/` doc is `NN-kebab-title.md`, so a lift needs a number:
  take the **next free number above the core block**, the same rule a conditional session's output
  doc follows (`METHOD.md` §4) — never a `01`–`14` slot, which belongs to the session that owns it and
  would collide with the doc you are about to write. **Free means unused on disk *and* unclaimed in
  the PLAN.** An included conditional was given its output-doc number back at `inv-5`, long before it
  runs, so that number is spoken for even though no file carries it yet; skip it, and skip any number
  an earlier lift took. Record the number you take beside that input's row the way a conditional's is
  recorded, so the next lift and the next conditional both see it. It **needs the `Version` / `Status` /
  `Version Log` header** like any other architecture doc (`check.sh` check 4 reads every numbered
  doc, however it got there) — a whole-file copy of a spec rarely arrives with one, so add it. And a
  large external standard you don't own is the case where you **reference instead of lift**, per the
  same base rule.
- **A PRD, prior design doc, or research note is synthesized, not lifted** — you read it, and what
  survives appears in the doc you write. The input doesn't come across verbatim.
- **A real decision record is adopted into `adr/`, not synthesized away.** A team that wrote ADRs (or
  a dated decisions log) wrote them *at the time*, first-hand — that is evidence, not reconstruction,
  so the no-fabricated-history rule doesn't bar it; the rule bars inventing a record for a choice
  nobody wrote down. Copy each into `adr/` under this project's numbering, keep its original date and
  author, register it in `adr/README.md` (`check.sh` check 5 reconciles the two), and say in the doc
  that it predates adoption. It carries **`Accepted`** — the status means the system is living with
  this decision, which is exactly what you verified against the code; where the code shows the
  decision was later reversed, it is `Superseded by …` and names what replaced it. Reshape it into
  `templates/adr-template.md`'s sections only where that is lossless: a record that resists the
  shape keeps its original body under the standard header, since what you are preserving is
  first-hand testimony, not a format. Judgment: only for a record that was actually ratified and
  still describes a live decision. Something merely ADR-*shaped* — an unratified rationale note, a
  superseded proposal — is a design note: **synthesize** it. Either way the decision itself appears in
  your doc's **Decision Summary**, which is where a reader looks for "this is how it is".
- **A runbook is operational content, not architecture.** If it still matches what the code and infra
  do, it belongs in `runbooks/`; if it doesn't, leave it in `inputs/` flagged stale and record the
  real procedure where the owning session's doc covers it. Don't fold a procedure into an
  `architecture/` doc to avoid deciding.
- **Update the ledger either way.** Flip that input's `inputs-index.md` row to record what
  `architecture/` has now superseded and what still holds, so a later session builds on current
  material rather than re-reading a stale seed.
- **Don't retire anything yourself.** A fully-superseded input is a *candidate* for `inputs/archive/`
  — say so and let the user decide, exactly as the periodic check-in does. Retiring is a move, never
  an edit or a delete, and never automatic.

### `1.1` also fills in `overview.md`
Greenfield gets its **project brief** from the kickoff interview: `BOOTSTRAP-PROMPT.md` asks who this
is for, what it does, what it deliberately doesn't, and writes `Code/{{PROJECT}}-docs/overview.md`.
Adoption skips that interview by design — so unless `1.1` fills the brief, the project lands with
`overview.md` still the blank template, section comments and *"open that copy and fill it in"*
scaffolding and all. That file is the first thing every later session, the planning session, and
every check-in reads, so leaving it blank is not a cosmetic gap.

`1.1` is where the content already exists. Its decision list *is* the brief's material — problem,
users, success criteria, scope and non-goals, constraints, risks — and by the end of step 5 all of it
has been harvested from the code, walked with the user, and written into
`architecture/01-system-overview.md`. So after that doc is written, **transcribe it down into
`overview.md`**: fill each brief section from the confirmed doc, in plain language, and delete the
template's explanatory comments and its "this is the template" preamble as you go. Where the brief
asks something the doc genuinely doesn't answer yet, say so in a short line rather than inventing it
(*"~40 internal users today; growth expectations covered at 1.5"*) — later sessions deepen
`architecture/`, and nothing comes back to rewrite this file.

Three things to leave exactly as they are: the `PROJECT-STATUS` and `CHECK-IN-CADENCE` marker
comments (live machinery — `status.sh` and `AGENTS.md` read them), and the **Release stage / launch
target** line, which Stage 1 already wrote from intake.

This is a **transcription, not a second interview** — every answer was confirmed row by row minutes
ago, so don't re-ask any of it. Show the user the filled brief once and let them correct the voice:
it is their document, and it is the one artifact here written for a human arriving cold rather than
for the method.

### `1.7` documents the design system that already exists
Read `1.7`'s `## How this session works` as an *interview procedure*, not as its lens, and don't
follow it here. It tells a greenfield run to generate rendered HTML option pages in a temporary
`ui-design/` folder, offer three or four labelled directions per decision, and wait for the user to
pick — machinery for reaching a decision nobody has made yet. This system already made them: the
palette, the type scale, the spacing, the component set, the navigation pattern are all sitting in
the code, the stylesheets, the design tokens, or the component library.

So harvest and **document what is there**. Its decision list is still the right work list — walk it,
read each answer out of the code, and confirm it. **No option pages, no `ui-design/` folder, no
asking the user to choose** anything the product already ships. Accessibility and localization are
harvested the same way: record what the code actually does, not what it should do.

Where the code genuinely has no answer — no accessibility story, no localization, no documented
component set — that is a **gap to record**, exactly like any other as-built gap: state the reality,
flag it, and let the forward work decide. Don't design it now; a baseline describes.

### The sessions that need a word about the float
Floating Phasing changes what the earlier sessions that read it can read, and gives Phasing itself a
different job. Nothing about their templates changes — these are the notes the wrapper adds when it runs them.

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
  Leaving the placeholder unresolved would strand the baseline at archive time. Do it exactly as the
  kickoff does at the same heading (`BOOTSTRAP-PROMPT.md`): set the name **and delete the
  explanatory comment beneath it**, so an adopted index and a greenfield one of the same age read
  the same.

> `1.14`'s side of this — reconciling Phasing against `1.3`/`1.5` once all three exist, and turning
> foreclosure into gap analysis — belongs to the Cross-Cutting Review, in the increment below.

> **When you reach `1.14` and Stage 4 is not present in this prompt, STOP.** Report that the
> architecture baseline (Stages 1–3) is complete — every in-scope session harvested, confirmed, and
> written — and that the Cross-Cutting Review and the baseline land are pending a future build
> increment, then wait. Do **not** improvise the land: leaving `PROJECT-STATUS: retcon` in place and
> the STEP index at its seed is the correct, resumable state.
