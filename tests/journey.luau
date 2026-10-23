--!nonstrict
-- Real campaign/services, offline instances. Does not simulate Roblox locomotion.
local H = require("../scripts/RobloxHarness")
local h = H.new("build/ADAPT.rbxlx"); local R = H.roblox
local Journey = h.require(h.shared.Journey); local Locations = h.require(h.shared.JourneyLocations)
local Definitions = h.require(h.shared.Adaptations); local Schema = h.require(h.shared.ProfileSchema)
local World = h.require(h.services.WorldService); World:Init()
local Persistence = h.require(h.services.PersistenceService); Persistence:Init()
local Analytics = h.require(h.services.AnalyticsService); Analytics:Init()
local Players = h.require(h.services.PlayerService); Players:Init(h.remotes, Persistence, Analytics)
local Characters = h.require(h.services.CharacterService); Characters:Init(Players, h.remotes)
local Ability = h.require(h.services.AbilityService); Ability:Init(Players, Analytics)
local Service = h.require(h.services.JourneyService); Service:Init(World, Players, Ability, Characters, h.remotes)
local Finale = h.require(h.services.FinaleService); Finale:Init(World, Players, Service, h.remotes, function(p) return Ability:CanInteract(p) end)
local Guardian = h.require(h.services.GuardianService); Guardian:Init(World, Players, h.remotes, Analytics, function(p) return Ability:CanInteract(p) end)
Guardian.onDefeated = function(p) Service:GuardianDefeated(p) end
Players.onBuildChanged = function(p) Ability:Stop(p); Characters:Apply(p) end
local function makePlayer(id)
	local p = R.Instance.new("Player"); p.UserId = id; p.Name = "Campaign"..id; p.DisplayName = p.Name; p.Parent = h.game:GetService("Players")
	assert(Players:Add(p, false)); Characters:Spawn(p); return p
end
local p, other = makePlayer(10), makePlayer(20)
local record = Players:Get(p); local profile = record.profile
local checks = 0
local function check(name, f) f(); checks += 1; print("PASS", name) end
local function move(player, point)
	Ability:Teleport(player, typeof(point) == "Vector3" and point or R.Vector3.new(table.unpack(point))); Ability.motion[player].blockedUntil = 0
end
local function choices()
	while record.pending do assert(Players:Choose(p, record.pending.token, record.pending.options[1])) end
