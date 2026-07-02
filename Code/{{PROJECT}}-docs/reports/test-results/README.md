# Test Results

Durable test, coverage, and quality-gate result reports for {{PROJECT}}.

Use this folder for completed evidence that should survive beyond an individual CI run or STEP:
coverage summaries, full-suite summaries, release-candidate test evidence, and notable failed
runs that create follow-up work. Routine transient build output still belongs in CI artifacts or
local ignored files; commit only the report or compact artifact that future maintainers should be
able to read.

Do not commit a generated multi-file coverage site by default. Tools such as JaCoCo,
pytest-cov/htmlcov, Istanbul, and LCOV viewers often produce an HTML tree that mirrors the source
tree. That is useful for inspection, but it is usually too noisy for the docs repo. Prefer a
Markdown summary here that points to the CI artifact, coverage service, or local command that
produced the full tree.

## When To Write One

Write a summary when the test result is evidence for a project checkpoint or decision: a check-in,
release candidate, incident follow-up, security review, major quality-gate change, or a failed run
that creates follow-up work — or when requested by a user. Do not write one for every routine CI pass.

## Naming

Prefer stable, sortable filenames:

```text
YYYY-MM-DD-step-NNNN-test-results.md
YYYY-MM-DD-step-NNNN-coverage-report.md
```

If a report covers a specific repo, language, or suite, append a short scope:

```text
YYYY-MM-DD-step-NNNN-api-coverage-report.md
YYYY-MM-DD-step-NNNN-web-e2e-test-results.md
YYYY-MM-DD-release-candidate-1-test-results.md
```

If a project has a real release, audit, or compliance reason to retain generated artifact trees in
git, define that project-specific convention in the Test Strategy architecture doc. Otherwise,
keep generated trees out of the docs repo.

## What To Record

Start from
[`../../templates/reports/test-results/test-results-summary-template.md`](../../templates/reports/test-results/test-results-summary-template.md)
when writing a Markdown summary.

Each report should include:

- STEP or release context, who ran it, environment, repo(s), branch(es), and commit SHA(s).
- Overall result and run source, such as a local command, CI run, PR, or release job.
- Commands or CI jobs run.
- Pass/fail/skip counts and important failures.
- Coverage tool, coverage result, and whether any configured threshold or changed-lines gate passed.
- Location of the full generated artifact, if any: CI artifact URL, coverage-service URL, or local
  ignored path.
- Follow-up issue, STEP, ADR, or accepted-risk reference for anything not fixed immediately.
- Additional notes for unusual context, manual verification, temporary workarounds, or known CI
  instability.

Coverage is a visibility and trend signal, not proof of quality. Pair the number with the
critical paths covered and the important gaps that remain.
