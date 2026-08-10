# Inputs index — what still holds, what's been superseded

> **What this is.** `inputs/` holds **point-in-time** source documents; `architecture/` holds the
> **living** truth (`inputs/README.md`). This file is the ledger that keeps the two honest: it
> records, per input, which parts an `architecture/` (or `adr/`) doc has already **superseded** and
> which parts still **hold** — so a later session builds only on what's current instead of
> re-reading a stale seed, and the periodic check-in can retire what's fully captured. It is the
> same shape as the other registries (`../registries/repos.yml`, `../registries/risks.yml`,
> `../adr/README.md`): a session updates it at the moment of change, and the check-in
> (`../runbooks/check-in.md`) reconciles it against reality.
>
> **Greenfield-inert.** A new project has captured nothing yet — every row is `Live` (or the table
> is empty), so sessions read all of `inputs/` exactly as before. The ledger only starts doing work
> once a generated doc covers ground an input first supplied.
>
> This file and `README.md` are **guidance, not inputs** — a session never treats them as source
> documents.

## How to read a row
- **Input** — the file under `inputs/`, e.g. `payments-protocol-v2.pdf` (or `specs/orders-api.md`).
- **Part** — the smallest piece of that input the input's own structure lets you name: a section,
  page range, or named region (`§3 Wire format`, `pp.4–6 sequence diagram`). Map as finely as the
  document allows. Use `(whole)` when it can't be cleanly decomposed — a single diagram, an image,
  an unstructured doc — rather than inventing sections.
- **Status** — `Live` (still authoritative — build on it) or `Superseded` (a generated doc now owns
  this ground — don't). An input with some rows `Live` and some `Superseded` is *partially*
  superseded: it stays in `inputs/` and is read only for its `Live` parts. When **every** row for an
  input is `Superseded`, it is fully captured — retire it to `inputs/archive/` (which sessions do
  not read) and leave its rows here as the record.
- **Covered by / note** — for a `Superseded` part, the `architecture/` doc or ADR that now owns it
  (e.g. `architecture/11-interface-contracts`). For a `Live` part, an optional note (e.g. *external
  protocol spec — authoritative until the protocol revises*).

## When to update it
- **On import** — a document lands in `inputs/`: add its row(s), `Live`.
- **On capture** — a session folds an input's content into an `architecture/` doc or an ADR: in the
  same edit, flip the captured part(s) to `Superseded` and name the covering doc. If the input is
  itself architecture-grade — e.g. a protocol/API spec or a finished design doc — lift it into
  `architecture/` promptly (a whole-file copy or a light reformat to match conventions) and mark it
  here — `inputs/` is never the living home. (Use judgment, though: some inputs are better
  **referenced** from `architecture/` and kept `Live` here — e.g. a large external standard you only
  partially implement — one example, not the only one.)
- **On check-in** — the inputs sweep in `../runbooks/check-in.md` reconciles this ledger against the
  architecture docs, dispositions anything now covered, and offers to archive fully-superseded
  inputs. Surface-and-decide — the sweep never moves or deletes a file on its own.

## Index

| Input | Part | Status | Covered by / note |
|-------|------|--------|-------------------|
<!-- Example rows — replace with your own once you add inputs:
| payments-protocol-v2.pdf | §3 Wire format         | Superseded | architecture/11-interface-contracts |
| payments-protocol-v2.pdf | §5 Retry / idempotency | Live       | external spec — authoritative until the protocol revises |
| brand-moodboard.png      | (whole)                | Live       | design reference; not decomposable |
-->

_No inputs indexed yet._
