# Rust coding standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane defaults so code is consistent from
> day one. Change anything that doesn't fit your team. If a rule here encodes a real
> decision (a chosen error or logging crate), record the *why* in an ADR and link it from
> this file.

**Baseline:** current stable Rust, a pinned `edition` in `Cargo.toml`. Format with
**`rustfmt`** (use its default style) and lint with **`clippy`** (`cargo clippy`,
warnings-as-errors in CI). Follow the [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
for public interfaces. Pin the toolchain (`rust-toolchain.toml`) so the standard is
enforced, not just documented.

## Naming
Per [RFC 430](https://rust-lang.github.io/rfcs/0430-finalizing-naming-conventions.html) — the
compiler's built-in lints enforce the case conventions (`clippy` adds more):
- `snake_case` for functions, methods, variables, modules, and crates; `UpperCamelCase` for
  types, traits, enums, and type parameters; `SCREAMING_SNAKE_CASE` for constants and statics.
- Conversion methods follow the `as_` / `to_` / `into_` convention (cheap borrow / expensive
  borrow-or-own / consume).
- Acronyms are one word: `Uuid`, `HttpClient` — not `UUID`, `HTTPClient`.
- Names say what, not how. Booleans read as predicates (`is_active`, `has_access`).

## Documentation
- **Doc comments (`///`) on every type, trait, function, and method — including private
  items** (the project rule — see [`README.md`](README.md)). `///` docs double as **doc-tests**
  (see Testing) and render with `cargo doc`. `#![warn(missing_docs)]` enforces them on the
  public API; carry the habit to private items.
- Comment the *why* of non-obvious logic; let types and names carry the *what*.

## Project / module layout
- Cargo project: `src/main.rs` for a binary, `src/lib.rs` for a library; split modules into
  files/directories with `mod`. Use a **workspace** for multi-crate projects.
- Keep the public API minimal — default to private, expose with `pub`; use `pub(crate)` for
  cross-module-but-internal items. The crate root re-exports the intended public surface.
- Derive common traits (`Debug`, `Clone`, `PartialEq`, …) where it makes sense; implement
  `Display` for user-facing types.

## Error handling
- Return **`Result<T, E>`** for fallible operations and propagate with the **`?`** operator.
  Use `Option<T>` for plain absence, `Result` for failure.
- Avoid `.unwrap()` / `.expect()` in library and production paths. If an invariant truly
  can't fail, `.expect("reason the invariant holds")` documents *why* — bare `.unwrap()` is
  for tests and prototypes.
- **Libraries** define their own error types (commonly via `thiserror`) so callers can match
  on variants. **Applications** favor an ergonomic context type (`anyhow` / `eyre`) and add
  context as errors propagate (`.context("loading config")`). This lib-vs-app split is the
  canonical convention — pick per crate.
- `panic!` is for unrecoverable bugs / broken invariants, never for ordinary error flow.

## Safety
- Prefer safe Rust. Reach for `unsafe` only when necessary; keep blocks small, document the
  invariants that make them sound, and wrap them in a safe API.
- Run `clippy` clean and test with sanitizers/`miri` where `unsafe` is involved.

## Logging
- Use the **`tracing`** crate (structured, async-friendly spans/events) or the **`log`**
  facade with a backend like `env_logger` — `tracing` is the common default for async and
  service code. Libraries depend on the facade, not a concrete backend.
- Emit structured fields, not interpolated strings: `info!(user_id, "user logged in")`.
- Levels: `trace`/`debug` dev detail, `info` lifecycle, `warn` recoverable surprises,
  `error` failures needing attention. Initialize the subscriber once in `main`. Never log
  secrets or PII.

## Concurrency
- Lean on **"fearless concurrency"**: the ownership model plus the `Send`/`Sync` marker traits
  turn data races into compile errors rather than runtime bugs — let the type system carry the
  guarantee.
- **CPU-bound parallelism → threads** (`std::thread`, or `rayon` for data-parallel iterators).
  **I/O-bound concurrency → async**. Prefer **message passing** (channels — `std::sync::mpsc` or
  `crossbeam`) over shared state; when you must share, use `Arc<Mutex<T>>` / `Arc<RwLock<T>>`.
- Async **futures are inert** — they do nothing until `.await`ed, and dropping one cancels it.
  The standard library ships **no executor**, so you choose a runtime (**`tokio`** is the common
  default). That choice is viral across the codebase — record it in an ADR.
- **Don't block inside async tasks** — a blocking or CPU-heavy call stalls the executor. Offload
  it to `tokio::task::spawn_blocking` or a dedicated thread. Spawned tasks must be `Send + 'static`;
  move owned data in with `async move` and share it via `Arc`.

## Testing
- Standard test framework: `#[cfg(test)] mod tests` with `#[test]` for **unit tests**
  alongside the code; **integration tests** in `tests/`; **doc tests** in `///` examples
  that double as verified documentation. Run with `cargo test`.
- One behavior per test, named for the behavior (`rejects_expired_token`). Use `Result` in
  tests so you can `?`. Keep tests fast and deterministic. As a guide, ~80% unit-test
  coverage is a reasonable thing to aim for — a suggestion, not a gate.
- Use `#[should_panic]` sparingly (prefer asserting on a returned `Err`). Reach for helper
  crates (`rstest`, `proptest`) only if the team wants them.
