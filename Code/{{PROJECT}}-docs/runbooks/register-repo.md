# Runbook — Register a repository

> **How to run:** **Not on its own.** This procedure is called by
> `templates/planning-session.md`'s *Repo scaffolding* step (a repo the architecture named),
> `runbooks/check-in.md` (a repo nobody registered), `runbooks/splitting-repos.md` (a repo the
> split created), and the per-asset substep on the existing-codebase front door — whenever the
> set of repositories the project has changes. There is no trigger phrase; something else sends
> you here.
>
> **Read `METHOD.md` §7 first if you have not.** It carries the model this implements: control is
> a permission granted once per repository, the three needs, and the ladder. This file is the
> procedure only.

## Why this runbook exists
A repository is registered in two places at once — its row in `registries/repos.yml` and its entry
in the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`). They are
one unit: neither moves without the other, and nothing maintains either by hand. Keeping the
procedure here means every caller can name **the action** instead of describing a row, so a caller
stays correct when the fields change.

**Seeded rows are not registered through this action.** The docs hub and `prompts/` are written by
`init.sh`, ship their own bespoke READMEs rather than a stamped template, and carry no `provides:`.
Leave them alone.

## Before you start
- [ ] **Is the repository on this machine?** If its `location` is not here — a path on someone
      else's machine, or a repo not cloned yet — **run steps 1-3, 5 and 6 and stop there**: the
      row and the Architecture Overview entry are the floor and always exist, but with **no
      `provides:` at all**, plus a `registries/risks.yml` row saying the repository was not
      reachable. Statuses are filled by looking; none may be guessed to complete the set. Say which
      repos you skipped, by name — a silent partial run reads as a complete one.
- [ ] **Is its work tree clean, with an attached HEAD?** If not, **write nothing into it.** Leave
      `control:` as it is — an unsaved edit in someone's editor is not an answer to the control
      question — and leave the affected `provides:` key **out** of the row on a first registration,
      or **exactly as it stands** on a re-run: a key already there recorded an observation made when
      the tree was clean, and dropping it would shrink the record. The affected key is `readme:` —
      the only need the ladder ever writes for; `ci:` and `license:` are filled by looking and a
      dirty tree does not stop you looking. Say what you found and ask the owner to commit or
      stash; re-running this is all that is needed afterwards.
- [ ] **Is it nested inside another repository's work tree?** A repo whose work tree sits inside
      another's has no independent control: record it `external`, with the containment named in the
      `note`, and write nothing. Unlike a dirty tree — which is transient — this is a permanent
      property of the repository, so it is an answer rather than a deferral.

**Any write that cannot be completed is handled the same way as a dirty tree** — a rejecting
pre-commit hook, branch protection, a read-only path, anything. Say what happened, leave the
`provides:` key out (or as it stands), leave `control:` alone, and invent no status. Neither
precondition aborts the action, and neither does this.

## The steps
1. **Identity → the row.** `name`, `location`, `type`, `description`. A `remote:` is **recorded**
   if the repo has one — never created, never repointed.
2. **`origin:`** — `created` if Throughstone is making this repo now, `adopted` if it already
   exists. It is written once and never changes; a repo handed over later was still created here.
3. **`control:`** — `managed` or `external`. A repo Throughstone is creating now is `managed`, with
   nothing asked; there is nobody else's work to write over. For a repo that already exists, **ask**
   — see *The control question* below.
4. **Fill `provides:`, one entry per need.** **No per-need question is asked**: control is the
   permission and it was granted once, for the whole repository. Writes happen only when
   `control: managed`; an `external` repo is observed and recorded, never written into.

   **A repo Throughstone is creating now** records what the scaffold wrote: `readme: ours` for the
   README stamped from `templates/repo-readme-template.md`, `ci: ours` for the gate it installed —
   `theirs`, note "nothing runs", if it installed none — and `license: ours` when a project
   `LICENSE` was written into that repo, otherwise `theirs` with a note naming
   `.throughstone/project-license` as where the posture is stated, because a proprietary project
   writes no per-repo `LICENSE` and the need is met by the posture being recorded.

   **A repo that already exists** is filled by looking, and its README runs the ladder
   (`METHOD.md` §7); the `## Role in <project>` section's shape is in
   `templates/repo-readme-template.md`. **Two sources disagreeing** about licensing — a `COPYING`
   and a `package.json` field, say — are both recorded as found in the note and the disagreement
   filed as a `registries/risks.yml` row; the status is still `theirs`, because the need is that
   the posture is *recorded*, not that it is tidy.

   Not every status can be reached by every need, and it saves hunting for a branch that does not
   exist: **README** reaches `ours`, `extended`, `theirs` and — on a repo Throughstone does not
   control — `gap`. **CI** and **licensing** reach only `ours` and `theirs`.
