# Registries

Machine-readable **inventories of the project's state** — structured data, not prose. Unlike
the other doc folders (whose README *is* the index), a registry's index is the data file
itself, because tooling and CI parse it. Keep each file the **source of truth**; describe the
*why/when* here and the *schema* in the file's own header — don't duplicate one in the other.

## Files

| File | What | Consumed by |
|------|------|-------------|
| [`repos.yml`](repos.yml) | The repo inventory — which repos exist, what each is, and where its docs live. See its header and `METHOD.md` §7. | `scripts/setup-workspace.sh` (clones from `remote:`); `runbooks/collaboration.md` (STEP-number reservation); CI. |
| [`risks.yml`](risks.yml) | The accepted risk / tech-debt index — known risks, conscious deferrals, and debt with owners, revisit triggers, and references to the artifact that explains the detail. | Security session deferrals; dependency audits; incident follow-ups; `runbooks/check-in.md`. |
| [`security-reviews.yml`](security-reviews.yml) | The security review ledger — latest S0/S1/S2 review dates, cadence, report paths, reviewed commit, rough SLOC snapshot, and deltas since the previous run. | `runbooks/security-review.md`; `runbooks/check-in.md` security gate. |

New registries (e.g. an owners or services map) get a row here and their own self-documenting
header.
