"""Build actual transparent soft-3D tower and icon sprites. No baked game text."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random
random.seed(14)
OUT=Path(__file__).resolve().parents[1]/'assets'/'art'
OUT.mkdir(parents=True,exist_ok=True)
K=2

def canvas(w,h): return Image.new('RGBA',(w*K,h*K),(0,0,0,0))
def draw(im): return ImageDraw.Draw(im,'RGBA')
def b(d,r,color,rad=0,outline=None,width=1):
    rr=tuple(int(v*K) for v in r)
    if rad:d.rounded_rectangle(rr,radius=int(rad*K),fill=color,outline=outline,width=int(width*K))
    else:d.rectangle(rr,fill=color,outline=outline,width=int(width*K))
def e(d,r,color):d.ellipse(tuple(int(v*K) for v in r),fill=color)
def ln(d,pts,color,width=2):d.line([(int(x*K),int(y*K)) for x,y in pts],fill=color,width=int(width*K))
def finish(im,name):
    im.resize((im.width//K,im.height//K),Image.Resampling.LANCZOS).save(OUT/name,'WEBP',quality=87,method=6)
def floor(state):
    roof,front,side= {
      'current':((255,239,198,255),(246,217,151,255),(208,165,112,255)),
      'completed':((226,245,222,255),(195,229,202,255),(143,189,160,255)),
      'locked':((239,237,248,255),(216,210,235,255),(164,157,193,255))
    }[state]
    im=canvas(900,325);d=draw(im)
    # common stone body with consistent horizontal architectural joints
    d.polygon([(int(x*K),int(y*K)) for x,y in [(63,73),(115,37),(773,37),(833,73),(833,254),(773,284),(115,284),(63,255)]],fill=side)
    d.polygon([(int(x*K),int(y*K)) for x,y in [(52,72),(115,26),(780,26),(845,72),(814,106),(80,106)]],fill=roof)
    b(d,(80,102,814,257),front,19)
    b(d,(173,118,730,245),(248,246,241,224),22,(255,255,255,205),3)
    b(d,(182,125,721,238),(180,167,158,38),18)
    for x in [36,783]:
        b(d,(x,87,x+82,268),side,35)
        b(d,(x+15,106,x+67,253),(255,255,255,135),26)
        b(d,(x+28,123,x+54,235),(125,134,170,130),15)
        b(d,(x+32,132,x+50,223),(255,222,158,155) if state!='locked' else (203,201,227,130),10)
    for x in (88,789): b(d,(x,94,x+14,264),(255,255,255,105),6)
    d.polygon([(int(x*K),int(y*K)) for x,y in [(36,86),(99,55),(794,55),(859,86),(842,101),(54,101)]],fill=roof)
    ln(d,[(61,94),(837,94)],(255,255,255,230),4)
    d.polygon([(int(x*K),int(y*K)) for x,y in [(42,257),(850,257),(831,286),(66,286)]],fill=side)
    d.polygon([(int(x*K),int(y*K)) for x,y in [(42,252),(850,252),(824,267),(69,267)]],fill=roof)
    ln(d,[(75,262),(817,262)],(255,255,255,145),3)
    for x in [145,360,559,756]: ln(d,[(x,57),(x-7,80)],(158,153,171,75),2)
    for x,y in [(77,65),(116,69),(777,62),(823,79),(92,253),(815,253)]:
        for i in range(4):
            xx=x+random.randint(-15,15);yy=y+random.randint(-7,9)
            e(d,(xx-10,yy-5,xx+10,yy+6),(110,179,116,210))
            e(d,(xx-7,yy-6,xx+2,yy+1),(177,220,153,205))
    shadow=canvas(900,325)
    b(draw(shadow),(90,276,810,291),(73,75,108,56),20)
    shadow=shadow.filter(ImageFilter.GaussianBlur(12*K))
    shadow.alpha_composite(im)
    finish(shadow,'soft_floor_'+state+'.webp')
def icon(kind):
    im=canvas(128,128);d=draw(im)
    b(d,(8,13,120,121),(70,82,110,45),27)
    b(d,(8,7,120,114),(252,250,245,255),27,(255,255,255,255),3)
    if kind=='2048':
        colors=[(245,190,161,255),(250,209,114,255),(150,201,239,255),(154,215,166,255)]
        for i in range(4):
            x=21+(i%2)*44;y=20+(i//2)*44
            b(d,(x,y,x+41,y+41),colors[i],10,(255,255,255,220),2)
    elif kind=='trail':
        ln(d,[(29,82),(63,33),(95,78)],(134,185,144,255),8)
        for (x,y),c in zip([(29,82),(63,33),(95,78)],[(93,164,240,255),(145,212,131,255),(242,146,113,255)]):
            e(d,(x-16,y-16,x+16,y+16),c)
    elif kind=='games':
        b(d,(24,44,104,89),(116,149,198,255),27)
        ln(d,[(41,64),(59,64)],(255,255,255,255),6)
        ln(d,[(50,55),(50,73)],(255,255,255,255),6)
        e(d,(75,58,86,69),(255,229,161,255));e(d,(64,71,75,82),(255,229,161,255))
    else:
        e(d,(30,23,98,91),(188,162,229,255))
        for x,y in [(48,43),(74,43),(47,67),(76,66)]:
            e(d,(x-13,y-13,x+13,y+13),(221,203,245,255))
        ln(d,[(63,32),(63,86)],(131,107,163,210),3)
    finish(im,'soft_icon_'+kind+'.webp')
def sky():
    im=canvas(540,1000)
    d=draw(im)
    for y in range(1000):
        t=y/1000
        if t<.54:
            u=t/.54;rgb=(round(169+65*u),round(213+29*u),round(247+5*u))
        else:
            u=(t-.54)/.46;rgb=(round(234+20*u),round(242+11*u),round(252-12*u))
        b(d,(0,y,540,y+1),(*rgb,255))
    far=canvas(540,1000);f=draw(far)
    for x,y,s in [(-18,520,.8),(440,580,.68),(55,735,.4),(380,790,.4)]:
        b(f,(x,y-250*s,x+100*s,y),(216,223,243,135),12)
        b(f,(x+21*s,y-328*s,x+80*s,y-250*s),(216,223,243,135),8)
        for i in range(3):b(f,(x+(18+26*i)*s,y-150*s,x+(31+26*i)*s,y-33*s),(248,248,253,105),8)
    im.alpha_composite(far.filter(ImageFilter.GaussianBlur(13*K)))
    clouds=canvas(540,1000);c=draw(clouds)
    for x,y,scale in [(-35,245,1.4),(453,307,1.3),(-25,885,1.65),(455,945,1.65)]:
        for dx,dy,r in [(0,18,56),(51,-9,64),(105,20,55),(158,26,41)]:
            xx=x+dx*scale;yy=y+dy*scale;rr=r*scale
            e(c,(xx-rr,yy-rr,xx+rr,yy+rr),(255,255,255,135))
    im.alpha_composite(clouds.filter(ImageFilter.GaussianBlur(20*K)))
    finish(im,'soft_sky.webp')
if __name__=='__main__':
    for state in ('current','completed','locked'):floor(state)
    for kind in ('2048','trail','games','mind'):icon(kind)
    sky()
    print('Generated 8 actual, reusable Flooria sprites')
