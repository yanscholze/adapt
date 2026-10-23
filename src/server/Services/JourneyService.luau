--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Journey = require(Shared.Journey)
local Locations = require(Shared.JourneyLocations)
local Definitions = require(Shared.Adaptations)
local Progression = require(Shared.Progression)
local Sanctuaries = require(script.Parent.Parent.World.Sanctuaries)
local Service = {}
local function v(p) return Vector3.new(table.unpack(p)) end
function Service:Init(world, players, ability, characters, remotes)
	self.world = world; self.players = players; self.ability = ability; self.characters = characters; self.remotes = remotes
	self.lastRescue = {}; self.lastTravel = {}; self.lastDamage = {}; self.oxygen = {}; self.connections = {}; self.lastStep = nil
	local folder = Sanctuaries:Build(world)
	for _, object in folder:GetDescendants() do
		if object:IsA("ProximityPrompt") then
			local part = object.Parent
			local action = part:GetAttribute("Camp") and "camp" or part:GetAttribute("Shrine") and "seal" or "rune"
			local id = part:GetAttribute("Camp") or part:GetAttribute("Shrine") or part:GetAttribute("Memory")
			if id then table.insert(self.connections, object.Triggered:Connect(function(player) self:Interact(player, action, id) end)) end
		end
	end
	players.journey = self
	characters.spawnPosition = function(player)
		local r = players:Get(player)
		return r and v(Locations.camps[r.profile.journey.checkpoint] or Locations.camps.Wilds) or Vector3.new(0, 5, 20)
	end
	characters.onDeath = function(player)
		local r = players:Get(player); if not r then return end
		r.profile.journey.deaths += 1; self.oxygen[player] = nil
		remotes.Feedback:FireClient(player, "Info", "Você retorna ao último refúgio em 3 s. Suas descobertas estão preservadas.")
	end
end
function Service:Alive(player)
	local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local h = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health <= 0 or not self.players:Get(player) then return nil end
	return root, h
end
function Service:Near(player, point, radius)
	local root = self:Alive(player)
	return root ~= nil and self.ability:CanInteract(player) and (root.CFrame.Position - v(point)).Magnitude <= radius
end
function Service:Info(player, message) self.remotes.Feedback:FireClient(player, "Info", message) end
function Service:Grant(player, id)
	local r = self.players:Get(player); local d = Definitions[id]
	if not r or not d then return end
	r.profile.milestones["UNLOCK_" .. id] = true
	if r.profile.discovered[id] then return end
	r.profile.discovered[id] = true; r.profile.equipped[d.slot] = id
	if self.players.onBuildChanged then self.players.onBuildChanged(player) end
	self.remotes.Feedback:FireClient(player, "Evolution", d.displayName)
end
function Service:GuardianDefeated(player)
	local r = self.players:Get(player); if not r or r.profile.journey.guardian then return end
	r.profile.journey.guardian = true
	for _, id in { "Wings", "GripClaws", "NightEyes" } do self:Grant(player, id) end
	self:Info(player, "Os três caminhos se abriram. Encontre as memórias no penhasco, na caverna e na ilha inicial.")
	self.players:Send(player)
end
function Service:Interact(player, action, id)
	local r = self.players:Get(player); if not r or type(action) ~= "string" or type(id) ~= "string" then return false end
	local p = r.profile; local j = p.journey
	if action == "intro" then j.started = true; self.players:Send(player); return true end
	local point = action == "rune" and Locations.runes[id] and Locations.runes[id].position or Locations.camps[id]
	if not point or not self:Near(player, point, action == "rune" and 13 or 19) then return false end
	if action == "camp" then
		local first = not j.camps[id]; local changed = j.checkpoint ~= id or first
		j.camps[id] = true; j.checkpoint = id
		local _, h = self:Alive(player); h.Health = h.MaxHealth; self.oxygen[player] = 20
		if first then self:Info(player, "Refúgio descoberto. Você pode voltar pelo mapa e trocar suas adaptações aqui.")
		elseif changed then self:Info(player, "Novo ponto de retorno definido.") else self:Info(player, "Vida restaurada. Abra o diário para trocar seu corpo ou viajar.") end
		self.players:Send(player); return true
	end
	if not j.guardian then self:Info(player, "Primeiro, desperte seu corpo e vença o guardião de Verdant."); return false end
	local area = action == "rune" and Journey.runeRegion(id) or id
	local region = Journey.regions[area]; if not region then return false end
	if region.ability and not Progression.hasAbility(p.equipped, Definitions, region.ability) then
		self:Info(player, area == "Tideglass" and "Equipe a Cauda das Marés, recebida em Oldgrowth." or area == "EmberAtoll" and "Equipe a Carapaça de Brasa, recebida em Sunscar." or area == "Hollow" and "Equipe os olhos de visão noturna no refúgio." or "Equipe suas asas no refúgio."); return false
	end
	if action == "rune" then
		if j.runes[id] then self:Info(player, "Esta memória já faz parte do seu diário."); return false end
		j.runes[id] = true; self.players:Energy(player, 12, "Memory")
		self.remotes.Feedback:FireClient(player, "Memory", region.name); self.players:Send(player); return true
	elseif action == "seal" then
		if j.seals[id] then self:Info(player, "Esta semente já foi restaurada."); return false end
		if not Journey.ready(j, id) then self:Info(player, "Encontre as três memórias deste bioma. O diário mostra a direção."); return false end
		j.seals[id] = true; j.camps[id] = true; j.checkpoint = id
		if region.reward then self:Grant(player, region.reward) end
		if Journey.count(j.seals) >= 7 then self:Grant(player, "SkyWings") end
		self.players:Energy(player, 40, "Sanctuary"); self.remotes.Feedback:FireClient(player, "Chapter", region.name, region.lore); self.players:Send(player); return true
	end
	return false
