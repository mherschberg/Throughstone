# API design standards — {{PROJECT}}

> **Starting point — review and customize.** These are sane, opinionated defaults so every API
> looks the same from day one. Change anything that doesn't fit your team — a few choices below are
> flagged as genuine forks to settle per project.
>
> **Cross-cutting, and complementary to the interface contract artifact.** The Interface Contracts
> session produces the Interface Contracts architecture doc, which decides which API/interface
> boundaries need formal contracts, where those artifacts live, and which
> artifact is the consumer-facing contract of record. That artifact pins *one* API's shape; this
> file pins the **house style every HTTP/REST API follows** — timestamps, pagination, errors,
> naming, versioning — so endpoints stay consistent no
> matter who (or which agent) writes them. Where a rule here conflicts with an **external** API you
> must integrate with, the external API wins — you don't own it. Record real decisions (the chosen
> pagination style, versioning scheme, casing) in an ADR and link it from this file.

**Scope:** this standard targets **REST / HTTP+JSON** APIs — the common case. A **GraphQL** or
**gRPC/protobuf** API has its own idioms (schema design, field deprecation, error models); keep the
cross-cutting parts here (timestamps, money, versioning intent) and follow the relevant ecosystem
guide for the rest.

**Baseline:** adopt a published guide as the reference rather than re-deriving one — the
[Google API Design Guide](https://cloud.google.com/apis/design) / [AIPs](https://google.aip.dev/),
the [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines), or the
opinionated [Zalando RESTful API Guidelines](https://opensource.zalando.com/restful-api-guidelines/).
Lint the OpenAPI spec with **[Spectral](https://github.com/stoplightio/spectral)** (the ShellCheck
of API design — rulesets for naming, required descriptions, response shapes), pinned in CI so the
standard is enforced, not just documented.

## Resource naming & URLs
- **Nouns, not verbs**; the HTTP method *is* the verb. `GET /orders/{id}`, not `GET /getOrder`.
- **Plural collections**, lowercase, `kebab-case` for multi-word path segments:
  `/shipping-addresses`, not `/shippingAddresses` or `/shipping_addresses`.
- Model relationships by nesting one level — `/orders/{id}/items` — but avoid deep nesting; link by
  ID past the first level. Keep query parameters for filtering/sorting/pagination, not for
  identifying resources.

## HTTP methods & status codes
- Use methods for their defined semantics: **GET** (safe, read), **POST** (create / non-idempotent
  action), **PUT** (full replace, idempotent), **PATCH** (partial update), **DELETE** (idempotent).
- Return **meaningful status codes**, not `200` for everything: `201 Created` (+ `Location` header)
  on create, `204 No Content` on an empty success, `400/401/403/404/409/422` for the matching client
  error, `429` when rate-limited, `5xx` only for genuine server faults. Don't bury an error inside a
  `200` body.

## Field conventions
- **Field casing — fork; pick one and apply it everywhere.** **Default: `snake_case`** (Google,
  Zalando, JSON:API; also matches `sql.md`, reducing mapping friction). **Alternative: `camelCase`**
  — switch if the API is consumed primarily by a JS/TS frontend and you'd rather not translate at the
  boundary. Whatever you choose, it is **uniform across every endpoint**; record it in an ADR.
- **Timestamps: always [RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339) / ISO 8601, in
  UTC, `Z`-suffixed** — `2026-06-01T14:30:00Z`. Never epoch ints, never local time, never a custom
  format. Name them with an `_at` suffix (`created_at`, `updated_at`) — or `_time` if you follow
  Google's AIPs. Durations use ISO 8601 (`P3D`, `PT30S`).
- **Money: integer minor units + an ISO 4217 currency code** (`{"amount": 1099, "currency":
  "USD"}`) — never floats; binary floating point silently corrupts currency.
- **Booleans read as predicates** (`is_active`, `has_items`). **Enums are lowercase strings**, not
  magic numbers, so they're self-describing and extensible.
- **Omit vs. null:** be consistent — prefer omitting absent fields, and document `null` only where it
  carries meaning distinct from absence. Don't return a field as `null` in one response and absent in
  another.

## Pagination
- **Fork; pick one.** **Default: cursor-based** — return an opaque `next` cursor (and `next` link);
  the client passes it back as `?cursor=…`. Cursors are stable when rows are inserted or deleted
  mid-scan, and they scale (no large `OFFSET`). **Alternative: offset/limit** (`?offset=&limit=`) —
  simpler, allows jumping to an arbitrary page; switch if the dataset is small and bounded and users
  need page numbers. Document the choice in an ADR.
- **Always cap and default `limit`** (e.g. default 25, max 100) so a client can't request the world.
  Convey links either via the **`Link` header** (`rel="next"`/`"prev"`, per
  [RFC 8288](https://www.rfc-editor.org/rfc/rfc8288)) **or** a consistent body envelope — pick one and
  use it for every collection.

## Errors
- **Use [RFC 9457 Problem Details](https://www.rfc-editor.org/rfc/rfc9457.html)** (obsoletes RFC
  7807) with `Content-Type: application/problem+json`. The body carries `type`, `title`, `status`,
  `detail`, `instance` — plus a stable, machine-readable `code` and per-field validation errors where
  relevant. One error shape across the whole API.
- **Never leak internals** — no stack traces, SQL, or internal hostnames in a response body.
  Include a correlation/request ID the client can quote in a support ticket (ties to the
  observability hooks in the Observability architecture doc). The status line and the `status`
  member agree.

## Versioning
- **Fork; pick one.** **Default: URI versioning** — a major version in the path (`/v1/…`). It's
  explicit, cache- and log-friendly, and trivial to route. **Alternative: header versioning** (e.g.
  `Accept: application/vnd.{{PROJECT}}.v1+json`) — keeps URLs clean and version-free; switch if you
  prefer content negotiation and your clients/proxies handle custom Accept media types well. Record
  the choice in an ADR.
- **Bump the major only on breaking changes.** Additive changes (new optional field, new endpoint)
  ship without a version bump — so clients **must ignore unknown fields**. Announce deprecations with
  a timeline (and the `Deprecation`/`Sunset` headers where practical) before removing anything.

## Idempotency, safety & limits
- **Make unsafe retries safe.** For non-idempotent creates, accept an **`Idempotency-Key`** header
  and de-dupe on it, so a client that retries after a timeout doesn't double-charge / double-create.
- **Rate-limit** public surfaces and signal it: `429` plus `Retry-After`. Validate and bound every
  input (sizes, lengths, ranges) at the edge.
- **Security is not optional:** authenticate every non-public endpoint, authorize per resource, and
  serve only over TLS. Depth lives in the security-threat-model session and the **security-review**
  process — this file just sets the house style.
