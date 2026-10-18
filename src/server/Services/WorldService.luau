--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Areas = require(Shared.Areas)
local Definition = require(Shared.WorldDefinition)
local Archipelago = require(script.Parent.Parent.World.Archipelago)
local Samples = require(Shared.WorldSamples)
local World = {}
local colors = { grass = Color3.fromRGB(82, 153, 129), rock = Color3.fromRGB(76, 83, 108), sand = Color3.fromRGB(229, 207, 164), gold = Color3.fromRGB(255, 194, 91) }
local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = CFrame.new(position); p.Anchored = true
	p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent; return p
end
local function sign(parent, text, position, color)
	local post = part(parent, "Sign", Vector3.new(0.4, 5, 0.4), position, colors.rock)
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(280, 68); gui.StudsOffset = Vector3.new(0, 4, 0); gui.MaxDistance = 140; gui.Parent = post
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundColor3 = colors.rock; label.BackgroundTransparency = 0.12
	label.Text = text; label.TextColor3 = color or Color3.new(1, 1, 1); label.FontFace = Font.fromEnum(Enum.Font.GothamBold); label.TextSize = 16; label.TextWrapped = true; label.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = label
end
function World:Init(force)
	local old = workspace:FindFirstChild("ADAPTWorld")
	if old and old:GetAttribute("WorldVersion") == Definition.version and not force then
		self.model = old; self.core = old:FindFirstChild("Core"); self:Metadata(); return
	end
	if old then old:Destroy() end
	self.model = Instance.new("Model"); self.model.Name = "ADAPTWorld"; self.model.Parent = workspace
	self.essenceSpawns = {}; self.areaVolumes = {}; self.areaOrder = {}
	local m = self.model
	part(m, "Wilds", Vector3.new(220, 8, 180), Vector3.new(0, -4, 10), colors.grass, Enum.Material.Grass)
	part(m, "Arrival", Vector3.new(16, 0.2, 16), Vector3.new(0, 0.1, 20), colors.sand)
	local spawn = Instance.new("SpawnLocation"); spawn.Name = "WildsSpawn"; spawn.Size = Vector3.new(8, 0.3, 8); spawn.CFrame = CFrame.new(0, 0.35, 20); spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = true; spawn.Duration = 0; spawn.Parent = m
	sign(m, "ADAPT!\nToque os cristais • descubra seu próximo corpo", Vector3.new(0, 2.5, 7))
	for i = 1, 8 do
		local x = -18 + i * 5
		part(m, "Trail", Vector3.new(3.8, 0.15, 4), Vector3.new(x, 0.15, -4), colors.sand)
	end
	for i, pos in { Vector3.new(-23, 1.5, 9), Vector3.new(22, 2, 25), Vector3.new(-35, 1.5, -12), Vector3.new(40, 2, 54) } do
		local stone = part(m, "Pebble" .. i, Vector3.new(6, pos.Y * 2, 5), pos, colors.rock); stone.Shape = Enum.PartType.Ball
	end
	-- Claws route. Only this face has the climb tag; adjacent walls remain ordinary rock.
	part(m, "CliffMass", Vector3.new(38, 44, 50), Vector3.new(70, 22, 35), colors.rock, Enum.Material.Slate)
	part(m, "CliffMeadow", Vector3.new(38, 1, 50), Vector3.new(70, 44.5, 35), colors.grass, Enum.Material.Grass)
	local climb = part(m, "ClimbFace", Vector3.new(13, 44, 0.5), Vector3.new(70, 22, 9.7), Color3.fromRGB(123, 102, 80), Enum.Material.Rock)
	CollectionService:AddTag(climb, "Climbable")
	for y = 4, 40, 6 do
		local mark = part(m, "GripMark", Vector3.new(5, 0.3, 0.2), Vector3.new(70, y, 9.35), colors.gold, Enum.Material.Neon)
		mark.CanCollide = false; mark.CanQuery = false
	end
	sign(m, "CLIFF\nGrip Claws • aproxime-se e use Escalar", Vector3.new(65, 2.5, -2), colors.gold)
	-- Public ramp gives Wings-first players independent access to a launch point.
	local from = Vector3.new(-63, 1, -65); local to = Vector3.new(28, 63, -65)
	local ramp = part(m, "SkyRamp", Vector3.new(12, 2, (to - from).Magnitude), (from + to) / 2, colors.rock, Enum.Material.Slate)
	ramp.CFrame = CFrame.lookAt((from + to) / 2, to)
	part(m, "LaunchDeck", Vector3.new(20, 2, 22), Vector3.new(31, 62.5, -65), colors.grass)
	sign(m, "ROTA DO CÉU\nSuba a rampa • salte • use Planar", Vector3.new(-58, 2.5, -53), Color3.fromRGB(170, 190, 255))
	sign(m, "SKY ISLAND →\nSalte e abra as asas", Vector3.new(36, 66, -65))
	part(m, "SkyIsland", Vector3.new(32, 7, 32), Vector3.new(118, 32, -65), colors.rock, Enum.Material.Slate)
	part(m, "SkyTurf", Vector3.new(32, 1, 32), Vector3.new(118, 36, -65), colors.grass, Enum.Material.Grass)
	local underside = part(m, "SkyCrystal", Vector3.new(20, 22, 20), Vector3.new(118, 19, -65), Color3.fromRGB(138, 118, 187)); underside.Shape = Enum.PartType.Ball
	sign(m, "SKY ISLAND\nAsas levam a novas possibilidades", Vector3.new(118, 39, -65))
	-- A lightproof cave shell, with an open entrance on the south side.
	local caveColor = Color3.fromRGB(40, 43, 65)
	part(m, "CaveBack", Vector3.new(44, 22, 3), Vector3.new(-64, 11, 73), caveColor, Enum.Material.Slate)
	part(m, "CaveLeft", Vector3.new(3, 22, 43), Vector3.new(-86, 11, 53), caveColor, Enum.Material.Slate)
	part(m, "CaveRight", Vector3.new(3, 22, 43), Vector3.new(-42, 11, 53), caveColor, Enum.Material.Slate)
	part(m, "CaveRoof", Vector3.new(47, 3, 45), Vector3.new(-64, 23, 53), caveColor, Enum.Material.Slate)
	part(m, "CaveEntranceLeft", Vector3.new(13, 20, 3), Vector3.new(-79, 10, 31), caveColor)
	part(m, "CaveEntranceRight", Vector3.new(13, 20, 3), Vector3.new(-49, 10, 31), caveColor)
	sign(m, "CAVE\nAlguma coisa brilha além da escuridão…", Vector3.new(-64, 2.5, 23), Color3.fromRGB(138, 255, 210))
	for i = 1, 5 do
		local hidden = part(m, "HiddenGlyph", Vector3.new(2, 0.15, 2), Vector3.new(-64, 0.25, 39 + i * 5), Color3.fromRGB(101, 255, 205), Enum.Material.Neon)
		hidden.Transparency = 1; hidden.CanCollide = false; CollectionService:AddTag(hidden, "NightVisionRevealable")
	end
	-- Guardian is on a short, readable route from the safe spawn.
	part(m, "GuardianArena", Vector3.new(30, 0.3, 26), Vector3.new(20, 0.2, 70), Color3.fromRGB(111, 105, 139))
	self.guardianPosition = Vector3.new(20, 4.5, 70)
	sign(m, "GUARDIAN\nEntre no círculo • Ataque [F] • saia do aviso vermelho", Vector3.new(20, 2.5, 50), Color3.fromRGB(255, 160, 177))
	local safe = part(m, "SafeRing", Vector3.new(28, 0.12, 28), Vector3.new(0, 0.3, 20), Color3.fromRGB(176, 242, 223)); safe.Transparency = 0.55; safe.CanCollide = false
	Lighting.GlobalShadows = true; Lighting.EnvironmentDiffuseScale = 0.4
	if not Lighting:FindFirstChild("ArchipelagoAir") then
		local air = Instance.new("Atmosphere"); air.Name = "ArchipelagoAir"; air.Density = .16; air.Offset = .08; air.Haze = .7; air.Glare = .12; air.Color = Color3.fromRGB(209,225,228); air.Decay = Color3.fromRGB(132,158,170); air.Parent = Lighting
		local bloom = Instance.new("BloomEffect"); bloom.Name = "CrystalBloom"; bloom.Intensity = .13; bloom.Size = 20; bloom.Threshold = 1.5; bloom.Parent = Lighting
		local sun = Instance.new("SunRaysEffect"); sun.Name = "AfternoonRays"; sun.Intensity = .04; sun.Spread = .75; sun.Parent = Lighting
	end
	-- Keep the original routes intact inside a small atomic spawn basin.
	local core = Instance.new("Model"); core.Name = "Core"; core.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, item in self.model:GetChildren() do item.Parent = core end
	core.Parent = self.model; self.core = core
	core.Wilds.Transparency = 1
	self:Metadata(); Archipelago:Build(self)
	self.model:SetAttribute("WorldVersion", Definition.version)
	self.model:SetAttribute("Generated", true)
