#!/usr/bin/env python3
"""Technical raster preview of exported Roblox parts; not a Studio screenshot."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]

def normalized(v):
    v=np.asarray(v,dtype=float)
    return v/np.maximum(np.linalg.norm(v,axis=-1,keepdims=True),1e-12)

def sphere():
    vertices=[]; triangles=[]
    rings,segments=24,40
    for y in range(rings+1):
        a=np.pi*y/rings
        for x in range(segments):
            b=2*np.pi*x/segments
            vertices.append([np.sin(a)*np.cos(b),np.cos(a),np.sin(a)*np.sin(b)])
    for y in range(rings):
        for x in range(segments):
            a=y*segments+x;b=y*segments+(x+1)%segments;c=a+segments;d=b+segments
            triangles.extend([[a,c,b],[b,c,d]])
    return np.array(vertices)*.5,np.array(triangles)
SPHERE=sphere()
WEDGE=(np.array([[-.5,-.5,-.5],[.5,-.5,-.5],[-.5,-.5,.5],[.5,-.5,.5],[-.5,.5,.5],[.5,.5,.5]]),np.array([[0,2,4],[1,5,3],[0,1,3],[0,3,2],[2,3,5],[2,5,4],[0,4,5],[0,5,1]]))

def render(variant,width=760,height=465):
    eye=np.array([8,4.6,-17]); target=np.array([0,.45,0]); f=normalized(target-eye); right=normalized(np.cross(f,[0,1,0])); up=np.cross(right,f)
    view=np.stack([right,up,f]); scale=min(width/11.7,height/8.2)
    yy=np.linspace(0,1,height)[:,None,None]
    canvas=np.broadcast_to(np.array([23,43,59])[None,None,:]*(1-yy)+np.array([12,25,37])[None,None,:]*yy,(height,width,3)).copy()
    depth=np.full((height,width),np.inf)
    light=normalized([-.5,.8,-.8]); rim=normalized([.6,.25,.8])
    for part in variant['parts']:
        if part['kind']=='box': continue
        raw,indices=SPHERE if part['kind']=='sphere' else WEDGE
        size=np.array(part['size']); cf=part['cf']; rot=np.array(cf[3:]).reshape(3,3); pos=np.array(cf[:3])
        world=(raw*size)@rot.T+pos
        points=(world-target)@view.T
        screen=np.column_stack([points[:,0]*scale+width/2,-points[:,1]*scale+height/2,points[:,2]])
        color=np.array(part['color'])*255
        normals=normalized(raw/size)@rot.T if part['kind']=='sphere' else None
        for ids in indices:
            pts=screen[ids]; a,b,c=pts
            area=(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
            if abs(area)<1e-8: continue
            x0=max(0,int(np.floor(pts[:,0].min()))); x1=min(width-1,int(np.ceil(pts[:,0].max())))
            y0=max(0,int(np.floor(pts[:,1].min()))); y1=min(height-1,int(np.ceil(pts[:,1].max())))
            if x0>x1 or y0>y1: continue
            x,y=np.meshgrid(np.arange(x0,x1+1)+.5,np.arange(y0,y1+1)+.5)
            w1=((x-a[0])*(c[1]-a[1])-(y-a[1])*(c[0]-a[0]))/area
            w2=((b[0]-a[0])*(y-a[1])-(b[1]-a[1])*(x-a[0]))/area; w0=1-w1-w2
            z=w0*a[2]+w1*b[2]+w2*c[2]
            mask=(w0>=0)&(w1>=0)&(w2>=0)&(z<depth[y0:y1+1,x0:x1+1])
            if not mask.any(): continue
            if normals is not None:
                n=normalized(w0[...,None]*normals[ids[0]]+w1[...,None]*normals[ids[1]]+w2[...,None]*normals[ids[2]])
            else:
                wa,wb,wc=world[ids]; n=normalized(np.cross(wb-wa,wc-wa))
                if np.dot(n,eye-wa)<0:n=-n
            diffuse=np.maximum(0,np.sum(n*light,axis=-1)); edge=np.maximum(0,np.sum(n*rim,axis=-1))
            shade=.53+.46*diffuse+.18*edge
            rgb=np.clip(color*shade[...,None],0,255)
            region=canvas[y0:y1+1,x0:x1+1]; region[mask]=np.broadcast_to(rgb,region.shape)[mask]
            depth[y0:y1+1,x0:x1+1][mask]=z[mask]
    return Image.fromarray(canvas.astype('uint8'))

def main():
    data=json.loads((ROOT/'build/character-preview.json').read_text())
    out=Image.new('RGB',(1600,1160),(10,20,31)); draw=ImageDraw.Draw(out)
    font='/usr/share/fonts/google-noto-vf/NotoSans[wght].ttf'
    if not Path(font).exists():font='/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf'
    def f(size):return ImageFont.truetype(font,size) if Path(font).exists() else ImageFont.load_default(size=size)
    draw.text((38,22),'ADAPT!  /  PERSONAGEM 3D',font=f(30),fill=(237,245,222))
    draw.text((40,65),'Geometria exportada do jogo • prévia técnica, não captura do Roblox Studio',font=f(17),fill=(154,190,198))
    labels=['BLANK · corpo inicial','EXPLORADOR · asas, garras e cauda','PLANANDO · asas abertas','GUARDIÃO · conjunto completo']
    for i,variant in enumerate(data['variants']):
        x=30+(i%2)*790;y=111+(i//2)*515
        out.paste(render(variant),(x,y))
        draw.text((x+14,y+468),labels[i],font=f(19),fill=(202,226,215))
    draw.text((40,1130),'Modelos e poses reais • iluminação desta prévia é aproximada',font=f(15),fill=(137,165,179))
    out.save(ROOT/'build/ADAPT-character-preview.png')
    print('Character preview rendered from exported geometry')
if __name__=='__main__':main()
