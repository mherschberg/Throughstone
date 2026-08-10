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

## Conventions
- Give each file a clear, descriptive name (e.g. `payments-protocol-v2.pdf`,
  `admin-dashboard-figma-export.png`) so a session can tell what it is at a glance.
- Subfolders are fine if you have a lot (e.g. `specs/`, `ui/`).
- These are **your source materials, not method output** — unlike `../architecture/` (*what*
  the system is) and `../adr/` (*why*), nothing here is versioned or rewritten by the sessions.
- The folder is **durable and not STEP-1-only**: a later phase, a V2, or a check-in can add
  new inputs the same way.
- Committed by default, so the whole team shares them. If a document is sensitive or very
  large, decide per your project's norms whether to track it.

> This README is just guidance — a session won't treat it as an input document.
