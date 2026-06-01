# The Method

**Method version: 0.1 (beta)** — still early; expect refinement, especially the collaboration layer.

> Built with **Throughstone** — this file and the other scaffold files (`templates/`,
> `runbooks/`, `scripts/`) are © 2026 Mark A. Herschberg under BSD-3-Clause; the full text is
> retained as `LICENSE-THROUGHSTONE` in this docs hub. Your own application code is under the
> license you chose at setup.

How projects built with this scaffold are structured. This is the canonical reference;
the agent reads it to understand how to work. Read it once before you start.

The core idea: **decide and document the architecture before writing code**, break the
work into small runnable units, and keep a durable record of *what* the system is and
*why* it's that way.

---

## 1. The three tiers of work

```
Phase            e.g. Phase 1 = "MVP"          a release-level milestone
  └─ STEP        e.g. STEP-1, STEP-2, STEP-87  a unit of work with a PLAN
       └─ Substep  e.g. 1.1, 1.5a               a single self-contained task
```

- **Phase** — a release-level container. *Phase 1 is your MVP.* Later phases (Phase 2,
  Phase 3, …) are larger bodies of work you've deliberately deferred. Phases live as
  folders: `prompts/001-mvp/`, `prompts/002-<name>/`.

- **STEP** — the main unit of work. Every STEP has a **PLAN** that lists its substeps,
  the decisions already locked, ground rules, and a definition of done. STEP numbers are
  **global and never reset** — Phase 3 might open at STEP-87. A STEP ends in a review. Its
  status moves through **Planned → In progress → Done**, or **Abandoned** if it was reserved
  but won't be built (the row stays so its number is never reused — see §8). These four are
  the only STEP states.

- **Substep** — the smallest unit: one focused task, written so it can be executed cold
  in a fresh chat. Numbered with dotted notation (`1.1`, `1.2`, `1.5a`). For the
  architecture STEP, each substep is an interactive **session** (see §4).

## 2. Architecture-first

**STEP-1 produces architecture docs and ADRs — no application code.** This is the most
important discipline in the method. You lock the shape of the system (what it does, how
it's structured, how it scales, how it's secured) before building, so you're not
rearchitecting on top of code later.

Only once the architecture is in place do later STEPs implement against it. The bridge
between the two is the **implementation planning session**
(`templates/planning-session.md`, run by name: *"run the planning session"*): after STEP-1
closes, it reads the locked architecture and **outlines all the Phase-1 implementation
STEPs** (a short scope each) into `prompts/STEP-index.md`. Each STEP's detailed PLAN is
written later, when you start it.

## 3. The two durable doc genres

Everything lives in the docs hub: `Code/{{PROJECT}}-docs/`.

| Genre | Location | Answers | Lifecycle |
|-------|----------|---------|-----------|
| **Architecture docs** | `architecture/NN-*.md` | *What is the system?* | Living. Versioned (see §6), maintained as reality changes. |
| **ADRs** | `adr/ADR-NNNN-*.md` | *Why is it this way?* | Point-in-time. Never rewritten — superseded or amended. |

- **Architecture docs** are the single source of truth for the current design. When
  something changes, you update the doc and bump its version log.
- **ADRs** capture a decision at the moment it's made — context, the choice, alternatives
  rejected, consequences. You don't edit an ADR's decision later; you write a new ADR that
  supersedes it, or append a dated amendment. There's an index at `adr/README.md`.

Other folders in the hub: `coding-standards/` (per-language; defaults ship for common
languages, and session 1.11 reconciles them to the stack you pick — review what's there,
add what's missing, prune the rest), `runbooks/` (repeatable procedures — ships with
`check-in.md` and `collaboration.md`; add your own operational ones), `registries/`
(e.g. `repos.yml`, the repo inventory for multi-repo projects).

## 4. Architecture sessions

Each substep of STEP-1 is a **session**: an interactive interview prompt that walks you
through the decisions for one architecture area and writes the resulting doc. The full
set lives in `templates/architecture-sessions/`.

**Core sessions (default):**

