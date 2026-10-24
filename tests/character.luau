--!nonstrict
local H=require("../scripts/RobloxHarness")
local h=H.new("build/ADAPT.rbxlx"); local r=H.roblox
local p=r.Instance.new("Player"); p.Name="ArtTester"; p.DisplayName="Blank"; p.UserId=12; p.Parent=h.game:GetService("Players")
h.game:GetService("Players").LocalPlayer=p
local profile=h.require(h.shared.ProfileSchema).defaults()
local characters=h.require(h.services.CharacterService)
characters:Init({Get=function() return {profile=profile} end,Send=function() end},h.remotes)
characters:Spawn(p)
local art=h.require(h.shared.CreatureAppearance); local motion=h.require(h.shared.CreatureMotion)
local definitions=h.require(h.shared.Adaptations)
local checks=0
local function check(name,fn) fn();checks+=1;print("PASS",name) end
check("base body has large head, articulated face, layered eyes and safe decoration",function()
 local appearance=p.Character.Appearance
 assert(appearance.BlankHead.Size.X>appearance.BlankBody.Size.X)
 assert(appearance.BlankHead.WeldConstraint.Part0==p.Character.Head)
 assert(appearance.BlankBody.WeldConstraint.Part0==p.Character.Torso)
 assert(appearance:FindFirstChild("EyeGlint") and appearance:FindFirstChild("Iris"))
 for _,part in appearance:GetDescendants() do
  if part:IsA("BasePart") then assert(part.Massless and not part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch) end
 end
 assert(p.Character.Torso.CanCollide and p.Character.Humanoid.WalkSpeed==20)
end)
check("all ten adaptations rebuild without granting progression or changing collision rig",function()
 local oldRoot=p.Character.HumanoidRootPart;local oldHead=p.Character.Head
 for id,def in definitions do
  profile.equipped={[def.slot]=id};art.build(p.Character,profile)
  assert(p.Character:GetAttribute("Slot"..def.slot)==id)
  assert(p.Character.Head==oldHead and p.Character.HumanoidRootPart==oldRoot)
  assert(profile.level==0 and not profile.discovered[id])
  for _,part in p.Character.Appearance:GetDescendants() do
   if part:IsA("BasePart") then
    for _,value in {part.CFrame:GetComponents()} do assert(value==value and math.abs(value)<100000) end
    assert(part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0)
   end
  end
 end
end)
check("complete body stays within decoration budget and references no uploaded meshes",function()
 profile.equipped={Head="NightEyes",Back="SkyWings",Arms="GripClaws",Body="EmberShell",Tail="TideTail",Legs="SpringLegs"};profile.journey.complete=true
 art.build(p.Character,profile)
 local parts,joints=0,0
 for _,item in p.Character.Appearance:GetDescendants() do
  if item:IsA("BasePart") then parts+=1;assert(item.Massless and not item.CanCollide and not item.CanQuery and not item.CanTouch)
  elseif item:IsA("Motor6D") then joints+=1; assert(item.Part0 and item.Part1)
  elseif item:IsA("SpecialMesh") then assert(item.MeshType==r.Enum.MeshType.Sphere) end
 end
 assert(parts<=400 and joints==4)
 print("Character budget:",parts,"decorative parts;",joints,"accessory joints")
end)
check("replacing an adaptation removes old geometry and stale slot attributes",function()
 profile.equipped={}; profile.journey.complete=false;art.build(p.Character,profile)
 assert(not p.Character.Appearance:FindFirstChild("Wing") and not p.Character.Appearance:FindFirstChild("TideTail"))
 assert(not p.Character:GetAttribute("SlotBack") and not p.Character:GetAttribute("SlotTail"))
 local count=0;for _,item in p.Character:GetChildren() do if item.Name=="Appearance" then count+=1 end end;assert(count==1)
end)
check("locomotion, flight, climb, swim, attack and landing produce distinct finite poses",function()
 local cases={{speed=0},{speed=20},{air=true,vertical=15},{air=true,vertical=-12},{mode="Glide"},{mode="Climb"},{swim=true},{attackAge=.16},{landAge=.12}}
 local signatures={}
 for _,state in cases do
  local pose,blink=motion.sample(state,1.8,1.2,false)
  assert(blink>=.05 and blink<=1)
  local values={}
  for _,name in {"RootJoint","Right Shoulder","Right Hip","WingLeft","TailTip"} do
   for _,n in {pose[name]:GetComponents()} do assert(n==n and math.abs(n)<3);table.insert(values,string.format("%.3f",n)) end
  end
  local signature=table.concat(values,",");assert(not signatures[signature]);signatures[signature]=true
 end
end)
check("idle blink reopens and reduced motion lowers secondary body motion",function()
 local _,closed=motion.sample({},.08,0,false);local _,open=motion.sample({},.3,0,false)
 assert(closed<.1 and open==1)
 local full=motion.sample({},.7,0,false);local reduced=motion.sample({},.7,0,true)
 assert(math.abs(reduced.RootJoint.Position.Y)<math.abs(full.RootJoint.Position.Y))
end)
check("runtime animation applies before physics, follows equipment rebuild and cleans up",function()
 profile.equipped={Back="Wings",Tail="TideTail"};art.build(p.Character,profile)
 local camera=r.Instance.new("Camera");camera.CFrame=r.CFrame.new(0,8,-15);camera.Parent=h.workspace;h.workspace.CurrentCamera=camera
 local animation=h.require(h.controllers.AnimationController).new()
 p.Character.HumanoidRootPart.AssemblyLinearVelocity=r.Vector3.new(0,0,20)
 h.overrides.RunService.PreSimulation:Fire(.1)
 local rig=animation.rigs[p.Character];assert(rig and rig.joints.WingLeft and rig.joints.TailTip)
 assert(rig.joints["Left Hip"].Transform~=r.CFrame.identity)
 animation:Attack();assert(rig.attacked==animation.time)
 local appearance=p.Character.Appearance;profile.equipped={};art.build(p.Character,profile)
 for _=1,5 do h.overrides.RunService.PreSimulation:Fire(.1) end
 rig=animation.rigs[p.Character];assert(rig.appearance~=appearance and not rig.joints.WingLeft)
 animation:Destroy();assert(next(animation.rigs)==nil)
 assert(p.Character.Torso["Left Hip"].Transform==r.CFrame.identity)
end)
print("CHARACTER:",checks,"checks passed; geometry/pose contracts only, Studio visual and physics review pending")
