# {{PROJECT}} — Security & Threat Model (Session 1.6)

> **How to run:** Tell your agent *"run session 1.6"*. It interviews you one decision at a
> time, then writes `architecture/06-security-threat-model.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md` and `architecture/03-*`, `04-*` first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Given the components and data from the last sessions, we'll work out what could realistically
go wrong security-wise and the protections this first version actually needs — no fortress,
but no negligence either.

## Why this session matters
"We're too small to be a target" is the most common — and most wrong — security
assumption. Anything on the public internet gets probed automatically; attackers don't
check your user count first. You don't need a fortress for an MVP, but you do need to know
your **assets, your boundaries, and the threats you're choosing to accept**. This session
can end in a *deliberate, recorded* deferral — but deferral must be a decision, not an
oversight.

## How this session works
- One decision at a time; **wait** for answers.
- For each threat, recommend a **minimum viable mitigation** for the MVP and note the
  **blast radius** if it's skipped.
- Keep it concrete to *this* system — use the assets and boundaries from 1.3/1.4.

## Decisions to make (in order)
1. **Assets.** What's worth protecting? (Credentials/keys, personal data, money/payments,
   proprietary data, availability itself.) List them — everything else hangs off this. (If
   **personal/regulated data** is among them, this session covers keeping attackers *out* of
   it; handling it *lawfully* — regimes, consent, retention, deletion rights — is the
   conditional Privacy/compliance session. Flag that it applies.)
2. **Trust boundaries.** Where does data cross a line of trust? (Internet → your service;
   user → admin; your service → third party; service → service.) Each boundary is where
   threats live.
3. **Threats per boundary** (STRIDE-lite). For each boundary, which apply: impersonation/
   spoofing, tampering, replay, information disclosure, denial of service, privilege
   escalation, insider misuse?
4. **AuthN / AuthZ posture.** High-level: how do you know who someone is, and what they're
   allowed to do? (Deep design is the conditional Identity/auth session — here just the
   stance.)
5. **Secrets & data protection.** Where do secrets live (never in code/repo) and how are
   they rotated? TLS in transit; encryption at rest for sensitive data? **Local dev
   convention:** secrets stay in a gitignored `.env` (values) or `.secrets/` (files like
   certs/keystores); the repo commits only a `.env.example` listing the required keys with
   placeholder values — see `templates/env-example.txt` for the full convention. The
   `.gitignore` stamped by `init.sh` already excludes these — confirm production secrets come
   from a real secrets manager, not a checked-in file.
6. **Common web risks.** Posture on input validation, injection, XSS/CSRF, rate limiting,
   dependency vulnerabilities. What's handled by the framework vs. needs attention? (The
   dependency/supply-chain posture you set here is operationalized in
   `runbooks/dependency-supply-chain.md` — vetting new deps and auditing them on a cadence.)
7. **Mitigate now vs. defer.** For each significant threat: mitigate in the MVP, or defer?
   For every deferral, record the blast radius and **what triggers revisiting** (e.g.
   "before we accept real user data / payments / go public").
8. **Deferral decision (if applicable).** If you're deferring a full threat model, state it
   explicitly with the trigger to revisit — a conscious, dated decision.

## Output
Write `architecture/06-security-threat-model.md` (use `templates/architecture-doc.md`). Body:
- **Assets**
- **Trust boundaries** (diagram or list)
- **Threats → mitigations** table — threat | boundary | MVP mitigation | deferred / blast radius
- **AuthN/AuthZ posture**, **secrets & data protection**, **web-risk posture**

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Capture
any contested or deferred decision as an **ADR** (`templates/adr.md`) — deferrals especially.
Update `prompts/STEP-index.md`: mark 1.6 done (or "deferred — see ADR-XXXX").

## Next
Once 1.6 is marked done, the next action is the lowest open STEP-1 substep — normally **1.7 (UI / design system)**. Tell the user to **start a fresh chat** and run it (*"run session 1.7"*); if the index shows a different next open substep (sessions can be skipped or added), run that instead. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
