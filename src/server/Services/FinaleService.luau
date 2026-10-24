--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Journey = require(Shared.Journey)
local Definitions = require(Shared.Adaptations)
local Progression = require(Shared.Progression)
local Finale = {}
local function part(parent, name, size, pos, color, shape)
	local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Size = size; p.CFrame = CFrame.new(pos); p.Color = color; p.Material = Enum.Material.Neon; p.Shape = shape or Enum.PartType.Ball; p.Parent = parent; return p
end
function Finale:Init(world, players, journey, remotes, canInteract)
	self.players = players; self.journey = journey; self.remotes = remotes; self.canInteract = canInteract
	self.center = Vector3.new(table.unpack(Journey.finale.position)); self.lastAttack = {}; self.contributors = {}; self.hp = Journey.finale.maxHealth; self.active = false; self.sequence = 0; self.nextAttack = 0
	local old = world.model:FindFirstChild("ZenithGuardian"); if old then old:Destroy() end
	self.model = Instance.new("Model"); self.model.Name = "ZenithGuardian"; self.model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic; self.model.Parent = world.model
	self.core = part(self.model, "Heart", Vector3.new(6, 8, 6), self.center, Color3.fromRGB(202, 182, 255))
	for i = 1, 6 do
		local a = i * math.pi/3
		local blade = part(self.model, "CrownPetal", Vector3.new(2, 8, 3), self.center + Vector3.new(math.cos(a)*5, 4, math.sin(a)*5), Color3.fromRGB(125, 147, 191), Enum.PartType.Block)
		blade.CFrame *= CFrame.Angles(0, -a, .3)
	end
	self.prompt = Instance.new("ProximityPrompt"); self.prompt.ActionText = "Despertar"; self.prompt.ObjectText = "Guardião do Zênite • 8 sementes"; self.prompt.KeyboardKeyCode = Enum.KeyCode.R; self.prompt.GamepadKeyCode = Enum.KeyCode.ButtonB; self.prompt.HoldDuration = 1; self.prompt.MaxActivationDistance = 18; self.prompt.RequiresLineOfSight = false; self.prompt.Parent = self.core
	self.prompt.Triggered:Connect(function(player) self:Start(player) end)
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(310, 70); gui.StudsOffset = Vector3.new(0, 11, 0); gui.MaxDistance = 100; gui.Parent = self.core
	self.label = Instance.new("TextLabel"); self.label.Size = UDim2.fromScale(1, 1); self.label.TextWrapped = true; self.label.FontFace = Font.fromEnum(Enum.Font.GothamBold); self.label.TextSize = 17; self.label.BackgroundColor3 = Color3.fromRGB(24, 30, 50); self.label.TextColor3 = Color3.fromRGB(237, 229, 255); self.label.Parent = gui
	self.warning = Instance.new("Folder"); self.warning.Name = "Telegraphs"; self.warning.Parent = self.model
	self:Update("OITO SEMENTES • UM MUNDO")
end
function Finale:Eligible(player, range)
	local r = self.players:Get(player); local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local h = char and char:FindFirstChildOfClass("Humanoid")
	if not r or Journey.count(r.profile.journey.seals) < 8 or not root or not h or h.Health <= 0 or not self.canInteract(player) then return nil end
	if (root.CFrame.Position - self.center).Magnitude > range then return nil end
	return h, root
end
function Finale:Update(message)
	self.model:SetAttribute("Health", self.hp); self.model:SetAttribute("MaxHealth", Journey.finale.maxHealth); self.model:SetAttribute("Active", self.active)
	self.label.Text = string.format("GUARDIÃO DO ZÊNITE • %d / %d\n%s", self.hp, Journey.finale.maxHealth, message or "")
end
function Finale:Start(player)
	if self.active or self.respawnAt or not self:Eligible(player, 20) then
		if not self.active then self.remotes.Feedback:FireClient(player, "Info", "Restaure as oito sementes para despertar o guardião.") end
		return false
	end
	self.active = true; self.hp = Journey.finale.maxHealth; self.contributors = {}; self.sequence = 0; self.nextAttack = os.clock() + 2; self.lastTarget = os.clock(); self.prompt.Enabled = false
	self:Update("Observe a luz no chão. Ataque entre os pulsos."); return true
