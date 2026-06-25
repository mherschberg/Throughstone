# {{PROJECT}} — Documentation Hub

The durable home for **what {{PROJECT}} is and why** — architecture, decisions, standards,
and the method that governs how it's built. This repo is *state* (the system as it is now);
the sibling `prompts/` repo is *history* (how it was built, STEP by STEP).

> This is a pointer. The substance lives in the files below — don't duplicate them here.

## Start here
- **Humans:** read [`METHOD.md`](METHOD.md) once — how this project is structured (Phase ▸
  STEP ▸ substep, architecture-first, the durable doc genres). The project brief is
  `overview.md` (written during kickoff).
- **New contributors:** read [`ONBOARDING.md`](ONBOARDING.md) for the first end-to-end path:
  set up an existing project workspace, read state from disk, and start your first
  contribution STEP.
- **AI agents:** [`AGENTS.md`](AGENTS.md) is your canonical context — start there. The
  workspace-root `CLAUDE.md` / `AGENTS.md` just point to it. New project? It routes you to
  [`BOOTSTRAP-PROMPT.md`](BOOTSTRAP-PROMPT.md) for kickoff.

## What's here
| Path | What |
|------|------|
| [`METHOD.md`](METHOD.md) | The method — read once before working here. |
| [`AGENTS.md`](AGENTS.md) | Canonical agent context + the next-action resolver. |
| [`ONBOARDING.md`](ONBOARDING.md) | New contributor setup guide for joining an existing project and starting the contributor's first STEP. |
| [`UPDATING-THROUGHSTONE.md`](UPDATING-THROUGHSTONE.md) | How to compare and selectively adopt newer Throughstone scaffold/process changes after bootstrap. |
| [`architecture/`](architecture/README.md) | *What* the system is — living, versioned design docs (indexed). |
| [`adr/`](adr/README.md) | *Why* it's that way — point-in-time decision records (indexed). |
| [`coding-standards/`](coding-standards/README.md) | Per-language engineering standards (indexed). |
| [`runbooks/`](runbooks/README.md) | Repeatable procedures — check-in, release, incident, dependencies, secrets, collaboration (indexed). |
| [`registries/`](registries/README.md) | Machine-readable inventories — repo map (`repos.yml`) and accepted risk / tech-debt index (`risks.yml`) (indexed). |
| [`templates/`](templates/) | The session, STEP, and doc templates the method runs from. |
| [`scripts/`](scripts/) | Setup and doctor helpers — status, structural checks, stale-link checks, workspace setup, and project-license propagation. |

> Built with **Throughstone**. The scaffold files (`METHOD.md`, `templates/`, `runbooks/`,
> `scripts/`) are © 2026 Mark A. Herschberg under BSD-3-Clause — full text in
> `LICENSE-THROUGHSTONE`. Your application code and project docs are yours, under the
> open-source license you chose at setup or kept private/proprietary. For open-source projects,
> this repo's `LICENSE` is the canonical project-license file copied unchanged into each
> application-code repo when it is created. `.throughstone/project-license` records the durable
> selection independently, and the repo-scaffolding helper validates the two before copying.
> It also copies `LICENSE-THROUGHSTONE` for retained Throughstone-authored README and CI
> templates and writes `LICENSING.md` so its limited scope is visible.
