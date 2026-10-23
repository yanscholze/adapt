--!nonstrict
-- Run after rojo build: generates the EDIT-TIME world using the actual game modules.
local fs = require("@lune/fs")
local Harness = require("./RobloxHarness")
local h = Harness.new("build/ADAPT.rbxlx")
local world = h.require(h.services.WorldService); world:Init(true)
local players = { records = {} }
local essence = h.require(h.services.EssenceService); essence:Init(world, players, h.remotes, function() return true end)
local guardian = h.require(h.services.GuardianService)
guardian:Init(world, players, h.remotes, {}, function() return true end)
local sanctuaries = h.require(h.game:GetService("ServerScriptService").Server.World.Sanctuaries); sanctuaries:Build(world)
local finale = h.require(h.services.FinaleService); finale:Init(world, players, {}, h.remotes, function() return true end)
local camera = Harness.roblox.Instance.new("Camera"); camera.Name = "PreviewCamera"; camera.CFrame = Harness.roblox.CFrame.lookAt(Harness.roblox.Vector3.new(-1150, 1600, -2050), Harness.roblox.Vector3.new(50, 120, 80)); camera.Parent = h.workspace; h.workspace.CurrentCamera = camera
fs.writeFile("build/ADAPT.rbxlx", Harness.roblox.serializePlace(h.game, true))
local binary = Harness.roblox.serializePlace(h.game)
fs.writeFile("build/ADAPT.rbxl", binary)
fs.writeFile("build/ADAPT-1.0.rbxl", binary)
local count = 0; for _, item in world.model:GetDescendants() do if item:IsA("BasePart") then count += 1 end end
print("Baked edit-time world:", count, "parts;", #world.essenceSpawns, "Essence spawns; 8 biomes; Guardian. Both place formats written.")
