#!/usr/bin/env python3
"""Bake original smooth voxel Terrain into a normal Roblox model file.
Format references: docs/WORLD_FOUNDATION.md; no Studio credentials or assets used.
"""
from pathlib import Path
import base64,hashlib,json,math,random,struct,sys,time
import numpy as np
from terrain_geometry import MATERIAL,field,sample,resolve_caves,chunk
ROOT=Path(__file__).resolve().parents[1]

def encode_runs(mat,occupancy):
    code=mat.ravel().astype(np.uint16)+(occupancy.ravel().astype(np.uint16)<<6)
    changes=np.flatnonzero(code[1:]!=code[:-1])+1
    starts=np.concatenate(([0],changes));ends=np.concatenate((changes,[32768]))
    out=bytearray()
    for start,end in zip(starts,ends):
        material=int(mat.ravel()[start]);occ=int(occupancy.ravel()[start]);count=int(end-start)
        # Air never stores occupancy. Non-air full voxels omit the occupancy byte.
        partial=material!=0 and occ!=255
        while count:
            n=min(256,count);flag=material|(64 if partial else 0)|(128 if n>1 else 0)
            out.append(flag)
            if partial:out.append(occ)
            if n>1:out.append(n-1)
            count-=n
    return out

def luau(value):
    if value is None:return 'nil'
    if value is True:return 'true'
    if value is False:return 'false'
    if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
    if isinstance(value,(int,float)):return str(round(value,3))
    if isinstance(value,list):return '{'+','.join(luau(v) for v in value)+'}'
    return '{'+','.join('['+luau(k)+']='+luau(v) for k,v in value.items())+'}'

def samples(data,caves):
    rng=random.Random(data['seed']);result={'islands':[],'caves':caves,'routes':[],'pois':[],'safeSpawns':{},'bridges':[],'islets':[]}
    for island in data['islands']:
        cx,cz=island['center'];rx,rz=island['radius'];trees=[];rocks=[]
        for _ in range(2200):
            if len(trees)>=island['trees']:break
            angle=rng.random()*math.tau;r=math.sqrt(rng.random())*.88
            x=cx+math.cos(angle)*rx*r;z=cz+math.sin(angle)*rz*r;y=sample(data,x,z)
            if y<4 or (island['id']=='Verdant' and -150<x<190 and -125<z<140):continue
            slope=max(abs(sample(data,x+5,z)-y),abs(sample(data,x,z+5)-y))
            if slope>4.5:continue
            if any((x-c['points'][0][0])**2+(z-c['points'][0][2])**2<1000 for c in caves):continue
            trees.append({'position':[round(x,2),round(y,2),round(z,2)],'scale':round(rng.uniform(.7,1.65),3),'angle':round(rng.random()*math.tau,3),'variant':rng.randrange(3)})
        for _ in range(16):
            a=rng.random()*math.tau;r=rng.uniform(.65,.98);x=cx+math.cos(a)*rx*r;z=cz+math.sin(a)*rz*r;y=sample(data,x,z)
            if y>data['seaLevel']+2:rocks.append({'position':[x,y,z],'scale':rng.uniform(3,8),'angle':rng.random()*math.tau})
        result['islands'].append({'id':island['id'],'trees':trees,'rocks':rocks,'centerHeight':sample(data,cx,cz)})
    for route in data['routes']:
        points=[]
        for a,b in zip(route['points'],route['points'][1:]):
            distance=math.dist(a,b);steps=math.ceil(distance/28)
            for i in range(steps):
                t=i/steps;x=a[0]+(b[0]-a[0])*t;z=a[1]+(b[1]-a[1])*t;points.append([x,sample(data,x,z),z])
        x,z=route['points'][-1];points.append([x,sample(data,x,z),z])
        result['routes'].append({'id':route['id'],'points':points})
    for poi in data['pois']:
        x,z=poi['position'];y=sample(data,x,z)
        if poi['kind']=='Cave':
            cave=next((c for c in caves if c['id']==poi['id']),None)
            if cave:y=cave['points'][0][1]-cave['radius']+3
        result['pois'].append({**poi,'position':[x,y,z]})
    for route in data['routes']:
        a,b=route['points'][1:3];vx=b[0]-a[0];vz=b[1]-a[1];length=math.hypot(vx,vz)
        t=.68;points=[]
        for offset in [-19,19]:
            x=a[0]+vx*(t+offset/length);z=a[1]+vz*(t+offset/length)
            points.append([x,sample(data,x,z)+.6,z])
        result['bridges'].append({'id':route['id'],'ends':points})
    for i,(x,z,rx,rz,peak) in enumerate(data.get('islets',[])):
        result['islets'].append({'id':'Shoal_'+str(i+1),'position':[x,sample(data,x,z),z],'radius':min(rx,rz)})
    for id,area in data.get('areas',{}).items():
        if id not in ['Wilds','Cliff','Cave','SkyIsland','SkyReach']:
            x,_,z=area['spawn'];result['safeSpawns'][id]=[x,sample(data,x,z)+5,z]
    return result

