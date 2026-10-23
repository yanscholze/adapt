--!nonstrict
-- Runs the real service modules against offline instances and mocked services.
local H = require("../scripts/RobloxHarness")
local h = H.new("build/ADAPT.rbxlx")
local r = H.roblox
local checks = 0
local function check(name, fn) fn(); checks += 1; print("PASS", name) end
local function player(id)
	local p = r.Instance.new("Player"); p.Name = "Tester" .. id; p.DisplayName = p.Name; p.UserId = id; p.Parent = h.game:GetService("Players"); return p
end
local p1, p2 = player(101), player(102)
local Config = h.require(h.shared.Config)
local Schema = h.require(h.shared.ProfileSchema)
local Analytics = h.require(h.services.AnalyticsService); Analytics:Init()
local Persistence = h.require(h.services.PersistenceService); Persistence:Init()
local Players = h.require(h.services.PlayerService); Players:Init(h.remotes, Persistence, Analytics)
local World = h.require(h.services.WorldService); World:Init()
local Characters = h.require(h.services.CharacterService); Characters:Init(Players, h.remotes)
local Ability = h.require(h.services.AbilityService); Ability:Init(Players, Analytics)
local Essence = h.require(h.services.EssenceService); Essence:Init(World, Players, h.remotes, function(p) return Ability:CanInteract(p) end)
local Guardian = h.require(h.services.GuardianService); Guardian:Init(World, Players, h.remotes, Analytics, function(p) return Ability:CanInteract(p) end)
local Debug = h.require(h.services.DebugService); Debug:Init(Players, Characters, Ability, h.remotes)
Players.onBuildChanged = function(p) Ability:Stop(p); Characters:Apply(p) end
local function move(p, pos)
	Ability:Teleport(p, pos); Ability.motion[p].blockedUntil = 0