end
function Finale:Attack(player)
	if not self.active or self.hp <= 0 or not self:Eligible(player, 16) then return false end
	if self.players:Get(player).pending then return false end
	local now = os.clock(); if now - (self.lastAttack[player] or -10) < .55 then return false end
	local char = player.Character; local root = char.HumanoidRootPart
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { char, self.model }
	if workspace:Raycast(root.CFrame.Position, self.center - root.CFrame.Position, params) then return false end
	self.lastAttack[player] = now; self.contributors[player] = true; self.hp = math.max(0, self.hp - 16)
	player.Character:SetAttribute("AttackSequence", (player.Character:GetAttribute("AttackSequence") or 0)+1)
	self.remotes.Feedback:FireClient(player, "Hit", 16); self:Update(self.pattern and self.pattern.message or "Encontre espaço entre os pulsos")
	if self.hp == 0 then
		self.active = false; self.pattern = nil; self.warning:ClearAllChildren(); self.respawnAt = now + 45
		self:Update("O ARQUIPÉLAGO DESPERTOU")
		for contributor in self.contributors do if self:Eligible(contributor, 65) then self.journey:Complete(contributor) end end
		self.contributors = {}
	end
	return true
end
function Finale:Warn(now)
	self.sequence += 1; local kind = (self.sequence - 1) % 3 + 1; local phase = self.hp <= Journey.finale.maxHealth/2
	local pattern = { kind = kind, strikesAt = now + (phase and 1.25 or 1.65), targets = {}, message = "" }
	local function disk(pos, radius)
		local p = part(self.warning, "Danger", Vector3.new(.18, radius*2, radius*2), Vector3.new(pos.X, self.center.Y - 3.7, pos.Z), Color3.fromRGB(255, 123, 137), Enum.PartType.Cylinder)
		p.CFrame *= CFrame.Angles(0, 0, math.pi/2); p.Transparency = .4
	end
	if kind == 1 then disk(self.center, 18); pattern.message = "PULSO • afaste-se do centro"
	elseif kind == 2 then
		pattern.message = "ANEL • entre no centro iluminado"
		for i = 1, 24 do local a = i*math.pi/12; disk(self.center + Vector3.new(math.cos(a)*27, 0, math.sin(a)*27), 8) end
	else
		pattern.message = "ECOS • saia das marcas no chão"
		for player in self.players.records do local _, root = self:Eligible(player, 40); if root then table.insert(pattern.targets, root.CFrame.Position); disk(root.CFrame.Position, 7) end end
	end
	self.pattern = pattern; self.nextAttack = now + (phase and 3.3 or 4.1); self:Update(pattern.message)
end
function Finale:Step(now)
	if self.respawnAt then
		if now >= self.respawnAt then self.respawnAt = nil; self.hp = Journey.finale.maxHealth; self.prompt.Enabled = true; self:Update("OITO SEMENTES • UM MUNDO") end
		return
	end
	if not self.active then return end
	local target = false
	for player in self.players.records do if self:Eligible(player, 60) then target = true; break end end
	if target then self.lastTarget = now elseif now - self.lastTarget > 10 then
		self.active = false; self.hp = Journey.finale.maxHealth; self.pattern = nil; self.contributors = {}; self.warning:ClearAllChildren(); self.prompt.Enabled = true; self:Update("Aguardando seu retorno"); return
	end
	local p = self.pattern
	if p and now >= p.strikesAt then
		for player, r in self.players.records do
			local h, root = self:Eligible(player, 43); if not h or r.pending or player.Character:FindFirstChildOfClass("ForceField") then continue end
			local delta = root.CFrame.Position - self.center; local d = Vector3.new(delta.X, 0, delta.Z).Magnitude
			local hit = p.kind == 1 and d <= 18 or p.kind == 2 and d >= 19 and d <= 35
			if p.kind == 3 then for _, pos in p.targets do if Vector3.new(pos.X-root.CFrame.Position.X, 0, pos.Z-root.CFrame.Position.Z).Magnitude <= 7 then hit = true end end end
			if hit and math.abs(root.CFrame.Position.Y - self.center.Y) < 8 then
				local damage = Progression.hasAbility(r.profile.equipped, Definitions, "HeatResistance") and 18 or 24
				h:TakeDamage(damage); self.remotes.Feedback:FireClient(player, "Hurt", damage)
			end
		end
		self.pattern = nil; self.warning:ClearAllChildren(); self:Update("Agora! Aproxime-se para atacar.")
	elseif not p and now >= self.nextAttack then self:Warn(now) end
end
function Finale:Remove(player) self.lastAttack[player] = nil; self.contributors[player] = nil end
return Finale
