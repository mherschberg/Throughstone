# {{PROJECT}} — Identity & Auth (Conditional Session)

> **Conditional.** Include this if the project has users/accounts or any access control
> worth designing (most apps with login do). The kickoff slots it in as a substep (e.g.
> `1.6a`, after the Security & Threat Model session) and the index records its number. Run it by name:
> *"run the identity-auth session."* It writes `architecture/NN-identity-auth.md` (number
> assigned in the index) and updates `prompts/STEP-index.md`.
> **Two separate numbers:** the *substep* number (e.g. `1.6a`) marks its place in STEP-1; the
> *doc file* number (`NN`) is the next free number **above the reserved core-doc block** — the
> standard sessions reserve a contiguous block at the front (the current core set is the session
> table in `METHOD.md` §4), and each conditional takes the next free number above that block
> if another conditional already claimed the first one — **not** the lowest unused number. (This session may run
> early, e.g. at `1.6a`, before the later core docs exist; still take the first free number
> above the core block, so a not-yet-run core session keeps its own reserved slot without a clash.) The substep
> number and the doc number don't have to match.
> Reads `overview.md`, the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`),
> the Data Model architecture doc (`architecture/*-data-model.md`), and the Security & Threat Model architecture doc
> (`architecture/*-security-threat-model.md`) first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Building on the data model and threat model, we'll design how users prove who they are and
what each is allowed to do — including the big build-vs-buy call of whether to use a managed
identity provider.

## Why this session matters
Authentication ("who are you?") and authorization ("what may you do?") are easy to get
subtly, dangerously wrong, and very expensive to retrofit. This session designs them
deliberately — and, importantly, decides **build vs. buy**, since rolling your own identity
is a common and costly mistake. It expands on the AuthN/AuthZ posture set in the Security &
Threat Model session.

## How this session works
- One decision at a time; **wait** for answers.
- Strongly recommend a **managed identity provider** for most projects, and flag the
  obligations of rolling your own; flag what each choice forecloses.
- Keep it consistent with the Data Model architecture doc and the Security & Threat Model
  architecture doc.

## Decisions to make (in order)
1. **Authentication methods.** Password, OAuth/social, SSO/SAML/OIDC, passwordless/magic
   link, MFA. Which for the MVP, which later.
2. **Identity provider — build vs. buy.** Managed (Auth0, Cognito, Clerk, Firebase,
   Keycloak self-host) vs. roll-your-own. Default: **buy**, unless there's a strong reason.
   Record the decision (an ADR).
3. **User / account model.** How users, accounts, and (if relevant) organizations relate —
   consistent with the data model. Account lifecycle: signup, verification, recovery,
   deactivation, deletion.
4. **Authorization model.** Roles (RBAC), attributes/policies (ABAC), or simple
   ownership-based permissions. What roles/permissions exist and how they're enforced.
5. **Multi-tenancy** (if applicable). Are users isolated by org/tenant? How is tenant
   isolation enforced in data and access?
6. **Sessions & tokens.** Session cookies vs. JWT/access+refresh tokens; lifetimes,
   refresh, and revocation. Where tokens are stored on the client (ties to web/native
   security).
7. **Service-to-service auth** (if multi-service). How components authenticate to each
   other (mTLS, signed service tokens, pre-shared credentials).

## Output
Write `architecture/NN-identity-auth.md` (use `templates/architecture-doc.md`; NN per the
index). Body covers each area above. Fill the **Decision Summary**, record **Open
Questions**, start the **Version Log**. Capture the build-vs-buy and authorization-model
choices as **ADRs**. Update `prompts/STEP-index.md`: mark this substep done.

## Next
Once this substep is marked done, the next action is the lowest open STEP-1 substep in the index — its position depends on where this conditional was slotted. Tell the user to **start a fresh chat** and run it. When all STEP-1 substeps and the Cross-Cutting Review are done, the next action is *"run the planning session."* See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run the identity-auth session" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
