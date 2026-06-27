# S0 Security Baseline Report Template — {{PROJECT}}

**Review level:** S0 — Security Baseline
**Review date:** YYYY-MM-DD
**Trigger:** First release approaching / explicit early baseline / repo-CI-hosting change /
S2 prerequisite / other: TBD
**Reviewer(s):** TBD
**Report owner:** TBD
**Reviewed commit:** TBD
**STEP / issue:** TBD

## Summary

- **Baseline decision:** Done / Planned before release / Deferred / Accepted Risk / Partial
- **Release-readiness impact:** TBD
- **Highest-risk gap:** TBD
- **Next required action:** TBD
- **Next review trigger/date:** TBD

## Scope

### Included

- Repositories: TBD
- CI/CD systems: TBD
- Package ecosystems: TBD
- Deployment artifacts: TBD
- Infrastructure/cloud/IaC: TBD
- Secret stores and environments: TBD
- External security tooling/dashboards: TBD

### Intentionally skipped

| Area skipped | Reason | Owner | Revisit trigger |
|--------------|--------|-------|-----------------|
| TBD | TBD | TBD | TBD |

## Change Markers

| Marker | Value | Notes |
|--------|-------|-------|
| Previous S0 report | TBD | Blank if this is the first S0. |
| Elapsed time since previous S0 | TBD | TBD |
| Reviewed commit | TBD | Match `registries/security-reviews.yml`. |
| Commits since previous S0 | TBD | Leave blank with note if impractical. |
| Rough SLOC or equivalent size | TBD | Optional cheap snapshot. |
| Rough SLOC delta since previous S0 | TBD | Leave blank with note if impractical. |
| Major repo/CI/hosting/ownership changes | TBD | TBD |

## Baseline Decision Table

Use statuses exactly as defined by
[`runbooks/security-review-s0-checklist.md`](../../../runbooks/security-review-s0-checklist.md):
`Done`, `Planned`, `Deferred`, `Accepted Risk`, or `N/A`.

| Area | Baseline item | Status | Decision date | Owner | Reason / evidence | Revisit trigger | Risk ref |
|------|---------------|--------|---------------|-------|-------------------|-----------------|----------|
| Release posture | First-release security baseline decision recorded. | TBD | YYYY-MM-DD | TBD | TBD | Before first release; before public launch; when release scope changes. | TBD |
| Repository hygiene | Branch protection, required checks, and review rules are configured or explicitly deferred. | TBD | YYYY-MM-DD | TBD | TBD | Before first release; after repo host changes. | TBD |
| CI hygiene | CI workflows, token permissions, third-party actions/images, and secret exposure rules are reviewed. | TBD | YYYY-MM-DD | TBD | TBD | After workflow changes; before accepting outside PRs. | TBD |
| Secrets handling | Secret storage, local config, secret scanning, and exposure response are configured or explicitly deferred. | TBD | YYYY-MM-DD | TBD | TBD | Before shared deployments; before public source. | TBD |
| Dependency alerts | Dependency vulnerability alerts, update policy, lockfile hygiene, and license review are configured or explicitly deferred. | TBD | YYYY-MM-DD | TBD | TBD | Before first release; after adding package ecosystems. | TBD |
| Static analysis | SAST/security linting is configured, planned, deferred, accepted as risk, or marked N/A. | TBD | YYYY-MM-DD | TBD | TBD | Before first release; after stack changes. | TBD |
| Artifacts | Container/image/package scanning and artifact provenance are configured or marked N/A. | TBD | YYYY-MM-DD | TBD | TBD | Before shipping artifacts; after pipeline changes. | TBD |
| Infrastructure | IaC/cloud config scanning and production-like access/network controls are reviewed or marked N/A. | TBD | YYYY-MM-DD | TBD | TBD | Before production infrastructure; after hosting changes. | TBD |
| SBOM | SBOM generation is configured, planned, deferred, accepted as risk, or marked N/A. | TBD | YYYY-MM-DD | TBD | TBD | Before customer/enterprise distribution; when S2 requires it. | TBD |
| Operations | Monitoring, incident entry point, access review, backup/recovery, and sensitive-data assumptions are reviewed. | TBD | YYYY-MM-DD | TBD | TBD | Before production use; after data/ops changes. | TBD |

## Tooling Inventory

| Tool / control | Purpose | Scope | Status | Evidence / link | Owner |
|----------------|---------|-------|--------|-----------------|-------|
| TBD | Dependency alerts | TBD | TBD | TBD | TBD |
| TBD | Secret scanning | TBD | TBD | TBD | TBD |
| TBD | SAST / security lint | TBD | TBD | TBD | TBD |
| TBD | Container/image/package scan | TBD | TBD | TBD | TBD |
| TBD | IaC/cloud config scan | TBD | TBD | TBD | TBD |
| TBD | SBOM generation | TBD | TBD | TBD | TBD |
| TBD | OpenSSF Scorecard-style repo hygiene | TBD | TBD | TBD | TBD |

## Findings and Decisions

### Fixed During Review

| Item | Change made | Evidence |
|------|-------------|----------|
| TBD | TBD | TBD |

### Planned Follow-Up

| Item | Owner | Target date / trigger | STEP / issue | Risk ref |
|------|-------|-----------------------|--------------|----------|
| TBD | TBD | TBD | TBD | TBD |

### Deferred Or Accepted Risk

| Risk ref | Decision | Reason | Owner | Revisit trigger |
|----------|----------|--------|-------|-----------------|
| TBD | Deferred / Accepted Risk | TBD | TBD | TBD |

## Reviewer Notes

TBD
