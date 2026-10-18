--!nonstrict
local H=require("../scripts/RobloxHarness")
local h=H.new("build/ADAPT.rbxlx")
local World=h.require(h.services.WorldService)
World:Init(true)
local checks=0
local function check(name,callback) callback();checks+=1;print("PASS",name) end
local Definition=h.require(h.shared.WorldDefinition)
local Samples=h.require(h.shared.WorldSamples)
check("eight biomes, authored floating islands and POIs are actually instantiated",function()
 assert(#Definition.islands==7 and #Definition.floating==8 and #Samples.pois==42)
 assert(World.model.Islands.SkyReach and #World.model.POIs:GetChildren()==42)
 for _, island in Definition.islands do assert(World.model.Islands:FindFirstChild(island.id)) end
 assert(World.model.POIs.AncientHeart.TreeOfAges)
 assert(World.model.Landmarks.EmberCaldera.CalderaLava)
end)
check("runtime reuses the baked world without destroying scenery",function()
 local model=World.model;local tree=model.POIs.AncientHeart.TreeOfAges;local count=#World.essenceSpawns
 World:Init();assert(World.model==model and tree.Parent and #World.essenceSpawns==count)
end)
check("spawn basin and former adaptation routes retain their coordinates",function()
 assert((World.model.Core.ClimbFace.CFrame.Position-H.roblox.Vector3.new(70,22,9.7)).Magnitude<.001)
 assert((World.model.Core.LaunchDeck.CFrame.Position-H.roblox.Vector3.new(31,62.5,-65)).Magnitude<.001)
 assert(World.essenceSpawns[1].id=="dew_1" and World.essenceSpawns[19].kind=="Lumen")
 assert(World.guardianPosition==H.roblox.Vector3.new(20,4.5,70))
end)
check("streaming never makes the whole archipelago atomic or persistent",function()
 local count,persistent=0,0
 for _, instance in World.model:GetDescendants() do
  if instance:IsA("BasePart") then
   count+=1;local parent=instance.Parent
   while parent and parent~=World.model do
    if parent:IsA("Model") and parent.ModelStreamingMode==H.roblox.Enum.ModelStreamingMode.Persistent then persistent+=1;break end
    parent=parent.Parent
   end
  end
 end
 assert(count<2000 and persistent<110)
 assert(World.model.Core.ModelStreamingMode==H.roblox.Enum.ModelStreamingMode.Atomic)
 print("World budget:",count,"scenery parts;",persistent,"persistent landmark parts")
end)
check("Essence and Guardian initialize once when starting from a baked place",function()
 local Essence=h.require(h.services.EssenceService);local players={records={}}
 Essence:Init(World,players,h.remotes,function() return true end)
 Essence:Init(World,players,h.remotes,function() return true end)
 local count=0;for _, object in World.model:GetChildren() do if object.Name=="Essence" then count+=1 end end
 assert(count==1 and #World.model.Essence:GetChildren()==#World.essenceSpawns)
 local Guardian=h.require(h.services.GuardianService)
 Guardian:Init(World,players,h.remotes,{},function() return true end);Guardian:Init(World,players,h.remotes,{},function() return true end)
 count=0;for _, object in World.model:GetChildren() do if object.Name=="Guardian" then count+=1 end end;assert(count==1)
end)
check("all geographic adaptation reservations and sea connections exist",function()
 assert(#World.model.FutureRoutes:GetChildren()==3 and #World.model.SeaPaths:GetChildren()==8)
 local tags=h.overrides.CollectionService:GetTagged("Climbable");assert(#tags>=8)
 for _, part in tags do assert(part.Size.Y<=55 and part.Size.Y>part.Size.X) end
end)
print("WORLD:",checks,"checks passed (built objects and contracts; no motor simulation)")
