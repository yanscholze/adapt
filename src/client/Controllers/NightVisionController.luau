--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Adaptations = require(Shared.Adaptations)
local Progression = require(Shared.Progression)
local Night = {}
function Night.new()
	local self = setmetatable({ enabled = false, connections = {}, lamp = nil }, { __index = Night })
	local function track(part)
		if not part:IsA("BasePart") then return end
		self.connections[part] = part:GetAttributeChangedSignal("Available"):Connect(function() self:Reveal(part) end)
		self:Reveal(part)
	end
	for _, part in CollectionService:GetTagged("NightVisionRevealable") do track(part) end
	self.added = CollectionService:GetInstanceAddedSignal("NightVisionRevealable"):Connect(track)
	self.removed = CollectionService:GetInstanceRemovedSignal("NightVisionRevealable"):Connect(function(part)
		if self.connections[part] then self.connections[part]:Disconnect(); self.connections[part] = nil end
	end)
	self.character = Players.LocalPlayer.CharacterAdded:Connect(function(char)
		task.spawn(function() local root = char:WaitForChild("HumanoidRootPart", 10); if root and char == Players.LocalPlayer.Character then self:AttachLamp(root) end end)
	end)
	return self
end
function Night:AttachLamp(root)
	if self.lamp then self.lamp:Destroy() end
	self.lamp = Instance.new("PointLight"); self.lamp.Name = "LocalNightLamp"; self.lamp.Color = Color3.fromRGB(145, 255, 220); self.lamp.Range = 30; self.lamp.Brightness = 2; self.lamp.Enabled = self.enabled; self.lamp.Parent = root
end
function Night:Reveal(part)
	if not part.Parent then return end
	local visible = self.enabled and part:GetAttribute("Available") ~= false
	-- Server starts hidden. Changing Transparency here affects this client only.
	part.Transparency = visible and 0.12 or 1
	local light = part:FindFirstChild("LocalRevealLight")
	if visible and not light then light = Instance.new("PointLight"); light.Name = "LocalRevealLight"; light.Color = part.Color; light.Range = 7; light.Brightness = 0.5; light.Parent = part end
	if light then light.Enabled = visible end
end
function Night:Update(state)
	self.enabled = Progression.hasAbility(state.profile.equipped, Adaptations, "NightVision") ~= nil
	local char = Players.LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and (not self.lamp or self.lamp.Parent ~= root) then self:AttachLamp(root) end
	if self.lamp then self.lamp.Enabled = self.enabled end
	for part in self.connections do self:Reveal(part) end
end
function Night:Destroy()
	self.added:Disconnect(); self.removed:Disconnect(); self.character:Disconnect()
	for _, connection in self.connections do connection:Disconnect() end
	if self.lamp then self.lamp:Destroy() end
end
return Night
