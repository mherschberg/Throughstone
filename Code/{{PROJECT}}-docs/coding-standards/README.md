# Coding Standards

Per-language engineering standards for {{PROJECT}}: naming, layout, error handling,
logging, testing conventions. Code substeps should reference the relevant standard so the
codebase stays consistent regardless of who (or which agent) writes it.

## How this works
- Default standards for common languages ship with Throughstone (e.g. `python.md`,
  `typescript.md`, `go.md`, `rust.md`, `dart.md`). **They are starting points — overwrite or
  replace them** to match your team's preferences.
- You only need the file(s) for the language(s) you actually use. **Session 1.11
  (test strategy)** reconciles this directory to the languages chosen in 1.3: for each
  language it either has you *review* the standard that ships, or *create* a new one from an
  existing file's pattern if there's no default — then prunes the rest. (See the "Coding
  standards per language" decision in that session.)
- If a standard reflects a decision (e.g. "we use X error-handling pattern because…"),
  link the ADR that records why.

## Files
Defaults that ship with Throughstone. Keep the file(s) for the language(s) you use, prune
the rest, and overwrite the contents to match your team.

| Language | File | Status |
|----------|------|--------|
| Python | [`python.md`](python.md) | Default — overwrite |
| TypeScript | [`typescript.md`](typescript.md) | Default — overwrite |
| Go | [`go.md`](go.md) | Default — overwrite |
| Rust | [`rust.md`](rust.md) | Default — overwrite |
| Dart / Flutter | [`dart.md`](dart.md) | Default — overwrite |
