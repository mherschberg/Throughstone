# Shell (Bash) coding standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane defaults so code is consistent from
> day one. Change anything that doesn't fit your team.
>
> **Cross-cutting.** Shell scripts show up across the repo — CI glue, dev scripts, Docker
> entrypoints — alongside whatever language a project is written in. Record real decisions (a
> required interpreter, a target environment) in an ADR and link it from this file.

**Baseline:** this standard targets **bash** — it is bash-specific, not portable POSIX `sh`.
Reach for `sh`/`dash` only when a constraint requires it (e.g. a minimal Alpine image), and say
so at the top of the script. Follow the
[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html); lint with
**ShellCheck** and format with **shfmt**, both pinned in CI so the standard is enforced, not just
documented.

**Prefer a real language past simple scripts (recommendation).** Shell is best for small
utilities and wrappers. When a script grows beyond ~100 lines, or needs non-straightforward
control flow or real data structures, it's usually worth rewriting in Python/Go — easier to test,
read, and maintain. This is a guideline to weigh, not a hard gate.

## Preamble & strict mode
- **Shebang — a project decision; pick one and apply it everywhere.** `#!/usr/bin/env bash`
  resolves bash via `PATH`, so it works where bash isn't in `/bin` (macOS/Homebrew, Nix);
  `#!/bin/bash` is an absolute path (what the Google guide mandates) and avoids `PATH` surprises.
  There's no universal default — settle it for the project (and record the why if it's not obvious).
- Start scripts with **strict mode**: `set -euo pipefail` — exit on error, error on unset
  variables, and fail a pipeline if any stage fails. Be aware `set -e` has well-known edge cases,
  so still check explicitly any command whose failure you must handle. Set `IFS=$'\n\t'` when
  word-splitting behavior matters.

## Safety & quoting
- **Always quote expansions** — `"${var}"`, `"$(cmd)"`, and `"$@"` (never `$*`). Unquoted
  expansion causes word-splitting and glob bugs, the single most common shell defect; ShellCheck
  flags them.
- Use **arrays** for argument lists and iterate with `"${arr[@]}"`. Avoid **`eval`**. Use explicit
  paths with globs (`./*`, not `*`), and don't parse the output of `ls`.

## Naming & layout
- `lower_snake_case` for variables and functions; `UPPER_SNAKE_CASE` for constants and exported
  environment (`readonly MAX_RETRIES=3`). Declare function-local variables with **`local`**.
- 2-space indentation (no tabs), lines ≤ 80 columns. Put `; then` / `; do` on the same line as
  `if`/`for`/`while`, and `{` on the same line as the function name. Define functions near the top;
  if a script has multiple functions, put the body in **`main()`** and call `main "$@"` at the end.

## Commands & idioms
- Prefer **`[[ … ]]`** over `[ … ]`/`test`; use `==` for string comparison and **`(( … ))`** for
  arithmetic and numeric comparison (never `<`/`>` inside `[[ … ]]`). Use **`$(…)`**, not
  backticks.
- Prefer shell builtins over spawning external processes. Avoid aliases in scripts — use functions.

## Error handling
- Send **all error and diagnostic messages to STDERR** (`echo "..." >&2`); keep STDOUT for real
  output. Return meaningful **exit codes** (`0` success, non-zero failure).
- Use a **`trap … EXIT`** to clean up temp files and resources even on failure
  (`trap 'rm -f "${tmpfile}"' EXIT`). Check return values — `if cmd; then …` or `$?` — and inspect
  individual stages of a pipeline via the **`PIPESTATUS`** array.