end
check("server services load without circular dependencies", function() assert(Players:Add(p1, true)); assert(Players:Add(p2, true)); Characters:Spawn(p1); Characters:Spawn(p2) end)
check("Blank rigs have complete R6 anatomy, visible shell and independent ownership", function()
	for _, p in { p1, p2 } do
		assert(p.Character.HumanoidRootPart and p.Character.Torso.Neck and p.Character["Left Leg"] and p.Character.Appearance.BlankBody)
		assert(p.Character.Torso.CanCollide and p.Character.Humanoid.WalkSpeed == Config.WalkSpeed)
	end
	assert(p1.Character ~= p2.Character)
end)
check("all areas resolve and only the marked wall is climbable", function()
	for id, data in h.require(h.shared.Areas) do assert(World:AreaAt(r.Vector3.new(table.unpack(data.spawn))) == id) end
	assert(World.model.Core.ClimbFace:HasTag("Climbable") and not World.model.Core.CliffMass:HasTag("Climbable"))
	assert(not World.model.Core.GripMark.CanQuery, "Decorative marks must not interrupt the wall raycast")
	assert(#Essence.nodes >= 21)
end)
check("simultaneous collection awards one player once and respects respawn", function()
	local node = Essence.nodes[1]; move(p1, node.part.CFrame.Position); move(p2, node.part.CFrame.Position)
	local before = Players:Get(p1).profile.energy + Players:Get(p2).profile.energy
	Essence:Step(100)
	assert(Players:Get(p1).profile.energy + Players:Get(p2).profile.energy == before + 6)
	assert(node.readyAt == 112 and node.part:GetAttribute("Available") == false)
	Essence:Step(101); assert(Players:Get(p1).profile.energy + Players:Get(p2).profile.energy == before + 6)
	Essence:Step(113); assert(node.readyAt == 125)
end)
check("rare Essence requires server-side NightVision, regardless of visibility", function()
	local node = Essence.nodes[19]; move(p1, node.part.CFrame.Position); move(p2, r.Vector3.new(0, 5, 20))
	local before = Players:Get(p1).profile.energy; node.part.Transparency = 0
	Essence:Step(200); assert(Players:Get(p1).profile.energy == before and node.readyAt == 0)
	Debug:Execute(p1, "grant", "NightEyes"); Essence:Step(201)
	assert(Players:Get(p1).profile.energy == before + 18 and node.readyAt > 201)
end)
check("forged option, stale token and replay cannot award an adaptation", function()
	Players:Energy(p1, 60, "Debug"); local pending = Players:Get(p1).pending
	assert(not Players:Choose(p1, "fake-token", "Wings"))
	assert(not Players:Choose(p1, pending.token, "DawnSails"))
	assert(Players:Choose(p1, pending.token, "Wings"))
	local level = Players:Get(p1).profile.level
	assert(not Players:Choose(p1, pending.token, "Wings") and Players:Get(p1).profile.level == level)
	assert(Players:Get(p1).profile.synergies.Moondrift and p1.Character.Appearance:FindFirstChild("Wing"))
end)
check("death and respawn preserve build, Codex and progress", function()
	local profile = Players:Get(p1).profile; local old = p1.Character
	old.Humanoid.Health = 0; old.Humanoid.Died:Fire()
	local callback; for _, item in h.delayed do if item.seconds == 3 then callback = item.callback end end
	assert(callback); callback()
	assert(p1.Character ~= old and Players:Get(p1).profile == profile and p1.Character.Appearance:FindFirstChild("Wing"))
end)
check("unowned abilities and NaN input never activate", function()
	move(p2, r.Vector3.new(0, 20, 20)); p2.Character.Humanoid.FloorMaterial = r.Enum.Material.Air
	Ability:Input(p2, "Glide", r.Vector3.new(1, 0, 0)); Ability:Step(0.1, os.clock())
	assert(not Ability.states[p2].mode)
	Ability:Input(p2, "Climb", r.Vector3.new(0 / 0, 0, 0)); assert(Ability.states[p2].request == "Glide")
end)
check("Glide applies downward motion and exhausts its airborne budget", function()
	move(p1, r.Vector3.new(30, 65, -65)); p1.Character.Humanoid.FloorMaterial = r.Enum.Material.Air
	p1.Character.HumanoidRootPart.AssemblyLinearVelocity = r.Vector3.new(0, -4, 0)
	for _ = 1, 120 do Ability:Input(p1, "Glide", r.Vector3.new(1, 0, 0)); Ability:Step(0.1, os.clock()) end
	assert(Ability.states[p1].glideUsed >= 11 and not Ability.states[p1].mode)
	p1.Character.Humanoid.FloorMaterial = r.Enum.Material.Grass; Ability:Input(p1, "None", r.Vector3.zero); Ability:Step(0.1, os.clock()); assert(Ability.states[p1].glideUsed == 0)
end)
check("landing ray stops Glide even when FloorMaterial stays Air", function()
	move(p1, r.Vector3.new(30, 65, -65)); p1.Character.Humanoid.FloorMaterial = r.Enum.Material.Air
	Ability:Input(p1, "Glide", r.Vector3.new(1, 0, 0)); Ability:Step(0.1, os.clock()); assert(Ability.states[p1].mode == "Glide")
	h.raycast = function() return { Instance = World.model.Core.Wilds, Normal = r.Vector3.new(0, 1, 0) } end
	Ability:Step(0.1, os.clock()); assert(not Ability.states[p1].mode and not p1.Character.Humanoid.PlatformStand and Ability.states[p1].glideUsed == 0)
	h.raycast = nil
end)
check("Climb rejects an untagged wall and accepts the marked face", function()
	Debug:Execute(p1, "grant", "GripClaws"); move(p1, r.Vector3.new(70, 5, 7)); p1.Character.Humanoid.FloorMaterial = r.Enum.Material.Air
	h.raycast = function() return { Instance = World.model.Core.CliffMass, Normal = r.Vector3.new(0, 0, -1) } end
	Ability:Input(p1, "Climb", r.Vector3.new(0, 0, 1)); Ability:Step(0.1, os.clock()); assert(not Ability.states[p1].mode)
	h.raycast = function() return { Instance = World.model.Core.ClimbFace, Normal = r.Vector3.new(0, 0, -1) } end
	Ability:Input(p1, "Climb", r.Vector3.new(0, 0, 1)); Ability:Step(0.1, os.clock()); assert(Ability.states[p1].mode == "Climb" and Ability.states[p1].velocity.VectorVelocity.Y > 0)
	move(p1, r.Vector3.new(70, 43, 7)); Ability:Input(p1, "Climb", r.Vector3.new(0, 0, 1)); Ability:Step(0.1, os.clock())
	assert(p1.Character.HumanoidRootPart.CFrame.Position.Y > 44 and p1.Character.HumanoidRootPart.CFrame.Position.Z > 9 and not Ability.states[p1].mode)
	h.raycast = nil
end)
check("Guardian telegraphs, damages and rewards nearby contributors only once", function()
	for _, p in { p1, p2 } do
		local record = Players:Get(p)
		while record.pending do assert(Players:Choose(p, record.pending.token, record.pending.options[1])) end
	end
	move(p1, World.guardianPosition + r.Vector3.new(0, 0, -7)); move(p2, World.guardianPosition + r.Vector3.new(0, 0, -8))
	for _, p in { p1, p2 } do local shield = p.Character:FindFirstChildOfClass("ForceField"); if shield then shield:Destroy() end end
	Guardian:Step(300); assert(Guardian.pendingStrike and Guardian.ring.Transparency < 1)
	local hp = p1.Character.Humanoid.Health; Guardian:Step(301); assert(p1.Character.Humanoid.Health == hp - Config.Guardian.Damage)
	local energy = Players:Get(p1).profile.energy
	for i = 1, 8 do Guardian.lastAttack[p1] = -100; Guardian:Attack(p1) end
	assert(Guardian.hp == 0 and Players:Get(p1).profile.energy == energy + Config.Guardian.Reward)
	Guardian.lastAttack[p1] = -100; Guardian:Attack(p1); assert(Players:Get(p1).profile.energy == energy + Config.Guardian.Reward)
	assert(not Players:Get(p2).profile.milestones.FIRST_GUARDIAN_DEFEATED)
	Guardian:Step(Guardian.respawnAt + 1); assert(Guardian.hp == Config.Guardian.MaxHealth)
end)
check("production debug is denied for non-admins", function()
	h.overrides.RunService.IsStudio = function() return false end
	local before = Players:Get(p2).profile.energy; Debug:Execute(p2, "energy", 500); assert(Players:Get(p2).profile.energy == before)
	h.overrides.RunService.IsStudio = function() return true end
end)
check("movement envelope rejects a teleport and blocks immediate collection", function()
	move(p2, r.Vector3.new(0, 5, 20)); local previous = p2.Character.HumanoidRootPart.CFrame.Position
	p2.Character.HumanoidRootPart.CFrame = r.CFrame.new(1000, 30, 1000); Ability:Step(0.1, os.clock())
	assert((p2.Character.HumanoidRootPart.CFrame.Position - previous).Magnitude < 0.1 and not Ability:CanInteract(p2))
	p2.Character.HumanoidRootPart.CFrame = r.CFrame.new(0 / 0, 0, 0)
	assert(not Ability:CanInteract(p2)); Ability:Step(0.1, os.clock())
	assert(p2.Character.HumanoidRootPart.CFrame.Position.X == p2.Character.HumanoidRootPart.CFrame.Position.X)
end)

-- In-memory UpdateAsync store: exercises failure handling without cloud credentials.
local store = { records = {}, fail = false, writes = 0 }
function store:UpdateAsync(key, callback)
	if self.fail then error("simulated API outage") end
	local result = callback(self.records[key])
	if result then self.records[key] = result; self.writes += 1 end
	return result
end
h.store = store
Config.StudioPersistence = true; Persistence:Init()
check("cloud lease blocks a second session and releases after save", function()
	local profile, mode = Persistence:Load(p1); assert(profile and mode == "Cloud")
	local duplicate = player(101); local blocked, why = Persistence:Load(duplicate); assert(not blocked and why == "Locked")
	profile.level = 7; assert(Persistence:Save(p1, profile, true)); assert(store.records.u_101.data.level == 7 and not store.records.u_101.session)
	local loaded = Persistence:Load(duplicate); assert(loaded.level == 7)
end)
check("failed cloud load never overwrites existing data with defaults", function()
	store.fail = true; local old = store.records.u_101; local writes = store.writes
	local profile, mode = Persistence:Load(p2); assert(profile and mode == "ReadOnly")
	assert(not Persistence:Save(p2, profile, false)); assert(store.writes == writes and store.records.u_101 == old)
	store.fail = false
end)
check("newer schema is preserved and refuses downgrade", function()
	store.records.u_102 = { version = 99, data = { level = 999 } }; local writes = store.writes
	local _, mode = Persistence:Load(p2); assert(mode == "ReadOnly" and store.writes == writes and store.records.u_102.data.level == 999)
end)
check("lease takeover prevents stale server saves", function()
	store.records.u_102 = nil; local profile = Persistence:Load(p2)
	store.records.u_102.session.id = "another-server"
	assert(not Persistence:Save(p2, profile, false) and p2:GetAttribute("Kicked"))
end)
check("analytics disabled is safe and marks each FTUE milestone once", function()
	local profile = Schema.defaults(); local called = 0; Analytics:SetSink(function() called += 1 end)
	Analytics:Once(p1, profile, "CODEX_OPENED"); Analytics:Once(p1, profile, "CODEX_OPENED"); assert(called == 0 and profile.milestones.CODEX_OPENED)
end)
print("INTEGRATION:", checks, "checks passed (offline adapters; physics/network/cloud not simulated)")