| # | Session | Produces |
|---|---------|----------|
| 1.1 | System overview, requirements & non-goals | `architecture/01-*` |
| 1.2 | Phasing & roadmap | `architecture/02-*` |
| 1.3 | Architecture overview & component boundaries *(asks which client surfaces — gates UI + app)* | `architecture/03-*` |
| 1.4 | Data model, ownership & retention | `architecture/04-*` |
| 1.5 | Scaling & performance | `architecture/05-*` |
| 1.6 | Security & threat model *(deferrable — but as a recorded, conscious decision)* | `architecture/06-*` |
| 1.7 | UI / design system *(platform-aware; "no UI" → skip)* | `architecture/07-*` |
| 1.8 | Infrastructure & deployment | `architecture/08-*` |
| 1.9 | Environments *(sandbox is a question inside)* | `architecture/09-*` |
| 1.10 | Observability | `architecture/10-*` |
| 1.11 | Test strategy | `architecture/11-*` |
| 1.12 | Glossary | `architecture/12-*` |
| 1.13 | Cross-cutting review | review doc |

**Conditional sessions** (included only when relevant, auto-selected by the 1.3 platform
question or by need): **Native app architecture** (mobile/desktop), **Identity & auth**.

### Running a session  *(Layer 1 — works in any agent)*

To run an architecture session, tell your agent:

> run session 1.1

The agent reads the matching file in
`Code/{{PROJECT}}-docs/templates/architecture-sessions/NN-*.md` and follows it exactly:
it interviews you one decision at a time, then writes the output doc and updates
`STEP-index.md`. No copy-paste, no special commands.

Each session reads what it needs (`overview.md` + earlier architecture docs) from disk, so
**you can clear the chat / start fresh between sessions** — the state lives in files, not
in the conversation. This keeps STEP-1's many sessions from piling up in one context.

### Sessions are re-runnable
A session isn't a one-time gate. If an assumption changes later — scaling needs grow, the
threat model shifts, a phase gets re-cut — **re-run that session** (*"run session 1.5"*).
It re-interviews you, **revises the existing architecture doc in place, and records the
change in that doc's Version Log** (and a new ADR if the decision is significant — the old
ADR is superseded, not edited). Re-running is the normal way the living docs stay true as
the project learns; it's not a sign something went wrong the first time.

### Calibrating to the user's experience level
The kickoff (`BOOTSTRAP-PROMPT.md`, Stage 0) asks the user how much experience they have
building a project like this and records it in `overview.md`: **Level 1** (no coding
experience), **Level 2** (basic coding experience), **Level 3** (senior developer or above).
Every session reads `overview.md` first, so each one sees this and **adjusts how it asks** —
the decisions reached are the same; only the explaining changes:

- **Level 1–2** — before each question, say in plain language *what* it's asking and *why* it
  matters, and lead with a recommended default. Don't assume jargon: concepts like scaling,
  security, threat model, infrastructure, and environments get a one-line "here's what this
  means for you" framing rather than being named and left bare.
- **Level 3** — assume fluency; keep it terse and decision-focused.
- **At any level**, the user can ask for a question to be unpacked — and they won't use a
  set phrase. Treat *any* sign of confusion or request to clarify as the cue: "what do you
  mean?", "why does that matter?", "huh?", a hesitation, a guess that misreads the question,
  or a literal *"explain what you're asking and why it matters."* Give the Level-1/2
  explanation on the spot, then re-ask. **Say so up front** — when you set the level (or at
  the first session), tell the user in plain terms that they can ask you to explain any
  question at any time; don't make them discover the affordance.

The level is advisory, not a gate: if the conversation shows the user is more or less
comfortable than they marked, adjust on the fly and correct the value in `overview.md`.

**Worked examples** — the *same* canonical question, rendered at each level. The substance is
identical; only the framing changes. Notice the recurring moves: Level 1 names the failure it
prevents and ends with a yes/no default so the user is never facing a blank prompt; Level 2
keeps the term but defines it inline the first time; Level 3 is terse and surfaces the
interesting trade-off, not the basics.

> *Non-goals (Session 1.1):*
> - **L1:** "Now the most important — and strangest — question: what are you deliberately **not** building, at least for now? Naming what you skip is the #1 thing that stops a project ballooning forever and never shipping. Two buckets: 'not yet' (good for later) and 'never' (just not what this is). One feature you'd firmly set aside for v1?"
> - **L2:** "Let's pin down non-goals — what you're deliberately leaving out, since that's what stops scope creep. Split 'not now' (deferred) vs. 'not ever' (out of scope by design). What's on each list?"
> - **L3:** "Non-goals — split 'not now' vs. 'not ever'. What are you explicitly excluding from v1?"

