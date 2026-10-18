--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Adaptations = require(Shared.Adaptations)
local Progression = require(Shared.Progression)
local Synergies = require(Shared.Synergies)
local Ability = {}
local function finitePosition(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 100000 and math.abs(v.Y) < 100000 and math.abs(v.Z) < 100000
end
local function finiteVector(v)
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) <= 1.1 and math.abs(v.Y) <= 1.1 and math.abs(v.Z) <= 1.1
end
function Ability:Init(players, analytics)
	self.players = players; self.analytics = analytics; self.states = {}; self.motion = {}
end
function Ability:Stop(player)
	local s = self.states[player]; if not s then return end
	if s.velocity then s.velocity:Destroy(); s.velocity = nil end
	if s.attachment then s.attachment:Destroy(); s.attachment = nil end
	if s.root and s.root.Parent then
		local h = s.root.Parent:FindFirstChildOfClass("Humanoid")
		if h then h.PlatformStand = false; h.AutoRotate = true; h.WalkSpeed = Config.WalkSpeed end
		s.root.Parent:SetAttribute("AbilityMode", "None")
		pcall(function() s.root:SetNetworkOwnershipAuto() end)
	end
	s.mode = nil
	s.root = nil
end
function Ability:Input(player, mode, direction)
	if type(mode) ~= "string" or not finiteVector(direction) then return end
	if mode ~= "Glide" and mode ~= "Climb" and mode ~= "None" then return end
	local s = self.states[player]
	if not s then s = { glideUsed = 0, climbUsed = 0 }; self.states[player] = s end
	s.input = Vector3.new(direction.X, 0, direction.Z); if s.input.Magnitude > 1 then s.input = s.input.Unit end
	s.lastInput = os.clock()
	if mode == "None" then self:Stop(player); s.request = nil; return end
	s.request = mode
end
function Ability:Wall(character, direction)
	local root = character.HumanoidRootPart
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { character }
	local vector = direction.Magnitude > 0.1 and direction.Unit or root.CFrame.LookVector
	local hit = workspace:Raycast(root.CFrame.Position, vector * Config.Ability.WallDistance, params)
	if hit and CollectionService:HasTag(hit.Instance, "Climbable") and math.abs(hit.Normal.Y) < 0.25 then return hit end
	return nil
end
function Ability:CanInteract(player)
	local m = self.motion[player]
	local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
	return m ~= nil and root ~= nil and finitePosition(root.CFrame.Position) and os.clock() >= (m.blockedUntil or 0)
end
function Ability:Grounded(character, humanoid)
	if humanoid.FloorMaterial ~= Enum.Material.Air then return true end
	-- PlatformStand does not reliably update FloorMaterial. Check the actual floor too.
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { character }
	local floor = workspace:Raycast(character.HumanoidRootPart.CFrame.Position, Vector3.new(0, -3.6, 0), params)
	return floor ~= nil and floor.Normal.Y > 0.5
end
function Ability:Teleport(player, position)
	self:Stop(player)
	local char = player.Character
	if char and char.PrimaryPart then
		char:PivotTo(CFrame.new(position)); char.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
		self.motion[player] = { position = position, time = os.clock(), character = char, blockedUntil = os.clock() + 0.5 }
	end
