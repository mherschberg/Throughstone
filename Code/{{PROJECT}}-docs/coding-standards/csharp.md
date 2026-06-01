# C# coding standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane defaults so code is consistent
> from day one. Change anything that doesn't fit your team. If a rule here encodes a real
> decision (a chosen framework, a logging library), record the *why* in an ADR and link it
> from this file.

**Baseline:** target a supported LTS release (.NET 8 or later). Follow Microsoft's
[C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
and the [Framework Design Guidelines](https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/)
for naming; the points below are where we're opinionated. Enforce style with an
**`.editorconfig`** checked into the repo and **`dotnet format`**; enable the Roslyn
**analyzers** with **nullable reference types on** (`<Nullable>enable</Nullable>`) and warnings
treated as errors in CI so the standard is enforced, not just documented.

## Naming
- **PascalCase** for namespaces, types, interfaces, methods, properties, events, enum members,
  constants, and public fields. **camelCase** for parameters and local variables. Interfaces
  are prefixed **`I`** (`IEnumerable`); type parameters are prefixed **`T`** (`T`, `TKey`,
  `TResult`).
- **Private/internal instance fields are `_camelCase`** (leading underscore); static fields
  `s_camelCase`, thread-static `t_camelCase`. `readonly` comes after `static`
  (`static readonly`).
- Two-letter acronyms are fully capitalized (`IOStream`); acronyms of three+ letters are
  PascalCased (`HtmlParser`, not `HTMLParser`). Treat closed-form compounds as one word (`Id`,
  `Email`, `Endpoint`). Async methods end in `Async`.
- **Use the language keywords, not the BCL type names** — `int`/`string`/`float`, not
  `Int32`/`String`/`Single` (including `int.Parse`). Avoid `this.` unless required to
  disambiguate.

## Documentation
- **XML doc comments (`///`) on every type and member — public *and* private** (the project
  rule — see [`README.md`](README.md)). This goes further than Microsoft's norm, which
  documents only public members. Use `<summary>`, `<param>`, `<returns>`, and `<exception>`;
  start the summary with a capital and end with a period. Enable doc-comment analyzers so gaps
  are flagged in CI.
- Use `//` for implementation comments, on their own line, explaining the *why*. Avoid `/* */`
  blocks. A `// TODO:` includes a tracking link.

## Project / file layout
- **File-scoped namespaces** (`namespace Foo.Bar;`). Put **`using` directives outside** the
  namespace declaration. **One top-level type per file**, named for the type.
- Standard solution layout: one project per deployable/library, `src/` and `tests/` separated.
  Organize by feature/domain rather than by technical layer once a project outgrows a handful
  of types. Keep the public surface minimal — `internal` by default, `public` deliberately.

## Language usage
- **`var` only when the type is obvious from the right-hand side** (a `new`, an explicit cast,
  or a literal). Spell out the type otherwise; don't rely on the method name to convey it.
- Prefer **`record`** types for immutable data; make fields `readonly` and properties
  `{ get; init; }` where possible. Use `required` properties over forcing initialization
  through constructors.
- Use **string interpolation** for short concatenation (`$"{first} {last}"`), **raw string
  literals** (`"""…"""`) over escapes/verbatim, and **`StringBuilder`** for building strings in
  loops. Use **collection expressions** (`int[] xs = [1, 2, 3];`) and **object initializers**.
- Use expression-bodied members and pattern matching / switch expressions where they read more
  clearly. Use `&&`/`||` (short-circuiting), not `&`/`|`, in conditions. Prefer LINQ for
  collection transforms.

## Error handling
- Catch the **most specific** exception type; **never catch `Exception` (or `Catch`-all)
  without a filter** you can actually handle. An empty `catch` needs a comment justifying it.
- **Rethrow with bare `throw;`**, never `throw ex;` — the latter resets the stack trace. Use
  exception filters (`catch (… ex) when (…)`) instead of catch-and-rethrow where possible.
- Validate arguments and fail fast: `ArgumentNullException.ThrowIfNull(x)`,
  `ArgumentException`. Don't use exceptions for ordinary control flow.
- Use **`using` declarations** (`using var f = …;`) for anything `IDisposable` rather than
  hand-written `try`/`finally`. Don't log *and* rethrow the same exception — pick one.

## Logging
- Log through **`Microsoft.Extensions.Logging`** (`ILogger<T>` via dependency injection) — not
  `Console.WriteLine` or a concrete logger.
- Use **structured message templates** with named placeholders, never string interpolation:
  `logger.LogInformation("User {UserId} logged in", userId)` — the named values flow to the
  logging backend as structured data. Pick levels deliberately
  (Critical/Error/Warning/Information/Debug/Trace). **Never log secrets, credentials, or PII.**

## Async & concurrency
- Use **`async`/`await`** for I/O-bound work; return `Task`/`Task<T>` (or `ValueTask` on hot
  paths) and suffix the method `Async`. **Never `async void`** except for event handlers.
- **Don't block on async code** with `.Result` or `.Wait()` — it risks deadlocks. Flow a
  **`CancellationToken`** through async call chains. In library code, use
  `ConfigureAwait(false)`.
- For shared mutable state prefer the concurrent collections and primitives in
  `System.Collections.Concurrent` / `System.Threading` over hand-rolled locking; immutable data
  is the simplest path to thread safety.

## Testing
- **xUnit** (or NUnit/MSTest) with **FluentAssertions** for readable assertions and a mocking
  library (**Moq** or **NSubstitute**). Tests live in a parallel `tests/` project.
- Name tests for the behavior under test, follow Arrange-Act-Assert, and keep them fast and
  deterministic — no sleeps, no shared mutable state. Gate slow/integration tests behind a
  trait/category so the unit suite stays quick.
- Cover behavior and edge cases, not a coverage number — though ~80% unit-test coverage is a
  reasonable guide to aim for, not a gate.
