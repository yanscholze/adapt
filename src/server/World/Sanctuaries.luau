--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Journey = require(Shared.Journey)
local Locations = require(Shared.JourneyLocations)
local CollectionService = game:GetService("CollectionService")
local Sanctuaries = {}
local function part(parent, name, size, pos, color, material, collide)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = CFrame.new(pos); p.Color = color
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = collide == true; p.CanTouch = false
	p.Material = material or Enum.Material.Slate; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent; return p
end
local function label(partObject, text, color)
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(230, 58); gui.StudsOffset = Vector3.new(0, 5, 0); gui.MaxDistance = 100; gui.Parent = partObject
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Text = text; t.TextWrapped = true; t.FontFace = Font.fromEnum(Enum.Font.GothamBold); t.TextSize = 15; t.TextColor3 = color; t.TextStrokeTransparency = .4; t.Parent = gui
end
local function prompt(partObject, action, target)
	local p = Instance.new("ProximityPrompt"); p.Name = "Interact"; p.ActionText = action; p.ObjectText = target; p.KeyboardKeyCode = Enum.KeyCode.R; p.GamepadKeyCode = Enum.KeyCode.ButtonB; p.HoldDuration = .35; p.MaxActivationDistance = 12; p.RequiresLineOfSight = false; p.Parent = partObject
end
function Sanctuaries:Build(world)
	local old = world.model:FindFirstChild("Journey")
	if old and old:GetAttribute("Version") == Journey.version then return old end
	if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = "Journey"; folder.Parent = world.model; folder:SetAttribute("Version", Journey.version)
	for _, area in Journey.order do
		local region = Journey.regions[area]; local color = Color3.fromRGB(table.unpack(region.color)); local pos = Vector3.new(table.unpack(Locations.camps[area]))
		local vegetation = world.model:FindFirstChild("Vegetation")
		if vegetation then
			for _, tree in vegetation:GetDescendants() do
				local trunk = tree:IsA("Model") and tree:FindFirstChild("Trunk")
				if trunk and Vector3.new(trunk.CFrame.Position.X-pos.X,0,trunk.CFrame.Position.Z-pos.Z).Magnitude < 19 then tree:Destroy() end
			end
		end
		local m = Instance.new("Model"); m.Name = area; m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic; m.Parent = folder
		local floorY = pos.Y - 4
		part(m, "SanctuaryFloor", Vector3.new(26, 1, 22), Vector3.new(pos.X, floorY, pos.Z), Color3.fromRGB(100, 124, 124), Enum.Material.Slate, true)
		-- Four shallow steps let the original terrain meet each raised refuge.
		for i = 1, 4 do part(m, "EntryStep", Vector3.new(14, 1, 3.5), Vector3.new(pos.X, floorY - i * .65, pos.Z + 10 + i * 2.8), Color3.fromRGB(122, 147, 139), Enum.Material.Slate, true) end
		local camp = part(m, "Camp", Vector3.new(2, 3, 2), pos + Vector3.new(-7, -1.5, 0), color, Enum.Material.Neon, false)
		camp.Shape = Enum.PartType.Ball; camp:SetAttribute("Camp", area); prompt(camp, "Descansar", "Refúgio • " .. region.name)
		CollectionService:AddTag(camp, "JourneyObject")
		label(camp, "REFÚGIO\nCura • troca de corpo • viagem", color)
		local shrine = part(m, "Shrine", Vector3.new(3, 5, 3), pos + Vector3.new(7, -.5, 0), color, Enum.Material.Neon, false)
		shrine.CFrame *= CFrame.Angles(0, math.pi/4, .15); shrine:SetAttribute("Shrine", area); prompt(shrine, "Restaurar", region.name)
		CollectionService:AddTag(shrine, "JourneyObject")
		for side = -1, 1, 2 do part(m, "ShrinePillar", Vector3.new(2, 8, 2), pos + Vector3.new(7 + side * 4, 0, 0), Color3.fromRGB(78, 88, 108), Enum.Material.Slate, true) end
		part(m, "ShrineLintel", Vector3.new(12, 2, 3), pos + Vector3.new(7, 4, 0), color, Enum.Material.Slate, true)
		local light = Instance.new("PointLight"); light.Color = color; light.Range = 16; light.Brightness = .6; light.Parent = camp
	end
	for id, data in Locations.runes do
		local color = Color3.fromRGB(table.unpack(Journey.regions[data.region].color)); local pos = Vector3.new(table.unpack(data.position))
		local m = Instance.new("Model"); m.Name = id; m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic; m.Parent = folder
		local rune = part(m, "Memory", Vector3.new(1.8, 3, 1.8), pos, color, Enum.Material.Neon, false); rune.CFrame *= CFrame.Angles(0, math.pi/4, .12)
		rune:SetAttribute("Memory", id); rune:SetAttribute("Region", data.region); prompt(rune, "Lembrar", "Memória • " .. Journey.regions[data.region].name)
		CollectionService:AddTag(rune, "JourneyObject")
		label(rune, "MEMÓRIA", color)
	end
	local arena = Instance.new("Model"); arena.Name = "ZenithArena"; arena.ModelStreamingMode = Enum.ModelStreamingMode.Atomic; arena.Parent = folder
	local center = Vector3.new(table.unpack(Journey.finale.position))
	local floor = part(arena, "ArenaFloor", Vector3.new(78, 2, 78), center - Vector3.new(0, 5, 0), Color3.fromRGB(92, 100, 135), Enum.Material.Slate, true)
	floor.Shape = Enum.PartType.Cylinder; floor.Size = Vector3.new(2, 78, 78); floor.CFrame *= CFrame.Angles(0, 0, math.pi/2)
	for i = 1, 12 do
		local a = math.pi * 2 * i / 12
		part(arena, "RimGlyph", Vector3.new(3, .2, 4), center + Vector3.new(math.cos(a)*35, -3.8, math.sin(a)*35), Color3.fromRGB(200, 180, 255), Enum.Material.Neon, false)
	end
	return folder
end
return Sanctuaries
