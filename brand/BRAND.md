# Throughstone™ — Brand Brief

> A throughstone (real masonry term) is a single stone that spans the full thickness of a
> wall, binding both faces into one structure. That's the brand: **the architecture laid down
> through the whole build, holding everything together from foundation to finish.**

This brief is the source of truth for Throughstone's identity. All collateral — wordmark, logo,
social card, landing page — derives from it. Feel: **solid, foundational, crafted, trustworthy,
calm.** Masonry and architecture, *not* "AI hype."

---

## 1. Positioning

**Category / eyebrow line (the standard short descriptor):**
> DISCIPLINED SOFTWARE DEVELOPMENT

**What it is (one line):**
> Disciplined software development with an AI coding agent — turning a rough idea into a
> planned, documented, well-built project.

**What makes it different:**
- It plans before it codes. The first step produces architecture docs and decision records —
  *no code* — so you never get a "mystery box."
- Decisions are recorded, not lost in a chat log.
- Work proceeds in runnable units: phases → STEPs → substeps.
- It's plain Markdown + a Bash wizard. Nothing to trust but text you can read.

**Who it's for:**
- People new to building with AI who don't want an opaque pile of generated code.
- Early-career developers who need project-shaping discipline.
- Senior devs / leads / founders who hand it to juniors — and to anyone who keeps asking
  *"how do I actually start building with AI?"*

---

## 2. Taglines

The throughline metaphor spans the whole build — not just setup, but every phase → STEP →
substep and check-in. The tagline carries that full arc.

**Primary (locked):**
> **From idea to blueprint to built.**

*The line itself completes the journey (build → built) — it implies the entire process, not
just the start.*

**Secondary / social lines:**
- Blueprint up front. Throughline all the way.
- Every build needs a throughline.
- A blueprint up front. A throughline all the way down.

**Descriptor (use under the wordmark / tagline in product/repo contexts):**
> Architecture first, carried through every step and check-in.

**One-line positioning (for repo "About", meta description):**
> Disciplined software development — build real, well-architected software with an AI coding agent.

---

## 3. Voice & Tone

Throughstone sounds like **a senior engineer who respects your time**: calm, precise,
plainspoken, and quietly confident. It explains; it doesn't sell.

**Do**
- Be concrete and direct. Short sentences. Strong nouns and verbs.
- Use building/craft metaphors *sparingly and accurately* (foundation, course, load-bearing,
  throughline) — never forced.
- Respect beginners without condescending; respect experts without jargon-flexing.
- Prefer "you" and the imperative ("Lay the architecture, then build.").

**Don't**
- No hype words: *revolutionary, magic, unleash, game-changing, 10x, supercharge.*
- No exclamation marks in headlines. No emoji in formal/product copy.
- Don't over-promise ("build anything instantly"). The promise is **discipline and clarity**,
  not speed-for-its-own-sake.
- Don't drown plain ideas in metaphor. One stone image per paragraph, max.

**Tone dial by context:** docs & CLI = matter-of-fact and instructive; landing page =
confident and welcoming; social = crisp and a touch wry (the anti-hype lines live here).

---

## 4. Color Palette — "Warm Sandstone"

Quarried-stone warmth: warm paper, sand, an ochre accent, mortar grey, near-black ink.

| Role | Name | Hex | Use |
|---|---|---|---|
| Background | **Paper** | `#F4EEE2` | Primary light background, page canvas |
| Background (raised) | **Limestone** | `#FBF7EE` | Cards/surfaces slightly above Paper |
| Fill / blocks | **Sand** | `#DEC9A0` | Stone blocks, subtle fills, dividers |
| **Accent (primary)** | **Ochre** | `#B07A35` | The through-stone, CTAs, links, highlights |
| Accent (dark) | **Ochre Deep** | `#8F6024` | Hover/active states, ochre text on light |
| Accent (light) | **Ochre Light** | `#C99A52` | Tints, focus rings, on-dark accents |
| Secondary text | **Mortar** | `#857667` | Captions, borders, muted UI, secondary text |
| Text / dark surface | **Ink** | `#2A2521` | Body text, the logo tile, dark sections |
| Dark surface (deep) | **Basalt** | `#1E1B17` | Deepest backgrounds, footers, code blocks |

