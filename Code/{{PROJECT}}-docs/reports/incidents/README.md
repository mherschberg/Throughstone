# Incident Reports

Incident postmortem reports for {{PROJECT}}.

Reports in this folder are produced by `runbooks/incident-postmortem.md`. They record the
durable RCA, similar-issue search, fixes, hardening, and follow-up work for production
incidents and near-misses. The Incident STEP tracks the work; the report artifact does not live
in the STEP folder.

Use stable, sortable filenames based on the report date and STEP number:

```text
YYYY-MM-DD-step-NNNN-incident-postmortem-report.md
```

If more than one incident postmortem report is written for the same STEP on the same date,
append a short scope:

```text
YYYY-MM-DD-step-NNNN-incident-postmortem-report-auth-timeouts.md
```

Completed report artifacts include `report` in the filename. Report templates include
`report-template`. Runbooks and checklists do not.

Start reports from
[`../../templates/reports/incidents/incident-postmortem-report-template.md`](../../templates/reports/incidents/incident-postmortem-report-template.md).

## Report Index

Add one row when a report is started, then update it when the incident closes. Keep the summary
short: what happened, who or what was affected, and the current state.

| Report | STEP | Report date | Incident window | Impact level | Status | Summary | Follow-up |
|--------|------|-------------|-----------------|--------------|--------|---------|-----------|
