--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Adaptations = require(Shared.Adaptations)
local Synergies = require(Shared.Synergies)
local HttpService = game:GetService("HttpService")
local PlayerService = {}
function PlayerService:Init(remotes, persistence, analytics)
	self.remotes = remotes; self.persistence = persistence; self.analytics = analytics
	self.records = {}; self.random = Random.new(); self.onBuildChanged = nil
end
function PlayerService:Get(player) return self.records[player] end
function PlayerService:Send(player)
	local r = self:Get(player); if not r then return end
	local p = r.profile
	local active = Progression.synergies(p.equipped, Adaptations, Synergies)
	for _, id in active do p.synergies[id] = true end
	if r.levelStat then r.levelStat.Value = p.level end
	self.remotes.State:FireClient(player, { profile = p, threshold = Progression.threshold(p.level), pending = r.pending, activeSynergies = active, persistence = r.mode, debug = r.debug })
end
function PlayerService:ReadyEvolution(player)
	local r = self:Get(player); if not r or r.pending then return end
	if r.profile.energy < Progression.threshold(r.profile.level) then return end
	local options = Progression.options(r.profile, Adaptations, self.random)
	if #options == 0 then return end
	r.pending = { token = HttpService:GenerateGUID(false), options = options }
	self.analytics:Once(player, r.profile, "FIRST_EVOLUTION_READY")
end
function PlayerService:Add(player, debugAllowed)
	local profile, mode = self.persistence:Load(player)
	if not player.Parent then if profile then self.persistence:Save(player, profile, true) end; return false end
	if not profile then player:Kick("Seu progresso ainda está aberto em outro servidor. Aguarde alguns segundos e tente novamente."); return false end
	local stats = Instance.new("Folder"); stats.Name = "leaderstats"; stats.Parent = player
	local level = Instance.new("IntValue"); level.Name = "Evolution"; level.Value = profile.level; level.Parent = stats
	self.records[player] = { profile = profile, mode = mode, levelStat = level, debug = debugAllowed, currentArea = nil }
	self.analytics:Once(player, profile, "FTUE_STARTED")
	self:ReadyEvolution(player)
	return true
end
function PlayerService:Energy(player, amount, source)
	local r = self:Get(player); if not r then return end
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then return end
	r.profile.energy = math.min(Config.MaxBankedEnergy, r.profile.energy + math.floor(amount))
	if source == "Essence" then self.analytics:Once(player, r.profile, "FIRST_ESSENCE") end
	self:ReadyEvolution(player); self:Send(player)
end
function PlayerService:Choose(player, token, id)
	local r = self:Get(player)
	if not r or not r.pending or type(token) ~= "string" or type(id) ~= "string" then return false end
	if r.pending.token ~= token or not table.find(r.pending.options, id) then return false end
	local definition = Adaptations[id]; local p = r.profile
	if not definition or p.energy < Progression.threshold(p.level) or definition.requirements.minLevel > p.level then return false end
	p.energy -= Progression.threshold(p.level); p.level += 1; p.discovered[id] = true; p.equipped[definition.slot] = id; r.pending = nil
	local newlyFound = {}
	for _, synergy in Progression.synergies(p.equipped, Adaptations, Synergies) do
		if not p.synergies[synergy] then table.insert(newlyFound, Synergies[synergy].displayName) end
		p.synergies[synergy] = true
	end
	self.analytics:Once(player, p, "FIRST_ADAPTATION_SELECTED")
	if self.onBuildChanged then self.onBuildChanged(player) end
	self.remotes.Feedback:FireClient(player, "Evolution", definition.displayName)
	for _, name in newlyFound do self.remotes.Feedback:FireClient(player, "Synergy", name) end
	self:ReadyEvolution(player); self:Send(player); return true
end
function PlayerService:Remove(player)
	local r = self:Get(player); if not r then return end
	self.persistence:Save(player, r.profile, true); self.records[player] = nil
end
return PlayerService