def main():
    data=json.loads((ROOT/'build/world-layout.json').read_text());caves=resolve_caves(data)
    out=bytearray([1,5]);previous=(0,0,0);count=0;nonempty=0;bounds=[1e9,-1e9]
    start=time.monotonic()
    # Sparse, deterministic chunk enumeration. Includes real water and seabed.
    for cx in range(-data['extent']//128,data['extent']//128):
        for cy in range(-2,6):
            for cz in range(-data['extent']//128,data['extent']//128):
                # Most high chunks contain only air: cheap conservative bounds reject them.
                if cy>=1:
                    near=any(abs(cx*128+64-p[0])<s[0]+100 and abs(cz*128+64-p[1])<s[1]+100 and cy*128<h+100 for island in data['islands'] for p,h,s in [(island['center'],max(q[2] for q in island['peaks']),island['radius'])])
                    near=near or any(abs(cx*128+64-f['center'][0])<f['radius'][0]+70 and abs(cz*128+64-f['center'][2])<f['radius'][2]+70 and abs(cy*128+64-f['center'][1])<f['radius'][1]+70 for f in data['floating'])
                    if not near:continue
                mat,occ=chunk(data,cx,cy,cz,caves)
                if not np.any(mat):continue
                # Studio stores coordinate deltas as big-endian i32 components,
                # then interleaves their bytes. Little-endian creates enormous
                # off-map coordinates and can hang Studio while loading.
                delta=tuple(n-p for n,p in zip((cx,cy,cz),previous));packed=[struct.pack('>i',v) for v in delta]
                out.extend(bytes(packed[axis][byte] for byte in range(4) for axis in range(3)))
                out.extend(encode_runs(mat,occ));previous=(cx,cy,cz);count+=1;nonempty+=int(np.count_nonzero(mat))
        if cx%5==0:print('Terrain column',cx,'chunks',count,flush=True)
    terrain=ROOT/'world/Terrain.rbxmx'
    terrain.write_text('<roblox version="4"><Item class="Terrain" referent="ADAPTTerrain"><Properties><bool name="Decoration">true</bool><string name="Name">Terrain</string><BinaryString name="SmoothGrid">'+base64.b64encode(out).decode()+'</BinaryString><Color3 name="WaterColor"><R>0.08</R><G>0.38</G><B>0.43</B></Color3><float name="WaterTransparency">0.3</float><float name="WaterReflectance">0.45</float><float name="WaterWaveSize">0.2</float><float name="WaterWaveSpeed">9</float></Properties></Item></roblox>')
    info=samples(data,caves)
    (ROOT/'src/shared/WorldSamples.luau').write_text('--!nonstrict\n-- Generated from WorldDefinition by scripts/build_terrain.py; do not hand-edit.\nreturn '+luau(info)+'\n')
    report={'version':data['version'],'seed':data['seed'],'chunks':count,'occupiedVoxels':nonempty,'smoothGridBytes':len(out),'smoothGridSha256':hashlib.sha256(out).hexdigest(),'worldWidth':data['extent']*2,'resolution':4,'trees':sum(len(i['trees']) for i in info['islands']),'caves':caves}
    (ROOT/'world/terrain-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Terrain baked:',count,'chunks,',nonempty,'occupied cells,',len(out),'bytes;',round(time.monotonic()-start,1),'seconds',flush=True)
if __name__=='__main__':main()
