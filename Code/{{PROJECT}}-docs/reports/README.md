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

Report templates live under `templates/reports/`; reports in this folder tree are completed
review and operational artifacts, not blank templates.
