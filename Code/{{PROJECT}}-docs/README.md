# {{PROJECT}} — Documentation Hub

The durable home for **what {{PROJECT}} is and why** — architecture, decisions, standards,
and the method that governs how it's built. This repo is *state* (the system as it is now);
the sibling `prompts/` repo is *history* (how it was built, STEP by STEP).

> This is a pointer. The substance lives in the files below — don't duplicate them here.

## Start here
- **Humans:** read [`METHOD.md`](METHOD.md) once — how this project is structured (Phase ▸
  STEP ▸ substep, architecture-first, the durable doc genres). The project brief is
  `overview.md` (written during kickoff).
- **AI agents:** [`AGENTS.md`](AGENTS.md) is your canonical context — start there. The
  workspace-root `CLAUDE.md` / `AGENTS.md` just point to it. New project? It routes you to
  [`BOOTSTRAP-PROMPT.md`](BOOTSTRAP-PROMPT.md) for kickoff.

## What's here
| Path | What |
|------|------|
| [`METHOD.md`](METHOD.md) | The method — read once before working here. |
| [`AGENTS.md`](AGENTS.md) | Canonical agent context + the next-action resolver. |
| [`architecture/`](architecture/README.md) | *What* the system is — living, versioned design docs (indexed). |
| [`adr/`](adr/README.md) | *Why* it's that way — point-in-time decision records (indexed). |
| [`coding-standards/`](coding-standards/README.md) | Per-language engineering standards (indexed). |
| [`runbooks/`](runbooks/) | Repeatable procedures — check-in, collaboration. |
| [`registries/`](registries/) | Inventories — `repos.yml`, the map of the project's repos. |
| [`templates/`](templates/) | The session, STEP, and doc templates the method runs from. |
| [`scripts/`](scripts/) | Setup helpers — e.g. `setup-workspace.sh`. |

> Built with **Throughstone**. The scaffold files (`METHOD.md`, `templates/`, `runbooks/`,
> `scripts/`) are © 2026 Mark A. Herschberg under BSD-3-Clause — full text in
> `LICENSE-THROUGHSTONE`. Your application code and project docs are yours, under the license
> you chose at setup.
