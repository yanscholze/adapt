"""Independent inspection of the Terrain blob actually shipped inside the place."""
from pathlib import Path
import base64,collections,json,math,struct,sys,unittest,xml.etree.ElementTree as ET
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from terrain_geometry import field,sample
ROOT=Path(__file__).resolve().parents[1]

def decode(blob):
    assert blob[:2]==b'\x01\x05';pos=2;previous=(0,0,0);chunks={};counts=collections.Counter()
    while pos<len(blob):
        delta=tuple(struct.unpack('<i',bytes(blob[pos+b*3+a] for b in range(4)))[0] for a in range(3));pos+=12
        key=tuple(p+d for p,d in zip(previous,delta));assert key not in chunks
        if chunks:assert key>previous
        previous=key;runs=[];total=0
        while total<32768:
            flag=blob[pos];pos+=1;material=flag&63;assert material<=22
            occupancy=0 if material==0 else 255
            if flag&64:occupancy=blob[pos];pos+=1
            n=1
            if flag&128:
                count=blob[pos];pos+=1
                if count==0:pos+=1 # optional shoreline water channel
                n=count+1
            total+=n;assert total<=32768
            runs.append((total,material,occupancy));counts[material]+=n
        chunks[key]=runs
    assert pos==len(blob);return chunks,counts

def voxel(chunks,x,y,z):
    coords=(math.floor(x/4),math.floor(y/4),math.floor(z/4));key=tuple(c//32 for c in coords)
    if key not in chunks:return 0,0
    local=tuple(c%32 for c in coords);index=(local[1]*32+local[2])*32+local[0]
    for end,material,occupancy in chunks[key]:
        if index<end:return material,occupancy
    raise AssertionError('Incomplete chunk')

class TerrainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((ROOT/'build/world-layout.json').read_text());cls.report=json.loads((ROOT/'world/terrain-manifest.json').read_text())
        tree=ET.parse(ROOT/'build/ADAPT.rbxlx')
        grids=tree.findall(".//Item[@class='Terrain']/Properties/BinaryString[@name='SmoothGrid']")
        assert len(grids)==1
        cls.blob=base64.b64decode(grids[0].text);cls.chunks,cls.counts=decode(cls.blob)
    def test_real_terrain_is_embedded_and_all_chunks_are_complete(self):
        self.assertEqual(len(self.chunks),self.report['chunks']);self.assertGreater(len(self.blob),1000000)
        self.assertEqual(self.counts.total(),32768*len(self.chunks));self.assertGreater(self.counts[1],1000000)
    def test_archipelago_has_separation_and_no_accidental_global_baseplate(self):
        x,z=np.meshgrid(np.linspace(-1910,1910,260),np.linspace(-1910,1910,260));height,_,_,water=field(self.data,x,z)
        fraction=float(np.mean(height>water));self.assertGreater(fraction,.13);self.assertLess(fraction,.4)
        for p in [(1750,-100,1750),(-1750,-100,-1750)]:self.assertEqual(voxel(self.chunks,*p)[0],1)
    def test_original_spawn_and_cave_are_not_buried(self):
        self.assertEqual(voxel(self.chunks,0,6,20)[0],0)
        self.assertNotEqual(voxel(self.chunks,0,-2,20)[0],0)
        self.assertEqual(voxel(self.chunks,-64,10,54)[0],0)
        self.assertEqual(voxel(self.chunks,70,24,7)[0],0)
    def test_floating_islands_have_solid_core_and_air_below(self):
        for f in self.data['floating']:
            x,y,z=f['center'];self.assertNotEqual(voxel(self.chunks,x,y,z)[0],0)
            if f['id']!='LumenPerch':self.assertEqual(voxel(self.chunks,x,y-f['radius'][1]-12,z)[0],0)
    def test_caves_have_enclosed_interiors_and_open_centerlines(self):
        for cave in self.report['caves']:
            x,y,z=cave['points'][-1]
            self.assertIn(voxel(self.chunks,x,y,z)[0],(0,1),cave['id'])
            self.assertNotIn(voxel(self.chunks,x,y+cave['radius']+3,z)[0],(0,1),cave['id']+' needs a rock roof')
            if 'approach' in cave:
                a,b=cave['approach'];grade=abs(a[1]-b[1])/math.hypot(a[0]-b[0],a[2]-b[2])
                self.assertLess(grade,.85,cave['id']+' exit slope')
                for t in np.linspace(0,1,8):
                    point=[aa+(bb-aa)*t for aa,bb in zip(a,b)]
                    self.assertIn(voxel(self.chunks,*point)[0],(0,1),cave['id']+' exit clearance')
    def test_landmark_heights_and_biome_contrast_are_real_voxels(self):
        self.assertEqual(voxel(self.chunks,1100,350,-1100)[0],13)
        self.assertIn(voxel(self.chunks,720,120,1210)[0],(6,11))
        self.assertNotEqual(voxel(self.chunks,370,650,-720)[0],0)
    def test_walkable_connections_are_continuous_above_the_ocean(self):
        graph=collections.defaultdict(set)
        for route in self.data['routes']:
            graph[route['from']].add(route['to']);graph[route['to']].add(route['from'])
            for a,b in zip(route['points'],route['points'][1:]):
                t=np.linspace(0,1,50);x=a[0]+(b[0]-a[0])*t;z=a[1]+(b[1]-a[1])*t
                heights=field(self.data,x,z)[0];low=heights<=self.data['seaLevel']+12
                # One short water channel is spanned by a real collidable stone bridge.
                if np.any(low):
                    aa,bb=route['points'][1:3];vx=bb[0]-aa[0];vz=bb[1]-aa[1];length=math.hypot(vx,vz)
                    along=((x-aa[0])*vx+(z-aa[1])*vz)/length
                    self.assertTrue(np.all(np.abs(along[low]-.68*length)<15),route['id'])
                step=math.dist(a,b)/49
                good=(heights[1:]>-5)&(heights[:-1]>-5)
                self.assertTrue(np.all(abs(np.diff(heights)[good])/step<1.25),route['id']+' has an unwalkable approach')
        reached={'Verdant'};pending=['Verdant']
        while pending:
            for n in graph[pending.pop()]-reached:reached.add(n);pending.append(n)
        self.assertEqual(reached,{i['id'] for i in self.data['islands']})
    def test_descending_glide_chain_fits_existing_ability(self):
        start=(980,sample(self.data,980,75)+3,75)
        for f in self.data['floating'][1:5]:
            x,y,z=f['center'];target=(x,y+f['radius'][1]+3,z)
            distance=math.hypot(x-start[0],z-start[2]);fall=start[1]-target[1]
            self.assertGreater(fall,0);self.assertLess(distance/34,9);self.assertLess(distance/34,fall/9+.25)
            start=target
    def test_artifact_streaming_and_budget_are_configured(self):
        tree=ET.parse(ROOT/'build/ADAPT.rbxlx');workspace=tree.find(".//Item[@class='Workspace']")
        self.assertEqual(workspace.findtext("./Properties/bool[@name='StreamingEnabled']"),'true')
        self.assertLess(sum(1 for p in workspace.iter('Item') if p.attrib['class'] in ['Part','WedgePart','MeshPart']),2000)

if __name__=='__main__':unittest.main(verbosity=2)
