#!/usr/bin/env python3
"""Generate the Throughstone **Retcon** sub-brand logo set.

Second logo (not a replacement): Throughstone keeps its main mark long-term; Retcon-related
posts/assets get this distinct label. Mirrors brand/logo/generate_logo.py's approach — the
Cinzel wordmark and the RETCON tag are outlined from the bundled TTF so the SVGs never depend
on a font being installed where they're viewed.

Locked spec:
  - Icon: the through-stone reworked as a tapered "sharpened stick" that fades in left->right
    (ghost/outline on the left, solid on the right, via a horizontal gradient) and extends
    further right past the wall face. Story: the throughline threaded back through existing code.
  - Color: Burnt Sienna #BC5A34 — an iron-oxide earth red inside the Warm Sandstone palette.
  - Tag: RETCON in an OUTLINE block tag (rx2.5, matching the through-stone radius), below the
    wordmark in the kicker position.
  - Type: real Cinzel for both THROUGHSTONE and RETCON, outlined to paths.

Needs a Python venv with fonttools (the system python may lack it).
"""
import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "..", "site", "assets", "fonts", "Cinzel.ttf")
OUT  = HERE

PAPER  = "#F4EEE2"; SAND = "#DEC9A0"; INK = "#2A2521"; BASALT = "#1E1B17"
SIENNA = "#BC5A34"

BLOCKS = [
    (16,16,21.33),(39.33,16,21.33),(62.66,16,21.34),
    (16,30,10.66),(28.66,30,21.33),(51.99,30,21.33),(75.32,30,8.68),
    (16,58,21.33),(39.33,58,21.33),(62.66,58,21.34),
    (16,72,10.66),(28.66,72,21.33),(51.99,72,21.33),(75.32,72,8.68),
]
# retcon through-stone: tapered "sharpened stick" tip, extends right past the wall face
FADE_PATH = "M13 44 L70 44 L94 50 L70 56 L13 56 Q11 56 11 54 L11 46 Q11 44 13 44 Z"

GRAD = ('<linearGradient id="gS" gradientUnits="userSpaceOnUse" x1="11" y1="0" x2="53" y2="0">'
        '<stop offset="0" stop-color="'+SIENNA+'" stop-opacity="0"/>'
        '<stop offset="1" stop-color="'+SIENNA+'" stop-opacity="1"/></linearGradient>')
TM = '<!-- Throughstone (TM) Retcon sub-brand — Mark A. Herschberg. Mark may not be altered. -->'

def block_rects(fill):
    return "".join(f'<rect x="{x}" y="{y}" width="{w}" height="12" rx="1.5" fill="{fill}"/>'
                   for (x,y,w) in BLOCKS)

def mark_fade(tile=INK, block=SAND):
    """Mark with the sienna fade-in through-stone. Uses gradient #gS (defined in root defs)."""
    s = f'<rect x="2" y="2" width="96" height="96" rx="18" fill="{tile}"/>' if tile else ""
    s += block_rects(block)
    s += (f'<path d="{FADE_PATH}" fill="url(#gS)" stroke="{SIENNA}" '
          f'stroke-width="1.6" stroke-linejoin="round"/>')
    return s

def glyph_path(text, tracking):
    font = TTFont(FONT); upem = font["head"].unitsPerEm
    cmap = font.getBestCmap(); gs = font.getGlyphSet(); hmtx = font["hmtx"]
    track = tracking * upem
    svgpen = SVGPathPen(gs); bpen = BoundsPen(gs); x = 0.0
    for ch in text:
        gname = cmap[ord(ch)]; t = (1,0,0,1,x,0)
        gs[gname].draw(TransformPen(svgpen, t)); gs[gname].draw(TransformPen(bpen, t))
        x += hmtx[gname][0] + track
    xmin,ymin,xmax,ymax = bpen.bounds
    return svgpen.getCommands(), xmin, ymin, xmax, ymax

def wm_group(d, xmin, ymax, fw, fh, fill, cap_px, x_off, y_center):
    scale = cap_px / fh; wpx = fw * scale; ytop = y_center - cap_px/2
    g = (f'<g transform="translate({x_off:g},{ytop:g}) scale({scale:g},{-scale:g}) '
         f'translate({-xmin:g},{-ymax:g})"><path d="{d}" fill="{fill}"/></g>')
    return g, wpx

def svg(name, w, h, body):
    out = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:g} {h:g}" '
           f'width="{w:g}" height="{h:g}" fill="none">{TM}{body}</svg>\n')
    with open(os.path.join(OUT, name), "w") as f:
        f.write(out)
    print(f"  wrote {name}  ({w:.1f}x{h:.1f})")

# ---- lockup layout (100-normalized mark) ----
MARK=84.0; GAP=20.0; CAP=38.0; PAD=12.0; TAGH=30.0; TAGGAP=9.0; TAG_CAP=13.0; TAG_PADX=15.0

wd,wxmin,wymin,wxmax,wymax = glyph_path("THROUGHSTONE", 0.045)
wfw,wfh = wxmax-wxmin, wymax-wymin
rd,rxmin,rymin,rxmax,rymax = glyph_path("RETCON", 0.10)
rfw,rfh = rxmax-rxmin, rymax-rymin

def lockup(name, tile, block, wm_fill, bg=None):
    mark_h = MARK; block_h = CAP + TAGGAP + TAGH
    canvas_h = PAD*2 + max(mark_h, block_h); cy = canvas_h/2
    markg = f'<g transform="translate(0,{cy-mark_h/2:g}) scale({MARK/100:g})">{mark_fade(tile,block)}</g>'
    block_top = cy - block_h/2
    wx = MARK + GAP
    wmg, wpx = wm_group(wd,wxmin,wymax,wfw,wfh, wm_fill, CAP, wx, block_top+CAP/2)
    tag_top = block_top + CAP + TAGGAP
    tag_w = rfw*(TAG_CAP/rfh) + 2*TAG_PADX
    tagrect = (f'<rect x="{wx:g}" y="{tag_top:g}" width="{tag_w:g}" height="{TAGH:g}" rx="2.5" '
               f'fill="none" stroke="{SIENNA}" stroke-width="2"/>')
    rg, _ = wm_group(rd,rxmin,rymax,rfw,rfh, SIENNA, TAG_CAP, wx+TAG_PADX, tag_top+TAGH/2)
    total_w = max(wx+wpx, wx+tag_w) + 4
    body = (f'<rect x="0" y="0" width="{total_w:g}" height="{canvas_h:g}" fill="{bg}"/>' if bg else "")
    body += f'<defs>{GRAD}</defs>' + markg + wmg + tagrect + rg
    svg(name, total_w, canvas_h, body)

def mark_icon(name, tile, block, bg=None):
    body = (f'<rect x="0" y="0" width="100" height="100" fill="{bg}"/>' if bg else "")
    body += f'<defs>{GRAD}</defs>' + mark_fade(tile, block)
    svg(name, 100, 100, body)

print("Building Throughstone Retcon logo set:")
lockup("throughstone-retcon-lockup.svg",        INK,  SAND, INK)     # primary (transparent bg)
lockup("throughstone-retcon-lockup-ondark.svg", None, SAND, PAPER, bg=BASALT)
mark_icon("throughstone-retcon-mark.svg",        INK,  SAND)          # icon w/ ink tile
mark_icon("throughstone-retcon-mark-ondark.svg", None, SAND)          # icon, no tile (floats on dark)
print("Done.")
