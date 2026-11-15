# Throughstone — Retcon sub-brand logo

A **second logo**, not a replacement. Throughstone keeps its main mark; this label marks
**Retcon**-related posts and assets (bringing an existing codebase into Throughstone — the
throughline threaded back through code that already exists).

## Spec
- **Icon:** the through-stone reworked as a tapered "sharpened stick" that fades in left→right
  (ghost on the left, solid on the right) and extends past the right wall face.
- **Color:** Burnt Sienna `#BC5A34` — an iron-oxide earth red, inside the Warm Sandstone palette
  (the red end vs. ochre's gold). No blue/green. See `brand/BRAND.md` §4.
- **Tag:** `RETCON` in an **outline** block tag (`rx2.5`, matching the through-stone radius),
  below the wordmark.
- **Type:** real **Cinzel** for both `THROUGHSTONE` and `RETCON`, outlined to paths.

## Files
| File | Use |
|---|---|
| `throughstone-retcon-lockup.svg` | Primary lockup (transparent bg, for light surfaces) |
| `throughstone-retcon-lockup-ondark.svg` | Lockup for dark backgrounds (Paper wordmark) |
| `throughstone-retcon-mark.svg` | Standalone icon, Ink tile — avatar/favicon |
| `throughstone-retcon-mark-ondark.svg` | Standalone icon, no tile (floats on dark) |

## Regenerate
```
python brand/logo/retcon/generate_retcon_logo.py
```
Needs a Python venv with `fonttools` (same dependency as `brand/logo/generate_logo.py`). Reads
the bundled `brand/site/assets/fonts/Cinzel.ttf`, so no font install is required.
