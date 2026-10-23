--!nonstrict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Definitions = require(Shared.Adaptations)
local Progression = require(Shared.Progression)
local Synergies = require(Shared.Synergies)
local Characters = {}
local function bodyPart(model, name, size, cf, color, hidden)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Transparency = hidden and 1 or 0; p.CanCollide = false; p.Massless = name ~= "HumanoidRootPart"; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = model
	return p
end
local function motor(parent, name, p0, p1, c0, c1)
	local j = Instance.new("Motor6D"); j.Name = name; j.Part0 = p0; j.Part1 = p1; j.C0 = c0 or CFrame.identity; j.C1 = c1 or CFrame.identity; j.Parent = parent; return j
end
local function ornament(folder, root, name, size, offset, color, shape, neon)
	local p = bodyPart(folder, name, size, root.CFrame * offset, color)
	p.Shape = shape or Enum.PartType.Ball; p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	p.CastShadow = not neon
	local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = p; w.Parent = p
	return p
end
function Characters:Init(players, remotes)
	Players.CharacterAutoLoads = false
	self.players = players; self.remotes = remotes; self.connections = {}; self.generations = {}
end
function Characters:Spawn(player)
	if not player.Parent or not self.players:Get(player) then return end
	if self.connections[player] then self.connections[player]:Disconnect() end
	self.generations[player] = (self.generations[player] or 0) + 1
	local generation = self.generations[player]
	local old = player.Character
	if old then old:Destroy() end
	local model = Instance.new("Model"); model.Name = player.Name
	local spawn = self.spawnPosition and self.spawnPosition(player) or Vector3.new(0, 5, 20)
	local origin = CFrame.new(spawn + Vector3.new((player.UserId % 5 - 2) * 1.5, 0, 0))
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
	humanoid.MaxSlopeAngle = 50; humanoid.DisplayName = player.DisplayName; humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff; humanoid.Parent = model
	local animator = Instance.new("Animator"); animator.Parent = humanoid
	model.PrimaryPart = root; model:SetAttribute("SpawnedAt", os.clock()); model:SetAttribute("AbilityMode", "None"); model:SetAttribute("AbilityStamina", 1)
	model.Parent = workspace; player.Character = model
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
	local r = self.players:Get(player); local model = player.Character
	if not r or not model or not model:FindFirstChild("HumanoidRootPart") then return end
	local old = model:FindFirstChild("Appearance"); if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = "Appearance"; folder.Parent = model
	local root = model.HumanoidRootPart
	local white = Color3.fromRGB(222, 239, 226)
	ornament(folder, root, "BlankBody", Vector3.new(2.7, 2.8, 2.1), CFrame.new(0, -0.2, 0), white)
	ornament(folder, root, "BlankHead", Vector3.new(2.5, 2, 2.1), CFrame.new(0, 1.25, -0.15), white)
	for _, side in { -1, 1 } do
		ornament(folder, model[side == -1 and "Left Leg" or "Right Leg"], "Foot", Vector3.new(1.1, 0.8, 1.5), CFrame.new(0, -0.65, -0.25), Color3.fromRGB(123, 174, 160))
		ornament(folder, model[side == -1 and "Left Arm" or "Right Arm"], "Paw", Vector3.new(0.75, 1.2, 0.8), CFrame.new(0, -0.5, 0), white)
	end
	local eyeColor = Color3.fromRGB(36, 50, 66); local eyeScale = 1; local bright = false
	for slot, id in r.profile.equipped do
		local def = Definitions[id]; local visual = def.visualData; local color = Color3.fromRGB(table.unpack(visual.color))
		model:SetAttribute("Slot" .. slot, id)
		if visual.kind == "Wings" then
			for _, side in { -1, 1 } do
				ornament(folder, root, "Wing", Vector3.new(3.4, 0.45, 2) * visual.scale, CFrame.new(side * 2.5, 0.65, 0.7) * CFrame.Angles(0, side * -0.3, side * 0.35), color, Enum.PartType.Block)
				ornament(folder, root, "WingTip", Vector3.new(1.4, 0.35, 1.6) * visual.scale, CFrame.new(side * 4.1, 1.35, 1) * CFrame.Angles(0, side * -0.6, side * 0.6), color, Enum.PartType.Block)
			end
		elseif visual.kind == "Claws" then
			for _, side in { -1, 1 } do
				local arm = model[side == -1 and "Left Arm" or "Right Arm"]
				for finger = -1, 1 do ornament(folder, arm, "Claw", Vector3.new(0.18, 0.8, 0.35) * visual.scale, CFrame.new(finger * 0.25, -1.15, -0.38) * CFrame.Angles(-0.4, 0, 0), color, Enum.PartType.Block, true) end
			end
		elseif visual.kind == "Eyes" then eyeColor = color; eyeScale = visual.scale; bright = true
		elseif visual.kind == "Shell" then
			ornament(folder, root, "EmberCarapace", Vector3.new(3.1, 2.6, 1.6), CFrame.new(0, -.2, .9), color)
			for i = -1, 1 do ornament(folder, root, "ShellFacet", Vector3.new(.35, 1.7, .4), CFrame.new(i*.75, 0, 1.65), Color3.fromRGB(255, 214, 125), Enum.PartType.Block, true) end
		elseif visual.kind == "Tail" then
			ornament(folder, root, "TideTail", Vector3.new(.8, .9, 2.4), CFrame.new(0, -1, 1.8)*CFrame.Angles(-.25,0,0), color)
			for _, side in { -1, 1 } do ornament(folder, root, "TailFin", Vector3.new(1.5, .3, 1.1), CFrame.new(side*.65, -.6, 2.8)*CFrame.Angles(0, side*.45,0), color, Enum.PartType.Block) end
		elseif visual.kind == "Legs" then
			for _, side in { -1, 1 } do ornament(folder, model[side == -1 and "Left Leg" or "Right Leg"], "SpringPaw", Vector3.new(1.3, 1, 1.7), CFrame.new(0,-.5,-.2), color) end
		end
	end
	for _, slot in { "Head", "Body", "Arms", "Legs", "Back", "Tail" } do if not r.profile.equipped[slot] then model:SetAttribute("Slot" .. slot, nil) end end
	for _, side in { -1, 1 } do ornament(folder, root, "Eye", Vector3.new(0.36, 0.5, 0.28) * eyeScale, CFrame.new(side * 0.55, 1.4, -1.15), eyeColor, Enum.PartType.Ball, bright) end
	local active = Progression.synergies(r.profile.equipped, Definitions, Synergies)
	if #active > 0 then
		local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(190, 170, 255); light.Brightness = 0.7; light.Range = 7; light.Parent = folder.BlankBody
	end
	if r.profile.journey and r.profile.journey.complete then
		for i = 1, 5 do
			local a = i*math.pi*2/5
			ornament(folder, root, "WorldkeeperCrown", Vector3.new(.25, .65, .25), CFrame.new(math.cos(a)*.7, 2.5, math.sin(a)*.7-.15), Color3.fromRGB(255, 222, 130), Enum.PartType.Block, true)
		end
	end
end
function Characters:Remove(player)
	self.generations[player] = nil
	if self.connections[player] then self.connections[player]:Disconnect(); self.connections[player] = nil end
	if player.Character then player.Character:Destroy() end
end
return Characters
