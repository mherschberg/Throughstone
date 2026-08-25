# {{repo-name}}

> One line: this repo's role, and how it fits the system. (Link the architecture doc that
> defines it, e.g. `{{PROJECT}}-docs/architecture/*-architecture-overview.md`.)

<!--
  Stamp a copy of this into each code repo **as Throughstone creates it** — every created repo,
  including in a multi-repo design, must carry one. Keep the section headings consistent across
  all repos so the project reads uniformly. Sections that don't apply can be dropped (e.g. no
  "API / interface" for a library), but keep the order — and never drop the role one-liner
  above or the Overview below: explaining what the repo *is* is the one non-negotiable part.

  Stamp the CI gate named by the Test Strategy architecture doc too: drop
  `templates/ci/code-repo-ci.yml` into this repo's `.github/workflows/ci.yml` and fill in its
  stack's test command (see `templates/ci/README.md`).

  Apply the project license established at bootstrap by running
  `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh <this-repo-path>`. It copies the
  docs hub's canonical `LICENSE` unchanged for open-source projects. Proprietary projects
  get no project license file. It also copies `LICENSE-THROUGHSTONE` for this retained
  Throughstone-authored README/CI scaffolding and writes `LICENSING.md` to make the boundary
  between the two licenses explicit.

  ---- A repo that already exists: augment, don't stamp ----

  Everything above is for a repo Throughstone creates. For a repo that already has a README,
  **never stamp this file over it, and never create a second README.** Add one section instead:

      ## Role in <project>

  carrying the role one-liner, two or three sentences naming the slice this repo owns *and what
  it explicitly does not*, and a link to the architecture doc that defines it. Not a bare pointer
  — the boundary statement is the thing a newcomer cannot get quickly from the code. Default to
  appending it at the end, and offer to place it higher: placement is content, and content is the
  owner's to shape. That heading through to the next `##` is the whole of Throughstone's part of
  the file, which is what a check-in sweeps. If the section is already there, update it in place.

  If the repo has **no** README at all, stamp this file — but **drop `## Licensing`**, whose link
  points at a `LICENSING.md` that is never written into a repo Throughstone did not create.
  Either way, do **not** install CI and do **not** apply a project license; for the Throughstone
  notice, and only where material of ours actually landed, run
  `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh --notice-only <this-repo-path>`.

  The whole procedure is `Code/{{PROJECT}}-docs/runbooks/register-repo.md`.
-->

## Overview
<!-- A short paragraph or two: what this repo does, the problem it owns within the system,
     how it relates to the other repos, and what a newcomer should understand before
     reading the code. Longer than the one-liner above, shorter than the architecture doc
     (link that for the full picture). This section is required — a repo without it doesn't
     explain itself.

     For a repo with real internal complexity, a README paragraph isn't enough: add an
     `ARCHITECTURE.md` at the repo root for its internal design — the main modules, key
     flows, and *why* it's built this way (the codebase-level counterpart to the hub's
     system-wide `architecture/` docs) — and link it from here. Skip it for a simple repo. -->

## Licensing

See [`LICENSING.md`](LICENSING.md) for the exact scope. A root `LICENSE`, when present,
governs project-authored content. `LICENSE-THROUGHSTONE` applies only to retained
Throughstone-authored scaffold material and does not license the project's application code.

## Tech stack
<!-- Language + version, framework, datastore(s), key libraries. -->

## Prerequisites
<!-- Explicit versions and external dependencies needed to run this locally. -->

## Setup
<!-- Step-by-step from a clean checkout to a runnable state. Number the steps. -->

## Running (local dev)
<!-- How to start it locally, and how to verify it's up (health check, sample request). -->

## API / interface
<!-- For a service: link the versioned spec (OpenAPI / GraphQL / protobuf) as the interface
     contract of record named by `{{PROJECT}}-docs/architecture/*-interface-contracts.md`, with a short
     endpoint table for orientation — don't duplicate the spec here. For a library: the
     public surface. Skip if not applicable. -->

## Testing
<!-- How to run the tests; the tiers (unit / integration / e2e) and what each covers. -->

## Configuration
<!-- Environment variables / config files, and where secrets come from per environment. -->

## Project structure
<!-- A short tree of the important directories. -->

## Troubleshooting
<!-- Common errors and their fixes. -->
