# {{PROJECT}} — Environments (Session 1.9)

> **How to run:** Tell your agent *"run session 1.9"*. It interviews you one decision at a
> time, then writes `architecture/09-environments.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md` and `architecture/08-*` first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Building on the infrastructure from 1.8, we'll define your environments and how config and
secrets differ between them, so untested code and leaked keys don't reach users.

## Why this session matters
Most early projects have exactly two environments — "my machine" and "production" — and
push straight from one to the other. That's how untested code and leaked secrets reach
users. Deciding your **environments, how config and secrets differ across them, and how
code is promoted** gives you a safe path to production.

## How this session works
- One decision at a time; **wait** for answers.
- Recommend the **fewest environments that give you safety** for the MVP (often local +
  one staging + prod), and flag what each adds in cost/maintenance.

## Decisions to make (in order)
1. **Which environments.** Local/dev, CI (for automated tests), staging/pre-prod,
   production. Which do you actually need for the MVP, and what is each *for*?
2. **Sandbox / demo environment?** Do you need a separate sandbox — for trying the product
   without real data, for demos, or for external integrators to test against? (Often *not*
   needed at MVP; decide consciously.)
3. **Config & secrets per environment.** How configuration differs per env (env vars /
   config files — never secrets in code) and where each env's secrets come from
   (consistent with 1.6/1.8). **Local dev** uses a gitignored `.env` (values) / `.secrets/`
   (files) with a committed `.env.example` documenting the keys — see
   `templates/env-example.txt` for the convention (the `init.sh` `.gitignore` already excludes
   these); **deployed envs** pull secrets from a secrets manager, not a file.
4. **Data per environment.** Seed/fixture data for local & CI; is staging data synthetic or
   a prod-like (scrubbed) copy?
5. **Parity.** How close each environment is to production, and where it deliberately
   differs (and the risk that creates).
6. **Promotion flow.** How code and config move between environments (e.g. merge → deploy
   to staging → verify → promote to prod). Who can deploy to each.
7. **Access control.** Who can read/modify each environment, especially production.

## Output
Write `architecture/09-environments.md` (use `templates/architecture-doc.md`). Body:
- **Environments table** — env | purpose | who has access | data
- **Sandbox decision** (needed or not, and why)
- **Config & secrets** per environment
- **Parity & promotion flow**

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.9 done.

## Next
Once 1.9 is marked done, the next action is the lowest open STEP-1 substep — normally **1.10 (Observability)**. Tell the user to **start a fresh chat** and run it (*"run session 1.10"*); if the index shows a different next open substep (sessions can be skipped or added), run that instead. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