5. **Write the row, with notes** — creating `registries/repos.yml` and `registries/risks.yml` if they
   are absent, and saying that you did. Every value sits on **one line** and `provides:` entries are
   flow mappings; the rules at the top of `registries/repos.yml` are load-bearing, because the
   scripts that read that file match line prefixes and do not parse YAML.
6. **Add or refresh the Architecture Overview Repos entry** — role, the slice this repo owns, and
   where its detail lives (its own README if Throughstone wrote one; the owners' docs if not).
   **If the doc does not exist, create it**, seeded from `templates/architecture-doc-template.md` at
   `**Status:** Draft`, with a Version Log line recording that the Repos section was seeded at first
   registration. A bare stub without those header facts fails the project doctor.
   **Steps 5 and 6 are one unit — never one without the other.**
7. **Write the notice, then commit.** Copy the Throughstone notice into the repository **only when
   our material landed there** — that is, when `readme:` came out `ours` or `extended` — by running
   `scripts/apply-project-license.sh --notice-only <repo-path>`. Never on an `external` repo, and
   **check the path exists first**: the script treats a missing target as a usage error, and a repo
   that is not here is a skip, not a failure. Then commit: **one commit per repository**, each
   naming its paths explicitly, never `git add -A`. The action spans at least two repositories by
   construction — the row and the architecture entry are in the docs hub, the README section and the
   notice are in the repo — so a single commit was never possible. Writes land on the **STEP branch**,
   never on a repository's trunk — except where that STEP is branchless, as `METHOD.md` §7 makes
   the mono→multi split; there they land on trunk with the rest of that split's commits.

**Before you commit the docs-hub change, run `scripts/check.sh` once** and fix anything it reports
about the registry. Once per registration session, not once per repository.

## The control question
Explain **once**, however many repos are in the list, then ask one line per repo. The preamble has to
say what the answer authorizes, or someone is consenting to something they were not shown:

- **`managed` is a standing write permission**, asked once for the whole repository and never per
  file. In practice it authorizes **two files**: this repo's README — a short section added to the
  one it has, or the whole template if it has none — and a small notice saying what of ours is in
  it. Never a CI workflow, never a license.
- **`external` is fully documented**, not excluded — the repo gets a row, statuses, notes and an
  Architecture Overview entry. It is simply never written into.
- **These are the only two answers.** A later refusal to have a file written is this question
  answered again, not a veto on that file.
- **Skipping is safe.** Unanswered reads as `external`, and the next check-in asks again.

**Recommend managing everything the operator has authority over** — and only that; a repo someone
else owns is exactly what `external` is for. The reason is cost, not preference: an `external` repo
never appears in a STEP's plan, its connection back to the project goes stale because nothing
maintains the section that points there, and the check-in re-asks about it every cycle, forever.
Mixed control also means everyone has to track which repos are which. **The recommendation does not
change the default** — unanswered still means `external`, because an unanswered permission is not a
granted one.

**"All of them" is a fine answer** — a team adopting its own repos is the ordinary case. If that is
the answer, **name the repos back before writing.** Twelve names is a half-second read and it catches
the one that should not have been on the list.

## Defaults, promotion and handover
- **Unanswered is `external`.** The safe value applies immediately; the question stays open until
  somebody answers it, and the doctor names the row meanwhile.
- **Promotion `external` → `managed` is this same action, re-run.** It re-runs the ladder for each
  need and must leave no `gap`. Nothing separate to build, which is what makes "manage three now,
  the rest later" cost nothing.
- **Handover `managed` → `external`** sets the field **and moves every `ours` / `extended` on that
  row to `theirs`, in the same edit**, each `note` recording that Throughstone wrote it
  (`METHOD.md` §7 for why). `origin:` never moves and the notice stays where it is. Promoting the
  repo back later leaves those statuses at `theirs`: the check-in re-checks them, not assumes.

## Running it again
This action is **idempotent and resumable**. Re-running it on a registered repo refreshes the row
rather than duplicating it — and if a `## Role in <project>` section is already in the README,
**update it in place; never append a second one.** `readme: extended` on the row tells you it is
there before you open the file. Refreshing means updating what this action writes, not rebuilding
the row: a `provenance:` block, which only a split writes (`runbooks/splitting-repos.md`), is left
exactly as it stands. Re-running is also the fix when a check-in finds the row and the
Architecture Overview entry out of step.

## Output / record
- The **row** in `registries/repos.yml`, with a note on every entry that needs one.
- The **Architecture Overview Repos entry** — created with the doc if the doc was absent.
- In a `managed` repo, the **README section** and the **notice** — and nothing else.
- A **`registries/risks.yml` row** for a repository that could not be reached, or for a shortfall
  that is genuinely risky. A thin README or a CI job that only runs a linter is recorded as what it
  is and left to ordinary forward work; that is not what this action is for.
