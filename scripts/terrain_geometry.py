"""Authored ADAPT geography, evaluated as smooth occupancy at 4-stud resolution."""
import numpy as np
def math_tau():return 6.283185307179586
MATERIAL = {'Air':0,'Water':1,'Grass':2,'Slate':3,'Sand':6,'Rock':8,'Sandstone':11,'Mud':12,'Basalt':13,'Ground':14,'CrackedLava':15,'LeafyGrass':19,'Limestone':21}


def field(data, x, z):
    shape=np.broadcast_shapes(np.shape(x),np.shape(z))
    top=np.full(shape,float(data['floor'])); surf=np.full(shape,6,dtype=np.uint8); rock=np.full(shape,8,dtype=np.uint8)
    water=np.full(shape,float(data['seaLevel']))
    for island in data['islands']:
        cx,cz=island['center'];rx,rz=island['radius'];dx=(x-cx)/rx;dz=(z-cz)/rz
        angle=np.arctan2(dz,dx)
        boundary=.045*np.sin(angle*5)+.025*np.sin(angle*9+.7)
        if island['id']=='Verdant':boundary+=.10*np.sin(angle*3+.5)
        if island['id']=='Crown':boundary+=.14*np.cos(angle*3)+.05*np.sin(angle*6)
        if island['id']=='Oldgrowth':boundary+=.13*np.sin(angle*2+.5)
        if island['id']=='Sunscar':boundary+=.09*np.cos(angle*4)
        if island['id']=='Hollow':boundary+=.14*np.cos(angle*5)
        rad=np.sqrt(dx*dx+dz*dz)*(1+boundary)
        core=np.clip(1-rad*rad,0,1)
        h=-35+(island['height']+35)*core**.62
        h += island['relief']*(np.sin((x+31)/57)*np.cos((z-11)/71)+.35*np.sin((x+z)/29))*core
        for px,pz,ph,sx,sz in island['peaks']:
            d=((x-px)/sx)**2+((z-pz)/sz)**2
            p=(ph-island['height'])*np.exp(-d*1.5)
            if island.get('mesas'):p=(ph-island['height'])*np.clip(1-((x-px)/sx)**4-((z-pz)/sz)**4,0,1)**.15
            h+=p*core**.15
        if island.get('volcano'):
            d=np.sqrt((x-1100)**2+(z+1020)**2)
            cone=-40+510*np.clip(1-d/310,0,1)**1.35
            h=np.maximum(h,cone)
            h=np.where(d<66,np.minimum(h,310+100*(d/66)**2),h)
        if island.get('canyon'):
            cleft=np.abs(.35*(x-1000)+(z-30))
            h=np.where((cleft<24)&(rad<.82),np.minimum(h,39+cleft*.25),h)
        if island.get('mesas'):
            ravine=np.abs(z-(1140+45*np.sin((x-530)/85)))
            h=np.where((ravine<22)&(rad<.82),np.minimum(h,8+ravine*.3),h)
        if island.get('lagoon'):
            lagoon=((x+650)/160)**2+((z-920)/145)**2
            h=np.where(lagoon<1,np.minimum(h,-62+22*lagoon),h)
            h=np.where((np.abs(x+650)<38)&(z>920),np.minimum(h,-42),h)
        # Curved, descending river in Verdant, clear of the original gameplay basin.
        if island['id']=='Verdant':
            river=np.abs(x-(-250+32*np.sin(z/65)))
            mask=(river<13)&(z>-190)&(z<190)&(rad<.94)
            level=np.minimum(h-2,18+.18*(180-z))
            water=np.where(mask,np.maximum(water,level),water)
            h=np.where(mask,level-7,h)
        valid=(rad<1.06)&(h>top)
        top=np.where(valid,h,top);surf=np.where(valid,MATERIAL[island['surface']],surf);rock=np.where(valid,MATERIAL[island['rock']],rock)
        surf=np.where(valid&(h<-5),MATERIAL['Basalt'] if island['id']=='Ember' else MATERIAL['Sand'],surf)
    for ix,iz,rx,rz,peak in data.get('islets',[]):
        radius=((x-ix)/rx)**2+((z-iz)/rz)**2
        h=-34+(peak+34)*np.clip(1-radius,0,1)**.6
        active=(radius<1)&(h>top);top=np.where(active,h,top);surf=np.where(active,6,surf);rock=np.where(active,21,rock)
    # Natural tidal ridges form a connected, walkable network through island chains.
    for route in data['routes']:
        for a,b in zip(route['points'],route['points'][1:]):
            ax,az=a;bx,bz=b;vx=bx-ax;vz=bz-az
            t=np.clip(((x-ax)*vx+(z-az)*vz)/(vx*vx+vz*vz),0,1)
            d=np.sqrt((x-ax-t*vx)**2+(z-az-t*vz)**2)
            width=route['width']*(1+.15*np.sin(t*9+ax)+1.15*np.exp(-((t-.38)/.18)**2))
            h=8+3*np.sin((ax+t*vx+az+t*vz)/80)+7*np.exp(-((t-.38)/.15)**2)-np.maximum(0,d-width*.50)*1.0
            valid=(d<width*2.6)&(h>top)
            top=np.where(valid,h,top);surf=np.where(valid,6,surf);rock=np.where(valid,21,rock)
    for route in data['routes']:
        a,b=route['points'][1:3];vx=b[0]-a[0];vz=b[1]-a[1];length=(vx*vx+vz*vz)**.5
        t=((x-a[0])*vx+(z-a[1])*vz)/(length*length)
        lateral=np.abs((x-a[0])*vz-(z-a[1])*vx)/length
        channel=(np.abs(t-.68)*length<11)&(lateral<route['width']*2.2)&(top<32)
        top=np.where(channel,np.minimum(top,-40),top)
    # A deliberately authored switchback trail winds to the Crown launch summit.
    angles=np.linspace(-1.0,math_tau()*1.65,44)
    trail=[]
    for i,a in enumerate(angles):
        t=i/(len(angles)-1);radius=185*(1-t)+8
        trail.append((980+np.cos(a)*radius,58+275*t,75+np.sin(a)*radius))
    for a,b in zip(trail,trail[1:]):
        vx=b[0]-a[0];vz=b[2]-a[2];t=np.clip(((x-a[0])*vx+(z-a[2])*vz)/(vx*vx+vz*vz),0,1)
        dist=np.sqrt((x-a[0]-t*vx)**2+(z-a[2]-t*vz)**2)
        desired=a[1]+(b[1]-a[1])*t
        blend=np.clip((18-dist)/8,0,1)
        top=top*(1-blend)+desired*blend
    # Join the canyon-floor refuge to the switchback. Without this cut, the
    # low Twin Gates basin is separated from the route by a steep cliff.
    crown_entry=[(1000,39,30),(1040,48,-15),(980+np.cos(-1)*185,58,75+np.sin(-1)*185)]
    for a,b in zip(crown_entry,crown_entry[1:]):
        vx=b[0]-a[0];vz=b[2]-a[2];t=np.clip(((x-a[0])*vx+(z-a[2])*vz)/(vx*vx+vz*vz),0,1)
        dist=np.sqrt((x-a[0]-t*vx)**2+(z-a[2]-t*vz)**2)
        desired=a[1]+(b[1]-a[1])*t
        blend=np.clip((20-dist)/8,0,1)
        top=top*(1-blend)+desired*blend
    # Oldgrowth's contained freshwater pool.
    pond=((x+1120)/48)**2+((z+650)/43)**2
    top=np.where(pond<1,np.minimum(top,31+5*pond),top)
    water=np.where(pond<1,np.maximum(water,37),water)
    # Preserve all original mechanics at their exact coordinates inside a meadow.
    legacy=(x>-116)&(x<146)&(z>-92)&(z<104)
    edge=np.minimum(np.minimum(x+140,170-x),np.minimum(z+116,128-z))
    blend=np.clip(edge/24,0,1)
    near=(x>-140)&(x<170)&(z>-116)&(z<128)
    top=np.where(near,top*(1-blend),top)
    top=np.where(legacy,0,top);surf=np.where(near,2,surf)
    # Existing cliff, cave and ramp are clothed in natural terrain while their
    # exact collision/interaction surfaces remain in the gameplay core.
    cliff=((x-70)/30)**4+((z-38)/34)**4
    cliff_h=44*np.clip(1-cliff,0,1)**.16
    front=(x>62)&(x<78)&(z<14)
    top=np.maximum(top,np.where((cliff<1)&~front,cliff_h,-1e6))
    mound=((x+64)/36)**2+((z-55)/38)**2
    cave_h=36*np.clip(1-mound,0,1)**.35
    top=np.maximum(top,np.where((z>31)&(mound<1),cave_h,-1e6))
    ramp_t=np.clip((x+63)/91,0,1)
    ramp_h=1+ramp_t*62-2-np.maximum(0,np.abs(z+65)-5)*1.4
    top=np.maximum(top,np.where((x>-66)&(x<40)&(np.abs(z+65)<30),ramp_h,-1e6))
    return top,surf,rock,water


