"""Map inspection derived from actual authored height/voxel geometry, not an engine screenshot."""
from pathlib import Path
import json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from terrain_geometry import field
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'build/world-layout.json').read_text())
N=900;axis=np.linspace(-1920,1920,N);x,z=np.meshgrid(axis,axis)
h,s,r,water=field(data,x,z)
colors={2:(78,131,92),3:(111,111,138),6:(203,184,144),8:(118,126,131),11:(186,135,90),13:(73,64,74),19:(39,103,85),21:(151,177,166)}
rgb=np.full((N,N,3),(25,65,82),dtype=float)
for material,color in colors.items():rgb=np.where(((s==material)&(h>water))[...,None],np.array(color),rgb)
ocean=h<water;depth=np.clip((water-h)/100,0,1)
sea=np.stack((42-depth*25,139-depth*80,151-depth*70),axis=-1)
rgb=np.where(ocean[...,None],sea,rgb)
gy,gx=np.gradient(h);shade=np.clip(.9-.06*gx-.08*gy,.55,1.25)
rgb=np.where((~ocean)[...,None],rgb*shade[...,None],rgb)
canvas=Image.new('RGB',(1250,1080),(15,27,39));canvas.paste(Image.fromarray(rgb.clip(0,255).astype('uint8')),(30,115))
draw=ImageDraw.Draw(canvas)
font_path='/usr/share/fonts/google-noto-sans-vf-fonts/NotoSans[wght].ttf'
try:font=ImageFont.truetype(font_path,17);big=ImageFont.truetype(font_path,36);small=ImageFont.truetype(font_path,13)
except OSError:font=ImageFont.load_default(size=17);big=ImageFont.load_default(size=36);small=ImageFont.load_default(size=13)
def project(xx,zz):return 30+(xx+1920)/3840*N,115+(zz+1920)/3840*N
draw.text((30,24),'ADAPT! / WORLD FOUNDATION',font=big,fill='#edf3ed')
draw.text((32,76),'3.840 × 3.840 studs • 8 biomas • relevo de −150 a +685 • seed 817204',font=font,fill='#a7c1c9')
for route in data['routes']:
 pts=[project(*point) for point in route['points']];draw.line(pts,fill='#eed8a1',width=2)
for island in data['islands']:
 px,pz=project(*island['center']);text=island['name'].upper();box=draw.textbbox((px,pz),text,font=small);w=box[2]-box[0]
 draw.rounded_rectangle((px-w/2-8,pz-12,px+w/2+8,pz+15),radius=6,fill='#162d39')
 draw.text((px-w/2,pz-9),text,font=small,fill='#f1e4c5')
for f in data['floating']:
 px,pz=project(f['center'][0],f['center'][2]);rr=max(f['radius'][0],f['radius'][2])*N/3840
 draw.ellipse((px-rr,pz-rr,px+rr,pz+rr),outline='#d3c1ff',width=2)
px,pz=project(0,20);draw.ellipse((px-5,pz-5,px+5,pz+5),fill='#fff5c7');draw.text((px+10,pz),'SPAWN',font=small,fill='#ffffff')
draw.text((965,130),'O ARQUIPÉLAGO',font=font,fill='#f1e4c5')
lines=['Verdant Island','  praias, rio e grutas','','Ember Atoll','  vulcão e túneis de basalto','','Rift Crown','  picos, fendas e escalada','','Sky Reach','  8 ilhas em várias alturas','','Oldgrowth Sanctuary','  floresta e árvore colossal','','Sunscar Expanse','  mesas e arcos de arenito','','Tideglass Reefs','  lagoa e entradas submersas','','Vesper Hollow','  cristais e câmaras ocultas']
for i,line in enumerate(lines):draw.text((965,170+i*28),line,font=small,fill='#aac6cc' if line.startswith(' ') else '#e2ece8')
draw.text((30,1030),'Atlas técnico extraído da geografia do projeto. Não é uma captura do Roblox Studio.',font=font,fill='#9cb5bd')
canvas.save(ROOT/'build/WORLD_ATLAS.png')
print('Atlas saved; land coverage',round(float(np.mean(~ocean))*100,1),'%; horizon extent 3840 studs')