end
function World:Metadata()
	self.essenceSpawns = {}; self.areaVolumes = {}; self.areaOrder = {}
	self.guardianPosition = Vector3.new(20, 4.5, 70)
	-- Fixed spawn anchors are cheap, deterministic, and easy to move in one place.
	for i, pos in {
		Vector3.new(-5, 2.2, 18), Vector3.new(-8, 2.2, 12), Vector3.new(-7, 2.2, 4), Vector3.new(0, 2.2, -2), Vector3.new(8, 2.2, -2),
		Vector3.new(18, 2.2, -2), Vector3.new(29, 2.2, 0), Vector3.new(39, 2.2, 4), Vector3.new(49, 2.2, 8),
		Vector3.new(-20, 2.2, 25), Vector3.new(-33, 2.2, 27), Vector3.new(-48, 2.2, 25),
		Vector3.new(68, 47, 23), Vector3.new(76, 47, 36), Vector3.new(65, 47, 48),
		Vector3.new(113, 39, -60), Vector3.new(123, 39, -71), Vector3.new(-61, 2.2, -56),
	} do table.insert(self.essenceSpawns, { id = "dew_" .. i, kind = "Dew", position = pos }) end
	for i, pos in { Vector3.new(-72, 2.2, 57), Vector3.new(-57, 2.2, 65), Vector3.new(-65, 2.2, 47) } do
		table.insert(self.essenceSpawns, { id = "lumen_" .. i, kind = "Lumen", position = pos })
	end
	for id, data in Areas do
		self.areaVolumes[id] = { center = Vector3.new(table.unpack(data.center)), half = Vector3.new(table.unpack(data.size)) / 2 }
		table.insert(self.areaOrder, id)
	end
	table.sort(self.areaOrder, function(a, b) return Areas[a].priority > Areas[b].priority or (Areas[a].priority == Areas[b].priority and a < b) end)
	for id, position in Samples.safeSpawns or {} do if Areas[id] then Areas[id].spawn = position end end
	Archipelago:Metadata(self)
end
function World:AreaAt(position)
	for _, id in self.areaOrder do
		local v = self.areaVolumes[id]; local d = position - v.center
		if math.abs(d.X) <= v.half.X and math.abs(d.Y) <= v.half.Y and math.abs(d.Z) <= v.half.Z then
			if Areas[id].floating then
				for _, f in Definition.floating do
					local c = Vector3.new(table.unpack(f.center)); local r = f.radius
					if math.abs(position.X-c.X)<r[1]+16 and math.abs(position.Z-c.Z)<r[3]+16 and math.abs(position.Y-c.Y)<r[2]+20 then return id end
				end
			else return id end
		end
	end
	return nil
end
return World
