--!nonstrict
-- Exports the shipped model, not an artist's approximation of it.
local H = require("./RobloxHarness")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local h=H.new("build/ADAPT.rbxlx"); local r=H.roblox
local profile=h.require(h.shared.ProfileSchema).defaults()
local p=r.Instance.new("Player"); p.Name="Blank"; p.DisplayName="Blank"; p.UserId=12; p.Parent=h.game:GetService("Players")
local characters=h.require(h.services.CharacterService)
characters:Init({Get=function() return {profile=profile} end, Send=function() end},h.remotes)
characters:Spawn(p); p.Character:PivotTo(r.CFrame.identity)
local art=h.require(h.shared.CreatureAppearance)
local motion=h.require(h.shared.CreatureMotion)
local gallery=r.Instance.new("Model"); gallery.Name="ADAPT_CharacterGallery"
local function vector(v) return {v.X,v.Y,v.Z} end
local function matrix(cf) return {cf:GetComponents()} end
local variants={
 {name="Blank",equipped={},state={speed=0}},
 {name="CrystalExplorer",equipped={Back="Wings",Arms="GripClaws",Tail="TideTail"},state={speed=0}},
 {name="Gliding",equipped={Back="Wings",Arms="GripClaws",Tail="TideTail",Head="NightEyes"},state={mode="Glide",air=true}},
 {name="Worldkeeper",equipped={Back="SkyWings",Arms="StoneHooks",Tail="TideTail",Head="EchoEyes",Body="EmberShell",Legs="SpringLegs"},state={speed=12},complete=true},
}
local result={variants={}}
for index,variant in variants do
 profile.equipped=variant.equipped; profile.journey.complete=variant.complete==true
 art.build(p.Character,profile)
 local model=p.Character:Clone(); model.Name=variant.name; model.Parent=gallery
 local poses=motion.sample(variant.state,1.8,1.2,false)
 local transforms={[model.HumanoidRootPart]=r.CFrame.identity}
 local joints={}; local offsets={}
 for _,item in model:GetDescendants() do
  if item:IsA("Motor6D") then table.insert(joints,item)
  elseif item:IsA("WeldConstraint") then offsets[item.Part1]={root=item.Part0,cf=item.Part0.CFrame:Inverse()*item.Part1.CFrame} end
 end
 for _=1,8 do
  for _,joint in joints do if transforms[joint.Part0] then transforms[joint.Part1]=transforms[joint.Part0]*joint.C0*(poses[joint.Name] or r.CFrame.identity)*joint.C1:Inverse() end end
  for child,bind in offsets do if transforms[bind.root] then transforms[child]=transforms[bind.root]*bind.cf end end
 end
 local parts={}
 for _,item in model:GetDescendants() do
  if item:IsA("BasePart") then
   if transforms[item] then item.CFrame=transforms[item] end
   item.Anchored=true
   if item.Transparency<1 then
    local mesh=item:FindFirstChildOfClass("SpecialMesh")
    table.insert(parts,{name=item.Name,kind=mesh and "sphere" or item.ClassName=="WedgePart" and "wedge" or "box",size=vector(item.Size),cf=matrix(item.CFrame),color={item.Color.R,item.Color.G,item.Color.B}})
   end
  end
 end
 table.insert(result.variants,{name=variant.name,parts=parts})
 model:PivotTo(r.CFrame.new((index-1)*12,4,0))
 -- Static inspection models only; do not accidentally run a second humanoid rig.
 model.Humanoid:Destroy()
end
fs.writeDir("assets/models")
fs.writeFile("assets/models/ADAPT-CharacterGallery.rbxmx",r.serializeModel({gallery},true))
fs.writeFile("build/character-preview.json",serde.encode("json",result))
print("Exported actual character geometry: 4 variants and editable Studio gallery")
