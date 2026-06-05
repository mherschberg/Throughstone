# Coding Standards

Per-language engineering standards for {{PROJECT}}: naming, layout, error handling,
logging, documentation, and testing conventions. Code substeps should reference the relevant
standard so the codebase stays consistent regardless of who (or which agent) writes it.

## How this works
- Default standards for common languages ship with Throughstone (e.g. `python.md`,
  `typescript.md`, `go.md`, `rust.md`, `dart.md`, `java.md`, `csharp.md`), plus cross-cutting
  `sql.md` (SQL in migrations, queries, and embedded in app code), `shell.md` (Bash scripts —
  CI glue, dev scripts, entrypoints), and `api.md` (the house style for REST/HTTP APIs —
  timestamps, pagination, errors, versioning). **These are starting points — review and
  customize them** to match your team's preferences. Nothing here is fixed law; treat the
  shipped contents as a draft to edit, not a rule to obey.
- You only need the file(s) for the language(s) you actually use. The **Test Strategy session**
  reconciles this directory to the languages chosen in the Architecture Overview doc and records
  the result in the Test Strategy architecture doc: for each language it either has you *review*
  the standard that ships, or *create* a new one from an existing file's pattern if there's no
  default — then prunes the rest. (See the "Coding standards per language" decision in that
  session.)
- If a standard reflects a decision (e.g. "we use X error-handling pattern because…"),
  link the ADR that records why.

## Documentation & comments  (all languages)
A project-wide rule; each language file shows the idiomatic *form* and the lint that
enforces it.
- **Docstrings are required on every class, method, and function** — and on fields/properties
  where the language documents them (e.g. Java fields, C# properties) — public *and* private.
  Say what it does, its parameters and return, and anything non-obvious about its contract.
  Describe what the code **actually does**, not what you set out to write — a docstring that
  drifts from the behavior misleads worse than silence. This is a gate: code without them
  isn't done.
- **Comment for the next reader.** As a guideline, expect roughly a comment every ~10 lines
  of non-trivial code — a readability *suggestion*, not a counted requirement. Explain the
  *why*; don't restate what the code already says. Cut narration (`// increment i`): it's
  noise, and it goes stale.
- **Keep comments and docstrings true** as the code changes — a stale one is worse than none.

## Files
Defaults that ship with Throughstone. Keep the file(s) for the language(s) you use, prune
the rest, and customize the contents to match your team.

| Language | File | Status |
|----------|------|--------|
| Python | [`python.md`](python.md) | Default — customize |
| TypeScript | [`typescript.md`](typescript.md) | Default — customize |
| Go | [`go.md`](go.md) | Default — customize |
| Rust | [`rust.md`](rust.md) | Default — customize |
| Dart / Flutter | [`dart.md`](dart.md) | Default — customize |
| Java | [`java.md`](java.md) | Default — customize |
| C# | [`csharp.md`](csharp.md) | Default — customize |
| SQL (cross-cutting) | [`sql.md`](sql.md) | Default — customize; secondary to the language docs |
| Shell / Bash (cross-cutting) | [`shell.md`](shell.md) | Default — customize |
| API design (cross-cutting) | [`api.md`](api.md) | Default — customize; keep only if the project exposes/consumes an HTTP API |
