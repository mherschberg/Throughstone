# {{PROJECT}} - Interface Contracts (Session 1.11)

> **How to run:** Tell your agent *"run session 1.11"*. It interviews you one decision at a
> time, then writes `architecture/11-interface-contracts.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md`, the Architecture Overview doc (`architecture/*-architecture-overview.md`),
> the Data Model doc (`architecture/*-data-model.md`), the Security & Threat Model doc
> (`architecture/*-security-threat-model.md`), the Environments doc
> (`architecture/*-environments.md`), and the Observability doc
> (`architecture/*-observability.md`) first - plus any conditional-session docs already written
> that affect boundaries, identity/auth, privacy, native clients, or data sent to third parties.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1-2 (no/basic coding background) explain each question's *what* and *why* in plain language - leading with a recommended default - before asking, and skip bare jargon. At any level, treat any confusion or request to clarify - in any words, not just those - as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` section 4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
With the components, data, security, environments, and observability choices in place, we'll
decide how system boundaries are specified and kept in sync so consumers build against a clear
contract instead of guessing from prose or code.

## Why this session matters
Interfaces are where separately-built pieces most often drift apart: an endpoint changes shape,
an event drops a field, or a generated client no longer matches the service. Architecture
Overview doc names the boundaries; this session turns the boundary policy into something concrete enough for
implementation STEPs, repo READMEs, check-ins, and CI gates to enforce.

## How this session works
- One decision at a time; **wait** for answers.
- Start from the boundaries named in the Architecture Overview doc, then pull in decisions from data, security/privacy,
  environments, observability, and conditionals.
- Keep the right weight for the project: formal contracts for public or cross-component
  boundaries; lightweight or explicitly informal contracts for simple internal seams.

## Decisions to make (in order)
1. **Boundary inventory.** List every boundary that may need a contract: frontend <-> backend,
   mobile/desktop <-> backend, service <-> service, worker/job <-> queue/event bus, public API
   consumers, webhooks, CLI interfaces, library/package public APIs, and data import/export
   formats. Separate **owned interfaces** from third-party APIs this project only consumes.
2. **Contract level per boundary.** For each owned boundary, decide whether it needs a formal
   contract artifact, a lightweight Markdown/interface note, or an explicit "informal for now"
   decision. Tiny single-component projects can record that no formal contract is needed yet.
3. **Contract style per boundary.** Choose the style that fits each formal boundary: REST +
   OpenAPI, GraphQL schema, gRPC/protobuf, AsyncAPI/event schema, JSON Schema, typed package
   interfaces, or another established format.
4. **Authoring source vs. consumer contract of record.** Decide how each contract is produced:
   design-first/manual artifact, code-first/generated from annotations or types, hybrid with
   generated output checked in, or explicitly deferred. Name both the **authoring source of
   truth** and the **consumer-facing contract of record**.
5. **Artifact locations.** Decide where contract artifacts or planned artifacts live: owning
   repo, docs hub, shared contracts package/repo, per-service `contracts/`, generated docs, or
   a placeholder to create during repo scaffolding when the code repo does not exist yet.
6. **Versioning and compatibility.** Decide URL/path/header versioning, schema/event versioning,
   backward-compatibility rules, deprecation process, consumer migration expectations, and when
   breaking changes are allowed.
7. **Request / message conventions.** For HTTP APIs: path/resource naming, field casing,
   timestamps, IDs, pagination, filtering/sorting, partial updates, idempotency keys, and content
   types. For non-HTTP: message/event naming, envelopes, correlation IDs, retry/idempotency
   semantics, and schema evolution rules.
8. **Error model.** Decide error format, status/code taxonomy, validation error shape,
   auth/permission error posture, and what information must not leak. For HTTP APIs, decide
   whether to use RFC 9457 problem details.
9. **Auth, authorization, and privacy.** Pull from security, identity/auth, and privacy docs:
   auth mechanism, required scopes/roles/permissions, tenant boundaries, personal data in
   payloads, deletion/export endpoints if relevant, and audit-sensitive operations.
10. **Observability hooks.** Pull from observability: request IDs/correlation IDs, trace headers,
    event IDs, and error logging expectations at boundaries.
11. **Contract testing and CI gates.** Define the contract validation expectations that the Test
    Strategy session will fold into the full test strategy: schema validation, generated client/server tests,
    consumer-driven contract tests if needed, OpenAPI/GraphQL/protobuf linting, backward
    compatibility checks, and what must pass before merge.
12. **Ownership and update rule.** Decide which component/team owns each contract, who reviews
    breaking changes, and the rule for implementation STEPs: any API/interface-changing substep
    updates the contract artifact, contract tests, and related README links before it is done.

## Output
Write `architecture/11-interface-contracts.md` (use `templates/architecture-doc.md`). Body:
- **Boundary contract inventory** - boundary | owner | contract level | style | status
- **Authoring source and contract of record** - per formal boundary
- **Artifact locations** - including repo-scaffolding placeholders where repos do not exist yet
- **Versioning & compatibility**
- **Request / message conventions**
- **Error model**
- **Auth, authorization & privacy**
- **Observability hooks**
- **Contract testing & CI inputs**
- **Ownership & review**
- **Deferred / informal interfaces**

Write an ADR if the project chooses a significant contract strategy with real tradeoffs
(for example, OpenAPI design-first vs. code-generated, GraphQL vs. REST, or a shared contracts
repo vs. repo-local contracts).

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.11 done.

## Next
Once 1.11 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` section 10.

**Begin now - in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user - in the one or two sentences from **What this session does** above - what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply - nothing more.
