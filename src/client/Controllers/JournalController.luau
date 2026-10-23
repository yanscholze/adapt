--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Players = game:GetService("Players")
local Journey = require(Shared.Journey)
local Locations = require(Shared.JourneyLocations)
local Definitions = require(Shared.Adaptations)
local World = require(Shared.WorldDefinition)
local Gui = require(script.Parent.Gui)
local Journal = {}
function Journal.new(root, remotes, openCodex)
	local self = setmetatable({ remotes = remotes, tab = "Jornada", rows = {}, tracking = nil }, { __index = Journal })
	self.scrim, self.panel = Gui.modal(root, "ADAPT!  /  Diário")
	Gui.button(self.panel, "Voltar", UDim2.fromOffset(78, 44), UDim2.new(1, -94, 0, 12), function() self:Close() end)
	self.tabs = {}
	for i, name in { "Jornada", "Mapa", "Corpo" } do
		local b = Gui.button(self.panel, name, UDim2.new(1/3, -20, 0, 44), UDim2.new((i-1)/3, 16, 0, 64), function() self.tab = name; self:Render() end)
		self.tabs[name] = b
	end
	self.list = Gui.new("ScrollingFrame", { Position = UDim2.fromOffset(16, 120), Size = UDim2.new(1, -32, 1, -238), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, self.panel)
	Gui.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, self.list)
	self.primary = Gui.button(self.panel, "CONTINUAR", UDim2.new(.5, -22, 0, 48), UDim2.new(0, 16, 1, -104), function()
		if self.state and not self.state.profile.journey.started then self.remotes.Journey:FireServer("intro", "") end
		self:Close()
	end, Gui.Theme.mint); self.primary.TextColor3 = Gui.Theme.ink
	self.codex = Gui.button(self.panel, "Codex e opções", UDim2.new(.5, -22, 0, 48), UDim2.new(.5, 6, 1, -104), function() self:Close(); openCodex() end)
	self.rescue = Gui.button(self.panel, "Voltar ao refúgio • resgate", UDim2.new(1, -32, 0, 44), UDim2.new(0, 16, 1, -52), function() remotes.Journey:FireServer("rescue", ""); self:Close() end)
	self.rescue.TextSize = 13
	return self
end
function Journal:Close()
	self.scrim.Visible = false
	local gui = game:GetService("GuiService")
	if gui.SelectedObject and gui.SelectedObject:IsDescendantOf(self.scrim) then gui.SelectedObject = nil end
end
function Journal:Toggle(tab)
	if not tab and self.scrim.Visible then self:Close(); return end
	if tab then self.tab = tab; self.scrim.Visible = true else self.scrim.Visible = not self.scrim.Visible end
	if self.scrim.Visible then self:Render(); pcall(function() game:GetService("GuiService").SelectedObject = self.primary end) end
end
function Journal:Resize(viewport)
	self.panel.Size = UDim2.fromOffset(math.min(820, viewport.X-24), math.min(710, viewport.Y-24))
	self.narrow = viewport.X < 620
	if self.state then self:Render() end
