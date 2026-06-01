# TypeScript coding standards — {{PROJECT}}

> **Starting point — overwrite this.** These are sane defaults so code is consistent from
> day one. Replace anything that doesn't fit your team. If a rule here encodes a real
> decision (a chosen framework, a module system), record the *why* in an ADR and link it
> from this file.

**Baseline:** TypeScript in **`strict` mode**, Node 20+ (or current LTS). Format with
**Prettier**, lint with **ESLint** (typescript-eslint) — let Prettier own formatting and
ESLint own correctness. Consider also enabling `noUncheckedIndexedAccess` (not part of
`strict`, but a safe-by-default extra). Pin these in the repo so the standard is enforced,
not just documented.

## Naming
- `camelCase` for variables, functions, and methods; `PascalCase` for types, interfaces,
  classes, enums, and React components; `UPPER_SNAKE_CASE` for true constants.
- Filenames: pick one convention and apply it project-wide — common choices are naming the
  file after its main export, or `kebab-case` for modules with `PascalCase` for React
  component files. (Note: Google uses `snake_case`; Airbnb matches the export's casing —
  there's no cross-community default, so just be consistent.) Prefer one primary export per
  file.
- No `I`-prefix on interfaces and no `T`-prefix on types. Booleans read as predicates
  (`isActive`, `hasAccess`).

## Documentation
- **A TSDoc/JSDoc `/** … */` block on every class, function, and method** (the project rule
  — see [`README.md`](README.md)) — `@param`/`@returns` where they add what the signature
  doesn't. `eslint-plugin-jsdoc` can enforce presence and shape.
- Comment the *why*; let types and names carry the *what*.

## Project / module layout
- Source under `src/`, tests colocated (`foo.test.ts`) or in `__tests__/` — pick one and be
  consistent. Compiled output to `dist/` (gitignored).
- Prefer **ESM** for new projects (`"type": "module"`); use path aliases (`@/…`) over deep
  `../../..` chains.
- Keep module internals unexported. Barrel files (`index.ts`) are optional — avoid large
  app-wide barrels, which hurt tree-shaking and bundler/test-runner performance.
- `type` vs `interface` is largely preference; a common rule is `interface` for object
  shapes and `type` for unions/aliases. Pick one and be consistent within a file.

## Types
- **No `any`.** Use `unknown` at boundaries and narrow. Reserve `as` casts for genuinely
  unavoidable cases — never to silence the compiler.
- Let inference work for locals; annotate **function signatures and public APIs** explicitly.
- Model invalid states out of existence — prefer discriminated unions over optional-field
  soup. Make illegal states unrepresentable.

## Error handling
- `throw` `Error` (or a subclass), never strings or plain objects. Define a small domain
  hierarchy (`class {{PROJECT}}Error extends Error`) so callers can discriminate.
- Preserve causes: `throw new WrappedError("…", { cause: err })`. Don't swallow — handle or
  rethrow.
- `throw` / `try`-`catch` is the idiomatic default. A typed result (`Result<T, E>` /
  discriminated union) is a reasonable option for domains where failures are expected and
  you want them in the signature — but it's an ADR-worthy team choice, not a default.
- Always handle promise rejections — `await` in `try/catch`, no floating promises (the lint
  rule enforces this).

## Logging
- Use a structured logger (e.g. **pino** or **Winston**); never `console.log` for
  diagnostics in shipped code (`console` is fine in CLI tools and scripts).
- Log structured fields, not interpolated strings — pass context as data (e.g. `{ userId }`)
  alongside a stable message. (The exact argument order is logger-specific.)
- Levels: `debug` dev detail, `info` lifecycle, `warn` recoverable surprises, `error`
  failures needing attention. Configure the logger once at the entrypoint. Never log secrets
  or PII.

## Async
- JavaScript is single-threaded: `async`/`await` gives you **concurrency, not parallelism**. Keep
  CPU-heavy work off the event loop — move it to **worker threads** (`node:worker_threads`); the
  built-in async I/O already handles I/O-bound work efficiently.
- Prefer `async`/`await` with `try/catch` over `.then()` chains; if you do chain, keep it flat and
  don't nest. Run **independent** operations concurrently with **`Promise.all`** (fail-fast),
  **`Promise.allSettled`** (want every outcome), `Promise.race`, or `Promise.any` — don't `await`
  them one at a time in a loop.
- **No floating promises** — every promise is `await`ed, returned, `.catch()`-ed, or `void`-ed
  (see *Error handling*); `@typescript-eslint/no-floating-promises` and `no-misused-promises`
  enforce it.
- Make long-running async work **cancellable** with `AbortController` / `AbortSignal` (and
  `AbortSignal.timeout(ms)` for deadlines), passing the `signal` to `fetch` and other
  signal-aware APIs.

## Testing
- **Vitest** (or Jest). Test files `*.test.ts`; one behavior per test, Arrange–Act–Assert.
- Name tests for the behavior (`rejects an expired token`), not the function. Mock at
  boundaries (network, fs, clock) — not the unit under test.
- Keep tests fast and deterministic; isolate slow/integration tests so the fast suite stays
  the default. Cover behavior and edge cases, not a coverage percentage — though ~80% unit-test coverage is a reasonable guide to aim for, not a gate.
