# Throughstone

[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)

A starting structure for building a software project *architecture-first*, with an AI
coding agent (Claude Code, Codex, etc.) as your collaborator. You bring an idea — roughly a
page or two's worth of thinking, though you don't have to write it down first; the kickoff
interview helps you capture it. This scaffold and the agent turn it into a planned,
documented, well-architected project.

It encodes a pattern proven across several real projects:
- **Think before you code.** The first STEP produces architecture docs and decision
  records — *no application code* — so the foundation is deliberate.
- **Decisions get recorded.** Architecture docs say *what* the system is; ADRs say *why*
  it's that way. Both are versioned and maintained.
- **Work is broken into runnable units.** Phases → STEPs → substeps, each small enough
  for an agent to execute cleanly in a fresh context.

> **Just want to start?** Jump to the **[Quickstart](#quickstart)**.

## Why I built this

I kept hearing the same story: a vibe-coded project that started great and then turned
unmaintainable a few months in. Dev shops I know would inherit projects that looked polished
on the surface but were a mess underneath; security holes are rampant in code shipped this
way. Experienced developers know a little upfront planning and a low-overhead, disciplined
approach to coding goes a long way. This project draws upon decades of building software to
give AI coders a framework that nudges them toward the practices experienced engineers take
for granted. I know it works because I've used it on my own projects. Like any tool, it
doesn’t guarantee success, but it should make it easier to do things right and reduce the
risk of creating unmaintainable code.

## Who it's for

- **New to building / little or no coding experience.** You have an idea and want to
  build it with an AI agent — but you don't want a mystery box of code you can't
  understand or extend. The sessions interview you in plain language and recommend
  sensible defaults; you bring the idea, the scaffold brings the structure.
- **Early-career developers.** You can write code, but the *project-shaping* part — what
  to decide first, how to phase the work, what the architecture should be — is exactly
  where AI agents tend to leave you with a tangle. This puts that discipline up front, so
  what you build holds together past v1.
- **Experienced developers and leads.** You may not need this for your own work — but it's
  a clean thing to hand the early-career developers and non-technical founders who keep
  asking you *"how do I even start building with AI?"* Point them here and let the scaffold
  do the mentoring you'd otherwise have to repeat by hand. *(Want it for your own projects?
  Set your experience level to senior at the start and the sessions stay terse and
  decision-focused.)*

**A scope note:** this is built for software meant to stick around (e.g., a product, an
internal business tool, a serious open-source project). For a throwaway proof-of-concept, a
school assignment, or other code you won't maintain, it's likely overkill.

You do **not** need to be a senior architect to use this. The architecture *sessions*
interview you — they ask about the things developers routinely skip (scaling, security,
phasing) and recommend sensible defaults while flagging what each choice forecloses. Two
things keep them approachable whatever your background:

- **Tell it how much you know.** Up front you set your experience level — from *no coding
  experience* to *senior developer* — and every session speaks to it: plain-language
  framing and a recommended default for newer builders, terse and decision-focused for
  veterans.
- **Ask whenever something's unclear.** At any point you can ask what a question means or
  why it matters and get a from-scratch explanation. The agent also offers one when you
  seem stuck.

> **A note on collaboration.** The scaffold includes conventions for multiple developers and
> agents working together — branch-per-STEP, global STEP-number reservation, an overlap
> warning, and ADR-based decisions (see
> [`runbooks/collaboration.md`](Code/{{PROJECT}}-docs/runbooks/collaboration.md)). In
> practice I've mostly used this on **solo** projects, so that collaboration layer is newer
> and less battle-tested — expect it to need some refinement as it meets real teams.
> Feedback and PRs welcome.

---

## Quickstart

> **Not a developer — or never used a command line?** You can still use this. The steps
> below assume a little comfort with a terminal, but you don't need to understand them
> deeply: you run two setup commands once, and everything after that is a normal
> conversation with your AI agent in plain English. Take it slowly, and if any step is
> unclear or throws an error, paste it to your agent and ask what it means — explaining
> things from scratch is exactly what this is built to do.
>
> Already have an AI agent open on your computer? You can let it drive the setup, too — just
> tell it: *"Read https://github.com/mherschberg/Throughstone/blob/main/README.md and walk
> me through getting started, one step at a time."* It can explain each command and, with
> your go-ahead, run them for you.

