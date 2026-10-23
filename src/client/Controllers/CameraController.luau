--!nonstrict
local Players = game:GetService("Players")
local Camera = {}
function Camera.new()
	local self = setmetatable({ player = Players.LocalPlayer, characterConnections = {} }, { __index = Camera })
	self.added = self.player.CharacterAdded:Connect(function(character) self:Bind(character) end)
	self.changed = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() self:Refresh() end)
	self:Bind(self.player.Character)
	return self
end
function Camera:Refresh()
	local character = self.character
	local camera = workspace.CurrentCamera
	if not character or character ~= self.player.Character or not character.Parent or not camera then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end
	if self.boundCamera == camera and self.boundCharacter == character then return end
	-- Set a playable starting view once; Roblox's native camera then owns orbit,
	-- zoom, collision and input. Never carry the editor's aerial view into Play.
	local target = root.CFrame.Position + Vector3.new(0, 1.5, 0)
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	camera.Focus = CFrame.new(target)
	camera.CFrame = CFrame.lookAt(target + Vector3.new(0, 7, 16), target)
	self.boundCamera = camera; self.boundCharacter = character
end
function Camera:Bind(character)
	for _, connection in self.characterConnections do connection:Disconnect() end
	self.characterConnections = {}; self.character = character
	self.boundCamera = nil; self.boundCharacter = nil
	if character then
		-- CharacterAdded may precede parenting and replication of the rig parts.
		table.insert(self.characterConnections, character.ChildAdded:Connect(function() self:Refresh() end))
		table.insert(self.characterConnections, character.AncestryChanged:Connect(function() self:Refresh() end))
	end
	self:Refresh()
end
function Camera:Destroy()
	self.added:Disconnect(); self.changed:Disconnect()
	for _, connection in self.characterConnections do connection:Disconnect() end
end
return Camera