**Accessibility & pairing rules** (don't skip — ochre is a mid-tone):
- **Body text:** always **Ink `#2A2521` on Paper/Limestone** (~13:1, AAA). This is the workhorse.
- **Mortar `#857667`** on Paper is ~3.6:1 — use only for **large or secondary** text, borders,
  and captions. Never small body copy.
- **Ochre `#B07A35`** on Paper is ~3:1 — fine for **large headings, icons, and the mark**, not
  for small text. For ochre *text* on light, use **Ochre Deep `#8F6024`**.
- **Ochre buttons:** use **Ink `#2A2521` text on Ochre** (passes AA) — *not* white (white on
  ochre is borderline). For a dark CTA, use **Limestone text on Ink**.
- On dark (Ink/Basalt) surfaces: body = **Paper `#F4EEE2`**; accent = **Ochre Light `#C99A52`**.

---

## 5. Typography System

**Wordmark / display — Cinzel** (SIL OFL, Google Fonts).
Classical Roman *inscriptional* capitals — literally carved-in-stone. Used for the wordmark,
the hero name, and short all-caps section eyebrows. Set in **caps** with **+4–6% letter-spacing**.
At small sizes (nav, favicon) use the **mark alone** rather than shrinking Cinzel.

**Body / UI — Source Sans 3** (SIL OFL). Calm, legible, neutral. All running UI, buttons,
labels, and short copy. This carries 90% of the words.

**Prose / long-form — Spectral** (SIL OFL). Sturdy book serif for documentation prose and
longer paragraphs where a "considered document" feel suits the disciplined-development story.

**Code / mono — IBM Plex Mono** (SIL OFL). For CLI snippets, file paths, and quickstart blocks.

### Type system — **A (locked)**

**System A — Inscription + Clean Sans:** **Cinzel** (wordmark + short all-caps eyebrows) ·
**Source Sans 3** (headings, body, UI, buttons — set headings in 600/semibold) · **IBM Plex
Mono** (code, paths, CLI). Clean, neutral, and versatile; the inscriptional wordmark carries the
"crafted" note while the page stays legible and unfussy.

*Alternates (not used):* **B** — Spectral serif headings/prose (warmer/editorial); **C** — Sora
geometric headings (more contemporary).

**Type scale (suggested, rem):** 3.0 / 2.25 / 1.75 / 1.375 / 1.125 / 1.0 / 0.875.
Line-height: 1.2 for display, 1.6 for body/prose.

All faces are SIL Open Font License — free to embed and self-host. The landing page self-hosts
them from `brand/site/assets/fonts/` (mirrored in `docs/assets/fonts/`); the asset generators
(`brand/logo/generate_logo.py`, `brand/social/generate_social.py`) read the same files, so the
brand is fully reproducible from the repo — only a Python venv with `fonttools` + `pillow` is
needed, no font downloads.

---

## 6. Logo — summary

(Full construction, variants, and SVG files are Deliverable 2.)

- **Mark:** a coursed sand-stone wall on a dark (Ink) rounded tile, with a single **ochre
  through-stone** running edge-to-edge through the middle course and protruding past both faces.
  It *is* the name made visible.
- **Wordmark:** "THROUGHSTONE" in Cinzel caps.
- **Lockup:** mark + wordmark, horizontally, with clear space = the tile's corner radius on all
  sides.
- **Variants to ship:** primary (full color on light), monochrome (Ink), and a simplified
  favicon (3-bar reduction of the wall).

**Do:** keep the ochre stone as the only accent; preserve clear space; use the mark alone when
small. **Don't:** recolor outside the palette, add gradients/3D/bevels, stretch, rotate, or place
the full wall mark below ~24 px (use the favicon reduction instead).

---

## 7. Trademark

**Throughstone™** is an unregistered trademark of **Mark A. Herschberg**. The name and identity
(wordmark + mark) are the ownable brand — use them consistently and don't alter the mark. The
*software* is licensed **BSD-3-Clause**; the brand assets are not a grant of trademark rights.
On first prominent use, write **Throughstone™**; thereafter, "Throughstone."

---

### Status of brand decisions (locked)
- Palette: **Warm Sandstone** (above).
- Mark motif: **through-stone in a bonded wall**, horizontal middle course, dark tile.
- Wordmark: **Cinzel** caps. Body type system: **A** (Source Sans 3 + IBM Plex Mono).
- Primary tagline: **"From idea to blueprint to built."** *(you chose this)*
- Landing page default: **light "paper & stone"** (Deliverable 4) — confirm when we get there.
