# {{PROJECT}} — Observability (Session 1.10)

> **How to run:** Tell your agent *"run session 1.10"*. It interviews you one decision at a
> time, then writes the Observability architecture doc and updates `prompts/STEP-index.md`.
> Reads `overview.md`, the Architecture Overview doc (`architecture/*-architecture-overview.md`),
> and the Scaling & Performance doc (`architecture/*-scaling-performance.md`) first — plus any conditional-session doc that
> affects what you log/alert on (e.g. identity-auth for auth-event audit logging, privacy-compliance
> for PII-in-logs and log retention, or one added later), if it's been written.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Given the components and scale targets from earlier, we'll decide what to log, measure, and
alert on, so when something breaks in production you can see *why* instead of guessing.

Terminology: **Observability** is the Session 1.10 process name;
`architecture/*-observability.md` is the **Observability architecture doc** it produces (the
exact output file is named in the Output section below); **observability artifacts** are
concrete outputs or settings governed by that doc, such as logging conventions, metrics,
tracing, health checks, error tracking, dashboards, alerts, tool configuration, and retention
rules.

## Why this session matters
When something breaks in production — and it will — observability is the difference between
"we saw it, here's why" and "users told us, and we have no idea." Developers add logging ad
hoc and discover too late they can't answer basic questions. Deciding **what to log, what
to measure, and what to alert on** now means you can actually operate the thing.

## How this session works
- One decision at a time; **wait** for answers.
- Recommend a **lightweight default** for the MVP (structured logs + a few key metrics +
  health checks + error tracking) and scale up only where the system warrants it.
- Be explicit about what must **not** be logged (secrets, PII).

## Decisions to make (in order)
1. **Logging.** Structured (JSON) logs; levels; what events to log; correlation/request IDs
   to trace a request across components. And the **never-log list** (secrets, tokens, PII).
2. **Metrics.** The few that matter — start from the "golden signals": latency, traffic,
   errors, saturation. Plus any domain metrics (e.g. signups/day, jobs processed). Tie
   targets to the performance numbers from the Scaling & Performance doc.
3. **Tracing.** Do you need distributed tracing? (Usually yes once multiple
   services/components are in a request path; often skippable for a single service.)
4. **Health checks.** Liveness/readiness endpoints each component exposes (used by infra
   from the Infrastructure & Deployment doc).
5. **Error tracking.** How exceptions are captured and surfaced (e.g. Sentry-style).
6. **Dashboards & alerting.** What you want to see at a glance; what conditions should page
   a human, the thresholds, and who's notified. Avoid alert noise — alert on symptoms users
   feel.
7. **Tooling & retention.** The stack (hosted vs. self-run, e.g. Prometheus/Grafana, a
   logging service) and how long logs/metrics are kept.

## Output
Write `architecture/10-observability.md` — the Observability architecture doc (use
`templates/architecture-doc.md`). Body:
- **Logging** — format, levels, correlation IDs, never-log list
- **Metrics** — the key set (+ targets) and domain metrics
- **Tracing & health checks**
- **Error tracking**
- **Dashboards & alerts** — condition | threshold | who's notified
- **Tooling & retention**

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.10 done.

## Next
Once 1.10 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep (for a numbered core session, *"run
session N.M"*; for a lettered conditional session, invoke it by name). See the next-action
resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
