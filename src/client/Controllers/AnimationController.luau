--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Motion = require(Shared.CreatureMotion)
local Animation = {}
function Animation.new()
	local self = setmetatable({rigs={}, scan=0, time=1, reduced=false}, {__index=Animation})
	-- Transform is applied immediately before physics, after Animator evaluation.
	self.connection = RunService.PreSimulation:Connect(function(dt) self:Step(dt) end)
	return self
end
function Animation:Bind(character, appearance)
	local rig = {character=character, appearance=appearance, joints={}, eyes={}, poses={}, phase=0, attackSequence=character:GetAttribute("AttackSequence")}
	for _, item in character:GetDescendants() do
		if item:IsA("Motor6D") then rig.joints[item.Name]=item
		elseif item:IsA("SpecialMesh") and item:GetAttribute("Blink") then table.insert(rig.eyes,item) end
	end
	self.rigs[character]=rig
	return rig
end
function Animation:Attack()
	if self.time-(self.lastAttack or -10)<.55 then return end
	self.lastAttack=self.time
	local rig=self.rigs[Players.LocalPlayer.Character]; if rig then rig.attacked=self.time end
end
function Animation:Step(dt)
	dt=math.min(dt,.1); self.time+=dt; self.scan-=dt
	if self.scan<=0 then
		self.scan=.4
		local present={}
		for _, player in Players:GetPlayers() do
			local char=player.Character; local appearance=char and char:FindFirstChild("Appearance")
			if appearance then
				present[char]=true
				if not self.rigs[char] or self.rigs[char].appearance~=appearance then self:Bind(char,appearance) end
			end
		end
		for char in self.rigs do if not present[char] then self.rigs[char]=nil end end
	end
	local camera=workspace.CurrentCamera; if not camera then return end
	for char,rig in self.rigs do
		local root=char:FindFirstChild("HumanoidRootPart"); local humanoid=char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health<=0 or not char.Parent then continue end
		local distance=(root.CFrame.Position-camera.CFrame.Position).Magnitude
		if distance>180 then continue end
		local velocity=root.AssemblyLinearVelocity
		local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
		rig.phase+=dt*math.clamp(speed*.5,0,14)
		local state=humanoid:GetState()
		local air=state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall
		if rig.air and not air then rig.landed=self.time end; rig.air=air
		local sequence=char:GetAttribute("AttackSequence")
		if sequence~=rig.attackSequence then
			rig.attackSequence=sequence
			if self.time-(rig.attacked or -10)>.3 then rig.attacked=self.time end
		end
		local poses,blink=Motion.sample({speed=speed,vertical=velocity.Y,air=air,swim=state==Enum.HumanoidStateType.Swimming,
			mode=char:GetAttribute("AbilityMode"),attackAge=rig.attacked and self.time-rig.attacked,landAge=rig.landed and self.time-rig.landed},self.time,rig.phase,self.reduced)
		local alpha=1-math.exp(-dt*14)
		for name,joint in rig.joints do
			if joint.Parent then
				rig.poses[name]=(rig.poses[name] or CFrame.identity):Lerp(poses[name] or CFrame.identity,alpha)
				joint.Transform=rig.poses[name]
			end
		end
		for _,mesh in rig.eyes do if mesh.Parent then mesh.Scale=Vector3.new(1,blink,1); mesh.Offset=(mesh:GetAttribute("BlinkOffset") or Vector3.zero)*(1-blink) end end
	end
end
function Animation:Update(state) self.reduced=state.profile.settings.reducedMotion end
function Animation:Destroy()
	self.connection:Disconnect()
	for _,rig in self.rigs do
		for _,joint in rig.joints do if joint.Parent then joint.Transform=CFrame.identity end end
		for _,mesh in rig.eyes do if mesh.Parent then mesh.Scale=Vector3.one; mesh.Offset=Vector3.zero end end
	end
	self.rigs={}
end
return Animation
