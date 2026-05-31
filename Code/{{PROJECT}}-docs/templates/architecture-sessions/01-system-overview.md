# {{PROJECT}} — System Overview, Requirements & Non-Goals (Session 1.1)

> **How to run:** Tell your agent *"run session 1.1"* (or *"read and run this file"*).
> It interviews you one decision at a time, then writes
> `architecture/01-system-overview.md` and updates `prompts/STEP-index.md`.
> Have `overview.md` (your 1–2 page brief) available — the session starts from it.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}
<!-- The kickoff fills this from overview.md. Running standalone? Read overview.md first. -->

## What this session does
We'll nail down *what* you're building and — just as important — what you're deliberately
*not* building: the problem, who it's for, how you'll know it works, and what's out of scope.

## Why this session matters
This is the foundation every other architecture doc builds on. The two things developers
most often skip:
- **Non-goals.** Writing down what you are *deliberately not* building is what stops scope
  creep. "We'll figure out scope as we go" is how projects never ship.
- **Success criteria.** If you can't state how you'll know it works, you can't tell when
  you're done — or whether it's healthy in production.

No code in this session. The output is a Markdown doc.

## How this session works
1. **One decision at a time.** Ask, show 2–4 concrete options/examples where useful, then
   **wait for the answer**. Don't assume.
2. **Start from what's known.** Pull everything you can from `overview.md` first; ask only
   what's missing or ambiguous. Don't re-ask what the brief already answers.
3. **Recommend, then flag the tradeoff.** Where there's a sensible default for a project at
   this stage, propose it — but say what it rules out later.
4. **Push gently on vague answers.** "It should be fast" / "for everyone" → ask for
   something concrete.

## Decisions to make (in order)

### Problem & value
1. **The problem.** In 2–3 sentences: what does {{PROJECT}} solve, and why now?
2. **Users & stakeholders.** Primary personas (1–3)? Who else is affected (admins, ops,
   compliance, your customers' customers)?
3. **Success criteria.** How will you know it works? Push for *measurable* outcomes
   ("new user completes X in under N minutes", "handles N requests/day"), not vanity metrics.

### Scope
4. **Core capabilities.** What must the first usable version do? Must-haves only — the
   things without which it isn't the product.
5. **Non-goals.** What are you deliberately NOT doing? Separate "not now" (deferred to a
   later phase) from "not ever" (out of scope by design). *Most important question here.*
6. **Constraints.** Regulatory/compliance, budget, timeline, team size & skills, systems
   you must integrate with or can't change.

### Foundations
7. **Assumptions.** What are you taking as given that, if wrong, would change the design?
   (Expected scale, available infra, third-party reliability, who owns what.)
8. **Key risks & open questions.** What's most likely to go wrong or is still unknown?
   These feed the roadmap (1.2) and the other sessions.

## Output
Write `architecture/01-system-overview.md` using
`templates/architecture-doc.md`. Body sections, in order:
- **Problem & Value** — the problem statement and why now
- **Users & Stakeholders** — primary personas + others affected
- **Success Criteria** — measurable
- **Scope** — a table with three columns: *Core (in)* | *Not now (deferred)* | *Not ever*
- **Constraints**
- **Assumptions**
- **Risks**

Then fill the **Decision Summary** (all 8 decisions + answers), record any **Open
Questions** for later sessions, and start the **Version Log** at v0.1.0.

Finally, update `prompts/STEP-index.md`: mark substep 1.1 done and note open questions carried
forward. If any decision was significant and contested (e.g. a deliberate "not ever"),
consider capturing it as an ADR using `templates/adr.md`.

## Next
Once 1.1 is marked done, **first give the user a quick map of what's ahead** so they have a
sense of the scope before continuing. Show this list of the remaining architecture sessions
(each is its own short, focused chat; some may not apply to this project — note any the plan
already marked skipped/N/A):

- **1.2 Phasing & roadmap** — what the MVP includes vs. what's deferred to later phases
- **1.3 Architecture overview** — the system's main components and how they connect
- **1.4 Data model** — the key data, who owns it, retention, what's sensitive
- **1.5 Scaling & performance** — making sure the MVP won't block later growth
- **1.6 Security & threat model** — what could go wrong and the protections needed now
- **1.7 UI / design system** — visual style and reusable UI building blocks (skip if no UI)
- **1.8 Infrastructure & deployment** — where it runs and how code gets there
- **1.9 Environments** — dev vs. prod and how config/secrets differ
- **1.10 Observability** — what to log, measure, and alert on
- **1.11 Test strategy** — what tests you'll write and what gates a merge
- **1.12 Glossary** — pinning down the precise meaning of key terms
- **1.13 Cross-cutting review** — a final pass checking it all hangs together

Mention that two **conditional** sessions slot in by name when they apply — **identity & auth**
(if there are user accounts / access control) and **native app** (if there's a mobile or
desktop app). The roadmap session (1.2) and the index confirm which sessions are in play.

Then point them at the next action — normally **1.2 (Phasing & roadmap)**. Tell the user to
**start a fresh chat** and run it (*"run session 1.2"*); if the index shows a different next
open substep (sessions can be skipped or added), run that instead. See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
