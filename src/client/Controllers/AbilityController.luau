--!nonstrict
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Ability = {}
function Ability.new(remotes, isModal)
	local self = setmetatable({ remotes = remotes, mode = "None", state = nil, elapsed = 0, wasActive = false, isModal = isModal }, { __index = Ability })
	local function toggle(mode)
		if self.isModal() or UserInputService:GetFocusedTextBox() then return end
		self.mode = self.mode == mode and "None" or mode; self.wasActive = false; self:Send()
	end
	CAS:BindAction("AdaptGlide", function(_, input)
		if input == Enum.UserInputState.Begin then toggle("Glide") end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.G, Enum.KeyCode.ButtonX)
	CAS:BindAction("AdaptClimb", function(_, input)
		if input == Enum.UserInputState.Begin then toggle("Climb") end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.E, Enum.KeyCode.ButtonY)
	CAS:BindAction("AdaptAttack", function(_, input)
		if input == Enum.UserInputState.Begin and not self.isModal() and not UserInputService:GetFocusedTextBox() then remotes.Attack:FireServer() end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)
	CAS:SetTitle("AdaptGlide", "Planar"); CAS:SetTitle("AdaptClimb", "Escalar"); CAS:SetTitle("AdaptAttack", "Atacar")
	CAS:SetPosition("AdaptGlide", UDim2.new(1, -154, 1, -220))
	CAS:SetPosition("AdaptClimb", UDim2.new(1, -80, 1, -278))
	CAS:SetPosition("AdaptAttack", UDim2.new(1, -80, 1, -200))
	self.characterConnection = Players.LocalPlayer.CharacterAdded:Connect(function() self.mode = "None"; self.wasActive = false end)
	self.connection = RunService.Heartbeat:Connect(function(dt)
		self.elapsed += dt
		if self.elapsed < 0.12 then return end
		self.elapsed = 0
		local char = Players.LocalPlayer.Character
		local active = char and char:GetAttribute("AbilityMode")
		if active and active ~= "None" then self.wasActive = true end
		if self.isModal() or (self.wasActive and active == "None") then self.mode = "None"; self.wasActive = false end
		if self.mode ~= "None" or self.lastSent ~= "None" then self:Send() end
	end)
	CAS:BindActionAtPriority("AdaptModalMovement", function()
		return self.isModal() and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value+1, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1)
	return self
end
function Ability:Resize(viewport)
	self.viewport = viewport
	local size = viewport and viewport.Y < 450 and 52 or 62
	for i, name in { "AdaptGlide", "AdaptClimb", "AdaptAttack" } do
		CAS:SetPosition(name, UDim2.new(1, -225 + (i-1)*70, 1, -160))
		local button = CAS:GetButton(name); if button then button.Size = UDim2.fromOffset(size, size) end
	end
end
function Ability:Send()
	local char = Players.LocalPlayer.Character; local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local direction = humanoid and humanoid.MoveDirection or Vector3.zero
	self.remotes.Ability:FireServer(self.mode, direction); self.lastSent = self.mode
end
function Ability:Update(state)
	self.state = state
	local equipped = state.profile.equipped
	CAS:SetTitle("AdaptGlide", equipped.Back == "SkyWings" and "Subir" or "Planar")
	for _, pair in { { "AdaptGlide", equipped.Back ~= nil }, { "AdaptClimb", equipped.Arms ~= nil }, { "AdaptAttack", true } } do
		local button = CAS:GetButton(pair[1]); if button then button.Visible = pair[2]; button.Size = UDim2.fromOffset(62, 62) end
	end
	self:Resize(self.viewport)
	if (self.mode == "Glide" and not equipped.Back) or (self.mode == "Climb" and not equipped.Arms) then self.mode = "None"; self:Send() end
end
function Ability:Destroy()
	self.connection:Disconnect(); self.characterConnection:Disconnect()
	for _, action in { "AdaptGlide", "AdaptClimb", "AdaptAttack", "AdaptModalMovement" } do CAS:UnbindAction(action) end
end
return Ability
