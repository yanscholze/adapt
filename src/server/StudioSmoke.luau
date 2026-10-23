--!nonstrict
-- Optional read-only inspection. In Play, select Server in Command Bar:
-- require(game.ServerScriptService.Server.StudioSmoke).run()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.Shared.Config)
local Smoke = {}
function Smoke.run()
	assert(RunService:IsStudio() and RunService:IsRunning(), "Run this in Studio Play, on the server")
	local world = assert(workspace:FindFirstChild("ADAPTWorld"), "Missing generated world")
	assert(world:GetAttribute("Generated"), "World generator did not finish")
	assert(world:FindFirstChild("Essence") and #world.Essence:GetChildren() >= 21, "Essence spawner did not initialize")
	assert(world:FindFirstChild("Guardian") and world.Guardian:GetAttribute("MaxHealth") == Config.Guardian.MaxHealth)
	assert(world:FindFirstChild("Journey") and world:FindFirstChild("ZenithGuardian"), "Campaign objects missing")
	assert(#CollectionService:GetTagged("JourneyObject") == 40, "Expected 8 refuges, 8 shrines and 24 memories")
	for _, name in Config.Remotes do assert(ReplicatedStorage.Remotes:FindFirstChild(name), "Missing remote " .. name) end
	assert(CollectionService:HasTag(world.Core.ClimbFace, "Climbable"))
	assert(not world.Core.GripMark.CanQuery)
	assert(#CollectionService:GetTagged("NightVisionRevealable") >= 8)
	local services = script.Parent.Services
	local state = require(services.PlayerService)
	assert(#Players:GetPlayers() > 0, "Use Play/F5, not Run/F8")
	for _, player in Players:GetPlayers() do
		assert(state:Get(player), "Profile did not load for " .. player.Name)
		local char = assert(player.Character, "No Blank for " .. player.Name)
		assert(char:FindFirstChild("Appearance") and char:FindFirstChild("HumanoidRootPart"))
		assert(char:FindFirstChildOfClass("Humanoid").Health > 0)
		assert(player.leaderstats.Evolution.Value == state:Get(player).profile.level)
		assert(state:Get(player).profile.version == 2 and state:Get(player).profile.journey.camps.Wilds)
	end
	print("[ADAPT SMOKE] Initial server invariants passed. Continue the movement, UI and multiplayer playtest.")
	return true
end
return Smoke
