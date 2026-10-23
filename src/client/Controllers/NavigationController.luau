--!nonstrict
local Players = game:GetService("Players")
local Gui = require(script.Parent.Gui)
local Navigation = {}
function Navigation.new(hud)
	local self = setmetatable({ hud = hud }, { __index = Navigation })
	self.anchor = Instance.new("Part"); self.anchor.Name = "LocalJourneyWaypoint"; self.anchor.Anchored = true; self.anchor.CanCollide = false; self.anchor.CanQuery = false; self.anchor.CanTouch = false; self.anchor.Transparency = 1; self.anchor.Size = Vector3.one; self.anchor.Parent = workspace
	self.billboard = Instance.new("BillboardGui"); self.billboard.Size = UDim2.fromOffset(220, 60); self.billboard.AlwaysOnTop = true; self.billboard.StudsOffset = Vector3.new(0, 5, 0); self.billboard.Adornee = self.anchor; self.billboard.Parent = hud.screen
	self.text = Gui.label(self.billboard, "", UDim2.fromScale(1, 1), UDim2.new(), 14, Gui.Theme.mint); self.text.TextXAlignment = Enum.TextXAlignment.Center; self.text.TextStrokeTransparency = .3
	self.distance = Gui.label(hud.guide, "", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 1, -21), 12, Gui.Theme.mint)
	hud.guideText.Size = UDim2.new(1, -28, 1, -30); hud.guideText.Position = UDim2.fromOffset(14, 3)
	return self
end
function Navigation:Step()
	local target = self.hud.journal:Target(); local char = Players.LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
	local visible = target and target.position and root and not self.hud:IsModal()
	self.billboard.Enabled = visible == true; self.distance.Visible = visible == true
	if not visible then return end
	local point = Vector3.new(table.unpack(target.position)); self.anchor.CFrame = CFrame.new(point)
	local delta = point - root.CFrame.Position; local distance = math.floor(delta.Magnitude)
	local compass = math.abs(delta.X) > math.abs(delta.Z) and (delta.X > 0 and "LESTE" or "OESTE") or (delta.Z > 0 and "SUL" or "NORTE")
	self.text.Text = target.title .. "\n" .. distance .. " studs"
	self.distance.Text = compass .. " • " .. distance .. " studs" .. (delta.Y > 25 and " • acima" or delta.Y < -25 and " • abaixo" or "") .. " • mapa [M]"
	if self.hud.journal.tracking then self.hud.guideText.Text = "Destino marcado • " .. target.title end
end
function Navigation:Destroy() self.anchor:Destroy(); self.billboard:Destroy(); self.distance:Destroy() end
return Navigation
