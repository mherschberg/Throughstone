# Go coding standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane defaults so code is consistent from
> day one. Change anything that doesn't fit your team. If a rule here encodes a real
> decision (a chosen framework, a logging library), record the *why* in an ADR and link it
> from this file.

**Baseline:** current Go release, `gofmt`/`goimports` enforced, vetted with **`go vet`** and
**`golangci-lint`**. Follow [Effective Go](https://go.dev/doc/effective_go) and the
[Go Code Review Comments](https://go.dev/wiki/CodeReviewComments); the points below are
where we're opinionated. Pin the linters in the repo so the standard is enforced.

## Naming
- `MixedCaps` / `mixedCaps` — never underscores. Exported = `PascalCase`, unexported =
  `camelCase`. Visibility is the access control; don't add `Get` prefixes to getters.
- Short names for short scopes (`i`, `r`, `buf`); descriptive names for package-level
  identifiers. The package name is part of the API — keep it short, lowercase, no
  underscores, and don't stutter (`http.Server`, not `http.HTTPServer`).
- Interfaces describing one method end in `-er` (`Reader`, `Stringer`). Errors: `ErrNotFound`
  for sentinels, `FooError` for types.

## Documentation
- **A doc comment on every type, func, and method — exported *and* unexported** (the project
  rule — see [`README.md`](README.md); Go's own norm is exported-only, the project rule goes
  further). Go style: begin with the identifier's name (`// Server handles …`); `go doc` /
  godoc render these. `revive` / `golangci-lint` can flag missing ones.
- Comment the *why* of non-obvious logic (and *why* an ignored error is safe — see below).

## Project / module layout
- One module per repo (`go.mod` at root, module path = repo URL). Package per directory;
  the directory name is the package name.
- A small repo can keep `main` at the root. As it grows: **`cmd/<binary>/`** for entrypoints
  (thin `main`), **`internal/`** for code that must not be imported externally (the toolchain
  enforces this boundary), top-level packages for the public API. Skip `pkg/` unless you have
  a real reason. These are conventions, not an official Go standard.
- Accept interfaces, return concrete types. Define interfaces in the **consumer** package
  where practical (well-known shared interfaces like `io.Reader` are an accepted exception).

## Error handling
- Return `error` as the last value; handle it immediately — no ignoring with `_` except
  where genuinely safe (and comment why).
- **Wrap with context** as errors propagate: `fmt.Errorf("loading config: %w", err)`. `%w`
  exposes the wrapped error as part of your API — use `%v` when you don't want that. Inspect
  with `errors.Is` / `errors.As`, not string matching.
- Error strings are lowercase and have no trailing punctuation (they're often wrapped):
  `"loading config"`, not `"Loading config."`.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) or typed errors for cases callers
  branch on. `panic` only for truly unrecoverable programmer errors, never for ordinary
  flow; recover only at process/goroutine boundaries.
- Don't log *and* return the same error — pick one (usually return; log at the top).

## Logging
- Standard **`log/slog`** for structured logging (zap/zerolog are faster for hot paths — an
  ADR-worthy swap if logging shows up in profiles). Pass a `*slog.Logger` (or use context);
  don't reach for package-level globals in libraries.
- Structured key/value pairs: `logger.Info("user logged in", "userID", id)` — not formatted
  strings. Never log secrets or PII.
- Libraries generally shouldn't log — return errors and let the caller decide. Configure
  handler and level once in `main`.

## Concurrency
- A goroutine's lifetime must be clear — know who stops it and when. Propagate
  `context.Context` as the first parameter for cancellation and deadlines.
- Don't leak goroutines or channels; prefer the simplest tool (a mutex is often clearer than
  a channel). Run tests and CI with **`-race`**.

## Testing
- Standard `testing` package; **table-driven tests** with subtests (`t.Run`). Files
  `*_test.go` alongside the code.
- Name tests for behavior (`TestRejectsExpiredToken`); use `t.Helper()` in assertion
  helpers. Reach for `testify` only if the team wants it.
- Keep the unit suite fast and deterministic; gate slow/integration tests behind
  `testing.Short()` or a build tag. Use `t.Parallel()` where safe. Cover behavior and edge
  cases, not a coverage percentage — though ~80% unit-test coverage is a reasonable guide to aim for, not a gate.