> *Threat model (Session 1.6):*
> - **L1:** "Now security. The common mistake is 'we're too small for anyone to attack us' — but most attacks are automated bots probing *everything*, not personal. So: if someone broke in, what would hurt most — leaking users' info, tampering with data, or the site going down? You don't need to know how to defend it, just what matters most."
> - **L2:** "A lightweight threat model. Skip the 'too small to be a target' instinct — anything public gets probed automatically. Name the assets worth protecting and the top threats: what would do the most damage if it leaked, got tampered with, or went down?"
> - **L3:** "Threat model — assets, trust boundaries, threats you actually care about. Crown-jewel data, and your stance on authn/authz, secrets, tenant isolation?"

> *Observability (Session 1.10):*
> - **L1:** "How will you *know* the app is healthy once people use it? The trap: it breaks, and the only signal is angry users — and even then you can't tell why. The fix is leaving yourself a trail of breadcrumbs to answer 'what happened?'. For v1 I'd suggest just good logs plus an alert if the site goes down. Enough to start?"
> - **L2:** "Observability — how you'll see what the system is doing in production; the failure mode is 'users told us it broke and we can't tell why.' Logs (what happened), metrics (is it healthy), alerts (tell me when it's not). For an MVP I'd default to structured logs + an error/uptime alert and add dashboards later. Start there?"
> - **L3:** "Observability — logs/metrics/traces and alerting. SLOs now or later? I'd default to structured logging + error tracking + an uptime alert for the MVP and defer tracing/SLOs unless you're latency-sensitive."

## 5. The prompt lifecycle

```
Upcoming Prompts/      ← the STEP you're working on now (work-in-progress)
        │  (STEP completes + review passes)
        ▼
prompts/001-mvp/step-NNNN/ ← archived: STEP PLAN + all substep prompts, kept for the record
```

- `prompts/STEP-index.md` is the **living roadmap** — every STEP, its status, one-line
  scope. It's the first place to look to understand where the project is.
- `prompts/README.md` holds the **conventions + the recipe for authoring a new STEP**.

**`prompts/` is history; the docs repo is state.** That's why they're separate repos.
`prompts/` records *how* the project was built, STEP by STEP — it spans all the code repos
in the project and is never rewritten. `Code/{{PROJECT}}-docs/` describes *what the system
is now* — it's kept current. Don't fold one into the other.

- **`prompts/` is its own repo** (project-wide; it cuts across the code repos).
- **`Upcoming Prompts/` is a workspace folder, not generally a repo** — it's scratch space
  for the STEP in flight, un-versioned until the STEP completes and is moved into
  `prompts/`. (You *can* make it a repo if you want in-flight work versioned; most don't.)
  It's the one allowed working folder at the workspace root (see §7 hygiene).

### Authoring and revising a STEP
A STEP's **PLAN and all its substep prompts are written together in a single chat** — that
session holds the whole STEP in mind, so the substeps are coherent. But they are **not
frozen**: while executing the substeps, decisions made in an earlier substep often change
what a later substep should do. Update the affected substep prompts (and the PLAN) as you
go — the prompts should reflect the current intent, not the original guess.

### Check-in STEPs
Roughly **every 10–20 STEPs**, the roadmap includes a **Check-in STEP** — a full STEP whose
job is to run `runbooks/check-in.md`: reconcile the architecture docs against the code in
**both directions** (stale doc → fix the doc/write an ADR; code drifted from a still-correct
doc → file a bug) and **run the full test suite**. The implementation planning session
interleaves these when it outlines a phase, placing each at a sensible breakpoint (after a
capability lands, not mid-feature). Treat 10–20 as a guideline — pick the breakpoint by
judgment. The agent should also **proactively suggest** inserting a check-in when about that
many STEPs have passed since the last one. This is the periodic safety net; it's separate
from the continuous rule that every substep updates the doc it changes.

## 6. Versioning architecture docs

Each architecture doc carries:
- **`Version:`** — `major.minor.patch`. Bump *patch* for fixes/clarifications, *minor*
  for added sections/decisions, *major* for a maturity era change.
- **`Status:`** — the maturity era: **Draft** (`v0.x`, pre-MVP, shape unstable) →
  **MVP** (`v1.x`, describes what's built) → **Stable** (`v2.x`, ready for outside
  consumers).
- A **Version Log** table at the bottom: one row per change (version, date, STEP, what).

ADRs are *not* versioned this way — they're dated, carry a Status (Accepted / Superseded /
…), and accumulate appended amendments.