end
function Ability:Step(dt, now)
	for player, r in self.players.records do
		local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local h = char and char:FindFirstChildOfClass("Humanoid")
		if not root or not h or h.Health <= 0 then self:Stop(player); continue end
		local m = self.motion[player]
		if not m or m.character ~= char then m = { position = root.CFrame.Position, time = now, character = char }; self.motion[player] = m end
		if not finitePosition(root.CFrame.Position) then
			root.CFrame = CFrame.new(finitePosition(m.position) and m.position or Vector3.new(0, 5, 20))
			root.AssemblyLinearVelocity = Vector3.zero; m.position = root.CFrame.Position; m.blockedUntil = now + 2
			self:Stop(player); continue
		end
		-- Generous movement envelope catches remote teleports without punishing ordinary falls.
		local delta = root.CFrame.Position - m.position; local elapsed = math.max(0.01, now - m.time)
		if Vector3.new(delta.X, 0, delta.Z).Magnitude > 60 * elapsed + 9 or delta.Y > 65 * elapsed + 9 then
			root.CFrame = CFrame.new(m.position); root.AssemblyLinearVelocity = Vector3.zero; m.blockedUntil = now + 2
		else m.position = root.CFrame.Position end
		m.time = now
		local s = self.states[player]
		if not s then s = { glideUsed = 0, climbUsed = 0 }; self.states[player] = s end
		local grounded = self:Grounded(char, h)
		-- Climbing at the base must not refill its budget every frame.
		if grounded and s.mode ~= "Climb" then s.glideUsed = 0; s.climbUsed = 0 end
		local request = s.request
		if not s.lastInput or now - s.lastInput > Config.Ability.InputTimeout then request = nil end
		local data = request and Progression.hasAbility(r.profile.equipped, Adaptations, request)
		local valid = data ~= nil and self:CanInteract(player)
		local wall
		if request == "Glide" then valid = valid and not grounded and root.AssemblyLinearVelocity.Y <= 8 end
		if request == "Climb" then wall = self:Wall(char, s.input or Vector3.zero); valid = valid and wall ~= nil end
		local maximum = 1; local used = 0
		if data and request == "Glide" then
			maximum = Config.Ability.GlideSeconds * data.durationMultiplier
			for _, id in Progression.synergies(r.profile.equipped, Adaptations, Synergies) do maximum += Synergies[id].bonusGlideSeconds or 0 end
			used = s.glideUsed; valid = valid and used < maximum
		elseif data and request == "Climb" then maximum = Config.Ability.ClimbSeconds * data.durationMultiplier; used = s.climbUsed; valid = valid and used < maximum end
		if not valid then self:Stop(player); char:SetAttribute("AbilityStamina", math.clamp(1 - used / maximum, 0, 1)); continue end
		if s.mode ~= request or s.root ~= root then
			self:Stop(player); s.root = root; s.mode = request
			root:SetNetworkOwner(nil)
			s.attachment = Instance.new("Attachment"); s.attachment.Name = "AdaptAbility"; s.attachment.Parent = root
			s.velocity = Instance.new("LinearVelocity"); s.velocity.Attachment0 = s.attachment; s.velocity.RelativeTo = Enum.ActuatorRelativeTo.World; s.velocity.ForceLimitsEnabled = false; s.velocity.Parent = root
			h.PlatformStand = true; h.AutoRotate = false
			char:SetAttribute("AbilityMode", request); self.analytics:Once(player, r.profile, "FIRST_ABILITY_USED")
		end
		if request == "Glide" then
			s.glideUsed += dt
			local direction = s.input.Magnitude > 0.1 and s.input.Unit or Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
			s.velocity.VectorVelocity = direction * Config.Ability.GlideSpeed * data.speedMultiplier + Vector3.new(0, -Config.Ability.GlideFallSpeed, 0)
			root.CFrame = CFrame.lookAt(root.CFrame.Position, root.CFrame.Position + direction)
		else
			s.climbUsed += dt; s.velocity.VectorVelocity = -wall.Normal * 2 + Vector3.new(0, Config.Ability.ClimbSpeed * data.speedMultiplier, 0)
			root.CFrame = CFrame.lookAt(root.CFrame.Position, root.CFrame.Position - wall.Normal)
			-- The top ray no longer sees the wall near the lip: step onto the ledge.
			local top = wall.Instance.CFrame.Position.Y + wall.Instance.Size.Y / 2
			if root.CFrame.Position.Y >= top - 1.5 then
				root.CFrame += -wall.Normal * 4 + Vector3.new(0, 5, 0); self:Stop(player); s.request = nil
				m.position = root.CFrame.Position
			end
		end
		char:SetAttribute("AbilityStamina", math.clamp(1 - used / maximum, 0, 1))
	end
end
function Ability:Remove(player) self:Stop(player); self.states[player] = nil; self.motion[player] = nil end
return Ability
