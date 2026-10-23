--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Gui = require(script.Parent.Gui)
local Shared = game:GetService("ReplicatedStorage").Shared
local Areas = require(Shared.Areas)
local Choice = require(script.Parent.ChoiceController)
local Codex = require(script.Parent.CodexController)
local Journal = require(script.Parent.JournalController)
local Hud = {}
function Hud.new(remotes)
	local self = setmetatable({}, { __index = Hud }); self.remotes = remotes
	self.screen = Gui.new("ScreenGui", { Name = "ADAPT", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, DisplayOrder = 10 }, Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.root = Gui.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, self.screen)
	self.hud = Gui.round(Gui.new("Frame", { Size = UDim2.fromOffset(340, 122), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = Gui.Theme.background, BackgroundTransparency = 0.08 }, self.root), 16)
	Gui.stroke(self.hud)
	self.title = Gui.label(self.hud, "ADAPT!   /   BLANK", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 17)
	self.energy = Gui.label(self.hud, "Encontrando seu mundo…", UDim2.new(1, -28, 0, 25), UDim2.fromOffset(14, 37), 14, Gui.Theme.muted)
	self.track = Gui.round(Gui.new("Frame", { Size = UDim2.new(1, -28, 0, 12), Position = UDim2.fromOffset(14, 68), BackgroundColor3 = Gui.Theme.panel, ClipsDescendants = true }, self.hud), 6)
	self.fill = Gui.round(Gui.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Gui.Theme.mint }, self.track), 6)
	self.health = Gui.label(self.hud, "Vida 100  •  habilidade 100%", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 88), 13, Gui.Theme.muted)
	self.codexButton = Gui.button(self.root, "CODEX [C]", UDim2.fromOffset(120, 48), UDim2.new(1, -132, 0, 12), function() if not self.choice.scrim.Visible then self.codex:Toggle() end end)
	self.guide = Gui.round(Gui.new("Frame", { Size = UDim2.new(0, 440, 0, 68), Position = UDim2.new(0.5, 0, 1, -20), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = Gui.Theme.background, BackgroundTransparency = 0.08 }, self.root), 16)
	self.guideText = Gui.label(self.guide, "Toque os cristais verdes. Sua primeira evolução está perto.", UDim2.new(1, -28, 1, -12), UDim2.fromOffset(14, 6), 15)
	self.toast = Gui.round(Gui.new("TextLabel", { Size = UDim2.fromOffset(420, 68), Position = UDim2.new(0.5, 0, 0, 145), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Gui.Theme.panel, TextColor3 = Gui.Theme.text, FontFace = Font.fromEnum(Enum.Font.GothamBold), TextSize = 17, TextWrapped = true, Visible = false, ZIndex = 8 }, self.root), 14)
	self.mode = Gui.label(self.root, "", UDim2.fromOffset(440, 44), UDim2.new(0.5, -220, 1, -132), 13, Gui.Theme.muted); self.mode.TextXAlignment = Enum.TextXAlignment.Center
	self.choice = Choice.new(self.root, remotes); self.codex = Codex.new(self.root, remotes)
	self.journal = Journal.new(self.root, remotes, function() self.codex:Toggle() end)
	self.journalButton = Gui.button(self.root, "DIÁRIO [C]", UDim2.fromOffset(120, 48), UDim2.new(1, -132, 0, 68), function()
		if not self.choice.scrim.Visible then self.codex.scrim.Visible = false; self.journal:Toggle() end
	end, Gui.Theme.accent); self.journalButton.TextColor3 = Gui.Theme.ink
	self.codexButton.Text = "CODEX"; self.codexButton.Activated:Connect(function() self.journal:Close() end)
	self.saveStatus = Gui.label(self.root, "", UDim2.fromOffset(340, 22), UDim2.fromOffset(14, 133), 12, Gui.Theme.muted)
	self.debug = Gui.new("ScrollingFrame", { Position = UDim2.new(1, -232, 0, 126), Size = UDim2.fromOffset(220, 265), BackgroundColor3 = Gui.Theme.background, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 4, ZIndex = 4 }, self.root)
	Gui.round(self.debug, 12); Gui.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, self.debug)
	self.debugButton = Gui.button(self.root, "DEV", UDim2.fromOffset(64, 44), UDim2.new(1, -76, 0, 124), function() self.debug.Visible = not self.debug.Visible end); self.debugButton.Visible = false
	for i, item in {
		{ "+60 energia", "energy", 60 }, { "Equipar Wings", "grant", "Wings" }, { "Equipar Grip Claws", "grant", "GripClaws" }, { "Equipar Night Eyes", "grant", "NightEyes" },
		{ "Resetar build", "reset" }, { "Ir para Wilds", "teleport", "Wilds" }, { "Ir para Cliff", "teleport", "Cliff" }, { "Ir para Cave", "teleport", "Cave" }, { "Ir para Sky Island", "teleport", "SkyIsland" }, { "Imprimir estado", "state" },
	} do
		local button = Gui.button(self.debug, item[1], UDim2.new(1, -8, 0, 44), UDim2.new(), function() remotes.Debug:FireServer(item[2], item[3]) end); button.LayoutOrder = i
	end
	local ids = {}; for id in Areas do if id ~= "Wilds" and id ~= "Cliff" and id ~= "Cave" and id ~= "SkyIsland" then table.insert(ids,id) end end; table.sort(ids)
	for i,id in ids do
		local button = Gui.button(self.debug,"Ir: "..Areas[id].displayName,UDim2.new(1,-8,0,44),UDim2.new(),function() remotes.Debug:FireServer("teleport",id) end)
		button.TextSize = 12; button.LayoutOrder = 20+i
	end
	self.toastSerial = 0
	return self
