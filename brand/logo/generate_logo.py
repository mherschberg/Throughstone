#!/usr/bin/env python3
"""Generate the Throughstone logo SVG set.

The mark is hand-built from rectangles (a coursed wall + an ochre through-stone on a
dark tile). The wordmark "THROUGHSTONE" is outlined from Cinzel into vector paths so the
final SVGs have NO font dependency. Run with the venv python that has fonttools.
"""
import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "site", "assets", "fonts", "Cinzel.ttf")
OUT = HERE

# ---- palette ----
PAPER  = "#F4EEE2"
SAND   = "#DEC9A0"
OCHRE  = "#B07A35"
MORTAR = "#857667"
INK    = "#2A2521"

# ---------------------------------------------------------------- mark builder
# all coordinates live in a 0..100 box
BLOCKS = [  # sand courses (x, y, w)  h=12
    (16,16,21.33),(39.33,16,21.33),(62.66,16,21.34),
    (16,30,10.66),(28.66,30,21.33),(51.99,30,21.33),(75.32,30,8.68),
    (16,58,21.33),(39.33,58,21.33),(62.66,58,21.34),
    (16,72,10.66),(28.66,72,21.33),(51.99,72,21.33),(75.32,72,8.68),
]
STONE = (11,44,78,12)  # ochre through-stone (protrudes past the 16..84 wall faces)

def _block_rects(fill):
    return "".join(
        f'<rect x="{x}" y="{y}" width="{w}" height="12" rx="1.5" fill="{fill}"/>'
        for (x,y,w) in BLOCKS)

def mark(tile=None, block=SAND, stone=OCHRE):
    """Full mark. tile=None => no background tile (for dark / floating use)."""
    s = ""
    if tile:
        s += f'<rect x="2" y="2" width="96" height="96" rx="18" fill="{tile}"/>'
    s += _block_rects(block)
    x,y,w,h = STONE
    s += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2.5" fill="{stone}"/>'
    return s

def mark_mono(color="currentColor"):
    """One-colour mark: blocks + protruding stone in a single colour, no tile.
    The stone is identifiable because it is longer and breaks the wall faces."""
    s = _block_rects(color)
    x,y,w,h = STONE
    s += f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2.5" fill="{color}"/>'
    return s

def favicon(tile=INK, block=SAND, stone=OCHRE):
    return (f'<rect x="2" y="2" width="96" height="96" rx="18" fill="{tile}"/>'
            f'<rect x="16" y="18" width="68" height="12" rx="2" fill="{block}"/>'
            f'<rect x="11" y="44" width="78" height="12" rx="2.5" fill="{stone}"/>'
            f'<rect x="16" y="70" width="68" height="12" rx="2" fill="{block}"/>')

# ---------------------------------------------------------------- wordmark
def wordmark_path(text="THROUGHSTONE", tracking=0.045):
    font = TTFont(FONT)
    upem = font["head"].unitsPerEm
    cmap = font.getBestCmap()
    gs = font.getGlyphSet()
    hmtx = font["hmtx"]
    track = tracking * upem

    svgpen = SVGPathPen(gs)
    bpen = BoundsPen(gs)
    x = 0.0
    for ch in text:
        gname = cmap[ord(ch)]
        t = (1,0,0,1,x,0)
        gs[gname].draw(TransformPen(svgpen, t))
        gs[gname].draw(TransformPen(bpen, t))
        x += hmtx[gname][0] + track
    d = svgpen.getCommands()
    xmin,ymin,xmax,ymax = bpen.bounds
    return d, xmin, ymin, xmax, ymax

# ---------------------------------------------------------------- svg writer
def write(name, w, h, body, comment=""):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:g} {h:g}" '
           f'width="{w:g}" height="{h:g}" fill="none">'
           f'{comment}{body}</svg>\n')
    with open(os.path.join(OUT, name), "w") as f:
        f.write(svg)
    print(f"  wrote {name}  ({w:g}x{h:g})")

