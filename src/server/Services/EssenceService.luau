--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Definitions = require(Shared.Essences)
local Adaptations = require(Shared.Adaptations)
local Progression = require(Shared.Progression)
local Essence = {}
function Essence:Init(world, players, remotes, canInteract)
	self.players = players; self.remotes = remotes; self.canInteract = canInteract; self.nodes = {}
	local old = world.model:FindFirstChild("Essence"); if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = "Essence"; folder.Parent = world.model
	for _, spawn in world.essenceSpawns do
		local definition = Definitions[spawn.kind]
		local orb = Instance.new("Part"); orb.Name = spawn.id; orb.Shape = Enum.PartType.Ball; orb.Size = Vector3.one * definition.visual.size
		orb.CFrame = CFrame.new(spawn.position); orb.Anchored = true; orb.CanCollide = false; orb.CanTouch = false; orb.CanQuery = false
		orb.Material = Enum.Material.Neon; orb.Color = Color3.fromRGB(table.unpack(definition.visual.color)); orb:SetAttribute("EssenceKind", spawn.kind); orb:SetAttribute("Available", true)
		orb.Transparency = definition.spawn.requiredAbility and 1 or 0; orb.Parent = folder
		if definition.spawn.requiredAbility then CollectionService:AddTag(orb, "NightVisionRevealable") else
			local light = Instance.new("PointLight"); light.Color = orb.Color; light.Brightness = 0.6; light.Range = 7; light.Parent = orb
		end
		table.insert(self.nodes, { part = orb, definition = definition, readyAt = 0 })
	end
end
function Essence:Step(now)
	for _, node in self.nodes do
		local orb = node.part
		if node.readyAt > 0 and now >= node.readyAt then
			node.readyAt = 0; orb:SetAttribute("Available", true)
			orb.Transparency = node.definition.spawn.requiredAbility and 1 or 0
			local light = orb:FindFirstChildOfClass("PointLight"); if light then light.Enabled = true end
		end
		if node.readyAt == 0 then
			for player, r in self.players.records do
				if r.pending then continue end
				local character = player.Character; local root = character and character:FindFirstChild("HumanoidRootPart"); local h = character and character:FindFirstChildOfClass("Humanoid")
				if not root or not h or h.Health <= 0 or not self.canInteract(player) then continue end
				if (root.CFrame.Position - orb.CFrame.Position).Magnitude > Config.CollectRadius then continue end
				local needed = node.definition.spawn.requiredAbility
				if needed and not Progression.hasAbility(r.profile.equipped, Adaptations, needed) then continue end
				-- Commit availability before awarding; one shared orb has exactly one winner.
				node.readyAt = now + node.definition.spawn.respawnSeconds; orb:SetAttribute("Available", false); orb.Transparency = 1
				local light = orb:FindFirstChildOfClass("PointLight"); if light then light.Enabled = false end
				self.players:Energy(player, node.definition.energyValue, "Essence")
				self.remotes.Feedback:FireClient(player, "Essence", node.definition.energyValue, orb.CFrame.Position)
				break
			end
		end
	end
end
return Essence
