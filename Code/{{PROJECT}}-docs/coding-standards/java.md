# Java coding standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane defaults so code is consistent
> from day one. Change anything that doesn't fit your team. If a rule here encodes a real
> decision (a chosen framework, a logging backend), record the *why* in an ADR and link it
> from this file.

**Baseline:** target a supported LTS release (Java 21 or later). Follow the
[Google Java Style Guide](https://google.github.io/styleguide/javaguide.html) for layout and
naming; the points below are where we're opinionated. Format with **`google-java-format`**
(via the **Spotless** plugin) so formatting is never hand-maintained or argued in review.
Analyze with **Error Prone**, **SpotBugs**, and **Checkstyle**, pinned in the build (Maven or
Gradle) so the standard is enforced in CI, not just documented here.

## Naming
- `UpperCamelCase` for classes, interfaces, enums, and records (noun phrases).
  `lowerCamelCase` for methods (verb phrases), fields, parameters, and locals. No underscores,
  no Hungarian notation, no `m`/`s` prefixes.
- `UPPER_SNAKE_CASE` only for `static final` constants whose contents are deeply immutable.
  A mutable `static final` field is not a constant — name it like a field.
- Packages: lowercase letters and digits, no underscores; concatenate words
  (`com.example.deepspace`). Type parameters: a single capital letter, optionally with a
  numeral (`E`, `T`, `T2`), or a descriptive name suffixed with `T` (`RequestT`).
- Don't add `get`/`set` to things that aren't bean accessors; don't encode types in names.
  Test classes end in `Test`.

## Documentation
- **Javadoc on every class, method, and field — public *and* private** (the project rule —
  see [`README.md`](README.md)). This goes further than Google's norm, which requires Javadoc
  only on visible members and exempts trivial getters and `@Override` methods. Begin with a
  summary fragment (a capitalized noun/verb phrase, not "This method returns…"); block tags in
  order `@param`, `@return`, `@throws`. Checkstyle can flag missing or malformed Javadoc.
- Comment the *why* of non-obvious logic, not the *what*. A `TODO:` includes a tracking link.
- Annotate with **`@Override` whenever it is legal** — the compiler then catches signature
  drift. Use `@Deprecated` (and say what to use instead in the Javadoc) rather than deleting
  public API silently.

## Project / module layout
- Standard Maven/Gradle layout: `src/main/java`, `src/test/java`, package = directory. **One
  top-level class per file**, named for the class. No wildcard imports.
- Package by feature/domain (`orders`, `billing`), not by layer (`controllers`, `services`)
  once the project outgrows a handful of classes — it keeps related code together and limits
  blast radius. Use the JPMS module system or package-private visibility to enforce
  boundaries; expose the minimum surface.

## Language & immutability
- **Prefer immutability.** Make fields `final` by default; expose unmodifiable collections.
  Use **`record`** for data carriers (`record Money(BigDecimal amount, Currency currency) {}`)
  instead of hand-written getters/`equals`/`hashCode`.
- Use **`Optional`** for return values that may be absent — never for fields or parameters,
  and never call `.get()` without first checking. Return empty collections, not `null`.
- Reach for modern constructs where they read more clearly: switch expressions, sealed
  hierarchies, pattern matching for `instanceof`, text blocks. Use `var` for locals only when
  the initializer makes the type obvious.
- **Never override `Object.finalize`.** Use try-with-resources for anything `AutoCloseable`.

## Error handling
- Catch the **most specific** exception you can handle; never catch `Exception`/`Throwable`
  broadly except at a top-level boundary. **Never swallow** — an empty `catch` needs a comment
  justifying why doing nothing is correct.
- When rethrowing, **preserve the cause**: `throw new OrderException("loading order " + id, e)`.
  Don't discard the stack trace by re-wrapping without the cause.
- Don't use exceptions for ordinary control flow. Validate arguments and fail fast
  (`Objects.requireNonNull`, `IllegalArgumentException`). Prefer unchecked exceptions for
  programming errors; reserve checked exceptions for recoverable conditions callers must handle.
- Don't log *and* rethrow the same exception — pick one (usually rethrow; log once at the
  boundary that handles it).

## Logging
- Log through the **SLF4J** facade with a Logback or Log4j 2 backend — never `System.out` or a
  concrete logger directly. One `private static final Logger log = LoggerFactory.getLogger(...)`
  per class.
- Use **parameterized messages**, never string concatenation:
  `log.info("user {} logged in", userId)` — the arguments are only formatted if the level is
  enabled. To log an exception, pass it as the **last argument** so the stack trace is
  captured: `log.error("failed to load order {}", id, e)`.
- Pick levels deliberately (ERROR/WARN/INFO/DEBUG). **Never log secrets, credentials, or PII.**

## Concurrency
- Immutability is the best concurrency strategy — share immutable objects freely. For mutable
  shared state, prefer **`java.util.concurrent`** (executors, concurrent collections, atomics)
  over raw `Thread` and hand-rolled `synchronized`/`wait`/`notify`.
- Document the thread-safety of any class designed for concurrent use. For I/O-bound
  fan-out on Java 21+, virtual threads are the simple default.

## Testing
- **JUnit 5 (Jupiter)** with **AssertJ** for fluent assertions and **Mockito** for mocking.
  Test classes named `FooTest`, alongside the standard `src/test/java` tree.
- Name tests for the behavior under test (`rejectsExpiredToken`), follow Arrange-Act-Assert,
  and keep them fast and deterministic — no sleeps, no shared mutable fixtures. Gate slow or
  integration tests behind a tag/profile so the unit suite stays quick.
- Cover behavior and edge cases, not a coverage number — though ~80% unit-test coverage is a
  reasonable guide to aim for, not a gate.
