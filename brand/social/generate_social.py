#!/usr/bin/env python3
"""Generate the Throughstone social card SVG.

The card is a 1280x640 Open Graph-style canvas with a dark left brand column and a
paper right text column. All copy is outlined to SVG paths via fonttools so the output is
self-contained and does not depend on installed fonts.
"""
import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
FDIR = os.path.join(HERE, "..", "site", "assets", "fonts")

PAPER = "#F4EEE2"
SAND = "#DEC9A0"
OCHRE = "#B07A35"
OCHRED = "#8F6024"
MORTAR = "#857667"
INK = "#2A2521"

CINZEL = os.path.join(FDIR, "Cinzel.ttf")
SANS = os.path.join(FDIR, "SourceSans3-400.ttf")
SANS600 = os.path.join(FDIR, "SourceSans3-600.ttf")
MONO = os.path.join(FDIR, "IBMPlexMono-400.ttf")

# Font cache stores the parsed font plus the tables needed by path/width helpers. Reusing
# TTFont objects keeps wrapping and composition from repeatedly parsing the same TTF files.
_cache = {}

def load(path):
    """Return cached fonttools data for one font path."""
    if path not in _cache:
        f = TTFont(path)
        _cache[path] = (
            f,
            f["head"].unitsPerEm,
            f.getBestCmap(),
            f.getGlyphSet(),
            f["hmtx"],
        )
    return _cache[path]

def text_path(text, font_path, size, x, baseline, fill, tracking=0.0, return_w=False):
    """Return SVG path markup for text drawn at a baseline.

    Fonts are y-up while SVG is y-down, so each glyph transform scales y by -scale and places
    the glyph at the requested SVG baseline. The optional width return lets the footer place
    mixed-color text without relying on browser text measurement.
    """
    f, upem, cmap, gs, hmtx = load(font_path)
    scale = size / upem
    track_u = (tracking * size) / scale  # tracking is an em fraction, converted to font units
    pen = SVGPathPen(gs)
    cur = 0.0
    space = cmap.get(0x20)

    for ch in text:
        gname = cmap.get(ord(ch), space)
        if gname is None:
            cur += 0.5 * upem + track_u
            continue

        # Affine transform: xx=scale, yy=-scale, dx=x+cur*scale, dy=baseline.
        t = (scale, 0, 0, -scale, x + cur * scale, baseline)
        gs[gname].draw(TransformPen(pen, t))
        cur += hmtx[gname][0] + track_u

    d = pen.getCommands()
    g = f'<path d="{d}" fill="{fill}"/>'
    if return_w:
        return g, cur * scale
    return g

def width_of(text, font_path, size, tracking=0.0):
    """Measure outlined text using the same glyph advances used by text_path."""
    f, upem, cmap, gs, hmtx = load(font_path)
    scale = size / upem
    track_u = (tracking * size) / scale
    cur = 0.0
    space = cmap.get(0x20)

    for ch in text:
        gname = cmap.get(ord(ch), space)
        cur += (hmtx[gname][0] if gname else 0.5 * upem) + track_u
    return cur * scale

def wrap(text, font_path, size, maxw):
    """Greedy-wrap copy to maxw using vector advance widths."""
    words = text.split()
    lines = []
    cur = ""

    for w in words:
        t = (cur + " " + w).strip()
        if width_of(t, font_path, size) <= maxw or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines

# ----- mark wall -----
# The wall reuses the logo's 0..100 mark coordinates, scaled up and placed in the left column.
# Rows 16/30/58/72 are sand blocks; row 44 is intentionally open for the ochre through-stone.
ROWS = {
    16: [(16, 21.33), (39.33, 21.33), (62.66, 21.34)],
    30: [(16, 10.66), (28.66, 21.33), (51.99, 21.33), (75.32, 8.68)],
    58: [(16, 21.33), (39.33, 21.33), (62.66, 21.34)],
    72: [(16, 10.66), (28.66, 21.33), (51.99, 21.33), (75.32, 8.68)],
}
WALL_X, WALL_Y, WALL_S = 64, 154, 3.32

def wall():
    """Return the scaled wall blocks for the social-card illustration."""
    s = ""
    for y, blocks in ROWS.items():
        for bx, bw in blocks:
            X = WALL_X + bx * WALL_S
            Y = WALL_Y + y * WALL_S
            W = bw * WALL_S
            H = 12 * WALL_S
            s += f'<rect x="{X:.1f}" y="{Y:.1f}" width="{W:.1f}" height="{H:.1f}" rx="5" fill="{SAND}"/>'
    return s

# ----- compose -----
# 1280x640 canvas: the left 460px is the dark brand column; the right column starts at X=540.
# The through-stone crosses out of the wall and toward the right column, echoing the mark.
X = 540  # right-column left edge
parts = []
parts.append(f'<rect x="0" y="0" width="1280" height="640" fill="{PAPER}"/>')
parts.append(f'<rect x="0" y="0" width="460" height="640" fill="{INK}"/>')
parts.append(wall())
parts.append(f'<rect x="96" y="300" width="430" height="40" rx="6" fill="{OCHRE}"/>')  # through-stone bridges seam

# Every text run below is converted to vector paths so the social card renders consistently in
# previews, crawlers, and static hosts that may not have the brand fonts.
# Wordmark THROUGHSTONE (Cinzel caps, tracking .05), cap height 40, baseline 210.
parts.append(text_path("THROUGHSTONE", CINZEL, 53, X, 212, INK, tracking=0.05))
# eyebrow
parts.append(text_path("DISCIPLINED SOFTWARE DEVELOPMENT", CINZEL, 17, X, 262, OCHRED, tracking=0.13))
# tagline (two lines), Source Sans 3 semibold (System A)
parts.append(text_path("From idea to blueprint", SANS600, 56, X, 330, INK))
parts.append(text_path("to built.", SANS600, 56, X, 392, INK))
# descriptor, Source Sans 22, wrapped
desc = "Start with your software idea — your AI agent turns it into a planned, documented, well-architected project."
lines = wrap(desc, SANS, 22, 600)
y = 452
for ln in lines:
    parts.append(text_path(ln, SANS, 22, X, y, MORTAR))
    y += 31
# footer, Plex Mono 15 — url ink, rest mortar
url = "github.com/mherschberg/Throughstone"
sep = "   ·   BSD-3-Clause · Throughstone™"
g1, w1 = text_path(url, MONO, 15, X, 592, INK, return_w=True)
parts.append(g1)
parts.append(text_path(sep, MONO, 15, X + w1, 592, MORTAR))

svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 640" width="1280" height="640">'
       '<!-- Throughstone (TM) social card -->' + "".join(parts) + '</svg>\n')
out = os.path.join(HERE, "throughstone-social.svg")
with open(out, "w") as f:
    f.write(svg)
print("wrote", out, f"({len(svg)} bytes)")
