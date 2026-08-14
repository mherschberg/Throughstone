# Reports

Durable review and operational reports for {{PROJECT}}.

Reports are factual artifacts produced by runbooks, audits, reviews, and incidents. They are
not plans and they are not architecture docs: a report records what was checked, what was found,
what changed, what was accepted as risk, and what follow-up work was created.

In a multi-repo project this folder lives in the documentation repo. In a mono-repo project it
lives under the scaffolded docs folder for that repo. Either way, keep reports out of STEP
folders; STEPs may create reports, but the reports themselves live here.

## Index

| Folder | What |
|--------|------|
| `./` | Check-in reports produced by `runbooks/check-in.md`. |
| [`incidents/`](incidents/README.md) | Incident postmortem reports produced by `runbooks/incident-postmortem.md`. |
| [`security/`](security/README.md) | Security baseline, sweep, and audit reports produced by `runbooks/security-review.md`. |
| [`test-results/`](test-results/README.md) | Durable test, coverage, and quality-gate result reports. |

## Check-In Reports

Check-in reports live directly in this folder because they are general project-health review
artifacts, not a specialized report family. Use stable, sortable filenames:

```text
YYYY-MM-DD-step-NNNN-check-in-report.md
```

If more than one check-in report is written for the same STEP, append a short scope:

```text
YYYY-MM-DD-step-NNNN-check-in-report-doc-drift.md
```

Start from
[`../templates/reports/check-in-report-template.md`](../templates/reports/check-in-report-template.md).
Keep the corresponding check-in STEP PLAN archived under `prompts/`; do not move the completed
report into the STEP folder.

## Recon Map Report

Written only when an existing codebase is adopted into {{PROJECT}} (`RETCON-PROMPT.md`, STEP-1). The
recon map is the point-in-time "birth certificate" of the adopted system — the inventory, stack,
services, data stores, integrations, existing-docs classification, and coverage found at adoption —
which the user confirms before anything is built on it, and which is never rewritten afterward. It
lives directly in this folder because it is a general review artifact, like a check-in report:

```text
YYYY-MM-DD-step-0001-recon-map.md
```

Start from
[`../templates/reports/recon-map-report-template.md`](../templates/reports/recon-map-report-template.md).
A greenfield project never produces one.

Report templates live under `templates/reports/`; reports in this folder tree are completed
review and operational artifacts, not blank templates.
