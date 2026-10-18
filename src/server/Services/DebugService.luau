--!nonstrict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Definitions = require(Shared.Adaptations)
local Areas = require(Shared.Areas)
local Debug = {}
function Debug:Allowed(player)
	return RunService:IsStudio() or table.find(Config.AdminUserIds, player.UserId) ~= nil
end
function Debug:Init(players, characters, ability, remotes)
	self.players = players; self.characters = characters; self.ability = ability; self.remotes = remotes
end
function Debug:Execute(player, command, argument: any)
	if not self:Allowed(player) or type(command) ~= "string" then return end
	local r = self.players:Get(player); if not r then return end
	if command == "energy" then
		if type(argument) == "number" and argument == argument and math.abs(argument) < math.huge then self.players:Energy(player, math.clamp(argument, 1, 500), "Debug") end
	elseif command == "grant" and type(argument) == "string" and Definitions[argument] then
		local definition = Definitions[argument]; r.profile.equipped[definition.slot] = argument; r.profile.discovered[argument] = true
		self.ability:Stop(player); self.characters:Apply(player); self.players:Send(player)
	elseif command == "reset" then
		r.profile.equipped = {}; r.pending = nil; r.profile.energy = 0; self.ability:Stop(player); self.characters:Apply(player); self.players:Send(player)
	elseif command == "teleport" and type(argument) == "string" and Areas[argument] then self.ability:Teleport(player, Vector3.new(table.unpack(Areas[argument].spawn)))
	elseif command == "state" then
		print("[ADAPT DEBUG]", player.UserId, HttpService:JSONEncode(r.profile)); self.remotes.Feedback:FireClient(player, "Info", "Estado impresso no Output do servidor.")
	end
end
return Debug
