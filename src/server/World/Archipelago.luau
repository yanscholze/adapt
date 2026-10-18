--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Definition = require(Shared.WorldDefinition)
local Samples = require(Shared.WorldSamples)
local Archipelago = {}
local function v(a) return Vector3.new(table.unpack(a)) end
local function folder(parent,name,model)
 local f=Instance.new(model and "Model" or "Folder");f.Name=name;f.Parent=parent;return f
end
local function part(parent,name,size,cf,color,material,collide,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.CanQuery=collide==true;p.CastShadow=collide==true
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;if shape then p.Shape=shape end;p.Parent=parent;return p
end
local function stone(parent,name,size,pos,color,collide)
 local p=part(parent,name,size,CFrame.new(pos)*CFrame.Angles(.12,.7,.15),color,Enum.Material.Rock,collide,Enum.PartType.Ball);return p
end
local function pole(parent,name,a,b,width,color,material,collide)
 return part(parent,name,Vector3.new((b-a).Magnitude,width,width),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,material,collide,Enum.PartType.Cylinder)
end
local function label(parent,name,position)
 local anchor=part(parent,"POIName",Vector3.one,CFrame.new(position),Color3.new(),nil,false);anchor.Transparency=1
 local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(220,38);gui.MaxDistance=90;gui.StudsOffset=Vector3.new(0,4,0);gui.Parent=anchor
 local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.FontFace=Font.fromEnum(Enum.Font.GothamMedium);text.TextSize=14;text.TextColor3=Color3.fromRGB(245,238,219);text.TextStrokeTransparency=.45;text.Text=name;text.Parent=gui
end
local function crystal(parent,pos,height,color,hidden)
 local p=part(parent,"Crystal",Vector3.new(height*.25,height,height*.3),CFrame.new(pos+Vector3.new(0,height/2,0))*CFrame.Angles(.1,.4,.16),color,Enum.Material.Neon,false)
 if hidden then p.Transparency=1;CollectionService:AddTag(p,"NightVisionRevealable") end
 return p
end
local function tree(parent,island,data)
 local m=folder(parent,"Tree",true);m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local origin=v(data.position);local s=data.scale;local tall=island.id=="Oldgrowth" and 1.55 or 1
 local wood=Color3.fromRGB(93,75,64);local leaf=Color3.fromRGB(table.unpack(island.palette));local height=17*s*tall
 if island.id=="Hollow" then
  crystal(m,origin,20*s,Color3.fromRGB(125+data.variant*20,122,198),false)
  crystal(m,origin+Vector3.new(5*s,0,2*s),9*s,Color3.fromRGB(92,171,186),false);return
 end
 pole(m,"Trunk",origin,origin+Vector3.new(1.7*s,height,0),2.5*s,wood,Enum.Material.Wood,true)
 if island.id=="Tideglass" then
  for i=1,4 do local a=i*math.pi/2+data.angle
   part(m,"PalmFrond",Vector3.new(3*s,1.2*s,14*s),CFrame.new(origin+Vector3.new(math.sin(a)*5*s,height,math.cos(a)*5*s))*CFrame.Angles(.2,a,.1),leaf,nil,false)
  end
 else
  part(m,"Canopy",Vector3.new(20,13,18)*s,CFrame.new(origin+Vector3.new(0,height,0))*CFrame.Angles(0,data.angle,0),leaf,nil,false,Enum.PartType.Ball)
  part(m,"CanopyLight",Vector3.new(13,11,14)*s,CFrame.new(origin+Vector3.new(5*s,height+5*s,-2*s)),leaf:Lerp(Color3.fromRGB(160,184,104),.18+data.variant*.07),nil,false,Enum.PartType.Ball)
 end
end
local function arch(parent,pos,width,height,color)
 for i=0,8 do
  local a=math.pi*i/8
  local point=pos+Vector3.new(math.cos(a)*width/2,math.sin(a)*height,0)
  part(parent,"ArchStone",Vector3.new(width*.22,height*.25,10),CFrame.new(point)*CFrame.Angles(0,0,a-math.pi/2),color,Enum.Material.Slate,true)
 end
end
local function climbStack(parent,pos,tiers,color,wood)
 for i=0,tiers-1 do
  local base=pos+Vector3.new(0,i*53,0)
  local wall=part(parent,"ClimbableBark",Vector3.new(14,52,3),CFrame.new(base+Vector3.new(0,26,0)),color,wood and Enum.Material.Wood or Enum.Material.Slate,true)
  CollectionService:AddTag(wall,"Climbable")
  part(parent,"RestingShelf",Vector3.new(24,3,18),CFrame.new(base+Vector3.new(0,52,4)),color,wood and Enum.Material.Wood or Enum.Material.Rock,true)
  local mark=part(parent,"GripMoss",Vector3.new(2,35,.1),CFrame.new(base+Vector3.new(0,28,-1.6)),Color3.fromRGB(213,193,108),Enum.Material.SmoothPlastic,false)
  mark.CastShadow=false
 end
end
local function waterfall(parent,pos,height,width)
 local p=part(parent,"FallingWater",Vector3.new(width,height,2),CFrame.new(pos-Vector3.new(0,height/2,0)),Color3.fromRGB(152,222,228),Enum.Material.Glass,false);p.Transparency=.28
 local foam=part(parent,"Foam",Vector3.new(width+8,1,11),CFrame.new(pos-Vector3.new(0,height,0)),Color3.fromRGB(216,244,235),Enum.Material.SmoothPlastic,false,Enum.PartType.Ball);foam.Transparency=.15
end
local function greatTree(parent,origin)
 local model=folder(parent,"TreeOfAges",true);model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local wood=Color3.fromRGB(87,78,67)
 pole(model,"AncientTrunk",origin,origin+Vector3.new(0,252,0),48,wood,Enum.Material.Wood,true)
 for i=1,7 do
  local a=i*math.pi*2/7;local radial=Vector3.new(math.cos(a),0,math.sin(a))
  pole(model,"ButtressRoot",origin+radial*90,origin+radial*9+Vector3.new(0,65,0),20,wood,Enum.Material.Wood,true)
  pole(model,"CrownBranch",origin+Vector3.new(0,185,0),origin+radial*86+Vector3.new(0,245+i%3*16,0),13,wood,Enum.Material.Wood,true)
  part(model,"HighCanopy",Vector3.new(118,60,105),CFrame.new(origin+radial*70+Vector3.new(0,260+i%3*17,0)),Color3.fromRGB(48+i*3,105+i*4,86),nil,false,Enum.PartType.Ball)
 end
 climbStack(model,origin+Vector3.new(0,0,-26),4,wood,true)
 return model
end
local function poi(parent,data)
 local m=folder(parent,data.id,true);m:SetAttribute("POI",true);m:SetAttribute("DisplayName",data.name);m:SetAttribute("Region",data.island)
 local pos=v(data.position);local dark=Color3.fromRGB(100,103,113);local kind=data.kind
 if kind=="Arch" then arch(m,pos,40,35,data.island=="Sunscar" and Color3.fromRGB(188,132,85) or dark)
 elseif kind=="GreatTree" then greatTree(m,pos)
 elseif kind=="Waterfall" then
  stone(m,"SourceOutcrop",Vector3.new(30,15,35),pos,dark,true);waterfall(m,pos+Vector3.new(17,6,0),math.max(45,math.min(pos.Y+18,125)),14)
 elseif kind=="Climb" then
  stone(m,"Pillar",Vector3.new(30,150,32),pos+Vector3.new(0,65,17),dark,true);climbStack(m,pos,3,dark,false)
 elseif kind=="Ruins" then
  for i=1,5 do local a=i*math.pi*2/5
   part(m,"WeatheredColumn",Vector3.new(5,10+i%3*5,5),CFrame.new(pos+Vector3.new(math.cos(a)*15,5,math.sin(a)*15))*CFrame.Angles(0,a,.08*i),Color3.fromRGB(149,155,132),Enum.Material.Limestone,true)
  end
 elseif kind=="Mystery" then
  m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for i=1,12 do local a=i*math.pi/6
   local p=part(m,"SuspendedMonolith",Vector3.new(5,20,7),CFrame.new(pos+Vector3.new(math.cos(a)*34,22+math.sin(a*2)*8,math.sin(a)*34))*CFrame.Angles(.15,a,.3),Color3.fromRGB(119,115,162),Enum.Material.Slate,true)
   crystal(m,p.CFrame.Position+Vector3.new(0,10,0),3,Color3.fromRGB(132,230,223),false)
  end
 elseif kind=="Crystals" then
  m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for i=1,7 do local a=i*math.pi*2/7;crystal(m,pos+Vector3.new(math.cos(a)*20,0,math.sin(a)*20),35+i%3*21,Color3.fromRGB(149,146,225),false) end
 elseif kind=="Secret" then
  for i=1,3 do crystal(m,pos+Vector3.new(i*3,0,2),7+i,Color3.fromRGB(151,226,200),true) end
 elseif kind=="Vents" then
  for i=1,5 do
   local vent=stone(m,"Vent",Vector3.new(10,6,10),pos+Vector3.new(i*9-27,1,i%2*17),Color3.fromRGB(59,54,60),true)
   local smoke=Instance.new("ParticleEmitter");smoke.Name="VolcanicHaze";smoke.Texture="rbxasset://textures/particles/smoke_main.dds";smoke.Rate=2;smoke.Lifetime=NumberRange.new(4,7);smoke.Speed=NumberRange.new(4,7);smoke.Color=ColorSequence.new(Color3.fromRGB(117,108,112));smoke.Size=NumberSequence.new(5);smoke.Transparency=NumberSequence.new(.65);smoke.Parent=vent;CollectionService:AddTag(smoke,"AmbientEmitter")
  end
 elseif kind=="Underwater" or kind=="Coral" then
  for i=1,6 do crystal(m,pos+Vector3.new(i*5-18,0,math.sin(i)*10),7+i%3*4,Color3.fromRGB(132+i*12,148,167+i*9),false) end
 elseif kind=="Cave" then
  -- The opening is real carved Terrain; these rocks frame it without closing it.
  stone(m,"MouthLeft",Vector3.new(9,19,13),pos+Vector3.new(-22,7,0),dark,false)
  stone(m,"MouthRight",Vector3.new(10,17,12),pos+Vector3.new(22,6,0),dark,false)
 elseif kind=="Vista" then
  stone(m,"ViewStone",Vector3.new(7,12,5),pos+Vector3.new(12,4,8),dark,true)
 elseif kind=="Salt" then
  part(m,"SaltPan",Vector3.new(55,.25,43),CFrame.new(pos+Vector3.new(0,.2,0)),Color3.fromRGB(225,210,185),Enum.Material.Salt,false)
 end
 if kind~="Secret" then label(m,data.name,pos+Vector3.new(0,5,0)) end
 return m
end
function Archipelago:Metadata(world)
 for _, p in Samples.pois do
  local position=v(p.position)+Vector3.new(0,2.3,0);local kind="Dew"
  if p.kind=="Secret" then kind="Lumen" end
  if p.kind=="Cave" then
   for _, c in Samples.caves do if c.id==p.id then local endPoint=v(c.points[#c.points]);position=endPoint-Vector3.new(0,c.radius-3,0);kind="Lumen" end end
  end
  table.insert(world.essenceSpawns,{id="poi_"..p.id,kind=kind,position=position})
 end
 for _, route in Samples.routes do
  for i=4,#route.points,5 do table.insert(world.essenceSpawns,{id=route.id.."_"..i,kind="Dew",position=v(route.points[i])+Vector3.new(0,2.4,0)}) end
 end
 for _, item in Samples.islets or {} do table.insert(world.essenceSpawns,{id=item.id,kind="Dew",position=v(item.position)+Vector3.new(0,2.3,0)}) end
 for _, f in Definition.floating do
  if f.id~="LumenPerch" then table.insert(world.essenceSpawns,{id="sky_"..f.id,kind="Dew",position=v(f.center)+Vector3.new(0,f.radius[2]+2.2,0)}) end
 end
end
function Archipelago:Build(world)
 local root=world.model
 local islands=folder(root,"Islands");local vegetation=folder(root,"Vegetation");local landmarks=folder(root,"Landmarks");local pois=folder(root,"POIs");local environment=folder(root,"Environment");local paths=folder(root,"SeaPaths");local reservations=folder(root,"FutureRoutes")
 for index,island in Definition.islands do
  local region=folder(islands,island.id,true);region:SetAttribute("DisplayName",island.name);region:SetAttribute("Region",island.area)
  local growth=folder(vegetation,island.id)
  for _, t in Samples.islands[index].trees do tree(growth,island,t) end
  for _, rock in Samples.islands[index].rocks do local p=stone(region,"CoastalBoulder",Vector3.new(1.7,1,1.4)*rock.scale,v(rock.position),Color3.fromRGB(105,110,115),false);p.CFrame*=CFrame.Angles(0,rock.angle,.2) end
 end
 for _, data in Samples.pois do poi(pois,data) end
 for _, cave in Samples.caves do
  if cave.approach then
   local a=v(cave.approach[1])-Vector3.new(0,12.5,0);local b=v(cave.approach[2])-Vector3.new(0,12.5,0)
   local ramp=part(pois:FindFirstChild(cave.id) or environment,"CaveEntryShelf",Vector3.new(15,1.4,(b-a).Magnitude+4),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(113,126,118),Enum.Material.Rock,true)
   ramp:SetAttribute("CaveExit",cave.id)
  end
 end
 for _, route in Samples.routes do
  local trail=folder(paths,route.id,true);trail:SetAttribute("WalkableConnection",true)
  for i=2,#route.points,5 do
   local pos=v(route.points[i]);stone(trail,"TideRock",Vector3.new(9,11,8),pos+Vector3.new(18,3,9),Color3.fromRGB(118,137,132),false)
   stone(trail,"TrailPebbles",Vector3.new(4,1,5),pos+Vector3.new(0,.5,0),Color3.fromRGB(215,205,168),false)
  end
 end
 for _, bridge in Samples.bridges or {} do
  local model=paths:FindFirstChild(bridge.id);local a=v(bridge.ends[1]);local b=v(bridge.ends[2])
  for i=0,6 do
   local t=i/6;local center=a:Lerp(b,t)+Vector3.new(0,math.sin(t*math.pi)*3-1.5,0)
   part(model,"NaturalBridgeDeck",Vector3.new(21,3,7.1),CFrame.lookAt(center,center+(b-a)),Color3.fromRGB(145,151,137),Enum.Material.Limestone,true)
  end
  for _, point in {a,b} do
   stone(model,"BridgeAbutment",Vector3.new(25,8,21),point-Vector3.new(0,4,0),Color3.fromRGB(112,132,127),false)
  end
 end
local outer=folder(islands,"OuterShoals",true)
 for i,item in Samples.islets or {} do
  local model=folder(outer,item.id,true);local pos=v(item.position)
  stone(model,"SeaStack",Vector3.new(9,14+i%4*4,8),pos+Vector3.new(8,4,8),Color3.fromRGB(111,135,139),false)
  crystal(model,pos+Vector3.new(-9,0,-5),5+i%3,Color3.fromRGB(149,201,185),false)
 end
 local sky=folder(islands,"SkyReach",true)
 for i,f in Definition.floating do
  local model=folder(sky,f.id,true);label(model,f.id,v(f.center)+Vector3.new(0,f.radius[2]+5,0))
  if f.id~="LumenPerch" then
   for j=1,3 do crystal(model,v(f.center)+Vector3.new(j*8-14,f.radius[2]-.6,0),6+j*2,Color3.fromRGB(145,192,217),false) end
   for j=1,3 do
    local dx=(j-2)*f.radius[1]*.25;local dz=(j%2)*f.radius[3]*.22
    local y=f.center[2]+f.radius[2]*math.sqrt(1-(dx/f.radius[1])^2-(dz/f.radius[3])^2)
    tree(model,{id="Sky",palette={151,174,198}},{position={f.center[1]+dx,y,f.center[3]+dz},scale=.7,angle=j,variant=j%3})
   end
   if i%2==0 then waterfall(model,v(f.center)+Vector3.new(f.radius[1]*.65,f.radius[2]*.7,0),f.radius[2]*3+20,7) end
  end
 end
 local volcano=folder(landmarks,"EmberCaldera",true);volcano.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local lava=part(volcano,"CalderaLava",Vector3.new(1,83,83),CFrame.new(1100,313,-1020)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(255,122,53),Enum.Material.Neon,false,Enum.PartType.Cylinder)
 lava:SetAttribute("FutureRequirement","HeatResistance")
 for i=1,9 do local a=i*math.pi*2/9;stone(volcano,"InnerBasaltSteps",Vector3.new(13,5,12),Vector3.new(1100+math.cos(a)*48,317+i%3*3,-1020+math.sin(a)*48),Color3.fromRGB(75,62,64),true) end
 -- A few distant silhouettes are persistent, while all dense decoration streams normally.
 for _, f in Definition.floating do
  if f.id=="ZenithCrown" or f.id=="StarNeedle" then
   local beacon=folder(landmarks,f.id.."Silhouette",true);beacon.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
   crystal(beacon,v(f.center)+Vector3.new(0,f.radius[2],0),28,Color3.fromRGB(167,198,225),false)
  end
 end
 for _, reservation in Definition.reservations do
  local marker=part(reservations,reservation.id,Vector3.one,CFrame.new(v(reservation.position)),Color3.new(),nil,false);marker.Transparency=1;marker:SetAttribute("FutureAdaptation",reservation.ability)
 end
 root:SetAttribute("POICount",#Samples.pois);root:SetAttribute("WorldWidth",Definition.extent*2)
 return environment
end
return Archipelago
