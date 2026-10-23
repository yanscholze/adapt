--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Areas = require(Shared.Areas)
local RateLimiter = require(Shared.RateLimiter)
local Services = script.Services
local World = require(Services.WorldService)
local Persistence = require(Services.PersistenceService)
local Analytics = require(Services.AnalyticsService)
local PlayerService = require(Services.PlayerService)
local Characters = require(Services.CharacterService)
local Ability = require(Services.AbilityService)
local Essence = require(Services.EssenceService)
local Guardian = require(Services.GuardianService)
local Debug = require(Services.DebugService)
local Journey = require(Services.JourneyService)
local Finale = require(Services.FinaleService)

Players.CharacterAutoLoads = false
local folder = Instance.new("Folder"); folder.Name = "Remotes"; folder.Parent = ReplicatedStorage
local remotes = {}
for _, name in Config.Remotes do local remote = Instance.new("RemoteEvent"); remote.Name = name; remote.Parent = folder; remotes[name] = remote end
local limiter = RateLimiter.new()
local function allowed(player, name, rate, burst)
	return limiter:allow(tostring(player.UserId) .. ":" .. name, os.clock(), rate, burst)
end
World:Init(); Persistence:Init(); Analytics:Init(); PlayerService:Init(remotes, Persistence, Analytics)
Characters:Init(PlayerService, remotes); Ability:Init(PlayerService, Analytics)
local function canInteract(player) return Ability:CanInteract(player) end
Essence:Init(World, PlayerService, remotes, canInteract)
Guardian:Init(World, PlayerService, remotes, Analytics, canInteract)
Journey:Init(World, PlayerService, Ability, Characters, remotes)
Finale:Init(World, PlayerService, Journey, remotes, canInteract)
Guardian.onDefeated = function(player) Journey:GuardianDefeated(player) end
Debug:Init(PlayerService, Characters, Ability, remotes)
PlayerService.onBuildChanged = function(player) Ability:Stop(player); Characters:Apply(player) end

remotes.RequestState.OnServerEvent:Connect(function(player)
	if allowed(player, "state", 1, 3) then PlayerService:Send(player) end
end)
remotes.Choose.OnServerEvent:Connect(function(player, token, id)
	if allowed(player, "choose", 2, 4) then
		if not PlayerService:Choose(player, token, id) then PlayerService:Send(player) end
	end
end)
remotes.Ability.OnServerEvent:Connect(function(player, mode, direction)
	if allowed(player, "ability", 15, 20) and PlayerService:Get(player) then Ability:Input(player, mode, direction) end
end)
remotes.Attack.OnServerEvent:Connect(function(player)
	if allowed(player, "attack", 3, 4) then if not Finale:Attack(player) then Guardian:Attack(player) end end
end)
remotes.Journey.OnServerEvent:Connect(function(player, action, id)
	if not allowed(player, "journey", 2, 3) then return end
	if action == "rescue" then Journey:Rescue(player) else Journey:Interact(player, action, id) end
end)
remotes.Equip.OnServerEvent:Connect(function(player, id)
	if allowed(player, "equip", 2, 3) then Journey:Equip(player, id) end
end)
remotes.Travel.OnServerEvent:Connect(function(player, id)
	if allowed(player, "travel", 1, 2) then Journey:Travel(player, id) end
end)
remotes.Codex.OnServerEvent:Connect(function(player)
	local r = PlayerService:Get(player)
	if r and allowed(player, "codex", 0.5, 2) then Analytics:Once(player, r.profile, "CODEX_OPENED") end
end)
remotes.Setting.OnServerEvent:Connect(function(player, key, value)
	local r = PlayerService:Get(player)
	if not r or not allowed(player, "setting", 2, 3) or type(key) ~= "string" or type(value) ~= "boolean" then return end
	if r.profile.settings[key] ~= nil then r.profile.settings[key] = value; PlayerService:Send(player) end
end)
remotes.Debug.OnServerEvent:Connect(function(player, command, argument)
	if allowed(player, "debug", 2, 4) then Debug:Execute(player, command, argument) end
end)

local joining = {}; local closing = false
local function join(player)
	if joining[player] or PlayerService:Get(player) or closing then return end
	joining[player] = true
	if PlayerService:Add(player, Debug:Allowed(player)) then Characters:Spawn(player) end
	joining[player] = nil
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player)
	Ability:Remove(player); Guardian:Remove(player); Characters:Remove(player)
	Journey:Remove(player); Finale:Remove(player)
	limiter:removePrefix(tostring(player.UserId) .. ":")
	PlayerService:Remove(player)
end)
for _, player in Players:GetPlayers() do task.spawn(join, player) end

local accumulated = 0
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	Ability:Step(math.min(dt, 0.1), now)
	accumulated += dt
	if accumulated < 0.15 then return end
	accumulated = 0
	Essence:Step(now); Guardian:Step(now); Journey:Step(now); Finale:Step(now)
	for player, r in PlayerService.records do
		local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		local area = World:AreaAt(root.CFrame.Position)
		if area and area ~= r.currentArea then
			r.currentArea = area
			if not r.profile.areas[area] then
				r.profile.areas[area] = true
				if area ~= "Wilds" then Analytics:Once(player, r.profile, "FIRST_NEW_AREA") end
			end
			remotes.Feedback:FireClient(player, "Area", Areas[area].displayName, Areas[area].hint); PlayerService:Send(player)
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(Config.AutosaveSeconds)
		for player, r in PlayerService.records do
			if closing then break end
			task.spawn(function()
				local ok = Persistence:Save(player, r.profile, false)
				if not ok and r.mode == "Cloud" and player.Parent then remotes.Feedback:FireClient(player, "Info", "Salvamento indisponível. Tentaremos novamente automaticamente.") end
			end)
		end
	end
end)
game:BindToClose(function()
	closing = true
	local remaining = 0
	for player, r in PlayerService.records do
		remaining += 1
		task.spawn(function() Persistence:Save(player, r.profile, true); remaining -= 1 end)
	end
	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do task.wait(0.1) end
end)
print("[ADAPT] Server ready • campaign 1.0 • authoritative progression")
