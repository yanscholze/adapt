--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Definitions = require(Shared.Adaptations)
local Synergies = require(Shared.Synergies)
local Areas = require(Shared.Areas)
local Gui = require(script.Parent.Gui)
local Codex = {}
function Codex.new(root, remotes)
	local self = setmetatable({}, { __index = Codex }); self.remotes = remotes
	self.scrim, self.panel = Gui.modal(root, "Seu Codex")
	Gui.button(self.panel, "Fechar", UDim2.fromOffset(76, 44), UDim2.new(1, -92, 0, 12), function() self.scrim.Visible = false end)
	self.list = Gui.new("ScrollingFrame", { Position = UDim2.fromOffset(20, 70), Size = UDim2.new(1, -40, 1, -150), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, self.panel)
	Gui.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, self.list)
	self.sound = Gui.button(self.panel, "Som: ligado", UDim2.new(0.48, -12, 0, 48), UDim2.new(0, 20, 1, -64), function() if self.state then remotes.Setting:FireServer("sound", not self.state.profile.settings.sound) end end)
	self.motion = Gui.button(self.panel, "Movimento: normal", UDim2.new(0.52, -28, 0, 48), UDim2.new(0.48, 8, 1, -64), function() if self.state then remotes.Setting:FireServer("reducedMotion", not self.state.profile.settings.reducedMotion) end end)
	return self
end
function Codex:Toggle()
	self.scrim.Visible = not self.scrim.Visible
	if self.scrim.Visible then self.remotes.Codex:FireServer() end
end
function Codex:Resize(viewport) self.panel.Size = UDim2.fromOffset(math.min(720, viewport.X - 24), math.min(620, viewport.Y - 24)) end
function Codex:Update(state)
	self.state = state
	self.sound.Text = state.profile.settings.sound and "Som: ligado" or "Som: desligado"
	self.motion.Text = state.profile.settings.reducedMotion and "Movimento: reduzido" or "Movimento: normal"
	local keys = {}
	for _, field in { "discovered", "synergies", "areas" } do
		for id, found in state.profile[field] do if found then table.insert(keys, field .. ":" .. id) end end
	end
	table.sort(keys); local signature = table.concat(keys, "|")
	if signature == self.signature then return end
	self.signature = signature
	for _, child in self.list:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
	local index = 0
	for _, section in {
		{ title = "ADAPTAÇÕES", registry = Definitions, found = state.profile.discovered },
		{ title = "SYNERGIES SECRETAS", registry = Synergies, found = state.profile.synergies },
		{ title = "LUGARES", registry = Areas, found = state.profile.areas },
	} do
		index += 1
		local header = Gui.label(self.list, section.title, UDim2.new(1, -12, 0, 32), UDim2.new(), 14, Gui.Theme.mint); header.LayoutOrder = index
		local ids = {}; for id in section.registry do table.insert(ids, id) end; table.sort(ids)
		for _, id in ids do
			local data = section.registry[id]; local discovered = section.found[id]
			index += 1
			local row = Gui.round(Gui.new("Frame", { Size = UDim2.new(1, -12, 0, 88), BackgroundColor3 = Gui.Theme.panel, LayoutOrder = index }, self.list), 12)
			Gui.label(row, discovered and data.displayName or "???", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 6), 18)
			local description = discovered and (data.description or data.hint or "Descoberto") or "Explore e transforme-se para descobrir."
			Gui.label(row, description, UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 34), 14, Gui.Theme.muted)
		end
	end
end
return Codex