end
function Journal:Row(title, description, color, action, callback)
	local height = self.narrow and 176 or 124
	local row = Gui.round(Gui.new("Frame", { Size = UDim2.new(1, -8, 0, height), BackgroundColor3 = Gui.Theme.panel, LayoutOrder = #self.rows+1 }, self.list), 12)
	Gui.new("Frame", { Size = UDim2.new(0, 3, 1, -24), Position = UDim2.fromOffset(0, 12), BackgroundColor3 = color, BorderSizePixel = 0 }, row)
	Gui.label(row, title, UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 6), 17, color)
	Gui.label(row, description, UDim2.new(1, -28, 0, self.narrow and 74 or 32), UDim2.fromOffset(14, 36), 14, Gui.Theme.muted)
	if action then
		local button = Gui.button(row, action, UDim2.new(1, -28, 0, 36), UDim2.new(0, 14, 1, -42), callback)
		button.Size = UDim2.new(1, -28, 0, 44); button.Position = UDim2.new(0, 14, 1, -48); button.TextSize = 13
	end
	table.insert(self.rows, row); return row
end
function Journal:RenderMap()
	local frame = Gui.round(Gui.new("Frame", { Size = UDim2.new(1, -8, 0, self.narrow and 290 or 380), BackgroundColor3 = Color3.fromRGB(23, 57, 68), LayoutOrder = 0, ClipsDescendants = true }, self.list), 14)
	table.insert(self.rows, frame)
	local function map(p) return (p[1]+1850)/3700, (p[#p]+1700)/3400 end
	for _, island in World.islands do
		local x, y = map(island.center)
		local land = Gui.round(Gui.new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(x,y), Size = UDim2.fromScale(island.radius[1]*2/3700, island.radius[2]*2/3400), BackgroundColor3 = Color3.fromRGB(table.unpack(island.palette)), BackgroundTransparency = .18, BorderSizePixel = 0 }, frame), 70)
		land.Rotation = island.id == "Hollow" and 20 or -8
	end
	for i, area in Journey.order do
		local x, y = map(Locations.camps[area]); local j = self.state.profile.journey
		local b = Gui.button(frame, tostring(i) .. (j.seals[area] and " ✓" or ""), UDim2.fromOffset(44,44), UDim2.fromScale(x,y), function() self.tracking = area; self:Close() end, Color3.fromRGB(table.unpack(Journey.regions[area].color)))
		b.AnchorPoint = Vector2.new(.5,.5); b.TextColor3 = Gui.Theme.ink; b.TextSize = 13
	end
	local char = Players.LocalPlayer.Character; local part = char and char:FindFirstChild("HumanoidRootPart")
	if part then
		local x,y = map({part.CFrame.Position.X,part.CFrame.Position.Z})
		local marker = Gui.round(Gui.new("Frame", { Size = UDim2.fromOffset(10,10), Position = UDim2.fromScale(x,y), AnchorPoint = Vector2.new(.5,.5), BackgroundColor3 = Gui.Theme.text, BorderSizePixel = 0, ZIndex = 3 }, frame), 5)
		Gui.stroke(marker, Gui.Theme.ink)
	end
	for i, area in Journey.order do
		local j = self.state.profile.journey; local region = Journey.regions[area]
		local status = j.seals[area] and "Semente restaurada" or j.camps[area] and "Refúgio descoberto" or "Explore para descobrir o refúgio"
		self:Row(i .. "  " .. region.name, status, Color3.fromRGB(table.unpack(region.color)), j.camps[area] and "Viajar • a partir de um refúgio" or "Marcar no mundo", function()
			if j.camps[area] then self.remotes.Travel:FireServer(area) else self.tracking = area end
			self:Close()
		end)
	end
end
function Journal:Render()
	if not self.state then return end
	for _, row in self.rows do row:Destroy() end; self.rows = {}
	for name, b in self.tabs do b.BackgroundColor3 = name == self.tab and Gui.Theme.accent or Gui.Theme.panel; b.TextColor3 = name == self.tab and Gui.Theme.ink or Gui.Theme.text end
	local p = self.state.profile; local j = p.journey
	self.primary.Text = j.started and "CONTINUAR EXPLORANDO" or "COMEÇAR A JORNADA"; self.primary.TextSize = self.narrow and 12 or 14
	if self.tab == "Mapa" then self:RenderMap(); return end
	if self.tab == "Corpo" then
		local char = Players.LocalPlayer.Character
		if char and char.PrimaryPart then
			local preview = Gui.round(Gui.new("ViewportFrame", { Size = UDim2.new(1,-8,0,220), BackgroundColor3 = Gui.Theme.background, Ambient = Color3.fromRGB(180,195,210), LightColor = Color3.fromRGB(255,236,208), LightDirection = Vector3.new(-1,-1,-1), LayoutOrder = 0 }, self.list), 14)
			local model = char:Clone()
			if model then
				for _, item in model:GetDescendants() do
					if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ForceField") then item:Destroy()
					elseif item:IsA("BasePart") then item.Anchored = true end
				end
				local worldModel = Instance.new("WorldModel"); worldModel.Parent = preview; model.Parent = worldModel; model:PivotTo(CFrame.identity)
				local camera = Instance.new("Camera"); camera.FieldOfView = 35; camera.CFrame = CFrame.lookAt(Vector3.new(8,4,-18), Vector3.new(0,.1,0)); camera.Parent = preview; preview.CurrentCamera = camera
			end
			table.insert(self.rows, preview)
		end
		self:Row("Seu corpo, seus caminhos", "Troque adaptações descobertas perto de um refúgio. Cada parte tem um único slot.", Gui.Theme.mint)
		for _, slot in { "Head", "Body", "Arms", "Legs", "Back", "Tail" } do
			local ids = {}; for id, d in Definitions do if d.slot == slot and p.discovered[id] then table.insert(ids,id) end end; table.sort(ids)
			for _, id in ids do
				local d = Definitions[id]; local equipped = p.equipped[slot] == id
				self:Row(d.displayName .. (equipped and " • equipado" or ""), d.description, Color3.fromRGB(table.unpack(d.visualData.color)), equipped and "Equipado" or "Equipar no refúgio", function() if not equipped then self.remotes.Equip:FireServer(id) end end)
			end
		end
		return
	end
	if not j.started then
		self:Row("UM CORPO EM BRANCO", "Você chegou a um arquipélago adormecido. Cada descoberta muda seu corpo e abre um caminho.", Gui.Theme.mint)
		self:Row("EXPLORE. TRANSFORME-SE. DESPERTE.", "Colete essência, evolua e restaure oito sementes. Derrote os guardiões junto de outros exploradores.", Gui.Theme.accent)
		self:Row("Encontre seu ritmo", "WASD / direcional: mover. Espaço: saltar. G: asas. E: garras. F: atacar. R: interagir. C: diário.", Gui.Theme.text)
	elseif j.complete then
		self:Row("O ARQUIPÉLAGO DESPERTOU", "Você reuniu oito sementes e alcançou o Zênite. Sua coroa de Guardião do Arquipélago celebra essa jornada.", Color3.fromRGB(255, 220, 130))
		self:Row("O mundo continua aberto", "Todas as descobertas permanecem com você. Complete o Codex, ajude novos exploradores e experimente combinações.", Gui.Theme.mint)
		self:Row("ADAPT! • versão 1.0", "Uma aventura original de transformação e exploração. Obrigado por dar vida a este mundo.", Gui.Theme.muted)
	end
	local objective = self.state.journey and self.state.journey.objective or Journey.objective(p)
	self:Row("AGORA • " .. objective.title, objective.text, Gui.Theme.mint, "Seguir objetivo da jornada", function() self.tracking = nil; self:Close() end)
	for i, area in Journey.order do
		local region = Journey.regions[area]; local n = 0
		for _, id in region.runes do if j.runes[id] then n += 1 end end
		self:Row(string.format("%02d  %s%s", i, region.name, j.seals[area] and " ✓" or ""), j.seals[area] and region.lore or string.format("Memórias %d/3. %s", n, region.reward and ("Recompensa: " .. Definitions[region.reward].displayName) or "Restaure a semente deste bioma."), Color3.fromRGB(table.unpack(region.color)), if j.seals[area] then nil else "Marcar próximo passo", function() self.tracking = area; self:Close() end)
	end
end
function Journal:Update(state)
	self.state = state
	if not state.profile.journey.started and not self.introShown then self.introShown = true; self.scrim.Visible = true end
	if state.profile.journey.complete and not self.wasComplete then
		if self.wasComplete == false then self.tab = "Jornada"; self.scrim.Visible = true end
	end
	self.wasComplete = state.profile.journey.complete
	if state.pending then self.scrim.Visible = false end
	if self.scrim.Visible then self:Render() end
end
function Journal:Target()
	if not self.state then return nil end
	local j = self.state.profile.journey
	if self.tracking then
		local area = self.tracking; local region = Journey.regions[area]
		if not j.seals[area] then
			for _, id in region.runes do if not j.runes[id] then return { title = "Memória • " .. region.name, position = Locations.runes[id].position } end end
		end
		return { title = region.name, position = Locations.camps[area] }
	end
	return self.state.journey and self.state.journey.objective or Journey.objective(self.state.profile)
end
return Journal
