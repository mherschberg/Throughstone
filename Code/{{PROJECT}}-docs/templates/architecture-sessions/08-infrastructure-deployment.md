# {{PROJECT}} — Infrastructure & Deployment (Session 1.8)

> **How to run:** Tell your agent *"STEP-1.8"* or *"session 1.8"*; a leading *"Run"* and
> `: Infrastructure & Deployment` are optional (but the label helps chat titles). It interviews you one decision at a
> time, then writes the Infrastructure & Deployment architecture doc and updates
> `prompts/STEP-index.md`. Reads `overview.md`, the Architecture Overview architecture doc
> (`architecture/*-architecture-overview.md`), the Scaling & Performance architecture doc
> (`architecture/*-scaling-performance.md`), and the Security & Threat Model architecture doc
> (`architecture/*-security-threat-model.md`) first — plus
> any conditional-session doc with infrastructure or deployment implications (e.g.
> privacy-compliance for data residency/retention, identity-auth for secrets & session stores,
> native-app for build/distribution & push, or one added later), if it's been written.
> **Calibrate to the local user profile.** Check the **Experience level** in root `.throughstone/local-user.md`: at Level 1-2 (no/basic coding background) explain each question's *what* and *why* in plain language - leading with a recommended default - before asking, and skip bare jargon. If the file is missing, ask the two local-profile questions from `BOOTSTRAP-PROMPT.md` Stage 0, create it, then continue. Also check **Communication style** there and use it as the default level of detail; an explicit style request in chat overrides it for this session only. At any level, treat any confusion or request to clarify - in any words, not just those - as a cue to explain plainly, and tell the user up front they can ask. (See `METHOD.md` §4, "Calibrating to the user's experience level".)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
With the architecture, scale, and security decided, we'll settle where the system runs, how
your code gets there, and how it survives the failures it will eventually hit — so deploys
are repeatable and recoverable instead of hand-assembled and fragile.

Terminology: **Infrastructure & Deployment** is the Session 1.8 process name;
`architecture/*-infrastructure-deployment.md` is the **Infrastructure & Deployment
architecture doc** it produces (the exact output file is named in the Output section below);
**deployment artifacts** are concrete files, settings, and operational conventions governed
by that doc, such as deploy pipelines, infrastructure-as-code files, rollback procedures,
runtime infrastructure, production secrets wiring, backup jobs, and DR runbooks.

## Why this session matters
"It runs on my laptop" is not a deployment. Without a deliberate plan, infrastructure
becomes a pile of hand-configured boxes no one can reproduce. Deciding **where it runs, how
it gets there, how it's provisioned, and how it recovers when something breaks** now keeps
deploys boring and recoverable — and keeps cloud lock-in a choice rather than an accident.
The failure half matters as much as the deploy half: every system eventually loses a
process, a machine, or a dependency it doesn't control, and "we never thought about it" is
how a small outage becomes permanent data loss.

## How this session works
- One decision at a time; **wait** for answers.
- Recommend the **lowest-operational-burden option that fits** (often a managed PaaS or
  containers on a managed platform for a first release), and flag cost and lock-in tradeoffs.
- Tie back to the Scaling & Performance and Security & Threat Model architecture docs where relevant.

## Decisions to make (in order)
1. **Hosting target.** Cloud provider / managed PaaS / self-host. What's already decided or
   constrained (existing accounts, compliance, budget)?
2. **Compute model.** Containers (Docker; orchestrated by K8s/ECS/etc.) vs. serverless
   functions vs. managed app platform vs. plain VMs. Default to the simplest that meets the
   scaling needs from the Scaling & Performance architecture doc.
3. **Build & deploy pipeline.** How code becomes a running version: CI builds, artifacts,
   and how a deploy is triggered (and rolled back). Manual is OK for a first release if it's
   written down and repeatable — the optional `runbooks/release-deploy.md` checklist is where that
   procedure lives operationally; this decision designs what it executes.
4. **Infrastructure as code.** Terraform / Pulumi / provider tooling / none. How infra is
   provisioned reproducibly — even a single script beats clicking in a console.
5. **Networking & TLS.** Load balancer / ingress, DNS, TLS certificates, public vs. private
   surfaces.
6. **Secrets in production.** Where prod secrets live (a secret manager) and how services
   get them. (Consistent with the Security & Threat Model architecture doc.)
7. **Failure modes & resilience.** Walk what happens when a piece dies — a single process,
   the machine or availability zone it runs on, or a dependency you don't control (the
   database, a third-party API). Name the **single points of failure** (this is the
   *availability* angle; the Scaling & Performance architecture doc named them for *load*) and pick an
   **availability target**: is a
   few hours of downtime fine, or must this stay up? For a modest availability target, a single
   region with a fast redeploy is often the right call — the point is to choose it knowingly, not
   by default.
   Where it's cheap, prefer **graceful degradation** (read-only mode, a cached response, a
   clear "try again shortly") over a hard crash when a dependency is unavailable.
8. **Backups & disaster recovery.** What's backed up, how often, and how long backups are
   retained; then the two numbers that define recovery — **RPO** (*recovery point* — how much
   *data loss* is tolerable: minutes? a day?) and **RTO** (*recovery time* — how long to get
   back *up*). The catch: **a backup
   you have never restored is not a backup** — decide how and how often a restore is actually
   rehearsed. Even "daily DB snapshot, restore rehearsed once, ~1-day RPO / few-hour RTO"
   counts. Note who does what when it's genuinely down (the bones of a DR runbook).
9. **Cost & cloud coupling.** Rough cost shape and what drives it as you scale; how coupled
   you are to one provider and what would be painful to move.

## Output
Write `architecture/08-infrastructure-deployment.md` (use `templates/architecture-doc-template.md`).
Body:
- **Hosting & compute** model + rationale
- **Deploy pipeline** — build → deploy → rollback
- **Infrastructure as code** approach
- **Networking, TLS, secrets**
- **Resilience** — single points of failure, availability target, failover & degraded-mode behavior
- **Backups & DR** — what, cadence, retention, restore-test plan, RPO/RTO, recovery responsibilities
- **Cost & cloud-coupling** notes

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Capture
provider/lock-in and availability/RPO-RTO decisions as ADRs if significant. Update
`prompts/STEP-index.md`: mark 1.8 done.

## Next
Once 1.8 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep with a descriptive first message. For
a numbered core session, use `Run STEP-1.N: <Session label from the index>` (for example,
`Run STEP-1.9: Environments`). For a lettered conditional session, use
`Run STEP-1.Xa: <Conditional session label>` and the invocation by name from that
conditional's template. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "STEP-1.N" or "session N.M", with or without a leading "Run" and with or without the session label, is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read root `.throughstone/local-user.md`, `overview.md` (plus anything relevant in `inputs/` and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the profile's experience level. That orientation plus the first question is your entire first reply — nothing more.