def sample(data,x,z):
    return float(field(data,np.asarray(float(x)),np.asarray(float(z)))[0])


def polyline_distance(x,y,z,points):
    result=np.full(np.broadcast_shapes(np.shape(x),np.shape(y),np.shape(z)),1e8)
    for a,b in zip(points,points[1:]):
        ax,ay,az=a;vx=b[0]-ax;vy=b[1]-ay;vz=b[2]-az
        t=np.clip(((x-ax)*vx+(y-ay)*vy+(z-az)*vz)/(vx*vx+vy*vy+vz*vz),0,1)
        result=np.minimum(result,np.sqrt((x-ax-t*vx)**2+(y-ay-t*vy)**2+(z-az-t*vz)**2))
    return result


def resolve_caves(data):
    result=[]
    for cave in data['caves']:
        item={**cave,'points':[p[:] for p in cave['points']]}
        # Entrance intersects the hillside; remaining segments descend gently into it.
        if cave['id']!='CoralGate':
            entrance=sample(data,*[item['points'][0][i] for i in (0,2)])-4
            item['points'][0][1]=entrance
            for a,b in zip(item['points'],item['points'][1:]):
                horizontal=((b[0]-a[0])**2+(b[2]-a[2])**2)**.5
                b[1]=max(b[1],a[1]-horizontal*.45)
        if cave['id']!='CoralGate':
            a,b=item['points'][:2];vx=b[0]-a[0];vz=b[2]-a[2];length=(vx*vx+vz*vz)**.5
            best=None
            for distance in [cave['radius']+38,cave['radius']+65,cave['radius']+100,cave['radius']+180]:
                for angle in [0,.5,-.5,1,-1,1.57,-1.57,2,-2]:
                    dx=-vx/length;dz=-vz/length
                    ox=a[0]+(dx*np.cos(angle)-dz*np.sin(angle))*distance
                    oz=a[2]+(dx*np.sin(angle)+dz*np.cos(angle))*distance
                    surface=sample(data,ox,oz);end=a[1]-cave['radius']+2
                    grade=abs(surface-end)/distance
                    score=grade+.025*abs(angle)+.002*(distance-cave['radius']-38)
                    if grade<.75 and (best is None or score<best[0]):best=(score,ox,oz,surface)
            if best is None:raise ValueError('No safe cave approach: '+cave['id'])
            _,ox,oz,surface=best
            item['approach']=[[ox,surface+12,oz],[a[0],a[1]-cave['radius']+14,a[2]]]
        result.append(item)
    return result