def wordmark_group(d, xmin, ymin, xmax, ymax, fill, cap_px, x_off=0, y_center=None):
    """Return (svg_group, width_px, height_px) for the wordmark scaled to cap_px."""
    fh = ymax - ymin
    fw = xmax - xmin
    scale = cap_px / fh
    wpx = fw * scale
    # flip y (font is y-up), normalise so top=0
    # point (X,Y) -> (scale*(X - xmin) + x_off, scale*(ymax - Y) + ytop)
    ytop = 0 if y_center is None else (y_center - cap_px/2)
    g = (f'<g transform="translate({x_off:g},{ytop:g}) scale({scale:g},{-scale:g}) '
         f'translate({-xmin:g},{-ymax:g})"><path d="{d}" fill="{fill}"/></g>')
    return g, wpx, cap_px

# ================================================================ build
print("Building Throughstone logo set:")
d, xmin, ymin, xmax, ymax = wordmark_path()
TM = '<!-- Throughstone (TM) — Mark A. Herschberg. Mark may not be altered. -->'

# 1. primary colour mark (ink tile)
write("throughstone-mark.svg", 100, 100, mark(tile=INK), TM)
# 2. on-dark colour mark (no tile; sand+ochre float on the dark surface)
write("throughstone-mark-ondark.svg", 100, 100, mark(tile=None), TM)
# 3. monochrome mark (currentColor)
write("throughstone-mark-mono.svg", 100, 100, mark_mono("currentColor"), TM)
# 4. favicon (simplified, colour)
write("throughstone-favicon.svg", 100, 100, favicon(), TM)

# 5. wordmark alone (ink), tight box
gw, wpx, hpx = wordmark_group(d, xmin, ymin, xmax, ymax, INK, cap_px=100, x_off=0, y_center=50)
write("throughstone-wordmark.svg", round(wpx,1), 100, gw)

# ---- lockups ----
# layout constants (in a 100-tall canvas)
MARK = 78.0          # mark box size
MX, MY = 0.0, 11.0   # mark position
GAP = 24.0           # gap between mark and wordmark
CAP = 46.0           # wordmark cap height in lockup

def lockup_horizontal(filename, tile, block, stone, wm_fill, mono=False):
    if mono:
        markbody = mark_mono("currentColor")
    else:
        markbody = mark(tile=tile, block=block, stone=stone)
    markg = f'<g transform="translate({MX:g},{MY:g}) scale({MARK/100:g})">{markbody}</g>'
    wx = MX + MARK + GAP
    gw, wpx, _ = wordmark_group(d, xmin, ymin, xmax, ymax, wm_fill, cap_px=CAP, x_off=wx, y_center=50)
    total_w = wx + wpx + 2
    write(filename, round(total_w,1), 100, markg + gw, TM)

# 6. primary horizontal lockup (colour mark + ink wordmark)
lockup_horizontal("throughstone-lockup.svg", INK, SAND, OCHRE, INK)
# 7. on-dark horizontal lockup (no-tile colour mark + paper wordmark)
lockup_horizontal("throughstone-lockup-ondark.svg", None, SAND, OCHRE, PAPER)
# 8. monochrome horizontal lockup (currentColor everything)
lockup_horizontal("throughstone-lockup-mono.svg", None, None, None, "currentColor", mono=True)

# 9. stacked lockup (mark centred above wordmark)
def lockup_stacked(filename, tile, block, stone, wm_fill):
    markbox = 96.0
    gw_tmp, wpx, _ = wordmark_group(d, xmin, ymin, xmax, ymax, wm_fill, cap_px=30)
    total_w = max(markbox, wpx)
    cx = total_w/2
    markg = f'<g transform="translate({cx-markbox/2:g},0) scale({markbox/100:g})">{mark(tile=tile,block=block,stone=stone)}</g>'
    wm_y = markbox + 22
    gw, _, _ = wordmark_group(d, xmin, ymin, xmax, ymax, wm_fill, cap_px=30, x_off=cx-wpx/2, y_center=wm_y+15)
    write(filename, round(total_w,1), round(wm_y+34,1), markg + gw, TM)

lockup_stacked("throughstone-lockup-stacked.svg", INK, SAND, OCHRE, INK)

print("Done.")
