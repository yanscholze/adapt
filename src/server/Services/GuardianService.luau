--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Definitions = require(Shared.Adaptations)
local G = Config.Guardian
local Guardian = {}
function Guardian:Init(world, players, remotes, analytics, canInteract)
	self.world = world; self.players = players; self.remotes = remotes; self.analytics = analytics; self.canInteract = canInteract
	local old = world.model:FindFirstChild("Guardian"); if old then old:Destroy() end
	self.damageByPlayer = {}; self.lastAttack = {}; self.nextAttack = 0; self:Spawn()
end
function Guardian:Spawn()
	if self.model then self.model:Destroy() end
	self.model = Instance.new("Model"); self.model.Name = "Guardian"; self.model.Parent = self.world.model
	self.hp = G.MaxHealth; self.damageByPlayer = {}; self.pendingStrike = nil; self.respawnAt = nil
	local core = Instance.new("Part"); core.Name = "Core"; core.Size = Vector3.new(7, 7, 7); core.Shape = Enum.PartType.Ball
	core.CFrame = CFrame.new(self.world.guardianPosition); core.Color = Color3.fromRGB(150, 120, 179); core.Material = Enum.Material.Slate; core.Anchored = true; core.Parent = self.model
	self.core = core; self.model.PrimaryPart = core
	for _, side in { -1, 1 } do
		local eye = Instance.new("Part"); eye.Name = "Eye"; eye.Size = Vector3.new(0.8, 1.3, 0.3); eye.CFrame = CFrame.new(core.CFrame.Position + Vector3.new(side * 1.2, 1, -3.3)); eye.Anchored = true; eye.CanCollide = false; eye.Color = Color3.fromRGB(255, 198, 110); eye.Material = Enum.Material.Neon; eye.Parent = self.model
	end
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(230, 58); gui.StudsOffset = Vector3.new(0, 5, 0); gui.MaxDistance = 100; gui.Parent = core
	self.label = Instance.new("TextLabel"); self.label.Size = UDim2.fromScale(1, 1); self.label.BackgroundColor3 = Color3.fromRGB(35, 32, 54); self.label.TextColor3 = Color3.new(1, 1, 1); self.label.FontFace = Font.fromEnum(Enum.Font.GothamBold); self.label.TextSize = 17; self.label.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = self.label
	local ring = Instance.new("Part"); ring.Name = "AttackWarning"; ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.15, G.AttackRange * 2, G.AttackRange * 2)
	ring.CFrame = CFrame.new(core.CFrame.Position.X, 0.5, core.CFrame.Position.Z) * CFrame.Angles(0, 0, math.pi / 2); ring.Color = Color3.fromRGB(255, 86, 116); ring.Material = Enum.Material.Neon; ring.Anchored = true; ring.CanCollide = false; ring.CanQuery = false; ring.Transparency = 1; ring.Parent = self.model; self.ring = ring
	self:Update()
end
function Guardian:Update()
	self.model:SetAttribute("Health", self.hp); self.model:SetAttribute("MaxHealth", G.MaxHealth)
	self.label.Text = "GUARDIAN  •  " .. self.hp .. " / " .. G.MaxHealth
end
function Guardian:Eligible(player, range)
	local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local h = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health <= 0 or not self.canInteract(player) then return nil end
	if (root.CFrame.Position - self.core.CFrame.Position).Magnitude > range then return nil end
	return h
end
function Guardian:Attack(player)
	if self.hp <= 0 or not self.players:Get(player) then return end
	if self.players:Get(player).pending then return end
	local now = os.clock()
	if now - (self.lastAttack[player] or 0) < G.PlayerCooldown or not self:Eligible(player, G.PlayerRange) then return end
	local root = player.Character.HumanoidRootPart
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(root.CFrame.Position, self.core.CFrame.Position - root.CFrame.Position, params)
	if hit and not hit.Instance:IsDescendantOf(self.model) then return end
	self.lastAttack[player] = now
	self.hp = math.max(0, self.hp - G.PlayerDamage); self.damageByPlayer[player] = (self.damageByPlayer[player] or 0) + G.PlayerDamage
	self.remotes.Feedback:FireClient(player, "Hit", G.PlayerDamage); self:Update()
	if self.hp > 0 then return end
	self.pendingStrike = nil; self.ring.Transparency = 1; self.core.Transparency = 0.7; self.respawnAt = now + G.RespawnSeconds
	self.label.Text = "GUARDIAN • regenerando…"
	-- Every nearby contributor receives one server-issued reward, once per life.
	for contributor in self.damageByPlayer do
		local r = self.players:Get(contributor)
		if r and self:Eligible(contributor, G.ArenaRange + 10) then
			self.analytics:Once(contributor, r.profile, "FIRST_GUARDIAN_DEFEATED")
			if self.onDefeated then self.onDefeated(contributor) end
			self.players:Energy(contributor, G.Reward, "Guardian"); self.remotes.Feedback:FireClient(contributor, "Guardian", G.Reward)
		end
	end
	self.damageByPlayer = {}
end
function Guardian:Step(now)
	if self.hp <= 0 then if self.respawnAt and now >= self.respawnAt then self:Spawn() end; return end
	local hasTarget = false
	for player, r in self.players.records do
		if self:Eligible(player, G.ArenaRange) then self.analytics:Once(player, r.profile, "FIRST_GUARDIAN"); hasTarget = true end
	end
	if self.pendingStrike and now >= self.pendingStrike then
		self.pendingStrike = nil; self.ring.Transparency = 1
		for player in self.players.records do
			local h = self:Eligible(player, G.AttackRange)
			if h and not self.players:Get(player).pending and not player.Character:FindFirstChildOfClass("ForceField") then
				local r = self.players:Get(player)
				local damage = Progression.hasAbility(r.profile.equipped, Definitions, "HeatResistance") and G.Damage*.75 or G.Damage
				h:TakeDamage(damage); self.remotes.Feedback:FireClient(player, "Hurt", damage)
			end
		end
	elseif not self.pendingStrike and hasTarget and now >= self.nextAttack then
		self.pendingStrike = now + G.Windup; self.nextAttack = now + G.AttackCooldown; self.ring.Transparency = 0.45
	end
end
function Guardian:Remove(player) self.lastAttack[player] = nil; self.damageByPlayer[player] = nil end
return Guardian