end
check("baked campaign has eight refuges, 24 memories and one final encounter", function()
	local camps, runes, seals = 0, 0, 0
	for _, part in World.model.Journey:GetDescendants() do
		if part:GetAttribute("Camp") then camps += 1 end
		if part:GetAttribute("Memory") then runes += 1 end
		if part:GetAttribute("Shrine") then seals += 1 end
	end
	assert(camps == 8 and runes == 24 and seals == 8 and World.model.ZenithGuardian)
end)
check("v1 migration preserves progress and defaults new journey tables independently", function()
	local old = { version = 1, level = 12, energy = 71, equipped = { Back = "Wings" }, areas = { Cave = true }, milestones = { FIRST_ESSENCE = true } }
	local migrated = Schema.sanitize(old, Definitions, h.require(h.shared.Synergies), h.require(h.shared.Areas))
	assert(migrated.version == 2 and migrated.level == 12 and migrated.energy == 71 and migrated.equipped.Back == "Wings" and migrated.areas.Cave)
	assert(migrated.journey.camps.Wilds and not migrated.journey.complete)
	local a, b = Schema.defaults(), Schema.defaults(); a.journey.runes.FirstSky = true; assert(not b.journey.runes.FirstSky)
	local bad = Journey.sanitize({ seals = { fake = true }, complete = true, checkpoint = "fake", camps = { bad = true }, runes = { fake = true } })
	assert(not bad.complete and not bad.runes.fake and bad.checkpoint == "Wilds")
end)
check("remote requests cannot award distant memories, seals, finale or locked travel", function()
	move(p, Locations.camps.Wilds)
	assert(not Service:Interact(p, "rune", "SkyNeedle")); assert(not Service:Interact(p, "seal", "Wilds"))
	assert(not Service:Complete(p)); assert(not Service:Travel(p, "SkyReach")); assert(not Service:Equip(p, "SkyWings"))
	assert(not Service:Interact(p, "complete", "Wilds")); assert(profile.energy == 0)
end)
check("tutorial and real starter Guardian unlock all three essential routes", function()
	assert(Service:Interact(p, "intro", "")); Players:Energy(p, 30, "Essence"); choices()
	move(p, World.guardianPosition + R.Vector3.new(0,0,-10))
	for _ = 1, 8 do Guardian.lastAttack[p] = -10; Guardian:Attack(p) end
	assert(Guardian.hp == 0 and profile.journey.guardian)
	for _, id in { "Wings", "GripClaws", "NightEyes" } do assert(profile.discovered[id]) end
	choices()
end)
check("first sanctuary requires all three memories and grants reward exactly once", function()
	for _, id in Journey.regions.Wilds.runes do
		move(p, Locations.runes[id].position); assert(Service:Interact(p, "rune", id)); local energy = profile.energy
		assert(not Service:Interact(p, "rune", id) and profile.energy == energy); choices()
	end
	move(p, Locations.camps.Wilds); assert(Service:Interact(p, "seal", "Wilds")); local energy = profile.energy
	assert(profile.discovered.SpringLegs and not Service:Interact(p, "seal", "Wilds") and profile.energy == energy); choices()
end)
check("all eight chapters complete in order using only earned rewards", function()
	for _, area in Journey.order do
		if profile.journey.seals[area] then continue end
		local region = Journey.regions[area]
		move(p, Locations.camps[area]); assert(Service:Interact(p, "camp", area))
		local required = ({ Tideglass = "TideTail", EmberAtoll = "EmberShell", Hollow = "NightEyes", SkyReach = "SkyWings" })[area]
		if required then
			assert(profile.discovered[required], "Missing earned dependency: " .. required)
			assert(Service:Equip(p, required))
		end
		for _, id in region.runes do
			move(p, Locations.runes[id].position); assert(Service:Interact(p, "rune", id), id); choices()
			if required then move(p, Locations.camps[area]); assert(Service:Equip(p, required)) end
		end
		move(p, Locations.camps[area]); assert(Service:Interact(p, "seal", area)); choices()
	end
	assert(Journey.count(profile.journey.seals) == 8 and Journey.count(profile.journey.runes) == 24)
	for _, id in { "SpringLegs", "TideTail", "EmberShell", "SkyWings" } do assert(profile.discovered[id]) end
	assert(Service:Snapshot(p).objective.kind == "Finale")
end)
check("equipment is server-validated and preserves other anatomical slots", function()
	move(p, { 500, 500, 500 }); assert(not Service:Equip(p, "Wings"))
	move(p, Locations.camps.Wilds); local before = profile.equipped.Tail; assert(Service:Equip(p, "Wings")); assert(profile.equipped.Tail == before)
	assert(not Service:Equip(other, "SkyWings"))
end)
check("discovered-camp travel sets a durable respawn checkpoint and has cooldown", function()
	assert(Service:Travel(p, "Oldgrowth")); assert(profile.journey.checkpoint == "Oldgrowth")
	assert(not Service:Travel(p, "Wilds"))
	Characters:Spawn(p); assert((p.Character.HumanoidRootPart.CFrame.Position-R.Vector3.new(table.unpack(Locations.camps.Oldgrowth))).Magnitude < 5)
	move(p, Locations.camps.Oldgrowth); assert(Service:Interact(p, "camp", "Oldgrowth")); assert(p.Character.Humanoid.Health == 100)
end)
check("rescue preserves discoveries and rejects repeated spam", function()
	local memories = Journey.count(profile.journey.runes)
	move(p, { 0, -230, 0 }); assert(Service:Rescue(p)); assert(not Service:Rescue(p)); assert(Journey.count(profile.journey.runes) == memories)
end)
check("water, heat, leap and shell have functional server effects", function()
	move(p, Locations.camps.Oldgrowth); assert(Service:Equip(p, "SpringLegs")); profile.equipped.Tail = nil; profile.equipped.Body = nil
	move(p, { -700, -83, 900 }); local hum = p.Character.Humanoid; hum:SetAttribute("TestSwimming", true)
	for i = 1, 24 do Service:Step(1000+i) end
	assert(hum.Health < 100 and p.Character:GetAttribute("Oxygen") == 0 and hum.JumpPower == 60)
	profile.equipped.Tail = "TideTail"; Service:Step(1025); assert(p.Character:GetAttribute("Oxygen") == 1 and hum.WalkSpeed == 28)
	hum:SetAttribute("TestSwimming", false); move(p, { 1100, 350, -1020 }); local before = hum.Health; Service:Step(1026); assert(hum.Health < before)
	profile.equipped.Body = "EmberShell"; before = hum.Health; Service:Step(1027); assert(hum.Health == before)
end)
check("ascendant wings generate upward velocity but cannot refill in the air", function()
	Characters:Spawn(p); move(p, {980,340,75}); profile.equipped.Back = "SkyWings"
	Ability:Input(p, "Glide", R.Vector3.new(1,0,0)); Ability:Step(.1, os.clock()); assert(Ability.states[p].velocity.VectorVelocity.Y == 20)
	Ability.states[p].glideUsed = 100; Ability:Step(.1, os.clock()); assert(not Ability.states[p].mode)
	Ability:Input(p, "Glide", R.Vector3.new(1,0,0)); Ability:Step(.1, os.clock()); assert(not Ability.states[p].mode)
end)
check("final encounter rejects players without eight seals", function()
	move(other, Finale.center); assert(not Finale:Start(other)); assert(not Finale:Attack(other))
	move(p, Finale.center + R.Vector3.new(0,0,-10)); assert(Finale:Start(p))
end)
check("three telegraphs create readable patterns and safe zones", function()
	local shield = p.Character:FindFirstChildOfClass("ForceField"); if shield then shield:Destroy() end
	local hum = p.Character.Humanoid; hum.Health = 100
	Finale.sequence = 0; Finale:Warn(2000); assert(Finale.pattern.kind == 1 and #Finale.warning:GetChildren() == 1)
	move(p, Finale.center + R.Vector3.new(25,0,0)); Finale:Step(2002); assert(hum.Health == 100)
	Finale:Warn(2003); assert(Finale.pattern.kind == 2 and #Finale.warning:GetChildren() == 24)
	move(p, Finale.center + R.Vector3.new(10,0,0)); Finale:Step(2005); assert(hum.Health == 100)
	Finale:Warn(2006); assert(Finale.pattern.kind == 3 and #Finale.pattern.targets == 1)
	Finale:Step(2008); assert(hum.Health == 82)
end)
check("final victory grants epilogue and crown once only to eligible contributors", function()
	move(p, Finale.center + R.Vector3.new(10,0,0))
	for _ = 1, 20 do Finale.lastAttack[p] = -10; assert(Finale:Attack(p)) end
	assert(profile.journey.complete and not Players:Get(other).profile.journey.complete)
	local energy = profile.energy; assert(not Service:Complete(p) and profile.energy == energy)
	assert(p.Character.Appearance:FindFirstChild("WorldkeeperCrown")); assert(Service:Snapshot(p).objective.kind == "Complete"); choices()
end)
check("empty final arena resets a damaged encounter without granting rewards", function()
	Finale:Step(Finale.respawnAt+1); move(p, Finale.center); assert(Finale:Start(p))
	Finale.lastAttack[p] = -10; assert(Finale:Attack(p)); move(p, Locations.camps.Wilds)
	Finale:Step(Finale.lastTarget+11); assert(not Finale.active and Finale.hp == Journey.finale.maxHealth and next(Finale.contributors) == nil)
end)
check("saved campaign roundtrip retains every seal, checkpoint and completion", function()
	local saved = Schema.sanitize(profile, Definitions, h.require(h.shared.Synergies), h.require(h.shared.Areas))
	assert(saved.journey.complete and Journey.count(saved.journey.seals) == 8 and Journey.count(saved.journey.runes) == 24)
	assert(saved.journey.checkpoint == profile.journey.checkpoint and saved.discovered.SkyWings)
	saved.journey.seals.Wilds = nil; assert(profile.journey.seals.Wilds)
end)
check("journal constructs all tabs at phone, landscape and desktop sizes", function()
	h.game:GetService("Players").LocalPlayer = p; R.Instance.new("PlayerGui").Parent = p
	local Hud = h.require(h.controllers.HudController); local hud = Hud.new(h.remotes)
	local state = { profile = profile, threshold = 200, activeSynergies = {}, persistence = "StudioMemory", journey = Service:Snapshot(p) }
	hud:Update(state)
	for _, size in { R.Vector2.new(360,640), R.Vector2.new(667,375), R.Vector2.new(1440,900) } do
		hud:Resize(size); assert(hud.journal.panel.Size.X.Offset <= size.X-24 and hud.journal.panel.Size.Y.Offset <= size.Y-24)
		for _, tab in { "Jornada", "Mapa", "Corpo" } do hud.journal:Toggle(tab); assert(#hud.journal.rows > 0 and hud:IsModal()) end
	end
	local Nav = h.require(h.controllers.NavigationController); local nav = Nav.new(hud); hud.journal:Close(); nav:Step(); nav:Destroy()
end)
print("JOURNEY:", checks, "checks passed; complete server campaign simulated, engine movement remains unverified")
