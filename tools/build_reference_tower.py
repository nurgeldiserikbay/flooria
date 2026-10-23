"""Render repeatable, alpha-transparent soft-3D tower modules for Flooria.

These are purpose-built 2.5D assets, not screen crops. Architecture geometry,
light direction and viewbox are identical for all three floor statuses.
Only the material palette varies; labels and icons stay live in Flutter.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random, math

DIR = Path(__file__).resolve().parents[1] / "assets" / "art"
DIR.mkdir(parents=True,exist_ok=True)
S = 2
W,H = 900*S,318*S

PALETTE = {
 "current": {"face":(255,224,157),"light":(255,246,209),"shade":(209,160,91),"side":(211,157,94),"trim":(249,194,100),"niche":(255,211,136)},
 "completed":{"face":(201,230,189),"light":(241,250,225),"shade":(139,178,131),"side":(136,169,128),"trim":(174,203,158),"niche":(255,226,161)},
 "locked":{"face":(217,213,235),"light":(247,243,252),"shade":(166,160,194),"side":(156,152,181),"trim":(198,191,215),"niche":(242,221,194)}
}

def rect(x0,y0,x1,y1): return tuple(round(v*S) for v in (x0,y0,x1,y1))
def polygon(points): return [(round(x*S),round(y*S)) for x,y in points]
def tint(rgb,amount):
    if amount>=0:return tuple(min(255,round(v+(255-v)*amount)) for v in rgb)
    return tuple(max(0,round(v*(1+amount))) for v in rgb)
def glass_arch(im,d,x,y,flavor):
    # Archway carved into the side of the building; warm inset light and rim.
    d.rounded_rectangle(rect(x,y,x+76,y+175),radius=33*S,
        fill=(*tint(flavor["side"],-.27),255))
    d.rounded_rectangle(rect(x+9,y+9,x+67,y+166),radius=27*S,
        fill=(*tint(flavor["trim"],.29),255))
    d.rounded_rectangle(rect(x+18,y+18,x+58,y+153),radius=20*S,
        fill=(*flavor["niche"],255))
    for i in range(45):
        a=i/45
        col=tint(flavor["niche"],.12+a*.40)
        d.line(polygon([(x+23+i*.5,y+40),(x+23+i*.5,y+145)]),fill=(*col,round((1-a)*2)),width=2*S)
    d.arc(rect(x+19,y+20,x+58,y+91),175,295,
        fill=(255,255,251,205),width=5*S)

def leaves(im, x, y, state, seed):
    r=random.Random(seed)
    if state=="locked": return
    dark=(73,131,83) if state=="completed" else (78,139,83)
    mid=(124,177,105)
    hi=(195,222,151)
    d=ImageDraw.Draw(im,"RGBA")
    for i in range(16):
        dx=r.uniform(-37,37);dy=r.uniform(-12,16);rad=r.uniform(6,13)
        col=r.choice([dark,mid,hi])
        d.ellipse(rect(x+dx-rad,y+dy-rad*.7,x+dx+rad,y+dy+rad*.7),fill=(*col,230))
    for i in range(5):
        dx=r.uniform(-30,30);dy=r.uniform(-5,15)
        d.ellipse(rect(x+dx-3,y+dy-3,x+dx+3,y+dy+3),
            fill=(255,248,220,245))

def render(state):
    p=PALETTE[state]
    im=Image.new("RGBA",(W,H),(0,0,0,0))
    # Soft ambient occlusion behind every common ledge.
    shade=Image.new("RGBA",(W,H),(0,0,0,0));sd=ImageDraw.Draw(shade,"RGBA")
    sd.rounded_rectangle(rect(69,60,837,282),radius=37*S,
        fill=(72,79,108,76))
    shade=shade.filter(ImageFilter.GaussianBlur(14*S));im.alpha_composite(shade)
    d=ImageDraw.Draw(im,"RGBA")
    # Depth: left and right wall extrusion, same geometry across variants.
    d.polygon(polygon([(69,89),(123,43),(777,43),(837,83),(837,251),(775,279),(116,279),(69,249)]),
        fill=(*p["side"],255))
    d.polygon(polygon([(775,45),(839,86),(839,246),(777,277)]),
        fill=(*tint(p["side"],-.07),255))
    d.polygon(polygon([(66,86),(119,56),(778,56),(827,86),(805,270),(110,270)]),
        fill=(*p["face"],255))
    # Vertical sculpted face illumination: bright upper left, shaded bottom.
    for y in range(89,266):
        a=(y-89)/177
        col=tint(p["face"],.20-a*.25)
        d.line(polygon([(124,y),(770,y)]),fill=(*col,254),width=S)
    # Angled wall light on the left/right, rounded side arches.
    glass_arch(im,d,46,96,p)
    glass_arch(im,d,778,97,p)
    # Thin stone pilasters and capitals.
    d.rounded_rectangle(rect(118,93,149,266),radius=8*S,
        fill=(*tint(p["face"],.33),255))
    d.rounded_rectangle(rect(752,93,784,266),radius=8*S,
        fill=(*tint(p["shade"],.14),255))
    for x in [112,748]:
        d.rounded_rectangle(rect(x,93,x+44,112),radius=7*S,
            fill=(*tint(p["trim"],.36),255))
        d.line(polygon([(x+8,123),(x+8,251)]),fill=(255,255,248,122),width=4*S)
    # Large clean front plaque, no graphics or baked labels.
    d.rounded_rectangle(rect(155,120,744,258),radius=27*S,
        fill=(*tint(p["shade"],-.04),92))
    d.rounded_rectangle(rect(159,116,739,251),radius=29*S,
        fill=(*tint(p["face"],.21),255),
        outline=(*tint(p["light"],.36),240),width=5*S)
    for y in range(126,240):
        t=(y-126)/114
        col=tint(p["face"],.38-t*.28)
        d.line(polygon([(183,y),(714,y)]),fill=(*col,210),width=S)
    d.arc(rect(169,122,729,256),190,340,fill=(255,255,255,180),width=3*S)
    # Deep overhanging upper cornice, three sculpted bands.
    d.polygon(polygon([(54,84),(121,32),(783,32),(853,81),(841,101),(64,101)]),
        fill=(*tint(p["trim"],.04),255))
    d.polygon(polygon([(64,76),(119,36),(778,36),(842,78)]),
        fill=(*tint(p["light"],.14),255))
    d.rounded_rectangle(rect(51,84,850,105),radius=10*S,
        fill=(*tint(p["shade"],.15),255))
    d.rounded_rectangle(rect(54,80,848,96),radius=7*S,
        fill=(*tint(p["light"],.04),255))
    d.line(polygon([(74,83),(826,83)]),fill=(255,255,255,205),width=5*S)
    d.rounded_rectangle(rect(113,26,789,49),radius=11*S,
        fill=(*tint(p["trim"],.24),255))
    d.line(polygon([(132,30),(775,30)]),fill=(255,255,255,174),width=4*S)
    # Lower rail overlaps next module when stacked.
    d.polygon(polygon([(42,254),(860,254),(841,282),(64,282)]),
        fill=(*tint(p["shade"],.20),255))
    d.rounded_rectangle(rect(48,250,854,268),radius=8*S,
        fill=(*tint(p["light"],.01),255))
    d.line(polygon([(63,252),(841,252)]),fill=(255,255,255,218),width=5*S)
    d.polygon(polygon([(69,279),(836,279),(811,293),(89,293)]),
        fill=(*tint(p["shade"],.11),255))
    d.line(polygon([(89,279),(813,279)]),fill=(255,255,255,138),width=3*S)
    # Sparse small sunlit greenery; never obscures UI or becomes a castle.
    leaves(im,106,87,state,7)
    leaves(im,808,83,state,13)
    leaves(im,88,253,state,23)
    leaves(im,817,257,state,39)
    im.resize((900,318),Image.Resampling.LANCZOS).save(
        DIR/f"ref_floor_{state}.webp","WEBP",quality=93,method=6)
    print(state, (DIR/f"ref_floor_{state}.webp").stat().st_size)

if __name__=="__main__":
    for state in PALETTE:render(state)