## 7. Repos & the workspace shell

Projects are typically **multi-repo**: the workspace folder is *not* itself a repo;
inside it, `prompts/` is one repo and each thing under `Code/` (including
`{{PROJECT}}-docs`) is its own **sibling** repo. Nothing sits "above" those repos except a
per-machine shell. The `init.sh` wizard sets this up for the first developer; service repos
aren't created at bootstrap — they're stamped from
`Code/{{PROJECT}}-docs/templates/repo-readme.md` once the architecture names them. (Or choose
mono-repo-for-now in the wizard — see *Mono-repo for now* below.) For multi-repo projects,
`registries/repos.yml` is the canonical inventory. **Every repo carries a README explaining
what it is** — its role and the slice of the system it owns — stamped from that template and
filled in when the repo is scaffolded (with a matching one-line `description` in
`registries/repos.yml`); a repo with real internal complexity adds an `ARCHITECTURE.md` at
its root for its internal design.

**All durable content lives in a repo** — almost always `Code/{{PROJECT}}-docs/`. The
workspace root holds only **per-machine** files: the pointer `CLAUDE.md` / `AGENTS.md`
(which redirect to the canonical `Code/{{PROJECT}}-docs/AGENTS.md`) and `.claude/` config.
These are not versioned (the root is not a repo) and are regenerated on each developer's
machine by `Code/{{PROJECT}}-docs/scripts/setup-workspace.sh`.

**Workspace-root hygiene:** besides the per-machine pointers/config, the repo folders, and
the `Upcoming Prompts/` working folder, no other file should sit at the workspace root (the
one-time `init.sh` may linger there until you delete it post-bootstrap — that's expected). If
any *other* file appears, ask whether it belongs in a repo (usually the docs hub) and move it.

**Path conventions in docs.** Top-level agent-facing docs (`AGENTS.md`, `BOOTSTRAP-PROMPT.md`,
this file) write paths **relative to the workspace root** — `Code/{{PROJECT}}-docs/architecture/…`,
`prompts/STEP-index.md`. The exception is the **session and template files** under
`templates/`: because they live and operate inside the docs hub, they write hub-local paths
(`architecture/04-*.md`, `adr/`, `overview.md`) relative to the hub. Either way, a reference
that **crosses into another repo is always written in full** — most notably
`prompts/STEP-index.md`, which lives in `prompts/`, never the hub, so it is never written bare.

**Mono-repo for now:** the wizard offers a single-repo start — then the **workspace root
itself is that one repo** (the lone exception to "the root is not a repo" above), with
`prompts/` and `Code/{{PROJECT}}-docs/` as folders inside it rather than sibling repos. In
this mode the root pointers (`CLAUDE.md` / `AGENTS.md`) are just ordinary committed files, not
per-machine artifacts, and the hygiene rule relaxes to match. It's a convenience for getting
moving solo; the multi-repo layout is the target. **Team collaboration assumes multi-repo.**
What a team actually needs is **shared remotes** (so the push-reject that referees STEP-number
reservation can fire — `runbooks/collaboration.md` §2); on top of that, the overlap warning
(§4 there) is repo-granular, so it's meaningless when every STEP touches the one mono-repo. So
split before you go team. Splitting later is standard git (extract `prompts/`
and the docs hub into their own repos); afterward, fill in the `remote:` fields in
`registries/repos.yml` and have others run `scripts/setup-workspace.sh`.

**Working with others:** every STEP is worked on its own branch (`step-NNNN-short-name`, same
name in every repo it touches) — **solo too**, so the workflow doesn't change the day a second
contributor arrives. The payoff is that when more than one developer or agent *is* active,
concurrent STEPs are the normal case — git keeps them isolated. The main thing that must be coordinated is
the **global STEP number**: adding a STEP row to `prompts/STEP-index.md` *is* reserving its
number, so it's committed and pushed **before** branching, and the loser of a race renumbers.
**ADR numbers are reserved the same way** — the registry in `adr/README.md` is shared, so two
authors appending the same number merge into a silent duplicate unless they renumber.
Decisions are socialized through ADRs (`Proposed` → `Accepted` in a team). Full conventions —
shared-file editing, the overlap warning, ADR authority, solo→team onboarding — are in
`runbooks/collaboration.md`.

## 8. Naming conventions

| Thing | Pattern | Example |
|-------|---------|---------|
| Phase folder | `NNN-kebab-name/` | `001-mvp/` |
| STEP folder (archived) | `step-NNNN/` | `step-0001/`, `step-0087/` |
| STEP plan | `{{PROJECT}}-STEP-N-PLAN.md` | `acme-STEP-1-PLAN.md` |
| Substep prompt | `{{PROJECT}}-STEP-N.M-PROMPT.md` | `acme-STEP-1.5a-PROMPT.md` |
| Architecture doc | `NN-kebab-title.md` | `06-security-model.md` |
| ADR | `ADR-NNNN-kebab-title.md` | `ADR-0004-pick-postgres.md` |
| STEP branch | `step-NNNN-short-name` | `step-0042-payment-webhooks` |

All filenames are kebab-case Markdown. A STEP number is written **unpadded in prose and the
index** (`STEP-7`) but **zero-padded to four digits in folder and branch names**
(`step-0007/`, `step-0007-short-name`). STEP numbers are global; architecture doc and ADR
numbers are sequential and never reused. (An abandoned STEP keeps its number — mark its index
row **Abandoned**, never delete it — so `max + 1` never reissues the number.) **Each STEP is
worked on its own branch** (above) —
the same branch name in every repo the STEP touches, even when you're working solo (it makes
concurrent work collision-free the day a second contributor arrives; see §7 and
`runbooks/collaboration.md`).

