## What this changes
A brief description of the change and why it's needed.

## Related issue
Closes #___

<!-- For larger methodology changes, please open an issue to discuss first — see CONTRIBUTING.md. -->

## Type of change
- [ ] Bug fix
- [ ] Documentation / wording
- [ ] New or updated template / coding-standard
- [ ] Methodology change (discussed in an issue first)
- [ ] Other:

## Checklist
- [ ] If I changed shell: `bash -n` and `shellcheck` pass for the affected scripts
- [ ] `Code/{{PROJECT}}-docs/scripts/check.sh` and the relevant `tests/*.sh` regressions pass
- [ ] If I changed the wizard or templates, I ran a throwaway `init.sh` smoke test and confirmed a clean generated project
- [ ] Kept the `{{PROJECT}}` placeholder convention intact
- [ ] Updated `METHOD.md` / `README.md` / `prompts/` for consistency where the change affects them
