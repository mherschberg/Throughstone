# SQL coding standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane defaults so code is consistent from
> day one. Change anything that doesn't fit your team.
>
> **Secondary to the language standards.** SQL is cross-cutting — you write it in migrations, in
> standalone queries, and embedded in application code. Where any rule here conflicts with a
> language standard or its ORM/framework conventions (a column named to match a mapped field,
> how a SQL string is formatted inside host code), **the language doc wins.** Record real
> decisions (the chosen dialect, the migration tool) in an ADR and link it from this file.

**Baseline:** there is no PEP 8 for SQL — adopt a community base (the
[SQL Style Guide](https://www.sqlstyle.guide/) or the
[dbt style guide](https://docs.getdbt.com/best-practices/how-we-style/2-how-we-style-our-sql))
and enforce it with **`sqlfluff`** (lint + autoformat) configured to **your pinned dialect**
(Postgres, MySQL, SQLite, …), pinned in CI so the standard is enforced, not just documented. The
two base guides disagree on some points (keyword case, key naming) — pick one and let the
formatter settle the rest.

## Naming
- `snake_case` for tables, columns, and all identifiers — never camelCase, `tbl_`/`sp_` prefixes,
  or Hungarian notation. Begin with a letter; use only letters, digits, and underscores.
- Pick **one** table-naming convention — plural (`customers`) or singular — and apply it
  everywhere. Column names are singular. Don't use SQL reserved words as identifiers.
- Decide a primary/foreign-key style and keep it consistent: e.g. an `id` PK with `<table>_id`
  FKs (common in ORM-backed schemas) or a named key per the SQL Style Guide. Use meaningful
  suffixes (`_id`, `_at`/`_date`, `_count`, `_status`).
- Always alias with the explicit **`AS`** keyword. When the language/ORM dictates a name, defer to
  it (see the header).

## Formatting
- **Let `sqlfluff` own formatting** — don't hand-argue it in review. Configure once and enforce:
  keyword case (UPPERCASE per the SQL Style Guide, or lowercase per dbt — pick one), indentation,
  and comma style (trailing is most common).
- One column/clause per line in non-trivial queries; put each `JOIN` and its `ON` on their own
  lines; break before `AND`/`OR`. Prefer **CTEs** over deeply nested subqueries for readability.

## Query practices
- **No `SELECT *`** in application or production queries — list columns explicitly so results stay
  stable as the schema changes.
- **Explicit join types** (`INNER JOIN`, `LEFT JOIN`) with `ON` predicates — never comma joins
  (`FROM a, b WHERE …`). **Qualify columns with their table** when two or more tables are in play.
- Filter and aggregate as early as possible, on the smallest dataset. Keep predicates **sargable**
  — avoid wrapping an indexed column in a function. Verify non-trivial queries with `EXPLAIN`.

## Safety
- **Always use parameterized queries / prepared statements. Never build SQL by concatenating user
  input** — this is the leading cause of SQL injection, and it's a hard rule, not a preference.
  OWASP's primary defense is parameterization; see the project's security review expectations
  for depth.
- Run the application under a **least-privilege** database account, never an admin/superuser. Wrap
  multi-statement changes that must succeed or fail together in a **transaction**, and keep
  transactions short to limit lock contention.

## Schema / DDL
- Explicit column types; `NOT NULL` with sensible defaults wherever a value is required. **Enforce
  integrity in the database** — primary keys, foreign keys, `UNIQUE`, and `CHECK` constraints — not
  only in application code.
- Index the columns you filter and join on, but add indexes deliberately (they cost on every
  write). Store timestamps in UTC.

## Migrations
- Every schema change ships as a **versioned, code-reviewed migration** (Flyway, Liquibase,
  Alembic, Rails, Prisma, … — choose per project and record it in an ADR). No ad-hoc changes
  against a live database.
- **Never edit a migration once it has been applied** anywhere shared — add a new one. Prefer
  **backward-compatible** changes (expand/contract) so deploys don't need downtime, and make
  migrations reversible (or document the rollback) where practical.
