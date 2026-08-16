# {{repo-name}}

> One line: this repo's role, and how it fits the system. (Link the architecture doc that
> defines it, e.g. `{{PROJECT}}-docs/architecture/*-architecture-overview.md`.)

<!--
  STAMP this into a repo the method CREATES — every repo, including in a multi-repo design,
  must carry a README. Keep the section headings consistent across all repos so the project
  reads uniformly. Sections that don't apply can be dropped (e.g. no "API / interface" for a
  library), but keep the order — and never drop the role one-liner above or the Overview
  below: explaining what the repo *is* is the one non-negotiable part.

  AUGMENT a repo REGISTERED IN PLACE — one that existed before this project did — WHEN IT ALREADY
  HAS A README. The rule keys on whether that file exists, not on how the repo got here: a
  registered-in-place repo with no README has nothing to preserve, so write its README from this
  template — every section except **Licensing**, which describes a repo the method created and is
  dropped here for the same reason it is never added when augmenting: no project `LICENSE` is
  applied to such a repo, so that section would describe files it does not have. `--notice-only`
  (below) writes the only licensing statement the method puts in such a repo.
  That creates the one file; nothing else about such a repo is scaffolded, and it is
  still offered rather than assumed, since it is the user's repo.

  Where a README does exist it is usually the repo's most-read file, often linked from outside
  it, so stamping over it destroys work the method did not do. Everything below except the role
  one-liner and Overview is something a working repo already documents — setup, tests,
  configuration — written by the people who actually run it; re-deriving those replaces accurate
  content with inferred content.
  What such a repo is usually missing is the part this template leads with: its place in a
  larger system.

  So add only that, as a short `## Role in {{PROJECT}}` section — the role one-liner, two or
  three sentences on the slice of the system this repo owns, and links to its architecture doc
  and the docs hub. Never replace, reorder, or rewrite a section the repo already has, and
  never stamp the Licensing section below into it (that describes a repo the method created).
  Show the exact text and where it will go, and get agreement before writing into someone
  else's repo; if they decline, that is a complete outcome — the same information already lives
  in the repo's architecture doc, and in its `registries/repos.yml` row where the project keeps
  an inventory.

  A DECLINE MAY BE STANDING. With several repos registered in place this same proposal goes to
  the same people repo after repo, and someone who has already said no is not asking to be asked
  again for each remaining one. So on a decline, establish whether it covers this repo or the
  rest — and where it is standing, stop proposing and record that those repos document
  themselves. Ask that once, not per repo. The permission is never what carries forward, only
  the refusal: a yes for one repo says nothing about the next, whose text is its own proposal.

  For a repo this method CREATES, stamp the CI gate named by the Test Strategy architecture doc
  too: drop `templates/ci/code-repo-ci.yml` into this repo's `.github/workflows/ci.yml` and fill
  in its stack's test command (see `templates/ci/README.md`). For a repo REGISTERED IN PLACE,
  never install it — that repo has its own CI, and the template gate fails until configured, so it
  would either replace what gates their merges or fail every build until removed. Record what the
  repo already runs and leave its pipeline alone.

  For a repo this method CREATES, apply the project license established at bootstrap by running
  `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh <this-repo-path>`. It copies the
  docs hub's canonical `LICENSE` unchanged for open-source projects. Proprietary projects
  get no project license file. It also copies `LICENSE-THROUGHSTONE` for this retained
  Throughstone-authored README/CI scaffolding and writes `LICENSING.md` to make the boundary
  between the two licenses explicit.

  For a repo REGISTERED IN PLACE — one that existed before this project did — do NOT run it.
  That repo already has an owner and a licensing status; a repo the method did not create keeps
  what it already has, licensing included (`METHOD.md` §7). Read what the repo uses
  (`LICENSE`, `COPYING`, `NOTICE`, package metadata, vendored third-party terms, or a deliberate
  absence), record that, and leave its licensing alone — including when it differs from the
  bootstrap selection, which governs only this method's own artifacts and the repos it creates.

  What such a repo may still be owed is the notice. If the README addition above was accepted —
  a `Role in {{PROJECT}}` section, or a README written from this template for a repo that had
  none — that material is Throughstone-authored, so run
  `Code/{{PROJECT}}-docs/scripts/apply-project-license.sh --notice-only <this-repo-path>`. It
  places `LICENSE-THROUGHSTONE` and a `LICENSING.md` naming only what the notice covers, writes
  no project `LICENSE`, and makes no claim about the rest of the repository — which is why it is
  allowed here when the plain invocation above is not. If the addition was declined, nothing
  Throughstone-authored is in the repo and nothing is owed: a notice pointing at absent material
  only misleads a later reader.

  EVERYTHING ABOVE SPLITS ON ONE QUESTION: did this method create this repo, or did the repo get
  here first? Where that is genuinely unclear, or where the answer doesn't settle what to do with
  this repo's README, CI, license, or notice, ASK THE USER AND WRITE NOTHING UNTIL THEY ANSWER
  (`METHOD.md` §7). The question costs one message; the wrong write lands in a repo this method
  does not own. That is a fallback for a case these rules don't reach, not a substitute for
  following them where they do.
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
