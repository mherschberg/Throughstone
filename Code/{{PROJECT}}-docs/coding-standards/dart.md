# Dart / Flutter coding standards — {{PROJECT}}

> **Starting point — overwrite this.** These are sane defaults so code is consistent from
> day one. Replace anything that doesn't fit your team. If a rule here encodes a real
> decision (state management, a logging package), record the *why* in an ADR and link it
> from this file.

**Baseline:** current stable Dart (sound null safety, on by default in Dart 3+). Format with
**`dart format`** (zero-config) and analyze with **`dart analyze`** — enable a lint set in
`analysis_options.yaml` (the **`lints`** package for Dart, **`flutter_lints`** for Flutter).
Follow [Effective Dart](https://dart.dev/effective-dart). Pin these in the repo so the
standard is enforced, not just documented.

## Naming
Per Effective Dart (the analyzer enforces most of it):
- `lowerCamelCase` for variables, parameters, functions, methods, **and constants**
  (`defaultTimeout`, not `DEFAULT_TIMEOUT`).
- `UpperCamelCase` for classes, enums, typedefs, extensions, mixins, and type parameters.
- `lowercase_with_underscores` for libraries, packages, directories, and **source files**
  (`user_repository.dart`).
- Acronyms are capitalized as words: `HttpRequest`, not `HTTPRequest`.
- Names say what, not how. Booleans read as predicates (`isActive`, `hasAccess`).

## Project / module layout
- Pub package: public API in `lib/`, implementation details in **`lib/src/`** (not imported
  directly by consumers); re-export the intended surface from `lib/<package>.dart`. Tests in
  `test/`. Config in `pubspec.yaml`.
- **Flutter:** a feature-first `lib/` layout (rather than grouping by type) scales better as
  the app grows; pick one structure and apply it consistently. Keep widgets small and composable;
  prefer `const` constructors; split big `build` methods into smaller widgets rather than
  helper methods that return widgets.
- Prefer `final` (and `const` for compile-time constants); avoid mutable top-level state.

## Null safety & async
- Lean on sound null safety: prefer non-nullable types; avoid the `!` null-assertion operator
  except where non-null is provable. Use `late` only with a clear, guaranteed initialization.
- Prefer `async`/`await` over raw `Future` chains. Don't leave futures unawaited — `await`
  them, or mark intentional fire-and-forget with `unawaited(...)`. Use `Stream`s for
  sequences of async events.

## Error handling
- Throw `Exception` subtypes for recoverable conditions callers may handle; `Error` subtypes
  (e.g. `ArgumentError`, `StateError`) signal programmer bugs and should **not** be caught.
- Catch narrowly with `on SomeException catch (e)` — avoid bare `catch (e)` that swallows.
  Use `rethrow` to propagate while preserving the stack trace. Don't use exceptions for
  ordinary control flow.
- Validate inputs at boundaries (API edges, deserialization); trust internal callers.

## Logging
- Don't use `print` for diagnostics in shipped code. Use `dart:developer`'s `log()` or the
  **`logging`** package; in Flutter, `debugPrint` (throttled) is fine for development logging
  — but note it still prints in release builds, so gate it with `kDebugMode` if that matters.
- Log structured context with a stable message and levels (`fine`/`info`/`warning`/
  `severe`). Configure the logger once at startup. Never log secrets or PII.

## Testing
- **`package:test`** for Dart, **`flutter_test`** for Flutter. Group with `group()`, write
  `test()` / `testWidgets()`, assert with `expect()` and matchers.
- One behavior per test, named for the behavior (`rejects an expired token`). Mock at
  boundaries (network, storage, clock) with `mockito` or `mocktail` — not the unit under test.
- Keep tests fast and deterministic; use `setUp`/`tearDown` for shared state. Cover behavior
  and edge cases, not a coverage percentage — though ~80% unit-test coverage is a reasonable guide to aim for, not a gate.
