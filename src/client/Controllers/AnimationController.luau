--!nonstrict
-- Procedural limb motion uses only our rig; no uploaded animation assets.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Animation = {}
function Animation.new()
	local self = setmetatable({ rigs = {}, scan = 0, reduced = false }, { __index = Animation })
	self.connection = RunService.RenderStepped:Connect(function(dt)
		self.scan -= dt
		if self.scan <= 0 then
			self.scan = 0.5; self.rigs = {}
			for _, player in Players:GetPlayers() do
				local char = player.Character; local torso = char and char:FindFirstChild("Torso")
				if torso and char:FindFirstChild("Appearance") then table.insert(self.rigs, char) end
			end
		end
		local camera = workspace.CurrentCamera
		for _, char in self.rigs do
			local root = char:FindFirstChild("HumanoidRootPart"); local torso = char:FindFirstChild("Torso")
			if not root or not torso or not camera or (root.Position - camera.CFrame.Position).Magnitude > 160 then continue end
			local velocity = root.AssemblyLinearVelocity; local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			local mode = char:GetAttribute("AbilityMode")
			local swing = math.sin(os.clock() * 10) * math.min(speed / 20, 1) * (self.reduced and 0 or 0.45)
			for _, side in { -1, 1 } do
				local name = side == -1 and "Left" or "Right"
				local hip = torso:FindFirstChild(name .. " Hip"); local shoulder = torso:FindFirstChild(name .. " Shoulder")
				if hip then hip.Transform = CFrame.Angles(swing * side, 0, 0) end
				if shoulder then shoulder.Transform = CFrame.Angles(mode == "Climb" and -1.6 + swing * side or -swing * side, 0, mode == "Glide" and side * -0.5 or 0) end
			end
		end
	end)
	return self
end
function Animation:Update(state) self.reduced = state.profile.settings.reducedMotion end
function Animation:Destroy() self.connection:Disconnect(); self.rigs = {} end
return Animation