def chunk(data,cx,cy,cz,caves):
    # Scan order is Y, then Z, then X. X is the contiguous dimension.
    x=(cx*32+np.arange(32)[None,None,:])*4+2
    z=(cz*32+np.arange(32)[None,:,None])*4+2
    y=(cy*32+np.arange(32)[:,None,None])*4+2
    height,surface,rock,water=field(data,x,z)
    density=np.broadcast_to((height-y)/4+.5,(32,32,32)).copy()
    mat=np.broadcast_to(np.where(y>height-9,surface,rock),(32,32,32)).copy()
    # Only the shallow seabed needs solid cells; everything below is outside exploration.
    density=np.where(y<data['floor']-8,0,density)
    for f in data['floating']:
        px,py,pz=f['center'];rx,ry,rz=f['radius']
        if abs(cx*128+64-px)>rx+70 or abs(cz*128+64-pz)>rz+70 or abs(cy*128+64-py)>ry+70:continue
        d=np.sqrt(((x-px)/rx)**2+((y-py)/ry)**2+((z-pz)/rz)**2)
        fill=(1-d)*min(rx,ry,rz)/4+.5
        active=fill>density;density=np.maximum(density,fill)
        mat=np.where(active,np.where(y>py+ry*.35,MATERIAL[f['surface']],3),mat)
    for c in caves:
        points=c['points'];bounds=np.asarray(points+c.get('approach',[]))
        if cx*128>bounds[:,0].max()+c['radius'] or (cx+1)*128<bounds[:,0].min()-c['radius'] or cz*128>bounds[:,2].max()+c['radius'] or (cz+1)*128<bounds[:,2].min()-c['radius']:continue
        d=polyline_distance(x,y,z,points)
        density=np.minimum(density,(d-c['radius'])/4+.5)
        if c.get('approach'):
            entry=polyline_distance(x,y,z,c['approach']);density=np.minimum(density,(entry-12)/4+.5)
    # Preserve the original Night Eyes chamber and its entrance at exact coordinates.
    starter_room=(x>-84)&(x<-44)&(z>28)&(z<73)&(y>0)&(y<21)
    density=np.where(starter_room,0,density)
    occupancy=np.rint(np.clip(density,0,1)*255).astype(np.uint8)
    mat=np.where(occupancy>0,mat,0).astype(np.uint8)
    wet=(occupancy==0)&(y<water)
    mat=np.where(wet,1,mat).astype(np.uint8);occupancy=np.where(wet,255,occupancy).astype(np.uint8)
    return mat,occupancy
