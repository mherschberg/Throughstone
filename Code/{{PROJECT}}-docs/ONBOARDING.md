# New Contributor Onboarding

This guide is for a new human or agent contributor joining an existing, initialized
Throughstone project. It gives the contributor's first end-to-end path: assemble the
workspace, read the project state from disk, and start their first contribution STEP without
guessing.

This is not the first project bootstrap. The first maintainer ran `./init.sh` from the
Throughstone scaffold to create the project. Later contributors use the generated project
workspace and, for multi-repo projects, `Code/<project>-docs/scripts/setup-workspace.sh`.

> Paths below are relative to the workspace root (the folder containing `Code/` and
> `prompts/`).

## 1. Identify the project shape

Most Throughstone projects are **multi-repo**:

- The workspace root is a per-machine shell, not a repo.
- The docs hub lives at `Code/<project>-docs/`.
- The prompt/history repo lives at `prompts/`.
- Code repos live as siblings under `Code/<project>-*`.

Some early projects are **mono-repo-for-now**:

- There is one repo.
- `AGENTS.md`, `CLAUDE.md`, and `doctor.sh` are committed in that repo.
- `setup-workspace.sh` is not needed. Clone the repo, open it, and continue at
  [Read the project state](#4-read-the-project-state).

## 2. Set up a multi-repo workspace

Create or choose the workspace root, then clone the docs hub into the expected location:

```sh
git clone <docs-repo-url> Code/<project>-docs
```

From the workspace root, run the generated setup helper:

```sh
Code/<project>-docs/scripts/setup-workspace.sh
```

The helper writes the per-machine root files first, then clones the sibling repos that
`Code/<project>-docs/registries/repos.yml` gives a remote. Verify these exist at the
workspace root:

- `AGENTS.md`
- `CLAUDE.md`
- `doctor.sh`

If a repo did not arrive, `setup-workspace.sh` names it and says why as it runs, then closes
with a count. The one case it stays quiet about is a repo with no `remote:` in
`Code/<project>-docs/registries/repos.yml` — it was never going to be cloned. Read its registry
entry and ask the maintainer how that repo is provided.

## 3. Create your local user profile

Before reading or running project sessions, create root `.throughstone/local-user.md`. If it
already exists on this machine, confirm it belongs to the active user; otherwise replace it
with this user's answers. This file is personal local state, not project documentation and not
something to commit. If an agent is guiding onboarding, this is its first user-facing step for
every second-or-later contributor.

**First**, read `Code/<project>-docs/METHOD.md` §4, "Calibrating to the user's experience
level". It says what the two answers change: the **Experience level** sets how much technical
background an agent may assume, the **Communication style** sets how much it explains why a
decision matters, and the two are independent. Reading it first is what lets you tell the new
contributor up front that they can ask for any question to be explained.

**Then** ask the two local-profile questions from `Code/<project>-docs/BOOTSTRAP-PROMPT.md`
Stage 0 and record the answers in the shape it gives. Stage 0 owns the question wording, the
answer labels, the file shape and the override precedence — don't restate them here.

Each contributor keeps their own profile. Never inherit another person's values from project
docs.

## 4. Read the project state

Start with these files, in this order:

1. `AGENTS.md` - agent and contributor operating context, including kickoff versus resume.
2. `Code/<project>-docs/METHOD.md` - the method, read once before working.
3. `Code/<project>-docs/overview.md` - project brief and bootstrap status marker.
4. `prompts/STEP-index.md` - roadmap, STEP status, owners, and repo projections.
5. `Code/<project>-docs/registries/repos.yml` - canonical repo inventory.

Then run the local checks from the workspace root:

```sh
./doctor.sh status
./doctor.sh check
./doctor.sh links
```

Use `./doctor.sh status` as the source of the next action. It reads the project state from
disk and applies the next-action resolver from `METHOD.md`. Confirm its result against
`prompts/STEP-index.md`, and if a STEP is already in progress, read its PLAN in
`Upcoming Prompts/`.

## 5. Start your first contribution STEP

Before editing code or durable docs:

1. Read the README for every repo you expect to touch. The repo README is the local setup and
   "about" document for that repo.
2. Read `prompts/STEP-index.md` and select the next appropriate STEP. If you are adding an
   ad-hoc STEP, reserve a number according to `Code/<project>-docs/runbooks/collaboration.md`.
3. Check the selected STEP's `Repos (projection)` against other in-flight rows. If there is
   overlap, call it out before proceeding.
4. Create a branch named `step-NNNN-short-name`. Use the same branch name in every repo the
   STEP touches.
5. Update only your STEP row in `prompts/STEP-index.md` to `In progress` when you start, and
   push that small status change to the shared trunk.
6. After the STEP PLAN is approved, work from it by running the lowest open substep first.
7. Edit shared tables narrowly: your own STEP row, your own ADR/registry row, or the row the
   STEP explicitly owns. Do not re-sort or reformat shared tables as drive-by cleanup.
8. When complete, update the STEP review state, archive the PLAN and substep prompts from
   `Upcoming Prompts/` into the appropriate `prompts/<phase>/step-NNNN/` folder, and mark the
   STEP `Done` in `prompts/STEP-index.md`.

For team and concurrency details, read
[`Code/<project>-docs/runbooks/collaboration.md`](runbooks/collaboration.md). That runbook owns
the full rules for reserving STEP numbers, branch naming, shared-file edits, ADR numbering,
overlap warnings, and push races.

## 6. Keep paths straight

This scaffold stores the template at `Code/{{PROJECT}}-docs/ONBOARDING.md`. In an
initialized project, the generated docs hub path is `Code/<project>-docs/ONBOARDING.md`.
When editing template files, keep the literal `{{PROJECT}}` placeholder. When instructing
contributors in generated projects, use `Code/<project>-docs`.