## 9. Updating the method itself

This file and the templates/runbooks beside it were **copied into your project** at
bootstrap — they're yours to edit, and upstream improvements to the Throughstone
template don't reach you automatically. Chasing them is rarely worth it, but if you ever want
a later improvement: compare your **Method version** (top of this file) against the upstream
template and hand-copy in the process changes you want, bumping the version when you do. Pull
only *process* (this file, `templates/`, `runbooks/`) — never your own `architecture/`,
`adr/`, `overview.md`, or `prompts/`.

## 10. What to do next (the next-action resolver)

The next action is always derivable from **disk**, never from chat memory — so any agent in a
fresh chat (and any teammate who just joined) can answer *"what do I do next?"* by reading
`prompts/STEP-index.md` (plus the in-flight PLAN in `Upcoming Prompts/` for sub-STEP
granularity). Every session and STEP also **ends by stating the next action** and telling you
to start a fresh chat for it — clearing context between units is the norm, since the state
lives in files (§4, §5).

Resolve the next action top-down against the index — the first rule that matches wins:

1. **STEP-1 has a `Planned` / `In progress` substep?** → run the lowest-numbered open one:
   *"run session N.M"* in a fresh chat. Skip any substep marked `N/A`. A substep with a
   **letter suffix** (e.g. `1.6a`, `1.7a`) is a **conditional session** the kickoff slotted
   in — invoke it **by name** (*"run the identity-auth session"* / *"run the native-app
   session"*), since its template file is named by topic, not by number (see §4).
2. **All STEP-1 substeps done but 1.13 not?** → *"run session 1.13"* (cross-cutting review).
3. **1.13 done and STEP-1 complete, but only the STEP-1 row exists?** → *"run the planning
   session"* — it outlines the Phase-1 implementation STEPs (§2).
4. **Implementation STEPs outlined (`Planned`) but none `In progress`?** → start the
   lowest-numbered `Planned` STEP: author its PLAN + substep prompts (`prompts/README.md` →
   "Recipe: adding a new STEP"), in a fresh chat.
5. **A STEP is `In progress`?** → open its PLAN in `Upcoming Prompts/` and run its lowest
   open substep: *"run substep N.M"*. When the last substep is done, run the STEP's review,
   then archive it (§5) and mark it `Done`.
6. **~10–20 STEPs since the last check-in?** → propose a **Check-in STEP** at the next
   sensible breakpoint (§5; `runbooks/check-in.md`).
7. **The phase is complete?** → open the next phase and re-run the planning session for it.

When the index and an in-flight PLAN disagree, the **index** is authoritative for *which
STEP* is next; the **PLAN** owns *which substep* within it.
