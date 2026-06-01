# Python coding standards — {{PROJECT}}

> **Starting point — overwrite this.** These are sane defaults so code is consistent from
> day one. Replace anything that doesn't fit your team. If a rule here encodes a real
> decision (a chosen framework, an error-handling pattern), record the *why* in an ADR and
> link it from this file.

**Baseline:** Python 3.11+, [PEP 8](https://peps.python.org/pep-0008/) with the deviations
below. Format and lint with **Ruff** — it covers formatting, linting, and import-sorting in
one tool (Black + Flake8 + isort is the equivalent classic stack). Type-check with a static
checker (**mypy** or **pyright**). Pin these in the repo so the standard is enforced, not
just documented.

## Naming
- `snake_case` for functions, methods, variables, modules, and packages.
- `PascalCase` for classes and type aliases; `UPPER_SNAKE_CASE` for module-level constants.
- Prefix intentionally-private names with a single underscore (`_helper`). Avoid the
  name-mangling double underscore unless you truly need it.
- Names say what, not how: `active_users`, not `user_list`. Booleans read as predicates
  (`is_active`, `has_access`). No single-letter names except short-lived loop indices.

## Documentation
- **Docstrings on every module, class, function, and method** (the project rule — see
  [`README.md`](README.md)). Triple-quoted, [PEP 257](https://peps.python.org/pep-0257/);
  pick one style for structured fields (Google or NumPy) and apply it consistently. Ruff's
  `pydocstyle` rules (`D`) can enforce presence.
- Comment the *why* of non-obvious logic; let clear names and type hints carry the *what*.

## Project / module layout
- **Layout:** for a packaged/distributable library, prefer the `src/` layout (package under
  `src/{{PROJECT}}/`, tests in a top-level `tests/`) — it keeps tests running against the
  installed package, not the working tree. A flat layout is fine for simple apps and scripts.
- One responsibility per module; keep `__init__.py` thin (re-exports, not logic).
- Manage with **`pyproject.toml`** (PEP 621) — no `setup.py`, no `requirements.txt` as the
  source of truth. Use a lockfile (`uv`, `poetry`, or `pip-tools`).
- **Type hints** on all public APIs at minimum; fully typing new code is recommended (and
  is what the strict type-checker config above assumes).

## Error handling
- Raise specific exceptions; define a small package-level hierarchy
  (`class {{PROJECT}}Error(Exception)`) and derive from it so callers can catch by domain.
- Never `except:` or bare `except Exception:` that swallows. Catch the narrowest type,
  handle or re-raise — `raise NewError(...) from err` to preserve the cause.
- Use exceptions for exceptional flow, return values for expected outcomes. Don't use
  exceptions for ordinary control flow.
- Validate inputs at boundaries (API edges, deserialization); trust internal callers.

## Logging
- Standard `logging` module, `logger = logging.getLogger(__name__)` per module. Never
  `print()` for diagnostics.
- **Structured / parameterized** logs — `logger.info("user %s logged in", user_id)`, not
  f-strings, so the message stays a stable key.
- Levels: `DEBUG` dev detail, `INFO` lifecycle events, `WARNING` recoverable surprises,
  `ERROR` failures needing attention. Configure handlers/format once at the entrypoint, not
  in libraries. Never log secrets or PII.

## Concurrency & async
- Pick the model by workload: **`asyncio`** for I/O-bound work with many concurrent operations
  (cooperative, single-threaded); **threads** (`threading` /
  `concurrent.futures.ThreadPoolExecutor`) for I/O-bound work that calls blocking libraries —
  both are bound by the **GIL**, so neither parallelizes CPU work. For **CPU-bound** work use
  processes (`multiprocessing` / `ProcessPoolExecutor`).
- In asyncio, **never block the event loop** — one slow call stalls every task. Offload blocking
  or CPU-heavy work with `asyncio.to_thread(...)` (or `loop.run_in_executor`), and enter the loop
  once at the top with `asyncio.run(main())`.
- Prefer **structured concurrency**: run related tasks under `async with asyncio.TaskGroup()`
  (3.11+) rather than bare `asyncio.gather` — a TaskGroup cancels its siblings when one fails and
  surfaces errors as an `ExceptionGroup`. Bound waits with `async with asyncio.timeout(...)`.
- For fire-and-forget `create_task`, **keep a strong reference** to the task — the loop holds only
  a weak one, so it can be garbage-collected mid-flight and its exception silently dropped.
- asyncio objects are **not thread-safe**: cross thread boundaries only via
  `asyncio.run_coroutine_threadsafe` / `loop.call_soon_threadsafe`. Let `CancelledError` propagate
  (it derives from `BaseException`) and do cleanup in `finally`.

## Testing
- **pytest**. Tests in `tests/`, files `test_*.py` (or `*_test.py`), plain `assert`.
- Arrange–Act–Assert; one behavior per test. Name tests for the behavior
  (`test_rejects_expired_token`), not the method.
- Use fixtures for setup and `pytest.mark.parametrize` for cases. Mock at boundaries (I/O,
  network, clock) — don't mock the code under test.
- Keep tests fast and deterministic; mark slow/integration tests so the fast suite stays
  the default. Aim for coverage of behavior and edge cases, not a percentage target — though ~80% unit-test coverage is a reasonable guide to aim for, not a gate.