end
function Service:AtCamp(player)
	for area, point in Locations.camps do if self:Near(player, point, 24) then return area end end
	return nil
end
function Service:Equip(player, id)
	local r = self.players:Get(player)
	if not r or type(id) ~= "string" or not Definitions[id] or not r.profile.discovered[id] or r.pending then return false end
	if not self:AtCamp(player) then self:Info(player, "Aproxime-se de um refúgio para mudar de corpo."); return false end
	r.profile.equipped[Definitions[id].slot] = id
	if self.players.onBuildChanged then self.players.onBuildChanged(player) end
	self.players:Send(player); return true
end
function Service:Travel(player, id)
	local r = self.players:Get(player); local root = self:Alive(player)
	if not r or not root or type(id) ~= "string" or not Locations.camps[id] then return false end
	local now = os.clock()
	if now - (self.lastTravel[player] or -100) < 3 then return false end
	if not r.profile.journey.camps[id] or not self:AtCamp(player) then self:Info(player, "Viaje a partir de um refúgio para outro já descoberto."); return false end
	self.lastTravel[player] = now; r.profile.journey.checkpoint = id
	self.ability:Teleport(player, v(Locations.camps[id])); self.players:Send(player); return true
end
function Service:Rescue(player)
	local r = self.players:Get(player); if not r or not self:Alive(player) then return false end
	local now = os.clock()
	if now - (self.lastRescue[player] or -100) < 30 then self:Info(player, "O resgate recarrega em até 30 segundos."); return false end
	self.lastRescue[player] = now
	self.ability:Teleport(player, v(Locations.camps[r.profile.journey.checkpoint] or Locations.camps.Wilds))
	self:Info(player, "Você voltou ao seu refúgio. Nenhum progresso foi perdido."); return true
end
function Service:Snapshot(player)
	local r = self.players:Get(player); if not r then return nil end
	local objective = Journey.objective(r.profile)
	if objective.target then objective.position = Locations.runes[objective.target].position
	elseif objective.region then objective.position = Locations.camps[objective.region] end
	return { objective = objective, seals = Journey.count(r.profile.journey.seals), total = 8 }
end
function Service:Complete(player)
	local r = self.players:Get(player)
	if not r or r.profile.journey.complete or Journey.count(r.profile.journey.seals) < 8 then return false end
	r.profile.journey.complete = true
	self.players:Energy(player, Journey.finale.reward, "Finale")
	if self.players.onBuildChanged then self.players.onBuildChanged(player) end
	self.remotes.Feedback:FireClient(player, "Complete", "GUARDIÃO DO ARQUIPÉLAGO"); self.players:Send(player); return true
end
function Service:Step(now)
	local dt = math.min(1, math.max(0, now - (self.lastStep or now))); self.lastStep = now
	for player, r in self.players.records do
		local root, h = self:Alive(player); if not root then continue end
		local char = player.Character; local pos = root.CFrame.Position
		local aquatic = Progression.hasAbility(r.profile.equipped, Definitions, "Aquatic") ~= nil
		local heat = Progression.hasAbility(r.profile.equipped, Definitions, "HeatResistance") ~= nil
		local leap = Progression.hasAbility(r.profile.equipped, Definitions, "Leap") ~= nil
		local swimming = h:GetState() == Enum.HumanoidStateType.Swimming
		if not h.PlatformStand then h.WalkSpeed = swimming and aquatic and 28 or leap and 24 or 20 end
		h.JumpPower = leap and 60 or 42
		local submerged = swimming and pos.Y < -24
		self.oxygen[player] = submerged and not aquatic and math.max(0, (self.oxygen[player] or 20) - (r.pending and 0 or dt)) or 20
		char:SetAttribute("Oxygen", self.oxygen[player] / 20); char:SetAttribute("Aquatic", aquatic)
		local hot = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(1100, 0, -1020)).Magnitude < 150 and pos.Y > 290
		char:SetAttribute("HeatDanger", hot and not heat)
		if not r.pending and (self.oxygen[player] == 0 or hot and not heat) and now - (self.lastDamage[player] or 0) >= 1 then
			self.lastDamage[player] = now; h:TakeDamage(8)
		end
		-- Gentle recovery outside both arenas; refuges restore immediately on interaction.
		local nearGuardian = (pos - self.world.guardianPosition).Magnitude < 45
		local nearFinale = (pos - v(Journey.finale.position)).Magnitude < 52
		if not nearGuardian and not nearFinale and not hot and not submerged then h.Health = math.min(h.MaxHealth, h.Health + dt * 3) end
		if pos.Y < -220 or math.abs(pos.X) > 2000 or math.abs(pos.Z) > 2000 then self:Rescue(player) end
	end
end
function Service:Remove(player)
	for _, t in { self.lastRescue, self.lastTravel, self.lastDamage, self.oxygen } do t[player] = nil end
end
return Service
