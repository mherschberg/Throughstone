# Runbook — Register a repository

Bring a repository into the project: record it, give it a README, and put our licence notice in
it. Run this when a repo is created, adopted, or split out of another.

The goal is that the **result** is the same however a repo arrived.

## Before you start

- **Work from the workspace root.** Every path below is written relative to it and can be used
  as-is, including the repo locations in the registry.
- **You need, per repo:** its name, location, `type`, a one-line description, whether it was
  created or adopted, its remote if it has one, and — for step 4 — its role, which slice of the
  project it owns, and where its detail lives. The `type` vocabulary is listed beside the field
  in `Code/{{PROJECT}}-docs/registries/repos.yml`.
- **Do not invent any of these. Ask.** A description or a role you guessed reads exactly like one
  somebody decided.

## The steps

1. **Add the row** to `Code/{{PROJECT}}-docs/registries/repos.yml`:

   ```yaml
   - name: "{{PROJECT}}-api"
     location: "Code/{{PROJECT}}-api/"
     type: service
     description: "..."
     added_as: adopted                     # created | adopted — written once, never changes
     remote: "git@example.com:TEAM/api.git"
   ```

   **`location:` is always inside the workspace** — a path relative to the workspace root, so a
   teammate reproduces the whole workspace from this file; a repo that genuinely cannot move stays
   where it is, with a symlink at that workspace-relative path pointing at the real checkout.

   **`remote:` is recorded if the repo has one** — never created, never repointed. Put nothing
   after a `- name:`, `location:` or `remote:` value: the readers take the rest of the line as part
   of it, so a trailing `# note` ends up inside the name, the path or the clone URL.

   **A repo split out of another is `added_as: created`** — the method made it — with the split
   history in its `provenance:` block, written by
   `Code/{{PROJECT}}-docs/runbooks/splitting-repos.md`.

   A repo with no remote yet is fine; the check-in flags it as a bus-factor risk. **`name` is the
   row's identity** — re-running matches on it, and a field that already says what you were going
   to write needs nothing. A `location:` or `remote:` that is **absent or empty** gets filled in:
   that is a refresh, and the periodic check-in does exactly that when it finds a row with no
   location, or a repo pushed to a host for the first time. One that holds a **different** value
   is **raised and changed by nobody** — a repo that moved or was repointed is a decision.

2. **The README — decided by what is in the repo.**
   - **No README** — stamp `Code/{{PROJECT}}-docs/templates/repo-readme-template.md`.
   - **A README already there** — leave it and add a `## Role in <project>` section, shape in the
     same template. If that section is already present, **update it in place; never append a
     second one.**

3. **Licensing — decided by whether we created the repo. Two separate artifacts, and they do not
   travel together.**

   | | created by us | adopted |
   |---|---|---|
   | project `LICENSE` + `LICENSING.md` | written from the posture | **never** — their licensing is not ours to state |
   | `LICENSE-THROUGHSTONE` | written | written — our material there needs a notice |

   - **Created by us** — `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh Code/<repo>/`
   - **Adopted** — `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh --notice-only Code/<repo>/`

   Check the path exists first. An existing notice is left alone. A **proprietary** posture writes
   `LICENSING.md` and the notice but no project `LICENSE` — that is the posture doing its job, not
   a failure.

4. **Add or refresh the Architecture Overview Repos entry** — the repo's role, the slice it owns,
   and where its detail lives. The doc is
   `Code/{{PROJECT}}-docs/architecture/03-architecture-overview.md`; match an existing entry by
   repo name. **If the doc does not exist, create it at exactly that path** from
   `Code/{{PROJECT}}-docs/templates/architecture-doc-template.md` at `**Status:** Draft`.

   **Always do both step 1 and step 4** — a row with no architecture entry, or the reverse, is
   half a registration. But if one fails, **do not roll back the other**: finish what works,
   report the gap, and re-running this runbook is the fix.

5. **Commit — one commit per repository**, naming its paths explicitly, never `git add -A`.
   - **Docs hub** — the row and the Architecture Overview entry.
   - **The repo itself** — its README and **every licensing artifact step 3 wrote there**, not
     the notice alone.

## When something does not work

**Raise it in the chat and keep going.** Nothing here aborts the run, and nothing is recorded as
a status to be reconciled later.

A repo may not be on this machine, may have a dirty tree, may reject the write, may be read-only,
may sit inside another repo's work tree. In every case: **do the parts that work, name the parts
that did not, and let the human decide.** They can commit, stash, grant access, or say skip it.

## Report — always, even when everything worked

End the run with one block per repository. **A repo you skipped is named here too**; a silent
partial run reads as a complete one.

- **`✓`** — the step's expected end state was reached **by this run**: the row says what it
  should say, the Role section is current, the artifact is on disk, the commit is in the log.
  Not "attempted", and not "already there but stale".
- **`—`** — not reached. Always takes a reason line.
- **`n/a`** — correctly did not apply. Also takes a reason. A commit with nothing to commit,
  because everything was already right, is `n/a` — never invent an empty commit to earn a `✓`.

```
{{PROJECT}}-api
  row ✓   README ✓ (stamped)   licence ✓   arch entry ✓   docs commit ✓   repo commit ✓

acme-billing
  row ✓   README —   licence ✓   arch entry ✓   docs commit ✓   repo commit —
  → README: work tree is dirty. Asked the owner to commit or stash, then re-run.
  → repo commit: blocked by the same dirty tree; the notice is written but uncommitted.

internal-tooling
  SKIPPED — nothing is checked out at Code/internal-tooling/ on this machine.
```

`licence ✓` means every artifact that repo's posture requires landed: for one we created,
`LICENSING.md` and `LICENSE-THROUGHSTONE`, plus a project `LICENSE` unless the posture is
proprietary; for an adopted repo, the notice alone.

## Running it again

Idempotent and resumable. Re-running matches the row by `name`, refreshing it rather than
duplicating it, and updates the `## Role in <project>` section in place.

`added_as:` never changes on a re-run, and a `provenance:` block is left exactly as it stands;
only a split writes it.

**There is no way to tell from the repo that a whole previous run succeeded** — a partial run may
have written the README while the row, the licence or a commit failed. Do not look for one. Just
re-run: it is safe, and it is also the fix when a check-in finds the row and the Architecture
Overview entry out of step.

## Example — adopting an existing repo

The team has `acme-billing` on GitHub, written before this project existed. It has its own README
and its own `LICENSE`.

1. Row: `added_as: adopted`, `remote` set to its GitHub URL, `type: service`.
2. It has a README, so that README stays exactly as it is and a `## Role in <project>` section
   goes on the end saying what slice of the project it owns.
3. `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh --notice-only Code/acme-billing/` —
   `LICENSE-THROUGHSTONE` lands beside their `LICENSE`, which is not touched.
4. `Code/{{PROJECT}}-docs/architecture/03-architecture-overview.md` gains a Repos entry pointing
   at the repo's own README.
5. Two commits: one in the docs hub, one in `acme-billing`.
