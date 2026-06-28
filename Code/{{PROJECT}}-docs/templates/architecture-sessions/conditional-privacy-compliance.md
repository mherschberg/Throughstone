# {{PROJECT}} — Privacy, Compliance & Data Governance (Conditional Session)

> **Conditional.** Include this if the project handles **personal or regulated data** — any
> meaningful PII, or special-category data (health, financial, biometric, children's), or
> falls under a compliance regime (GDPR/UK-GDPR, CCPA/CPRA, HIPAA, PCI-DSS, COPPA, SOC 2,
> sector rules). The kickoff slots it in as a substep (e.g. `1.6b`, after the security
> session) and the index records its number. Run it by name: *"run the privacy session"* (or
> *"run the privacy-compliance session"*). It writes `architecture/NN-privacy-compliance.md`
> (number assigned in the STEP-1 index when run there, or in the follow-up PLAN when run
> later) and updates `prompts/STEP-index.md`.
> It may also be scheduled later as its own follow-up STEP when a periodic check-in finds
> that privacy/compliance has become applicable. In that mode, use the follow-up STEP's
> status and review bookkeeping rather than reopening STEP-1.
> **Two separate numbers:** the *substep* number (e.g. `1.6b`) marks its place in STEP-1; the
> *doc file* number (`NN`) is the next free number **above the reserved core-doc block** — the
> standard sessions reserve a contiguous block at the front (the current core set is the session
> table in `METHOD.md` §4), and each conditional takes the next free number above that block
> if another conditional already claimed the first one — **not** the lowest unused number.
> (This session may run early, before the later core docs
> exist; still take the first free number above the core block, so a not-yet-run core session keeps
> its own reserved slot without a clash.) The substep number and the doc number don't have to match.
> Reads `overview.md`, the Data Model architecture doc (`architecture/*-data-model.md`), and
> the Security & Threat Model architecture doc (`architecture/*-security-threat-model.md`)
> first; also read the Infrastructure & Deployment architecture doc
> (`architecture/*-infrastructure-deployment.md`) if it already exists, especially in
> follow-up mode. Read the active STEP PLAN in `Upcoming Prompts/` when this is a later
> follow-up.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Building on the data model and threat model, we'll decide how {{PROJECT}} handles **personal
and regulated data lawfully and responsibly** — which rules apply, what data you hold and
why, how long you keep it, and how you'll honor the rights people have over their own data.

## Why this session matters
The Security & Threat Model session asks "how do we keep attackers *out*?" This one asks a different
question: "are we handling people's data *lawfully and responsibly*?" — and that's where the
fines, the lawsuits, and the trust damage come from. The common mistake is treating privacy
as a checkbox bolted on before launch; in reality it's an *architecture* decision, because
"collect everything, keep it forever, figure out deletion later" bakes in obligations you
then can't meet. Deciding the regimes, the data you hold, retention, and how you'll satisfy
deletion/export requests **now** keeps compliance a design property rather than an emergency.

## How this session works
- One decision at a time; **wait** for answers.
- Recommend the **least data, least retention, clearest purpose** option that meets the need,
  and flag what each choice obligates you to.
- Keep it consistent with the Data Model architecture doc and the Security & Threat Model
  architecture doc; flag where a choice ties to Infrastructure & Deployment residency
  decisions, or needs to feed the Infrastructure & Deployment session if that doc does not
  exist yet.
- This is **not legal advice** — it produces an engineering record of intent and surfaces
  where a lawyer or DPO should confirm. Say so when a question turns on a legal judgment.

## Decisions to make (in order)
1. **Applicable regimes.** Given your users, your data, and where they are, which laws and
   standards apply — GDPR/UK-GDPR, CCPA/CPRA, HIPAA, PCI-DSS, COPPA (children), SOC 2, sector
   rules? Name them, or consciously record "none apply, and why." Everything below follows
   from this. (When it turns on a legal judgment, flag it for a lawyer rather than guessing.)
2. **Personal-data inventory.** What categories of personal data you collect, where each
   lives, and how sensitive it is (ordinary PII vs. special-category: health, financial,
   biometric, children's). This is the privacy lens on the Data Model architecture doc — you can't
   govern what you haven't named. A simple table is the deliverable.
3. **Lawful basis & consent.** For each category, *why* you're permitted to process it
   (consent, contract, legitimate interest, legal obligation…), and — where it's consent —
   how consent is captured, recorded, and **withdrawn** (cookie/tracking consent included).
4. **Data minimization & purpose limitation.** Collect only what you need; use it only for
   what you told people. Walk the inventory and challenge each field: do you actually need it,
   and for what stated purpose? Dropping a field now is the cheapest control there is.
5. **Retention & deletion.** How long each category is kept, and how it's actually deleted
   when the period ends and on account closure (including backups and downstream copies).
   This sharpens the retention answer from the Data Model architecture doc with the legal *must-delete* angle.
6. **Data-subject rights.** How you'll satisfy access, export/portability, correction, and
   deletion ("right to be forgotten") requests — as an *operational process*, not a promise.
   Manual is fine for an MVP **if it's written down** and someone owns it.
7. **Data residency & sub-processors.** Where data physically lives (residency/sovereignty
   constraints) and which third parties (analytics, hosting, payment, email, AI APIs) receive
   personal data — your sub-processors — plus a transfer mechanism if data crosses borders.
   Ties to the Infrastructure & Deployment architecture doc.
8. **Governance & accountability.** Who owns privacy, where the record-of-processing / data
   map lives and stays current, your **breach-notification** obligations (who you must notify
   and how fast), and the plan for a public **privacy policy** (and a DPA where required).
   Lightweight for an MVP — but assigned to a name, not left ownerless.

## Output
Write `architecture/NN-privacy-compliance.md` (use `templates/architecture-doc-template.md`; NN per
the active STEP's index/PLAN). If the doc already exists, revise it in place and bump its
Version Log instead of creating a second privacy/compliance doc. Body covers each area above
— lead with the **applicable-regimes** decision and the **personal-data inventory** table,
since the rest follows from them. Fill the **Decision Summary**, record **Open Questions**
(flag any awaiting legal/DPO confirmation), and capture significant choices as **ADRs** —
applicable regimes, data residency, retention periods, and any consent/sub-processor decision
that consumers depend on. Cross-check retention against the Data Model architecture doc and
residency against the Infrastructure & Deployment architecture doc if it exists; otherwise,
record the residency constraint as an input to the Infrastructure & Deployment session. Note
any updates those docs need. If this is a later follow-up STEP, add or update this doc's row
in `architecture/README.md`. Update
the active PLAN to mark this substep done. In STEP-1 mode, also mark the lettered substep
done in `prompts/STEP-index.md`. In follow-up mode, keep the parent STEP `In progress` there
until its review and normal completion bookkeeping are finished.

## Next
If this session was slotted into STEP-1, mark its lettered substep done; the next action is
the lowest open STEP-1 substep in the index. If the Cross-Cutting Review discovered it, that
review remains open and must restart from the beginning after this session. If a periodic
check-in scheduled this as a later follow-up STEP, complete that STEP's normal review and
bookkeeping instead of modifying STEP-1; re-run the planning session before more
implementation work if these decisions change the remaining roadmap. Tell the user to
**start a fresh chat** for the next action from the resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run the privacy session" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md`, the relevant architecture docs, and any active follow-up PLAN silently; the PLAN determines the execution mode and output-doc number when this is not part of STEP-1. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
