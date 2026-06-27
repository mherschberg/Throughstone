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
| [`security/`](security/README.md) | Security baseline, sweep, and audit reports produced by `runbooks/security-review.md`. |

Report templates live under `templates/reports/`; reports in this folder are completed review
artifacts, not blank templates.
