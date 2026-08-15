# Inputs — documents you already have

Drop any material that should **inform {{PROJECT}}'s design** here. This is where the project
starts from what you already know instead of from a blank page.

## What goes here
Anything that informs the design, in any format (Markdown, PDF, images, exports):
- product specs, PRDs, or requirements documents
- prior or external **architecture / design docs** and system diagrams
- **protocol / API specifications** the system must implement or interoperate with
- **UI designs**, mockups, wireframes, style guides, exported design files (e.g. Figma)
- competitor / prior-art analysis, research, notes
- anything else you'd otherwise re-explain from scratch

Not sure whether something belongs? Put it here — it costs nothing, and a session ignores
what isn't relevant to it.

## How it's used
The **architecture sessions** (STEP-1, and any later architecture work) read the relevant
documents from this folder and build on them, so you don't have to restate what a document
already says. If you'd rather paste a document or point the agent at one **in chat**, the
agent **saves a copy here** so it persists for later sessions and fresh chats — sessions run
in separate chats and read their inputs from disk, not from the conversation.

## Lifecycle — these are point-in-time; `../architecture/` is living
An input is a **starting point**, not a lasting source of truth. It's a snapshot of what you knew
or were handed at one moment; the living description of the system lives in `../architecture/` (and
the decisions behind it in `../adr/`) — **even when an architecture doc began as a copy of something
here.** Where a generated `../architecture/` or `../adr/` doc covers the same ground as an input,
**the generated doc wins.**

Architecture-grade material belongs in `../architecture/` **promptly** — the difference between
inputs is only *how* it gets there:
- A **PRD, prior design doc, or research** is *synthesized*: a session reads it, makes the
  decisions, and writes an architecture doc that interprets it. The input rarely survives verbatim,
  and once folded in it's history (provenance, not current intent).
- A **protocol / API spec, or another finished, authoritative doc** is often already in final form.
  Don't leave it living here with `../architecture/` merely *pointing* at it — **lift it into
  `../architecture/` as soon as it's in play.** That lift may be a **whole-file copy, or a light
  reformat** to follow the doc conventions: fit the naming, and add the **`Version`**, **`Status`**,
  and **`Version Log`** header fields every architecture doc carries — `scripts/check.sh` requires
  all three of a numbered doc however it got there, and a document written outside the method almost
  never arrives with them. From then on the architecture copy is the living version you keep true,
  and the original stays here as provenance.
  - *Use judgment, though:* lifting isn't always the right move — sometimes you **reference** the
    input from `../architecture/` and keep it here, long-lived and `Live`, instead of copying it in.
    A large external standard you don't own and only partially implement (a long RFC/ISO) is the
    clearest example — write a compliance/interface doc that references it and keep the artifact
    pinned by version — but it's *an* example, not the only case.

Two things keep this from rotting:
- **The index — `inputs-index.md`.** It records, per input, which parts `../architecture/` has
  already superseded and which still hold, so a later session builds only on what's current instead
  of re-reading a stale seed. Add a row when you drop in an input; flip it when a session captures
  one (see that file).
- **The archive — `inputs/archive/`.** When an input has been **fully** superseded, retire it by
  moving it into `inputs/archive/`. **Sessions read `inputs/` but not `inputs/archive/`,** so a
  captured seed stops reading as current intent while its file is kept for history. This is a
  **move, never an in-place edit or a delete** — the periodic check-in (`../runbooks/check-in.md`)
  surfaces candidates and you decide; nothing is auto-moved.

## Conventions
- Give each file a clear, descriptive name (e.g. `payments-protocol-v2.pdf`,
  `admin-dashboard-figma-export.png`) so a session can tell what it is at a glance.
- Subfolders are fine if you have a lot (e.g. `specs/`, `ui/`).
- These are **your source materials, not method output** — unlike `../architecture/` (*what*
  the system is) and `../adr/` (*why*), nothing here is versioned or rewritten by the sessions (a
  superseded input is *moved* to `inputs/archive/`, never edited in place — see Lifecycle above).
- `inputs-index.md` (the live-vs-superseded ledger) and this `README.md` are **guidance, not
  inputs** — a session never treats them as source documents.
- The folder is **durable and not STEP-1-only**: a later phase, a V2, or a check-in can add
  new inputs the same way.
- Committed by default, so the whole team shares them. If a document is sensitive or very
  large, decide per your project's norms whether to track it.

> This README is just guidance — a session won't treat it as an input document.
