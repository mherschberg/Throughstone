# CI starter (GitHub Actions)

Two workflows so a {{PROJECT}} project has continuous integration **from day one** — the method
checks and the test gate the architecture's test-strategy session calls for (`architecture/11-test-strategy.md`,
"CI gates"). They're GitHub Actions, but the *shape* (check on push/PR, fail on red) ports to any CI.

## 1. Method integrity — `method-check.yml`  *(ships live; no template step)*

Runs the project "doctor" (`scripts/check.sh` in the docs hub): duplicate STEP/ADR numbers, invalid statuses,
architecture-doc frontmatter, ADR registry vs. files on disk, root hygiene. It is **already
installed** in the docs hub at `Code/{{PROJECT}}-docs/.github/workflows/method-check.yml`, so in a
**multi-repo** project (the hub is its own repo) it's active the moment you push the hub — nothing
to place.

- **Multi-repo:** active as shipped. In the hub it validates the hub's content (ADRs + architecture
  docs); the `STEP-index` lives in the `prompts/` repo, so those checks skip here and run in full
  when the whole workspace is checked out (locally and at each check-in).
- **Mono-repo-for-now:** the workspace root is the single repo, and a workflow nested under
  `Code/<project>-docs/` does **not** trigger there — **copy** `method-check.yml` to the **root**
  `.github/workflows/`. The workflow auto-detects `Code/<project>-docs/scripts/check.sh`;
  from the root, that script sees `prompts/` too, so the STEP-index checks run as well.

## 2. Code-repo tests — `code-repo-ci.yml`  *(template; stamp per repo)*

The test gate for a code repo. When you scaffold a code repo (stamping its README from
`templates/repo-readme.md`), also drop this into that repo's `.github/workflows/ci.yml` and fill in
the toolchain + test command for its stack — examples for Node / Python / Go / Rust are inlined.

It **fails until configured** on purpose: an unconfigured gate that silently passes is worse than
none. Replace the `Configure me` step (which `exit 1`s) with your real setup + test command.

## Keeping it honest

CI enforces what the method otherwise trusts to discipline. Pair it with the local tools:
`scripts/status.sh` (where am I / what's next) and `scripts/check.sh` in the docs hub (the same
checks CI runs, on your machine before you push). The periodic check-in (`runbooks/check-in.md`)
already runs `check.sh` as its mechanical first pass.
