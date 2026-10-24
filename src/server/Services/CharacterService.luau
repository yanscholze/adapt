--!nonstrict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Appearance = require(Shared.CreatureAppearance)
local Characters = {}
local function bodyPart(model, name, size, cf, color, hidden)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Transparency = hidden and 1 or 0; p.CanCollide = false; p.Massless = name ~= "HumanoidRootPart"; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = model
	return p
end
local function motor(parent, name, p0, p1, c0, c1)
	local j = Instance.new("Motor6D"); j.Name = name; j.Part0 = p0; j.Part1 = p1; j.C0 = c0 or CFrame.identity; j.C1 = c1 or CFrame.identity; j.Parent = parent; return j
end
-- Use a shared StarterCharacter template so the engine initializes its native
-- player controls, camera and character lifecycle through LoadCharacterAsync.
local function blankRig()
	local model = Instance.new("Model"); model.Name = "StarterCharacter"
	local origin = CFrame.identity
	local white = Color3.fromRGB(222, 239, 226)
	local root = bodyPart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), origin, white, true)
	root.RootPriority = 127
	local torso = bodyPart(model, "Torso", Vector3.new(2, 2, 1), origin, white, true)
	torso.CanCollide = true
	local head = bodyPart(model, "Head", Vector3.new(2, 1, 1), origin * CFrame.new(0, 1.5, 0), white, true)
	motor(root, "RootJoint", root, torso)
	motor(torso, "Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	for _, side in { -1, 1 } do
		local label = side == -1 and "Left" or "Right"
		local arm = bodyPart(model, label .. " Arm", Vector3.new(1, 2, 1), origin * CFrame.new(side * 1.5, 0, 0), white, true)
		local leg = bodyPart(model, label .. " Leg", Vector3.new(1, 2, 1), origin * CFrame.new(side * 0.5, -2, 0), white, true)
		motor(torso, label .. " Shoulder", torso, arm, CFrame.new(side * 1, 0.5, 0), CFrame.new(-side * 0.5, 0.5, 0))
		motor(torso, label .. " Hip", torso, leg, CFrame.new(side * 0.5, -1, 0), CFrame.new(0, 1, 0))
	end
	local humanoid = Instance.new("Humanoid"); humanoid.RigType = Enum.HumanoidRigType.R6; humanoid.WalkSpeed = Config.WalkSpeed; humanoid.UseJumpPower = true; humanoid.JumpPower = Config.JumpPower
	humanoid.MaxHealth = 100; humanoid.Health = 100
	humanoid.MaxSlopeAngle = 50; humanoid.DisplayName = "Blank"; humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff; humanoid.Parent = model
	local animator = Instance.new("Animator"); animator.Parent = humanoid
	model.PrimaryPart = root
	return model
end
function Characters:Init(players, remotes)
	Players.CharacterAutoLoads = false
	self.players = players; self.remotes = remotes; self.connections = {}; self.generations = {}; self.loading = {}; self.loadFailures = {}
	local starter = game:GetService("StarterPlayer")
	starter.LoadCharacterAppearance = false
	local template = starter:FindFirstChild("StarterCharacter")
	if not template then template = blankRig(); template.Parent = starter end
end
function Characters:Spawn(player)
	if not player.Parent or not self.players:Get(player) or self.loading[player] then return end
	if self.connections[player] then self.connections[player]:Disconnect() end
	self.generations[player] = (self.generations[player] or 0) + 1
	local generation = self.generations[player]
	self.loading[player] = true
	local ok, err = pcall(function() player:LoadCharacterAsync() end)
	self.loading[player] = nil
	if self.generations[player] ~= generation or not player.Parent then return end
	if not ok then
		warn("[ADAPT] Character load failed: " .. tostring(err))
		self.loadFailures[player] = (self.loadFailures[player] or 0) + 1
		if self.loadFailures[player] <= 3 then
			task.delay(3, function() if self.generations[player] == generation then self:Spawn(player) end end)
		end
		return
	end
	self.loadFailures[player] = nil
	local model = player.Character
	local root = model:WaitForChild("HumanoidRootPart")
	local humanoid = model:WaitForChild("Humanoid")
	local spawn = self.spawnPosition and self.spawnPosition(player) or Vector3.new(0, 5, 20)
	model:PivotTo(CFrame.new(spawn + Vector3.new((player.UserId % 5 - 2) * 1.5, 0, 0)))
	root.AssemblyLinearVelocity = Vector3.zero
	humanoid.WalkSpeed = Config.WalkSpeed; humanoid.UseJumpPower = true; humanoid.JumpPower = Config.JumpPower
	humanoid.DisplayName = player.DisplayName
	-- ADAPT animates this rig procedurally; do not run the avatar Animate script too.
	local animate = model:FindFirstChild("Animate"); if animate then animate:Destroy() end
	model:SetAttribute("SpawnedAt", os.clock()); model:SetAttribute("AbilityMode", "None"); model:SetAttribute("AbilityStamina", 1)
	root:SetNetworkOwner(player)
	player.CameraMode = Enum.CameraMode.Classic
	self:Apply(player)
	local shield = Instance.new("ForceField"); shield.Visible = false; shield.Parent = model
	task.delay(Config.SpawnProtectionSeconds, function() if shield.Parent then shield:Destroy() end end)
	self.connections[player] = humanoid.Died:Connect(function()
		model:SetAttribute("AbilityMode", "None")
		if self.onDeath then self.onDeath(player) end
		task.delay(3, function() if self.generations[player] == generation then self:Spawn(player) end end)
	end)
	self.players:Send(player)
end
function Characters:Apply(player)
	local record = self.players:Get(player); local model = player.Character
	if not record or not model or not model:FindFirstChild("HumanoidRootPart") then return end
	Appearance.build(model, record.profile)
end
function Characters:Remove(player)
	self.generations[player] = nil; self.loading[player] = nil; self.loadFailures[player] = nil
	if self.connections[player] then self.connections[player]:Disconnect(); self.connections[player] = nil end
	if player.Character then player.Character:Destroy() end
end
return Characters