end
function Hud:Resize(viewport)
	local small = viewport.X < 620
	self.hud.Size = UDim2.fromOffset(math.min(340, viewport.X - 156), 122)
	self.title.TextSize = small and 14 or 17
	self.guide.Size = UDim2.fromOffset(math.min(440, viewport.X - 32), 84)
	if UserInputService.TouchEnabled then
		self.guide.Position = UDim2.new(0.5, 0, 0, 144); self.guide.AnchorPoint = Vector2.new(0.5, 0)
		self.mode.Visible = false; self.codexButton.Text = "CODEX"
	else self.guide.Position = UDim2.new(0.5, 0, 1, -20); self.guide.AnchorPoint = Vector2.new(0.5, 1) end
	self.toast.Size = UDim2.fromOffset(math.min(420, viewport.X - 32), 68)
	self.mode.Size = UDim2.fromOffset(math.min(440, viewport.X - 24), 44); self.mode.Position = UDim2.new(0.5, 0, 1, -164); self.mode.AnchorPoint = Vector2.new(0.5, 0)
	self.choice:Resize(viewport); self.codex:Resize(viewport)
	self.journal:Resize(viewport)
	self.guide.Position = UserInputService.TouchEnabled and UDim2.new(.5, 0, 0, 170) or UDim2.new(.5, 0, 1, -20)
	self.guideText.TextSize = small and 13 or 15
	self.toast.Position = UDim2.new(.5, 0, 0, UserInputService.TouchEnabled and 266 or 172)
	self.saveStatus.Size = UDim2.fromOffset(math.min(340, viewport.X-100), 30)
	self.journalButton.Text = UserInputService.TouchEnabled and "DIÁRIO" or "DIÁRIO [C]"
	self.health.TextSize = small and 12 or 13
	if UserInputService.TouchEnabled and viewport.Y < 450 and viewport.X >= 620 then
		self.hud.Size = UDim2.fromOffset(230,122)
		self.guide.Size = UDim2.fromOffset(viewport.X-390,112)
		self.guide.Position = UDim2.fromOffset(254,12); self.guide.AnchorPoint = Vector2.zero
		self.guideText.TextSize = 13; self.toast.Position = UDim2.new(.5,0,0,172)
		self.toast.Size = UDim2.fromOffset(math.min(360,viewport.X-32),44)
	end
end
function Hud:Message(text)
	self.toastSerial += 1; local serial = self.toastSerial
	self.toast.Text = text; self.toast.Visible = true
	task.delay(3.5, function() if serial == self.toastSerial then self.toast.Visible = false end end)
end
function Hud:Update(state)
	self.state = state
	local p = state.profile
	self.title.Text = "ADAPT!   /   NÍVEL " .. p.level
	self.energy.Text = string.format("%d / %d  •  energia", p.energy, state.threshold)
	Gui.tween(self.fill, { Size = UDim2.fromScale(math.clamp(p.energy / state.threshold, 0, 1), 1) }, p.settings.reducedMotion)
	self.choice:Update(state); self.codex:Update(state)
	self.journal:Update(state)
	if state.pending then self.codex.scrim.Visible = false; self.debug.Visible = false end
	self.debugButton.Visible = state.debug == true
	local controls = {}
	if p.equipped.Back then table.insert(controls, "[G] Planar") end
	if p.equipped.Arms then table.insert(controls, "[E] Escalar") end
	if p.equipped.Head then table.insert(controls, "Visão noturna ativa") end
	table.insert(controls, "[F] Atacar")
	self.mode.Text = table.concat(controls, "  •  ")
	if p.equipped.Back == "SkyWings" then self.mode.Text = self.mode.Text:gsub("Planar", "Ascender") end
	if p.level == 0 then self.guideText.Text = "Siga o sinal e toque os cristais verdes para evoluir."
	elseif p.equipped.Back and not p.areas.SkyIsland then self.guideText.Text = "Wings: suba a rampa oeste. Salte e use Planar [G] até a ilha."
	elseif p.equipped.Arms and not p.areas.Cliff then self.guideText.Text = "Grip Claws: chegue às marcas douradas e use Escalar [E]."
	elseif p.equipped.Head and not p.areas.Cave then self.guideText.Text = "Night Eyes: entre na caverna e encontre a essência oculta."
	else self.guideText.Text = "Explore, combine adaptações e enfrente o Guardian. [C] abre o Codex." end
	if state.journey then self.guideText.Text = state.journey.objective.title .. " • " .. state.journey.objective.text end
	self.saveStatus.Text = state.persistence == "Cloud" and "Progresso com salvamento automático" or state.persistence == "ReadOnly" and "SEM SALVAMENTO • dados indisponíveis" or "TESTE LOCAL • progresso temporário"
	if self.lastPersistence ~= state.persistence then
		self.lastPersistence = state.persistence
		if state.persistence == "ReadOnly" then self:Message("Dados indisponíveis: esta sessão não será salva.") end
	end
end
function Hud:Vitals(health, stamina, mode)
	self.health.Text = string.format("Vida %d  •  %s %d%%", math.ceil(health), mode == "None" and "habilidade" or mode, math.floor(stamina * 100))
	local char = Players.LocalPlayer.Character
	if char and char:GetAttribute("HeatDanger") then self.health.Text = "CALOR INTENSO • equipe Carapaça de Brasa"
	elseif char and (char:GetAttribute("Oxygen") or 1) < 1 then self.health.Text = string.format("Vida %d • Ar %d%% • suba!", math.ceil(health), math.floor(char:GetAttribute("Oxygen")*100)) end
end
function Hud:IsModal() return self.choice.scrim.Visible or self.codex.scrim.Visible or self.journal.scrim.Visible end
return Hud
