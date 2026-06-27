# Security Reports

Security review reports for {{PROJECT}}.

Reports in this folder are produced by `runbooks/security-review.md`:
- **S0 — Security Baseline**
- **S1 — Security Sweep**
- **S2 — Security Audit**

Use stable, sortable filenames:

```text
YYYY-MM-DD-s0-security-baseline.md
YYYY-MM-DD-s1-security-sweep.md
YYYY-MM-DD-s2-security-audit.md
```

If more than one report of the same level is written on the same date, append the STEP number or
a short scope:

```text
YYYY-MM-DD-s1-security-sweep-step-0042.md
YYYY-MM-DD-s2-security-audit-payments.md
```

`registries/security-reviews.yml` points to the latest report for each S0/S1/S2 level. Keep
older reports here for history; do not move them into STEP folders when the STEP is archived.

## Templates

Start S0 reports from
[`../../templates/reports/security/s0-security-baseline-report-template.md`](../../templates/reports/security/s0-security-baseline-report-template.md)
and copy the applicable rows from
[`../../runbooks/security-review-s0-checklist.md`](../../runbooks/security-review-s0-checklist.md).

Start S1 reports from
[`../../templates/reports/security/s1-security-sweep-report-template.md`](../../templates/reports/security/s1-security-sweep-report-template.md)
and copy the applicable rows from
[`../../runbooks/security-review-s1-checklist.md`](../../runbooks/security-review-s1-checklist.md).

Start S2 reports from
[`../../templates/reports/security/s2-security-audit-report-template.md`](../../templates/reports/security/s2-security-audit-report-template.md)
and use the applicable module prompts from
[`../../runbooks/security-review-s2-checklist.md`](../../runbooks/security-review-s2-checklist.md)
to write the module prose sections and compact outcome tables. Do not paste the wide S2
checklist table into the report unless the project needs row-level traceability.
