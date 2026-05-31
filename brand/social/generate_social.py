#!/usr/bin/env python3
"""Generate the Throughstone social card (Option C) as a self-contained SVG with
ALL text outlined to vector paths (no font dependency). 1280x640."""
import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
FDIR = os.path.join(HERE, "..", "explore", "fonts")
def fp(n): return os.path.join(FDIR, n)

PAPER="#F4EEE2"; SAND="#DEC9A0"; OCHRE="#B07A35"; OCHRED="#8F6024"; MORTAR="#857667"; INK="#2A2521"

_cache={}
def load(path):
    if path not in _cache:
        f=TTFont(path)
        _cache[path]=(f, f["head"].unitsPerEm, f.getBestCmap(), f.getGlyphSet(), f["hmtx"])
    return _cache[path]

def text_path(text, font_path, size, x, baseline, fill, tracking=0.0, return_w=False):
    f,upem,cmap,gs,hmtx = load(font_path)
    scale=size/upem
    track_u = (tracking*size)/scale  # tracking given as em fraction
    pen=SVGPathPen(gs)
    cur=0.0
    space=cmap.get(0x20)
    for ch in text:
        gname=cmap.get(ord(ch), space)
        if gname is None:
            cur += 0.5*upem + track_u; continue
        # affine: xx=scale, yy=-scale, dx=x+cur*scale, dy=baseline
        t=(scale,0,0,-scale, x+cur*scale, baseline)
        gs[gname].draw(TransformPen(pen, t))
        cur += hmtx[gname][0] + track_u
    d=pen.getCommands()
    g=f'<path d="{d}" fill="{fill}"/>'
    if return_w: return g, cur*scale
    return g

def width_of(text, font_path, size, tracking=0.0):
    f,upem,cmap,gs,hmtx=load(font_path)
    scale=size/upem; track_u=(tracking*size)/scale; cur=0.0; space=cmap.get(0x20)
    for ch in text:
        gname=cmap.get(ord(ch),space)
        cur += (hmtx[gname][0] if gname else 0.5*upem) + track_u
    return cur*scale

def wrap(text, font_path, size, maxw):
    words=text.split(); lines=[]; cur=""
    for w in words:
        t=(cur+" "+w).strip()
        if width_of(t,font_path,size)<=maxw or not cur: cur=t
        else: lines.append(cur); cur=w
    if cur: lines.append(cur)
    return lines

CINZEL=fp("Cinzel.ttf"); SPECTRAL=fp("Spectral.ttf"); SANS=fp("SourceSans3-400.ttf"); SANS600=fp("SourceSans3-600.ttf"); MONO=fp("IBMPlexMono-400.ttf")

# ----- mark wall (rows 16/30/58/72; row 44 left open for the stone) -----
ROWS={
 16:[(16,21.33),(39.33,21.33),(62.66,21.34)],
 30:[(16,10.66),(28.66,21.33),(51.99,21.33),(75.32,8.68)],
 58:[(16,21.33),(39.33,21.33),(62.66,21.34)],
 72:[(16,10.66),(28.66,21.33),(51.99,21.33),(75.32,8.68)],
}
WALL_X, WALL_Y, WALL_S = 64, 154, 3.32
def wall():
    s=""
    for y,blocks in ROWS.items():
        for (bx,bw) in blocks:
            X=WALL_X+bx*WALL_S; Y=WALL_Y+y*WALL_S; W=bw*WALL_S; H=12*WALL_S
            s+=f'<rect x="{X:.1f}" y="{Y:.1f}" width="{W:.1f}" height="{H:.1f}" rx="5" fill="{SAND}"/>'
    return s

# ----- compose -----
X = 540  # right-column left edge
parts=[]
parts.append(f'<rect x="0" y="0" width="1280" height="640" fill="{PAPER}"/>')
parts.append(f'<rect x="0" y="0" width="460" height="640" fill="{INK}"/>')
parts.append(wall())
parts.append(f'<rect x="96" y="300" width="430" height="40" rx="6" fill="{OCHRE}"/>')  # through-stone bridges seam

# wordmark THROUGHSTONE (Cinzel caps, tracking .05), cap height 40, baseline 210
parts.append(text_path("THROUGHSTONE", CINZEL, 53, X, 212, INK, tracking=0.05))
# eyebrow
parts.append(text_path("DISCIPLINED SOFTWARE DEVELOPMENT", CINZEL, 17, X, 262, OCHRED, tracking=0.13))
# tagline (two lines), Source Sans 3 semibold (System A)
parts.append(text_path("From idea to blueprint", SANS600, 56, X, 330, INK))
parts.append(text_path("to built.", SANS600, 56, X, 392, INK))
# descriptor, Source Sans 22, wrapped
desc="Turn a rough idea into a planned, documented, well-architected project — with an AI coding agent."
lines=wrap(desc, SANS, 22, 600)
y=452
for ln in lines:
    parts.append(text_path(ln, SANS, 22, X, y, MORTAR)); y+=31
# footer, Plex Mono 15 — url ink, rest mortar
url="github.com/mherschberg/Throughstone"
sep="   ·   BSD-3-Clause · Throughstone™"
g1,w1=text_path(url, MONO, 15, X, 592, INK, return_w=True)
parts.append(g1)
parts.append(text_path(sep, MONO, 15, X+w1, 592, MORTAR))

svg=('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 640" width="1280" height="640">'
     '<!-- Throughstone (TM) social card -->'+"".join(parts)+'</svg>\n')
out=os.path.join(HERE,"throughstone-social.svg")
with open(out,"w") as f: f.write(svg)
print("wrote", out, f"({len(svg)} bytes)")
