--!nonstrict
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Feedback = {}
function Feedback.new(hud)
	local self = setmetatable({ hud = hud, settings = { sound = true, reducedMotion = false } }, { __index = Feedback })
	self.waypoint = Instance.new("BillboardGui"); self.waypoint.Name = "FirstEssenceWaypoint"; self.waypoint.Size = UDim2.fromOffset(150, 44); self.waypoint.StudsOffset = Vector3.new(0, 3.5, 0); self.waypoint.AlwaysOnTop = true; self.waypoint.Parent = hud.screen
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1); label.BackgroundColor3 = Color3.fromRGB(22, 38, 43); label.TextColor3 = Color3.fromRGB(149, 255, 218); label.FontFace = Font.fromEnum(Enum.Font.GothamBold); label.TextSize = 15; label.Text = "↓  COLETE"; label.Parent = self.waypoint
	return self
end
function Feedback:Update(state)
	self.settings = state.profile.settings; self.level = state.profile.level
	self.waypoint.Enabled = self.level == 0 and not state.pending
end
function Feedback:Sound(evolution)
	if not self.settings.sound then return end
	local sound = Instance.new("Sound"); sound.SoundId = "rbxasset://sounds/volume_slider.ogg"; sound.Volume = 0.2; sound.PlaybackSpeed = evolution and 0.8 or 1.4; sound.Parent = SoundService
	sound:Play(); Debris:AddItem(sound, 3)
end
function Feedback:Pulse(position)
	if self.settings.reducedMotion then return end
	local part = Instance.new("Part"); part.Name = "LocalEssencePulse"; part.Shape = Enum.PartType.Ball; part.Size = Vector3.one; part.Position = position; part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
	part.Material = Enum.Material.Neon; part.Color = Color3.fromRGB(130, 255, 212); part.Transparency = 0.35; part.Parent = workspace
	TweenService:Create(part, TweenInfo.new(0.4), { Size = Vector3.one * 5, Transparency = 1 }):Play(); Debris:AddItem(part, 0.5)
end
function Feedback:Event(kind, value, extra)
	if kind == "Essence" then self:Sound(false); if typeof(extra) == "Vector3" then self:Pulse(extra) end
	elseif kind == "Evolution" then self:Sound(true); self.hud:Message("ADAPTAÇÃO DESCOBERTA  •  " .. value)
	elseif kind == "Synergy" then self:Sound(true); self.hud:Message("SYNERGY SECRETA  •  " .. value)
	elseif kind == "Guardian" then self:Sound(true); self.hud:Message("Guardian vencido!  +" .. value .. " energia")
	elseif kind == "Area" then self.hud:Message(value .. "  •  " .. extra)
	elseif kind == "Hurt" then self.hud:Message("Impacto! Afaste-se do círculo vermelho antes do próximo ataque.")
	elseif kind == "Hit" then self:Sound(false)
	elseif kind == "Info" then self.hud:Message(value) end
end
function Feedback:Step()
	if self.level ~= 0 then return end
	local char = Players.LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("ADAPTWorld"); local essence = world and world:FindFirstChild("Essence")
	if not root or not essence then return end
	local nearest; local distance = math.huge
	for _, orb in essence:GetChildren() do
		if orb:GetAttribute("EssenceKind") == "Dew" and orb:GetAttribute("Available") then
			local d = (root.Position - orb.Position).Magnitude
			if d < distance then distance = d; nearest = orb end
		end
	end
	self.waypoint.Adornee = nearest
end
return Feedback