> **Requirements:** a POSIX shell (`bash`), `git`, and `perl` — `init.sh` uses `perl` for its
> placeholder substitution; all three ship on macOS and nearly every Linux. `gh` is optional
> (only for auto-creating GitHub remotes), and the later `setup-workspace.sh` uses `python3`
> if present (with a plain-shell fallback). The methodology, prompts, and templates themselves
> are plain Markdown — these are just the two setup wizards.

1. **Get the files into a folder named for your project.** The folder you download into
   **becomes your project's workspace root** — `init.sh` never renames it — so give it the
   name you want the project to have (e.g. `acme` or `MyCoolMobileApp`, not `Throughstone`). Two ways:
   - **Clone this repo directly** into a project-named folder (e.g. `acme`):
     ```bash
     git clone https://github.com/mherschberg/Throughstone.git acme
     cd acme
     ```
   - **Or use GitHub "Use this template" ▸ Create a new repository.** This is mainly useful
     if you're choosing **mono-repo for now**; `init.sh` will reuse that repo's `origin`.
     In the default **multi-repo** setup, the root is only a workspace shell, so the template
     repo is just a download vehicle — use `--remotes=yes` or add remotes later for the docs
     and prompts repos. Name the new repo for your project, then clone it into a folder of
     that name (e.g. `acme`):
     ```bash
     git clone <your-new-repo-url> acme
     cd acme
     ```
   Everything from here runs *inside* this folder. After setup it holds your repo(s); the
   root folder itself is just the shell around them (see [Layout](#layout)), so its name is
   cosmetic — but matching it to your project keeps things clear.

2. **Run the setup wizard** from inside that folder:
   ```bash
   ./init.sh
   ```
   It asks a few questions (project slug, repo layout, **license**, optional pieces), then
   detaches this download from the template's git history, renames the `{{PROJECT}}`
   placeholder everywhere to your slug, stamps your chosen `LICENSE`, and initializes your
   repo(s). See [`init.sh`](init.sh).

   Prefer to script it? Every question has a flag — run `./init.sh --help` to see them, or
   pre-answer non-interactively, e.g.:
   ```bash
   ./init.sh --non-interactive --slug=acme --desc="platform for roadrunner catching" \
             --license=mit --holder="Acme Inc." --layout=multi
   ```
   Any flag you omit is still prompted (without `--non-interactive`); with it, a missing
   required value is an error. `init.sh` first checks that `git` and `perl` are present. When
   it finishes you can delete `init.sh` — it has done its job.

3. **Start your AI agent in the project folder, and send it one command.** Launch your
   agent however you normally do (Claude Code, Codex, … — start it yourself; this scaffold
   doesn't try to launch it for you), with its working directory set to the project folder
   (the one containing `Code/` and `prompts/`). Then send it this single message:

   > **Read AGENTS.md and follow it.**

   That's the whole handoff — the same command for every project and every agent (no paths
   or project name to fill in). The agent reads the context, sees the project hasn't been
   started yet, and **begins the kickoff on its own**: it greets you, asks your experience
   level, and helps you write the project brief (`Code/{{PROJECT}}-docs/overview.md`) right
   in the chat. Just describe your idea when it asks — you don't have to pre-write anything.

   From there the agent proposes a roadmap and starts the architecture STEP; you work
   through the architecture sessions one at a time (*"run session 1.1"*), then move into
   building. On any later session, the same **"Read AGENTS.md and follow it"** resumes where
   you left off (it reads the roadmap in `prompts/STEP-index.md`) rather than re-running the
   kickoff.

   > *Prefer to write the brief yourself first?* You can — fill in
   > `Code/{{PROJECT}}-docs/overview.md` before sending the command.

---

## Layout

After setup, the workspace is a multi-repo project. The **workspace root is not a repo** —
it's a per-machine shell holding only pointers/config. Everything durable lives in sibling
repos:

```
your-project/                    ← workspace shell (per-machine, not a repo)
├── CLAUDE.md, AGENTS.md         ← per-machine pointers to the canonical context
├── .claude/                     ← per-machine agent config
├── init.sh                      ← one-time setup wizard (this download)
├── prompts/                     ← [repo] STEP plans + substep prompts; STEP-index.md roadmap
├── Upcoming Prompts/            ← scratch for the in-flight STEP (not a repo)
└── Code/
    └── {{PROJECT}}-docs/         ← [repo] the docs hub — ALL durable content:
        ├── AGENTS.md            ← canonical agent context
        ├── METHOD.md            ← the methodology — read this
        ├── BOOTSTRAP-PROMPT.md  ← the kickoff prompt
        ├── overview.md          ← your project brief (you create this)
        ├── templates/           ← architecture docs, sessions, ADRs, STEP plans, READMEs
        ├── architecture/  adr/  coding-standards/  registries/  runbooks/
        └── scripts/             ← setup-workspace.sh (onboard a new developer's machine)
```

> `{{PROJECT}}` is a placeholder the wizard replaces with your project's name.

> *If you chose **mono-repo for now** in `init.sh`, the workspace root itself is the single
> repo and `prompts/` / `Code/` are folders inside it — the multi-repo split above is the
> target. See [`Code/{{PROJECT}}-docs/METHOD.md`](Code/{{PROJECT}}-docs/METHOD.md) §7.*

**Start with [`Code/{{PROJECT}}-docs/METHOD.md`](Code/{{PROJECT}}-docs/METHOD.md)** to
understand how the project is organized.

## Updating after setup

Throughstone is copied into your project at bootstrap; later template improvements do not
apply automatically. That is intentional: your architecture docs, ADRs, prompts, generated
repo files, and application code become project-owned state.

If you want to compare a bootstrapped project against a newer Throughstone release, use the
scaffold update guide in the docs hub:
[`Code/{{PROJECT}}-docs/UPDATING-THROUGHSTONE.md`](Code/{{PROJECT}}-docs/UPDATING-THROUGHSTONE.md).
It defines a conservative process: report first, protect project-owned files, review even
script updates, and apply only verified scaffold/process changes. If updater tooling is added
later, its project state belongs in `Code/{{PROJECT}}-docs/.throughstone/manifest.yml`.

## Works with any agent

The methodology, prompts, and templates are plain Markdown + a Bash wizard — nothing is
tied to one AI tool. The only tool-specific files are thin pointers (`CLAUDE.md` for Claude
Code, `AGENTS.md` for Codex and others) that both point at the same canonical context. Use
whichever agent you like.

## FAQ

### What kinds of projects is Throughstone best for?

Throughstone is best for software you expect to maintain: a product, internal business tool,
serious open-source project, or anything where architecture, security, tests, and future
changes matter. It is probably too much ceremony for a throwaway demo, quick script, school
assignment, or one-off prototype you do not plan to keep.

### What do I need before I start?

You need an idea and a local AI coding agent. A page or two of notes helps, but it is not
required; the kickoff interview can help you turn a rough idea into the initial project
brief. For setup, you need a POSIX shell, `git`, and `perl` as described in the
[Quickstart](#quickstart).

### Is this just better vibe-coding prompts?

No. Throughstone is not trying to solve AI coding by adding a larger rule file and hoping the
model obeys it perfectly. AI agents still speculate, miss existing patterns, add accidental
scope, and make plausible-looking mistakes.

Throughstone's bet is different: move as much project judgment as possible out of a long chat
and into a durable process. Architecture comes first, decisions are recorded, work is split
into small STEPs, each STEP has review criteria, and periodic check-ins reconcile code back
against the docs. The goal is not to make the AI incapable of being wrong; it is to make wrong
turns smaller, easier to see, and less likely to compound into an unmaintainable project.

### Why does Throughstone do architecture before code?

Because AI agents are fast enough to turn an unclear idea into a lot of code before anyone has
decided what the system is supposed to be. STEP-1 deliberately produces architecture docs and
decision records before application code, so core choices about scope, data, security,
deployment, testing, and interfaces are intentional instead of accidental.

The point is not to freeze the project forever. It is to give the work a clear starting shape
before implementation begins.

### Does this let a non-developer ship production software alone?

Not by magic. A non-developer can use Throughstone to describe the product, make guided
architecture decisions, and work with an AI agent in a much more disciplined way than an
open-ended chat. That can get a project much farther than raw prompting.

But production software still needs judgment: security, data correctness, deployment risk,
access control, payments, compliance, and other high-stakes areas deserve expert review.
Throughstone is meant to make that review cheaper and clearer by leaving behind architecture
docs, ADRs, scoped STEPs, tests, and a roadmap instead of a mystery pile of generated code.

### Can I use this with an existing project?

In theory it could work, but Throughstone was not designed or tested for that yet. We plan to
add better support for existing projects in the future.

In the meantime, you could try creating the documentation and following the STEP process
manually. If you do, first make sure your code is saved in a git repo so you can revert
changes. Second, tell the LLM that you want to use Throughstone on an existing project and
that it should take the process step by step manually, without deleting existing code.

### Can I change decisions later?

Yes. Architecture-first does not mean architecture-once. If an assumption changes, rerun the
relevant architecture session, update the architecture doc, and record any significant change
with a new ADR or an amendment to the old one. Throughstone treats documentation as living
project state, not a museum.

### Do I have to keep using Throughstone after setup?

No. The generated project is yours, and the files are plain Markdown and normal repos. But the
value comes from continuing the discipline: working in scoped STEPs, keeping the roadmap
current, recording important decisions, and updating architecture docs when reality changes.

### How do I update my project when Throughstone improves?

Throughstone is copied into your project at setup time; template improvements do not apply
automatically. Use the scaffold update guide in
[`Code/{{PROJECT}}-docs/UPDATING-THROUGHSTONE.md`](Code/{{PROJECT}}-docs/UPDATING-THROUGHSTONE.md)
to compare carefully and apply only the updates that make sense for your project.

### Can multiple people or agents work on the same project?

Yes. Throughstone includes collaboration conventions for branch-per-STEP work, STEP-number
reservation, overlap warnings, and ADR-based decisions. That layer is newer than the solo
workflow, so treat it as useful but still evolving, and expect the team to refine it as real
projects exercise it.

### Do I need Claude Code or Codex specifically?

No. Use the agent or AI-enabled IDE you already prefer: Claude Code, Codex, Cursor,
Antigravity, or another tool. Throughstone is just files, prompts, scripts, and conventions in
your project folder. As long as your tool can read the workspace, edit files, and follow
`AGENTS.md` or `CLAUDE.md`, it can participate.

If your IDE has its own rule system, keep using it for local preferences. Treat Throughstone's
docs as the project source of truth: the agent should read the canonical context, follow the
STEP plan, and update the architecture docs and ADRs when decisions change.

## Contributing & community

Throughstone launched as a single-maintainer project and the hope is that it grows — bug
reports, fixes, and ideas are genuinely welcome. A few starting points:

- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to propose changes (small fixes vs. larger
  method changes).
- **[Code of Conduct](CODE_OF_CONDUCT.md)** — be kind; this is a welcoming community.
- **[Security policy](SECURITY.md)** — how to report a vulnerability privately.

## Contact & support

- **Questions / how do I…?** — open a [Discussion](../../discussions).
- **Bugs and feature ideas** — open an [Issue](../../issues).
- **Security reports** — please use the private channel in [SECURITY.md](SECURITY.md), not a
  public issue.
- **Conduct concerns** — email **hershey@throughstone.org** (see the [Code of Conduct](CODE_OF_CONDUCT.md)).

## License

This Throughstone template is released under the [BSD 3-Clause License](LICENSE) — use
it freely. `init.sh` sets up **your** project's own license for the code you write: it asks
whether your project is open source (MIT, BSD-3, or Apache-2.0) or private/proprietary (an
"all rights reserved" notice) and stamps that into each repo. The scaffold's own files
(`METHOD.md`, `templates/`, `runbooks/`, `scripts/`) remain under BSD-3-Clause — `init.sh`
retains it as `LICENSE-THROUGHSTONE` in the docs hub (BSD-3 requires keeping the notice). So your
application code is governed by the license you chose, while the project keeps a reference
back to Throughstone.

> **A note on the name.** The BSD-3-Clause license covers the *code*, not the *name*.
> "Throughstone" is a trademark of Mark A. Herschberg — you're welcome to say you *use*
> Throughstone, but please don't name your own fork or product after it. See
> [TRADEMARK.md](TRADEMARK.md).

> **Maintainers:** on GitHub, mark this repo as a *template repository* (Settings ▸ General
> ▸ "Template repository") so others get the "Use this template" button.
