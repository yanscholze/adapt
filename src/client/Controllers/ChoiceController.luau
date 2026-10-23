--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Definitions = require(Shared.Adaptations)
local Gui = require(script.Parent.Gui)
local Choice = {}
function Choice.new(root, remotes)
	local self = setmetatable({}, { __index = Choice })
	self.remotes = remotes; self.cards = {}; self.token = nil; self.busy = false
	self.scrim, self.panel = Gui.modal(root, "Seu próximo corpo")
	Gui.label(self.panel, "Escolha uma adaptação. Seu corpo muda agora.", UDim2.new(1, -40, 0, 38), UDim2.fromOffset(20, 52), 15, Gui.Theme.muted)
	self.list = Gui.new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(16, 104), Size = UDim2.new(1, -32, 1, -124), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5 }, self.panel)
	self.layout = Gui.new("UIGridLayout", { CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, self.list)
	return self
end
function Choice:Resize(viewport)
	local w = math.min(viewport.X - 24, 900); local h = math.min(viewport.Y - 24, viewport.X < 620 and 640 or 420)
	self.panel.Size = UDim2.fromOffset(w, h)
	local narrow = w < 620
	self.layout.CellSize = narrow and UDim2.new(1, -8, 0, 150) or UDim2.new(1 / 3, -11, 1, -8)
end
function Choice:Pick(index)
	if not self.pending or self.busy then return end
	local id = self.pending.options[index]; if not id then return end
	self.busy = true
	self.remotes.Choose:FireServer(self.pending.token, id)
	for _, card in self.cards do card.AutoButtonColor = false end
	-- A dropped reply must not strand the player behind a disabled choice panel.
	local token = self.pending.token
	task.delay(2, function()
		if self.pending and self.pending.token == token then self.busy = false; self.remotes.RequestState:FireServer() end
	end)
end
function Choice:Update(state)
	self.pending = state.pending; self.scrim.Visible = state.pending ~= nil; self.busy = false
	if not state.pending then self.token = nil; return end
	if self.token == state.pending.token then return end
	self.token = state.pending.token
	for _, card in self.cards do card:Destroy() end; self.cards = {}
	for index, id in state.pending.options do
		local def = Definitions[id]; if not def then continue end
		local color = Color3.fromRGB(table.unpack(def.visualData.color))
		local card = Gui.button(self.list, "", UDim2.new(), UDim2.new(), function() self:Pick(index) end)
		card.LayoutOrder = index; card.Name = id
		Gui.stroke(card, color)
		Gui.label(card, tostring(index) .. "  /  " .. string.upper(def.slot), UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 10), 13, color)
		Gui.label(card, def.displayName, UDim2.new(1, -28, 0, 32), UDim2.fromOffset(14, 34), 21)
		Gui.label(card, def.description, UDim2.new(1, -28, 0, 62), UDim2.fromOffset(14, 70), 15, Gui.Theme.muted)
		local old = state.profile.equipped[def.slot]
		if old then card:SetAttribute("Replaces", old) end
		table.insert(self.cards, card)
	end
	pcall(function() game:GetService("GuiService").SelectedObject = self.cards[1] end)
end
return Choice
