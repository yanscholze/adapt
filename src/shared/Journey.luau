--!nonstrict
-- Campaign definitions are shared; only JourneyService mutates saved progress.
local Journey = {}
Journey.version = 1
Journey.order = { "Wilds", "Oldgrowth", "Tideglass", "Sunscar", "EmberAtoll", "Hollow", "RiftCrown", "SkyReach" }
Journey.regions = {
	Wilds = { name = "Berço Verde", color = { 116, 231, 178 }, reward = "SpringLegs", lore = "A primeira semente acordou. O arquipélago reconhece seus passos.", runes = { "FirstCliff", "FirstCave", "FirstSky" } },
	Oldgrowth = { name = "Memória das Raízes", color = { 84, 200, 133 }, reward = "TideTail", lore = "As raízes lembram o tempo em que todas as ilhas eram uma só.", runes = { "MossGate", "CanopyNest", "SleepingSeed" } },
	Tideglass = { name = "Voz da Maré", color = { 88, 212, 234 }, ability = "Aquatic", lore = "Sob a maré, as ruínas ainda cantam. Sua cauda permite ouvir sem pressa.", runes = { "ReefEntry", "ReefDepth", "ReefHeart" } },
	Sunscar = { name = "Coração de Âmbar", color = { 247, 198, 107 }, reward = "EmberShell", lore = "O deserto guardava uma armadura feita de sol.", runes = { "SaltBasin", "BuriedRing", "SunGate" } },
	EmberAtoll = { name = "Fagulha Ancestral", color = { 255, 131, 96 }, ability = "HeatResistance", lore = "O fogo deixa de ser uma barreira e se torna uma lembrança.", runes = { "LavaRim", "SmokeField", "CalderaOverlook" } },
	Hollow = { name = "Eco de Vesper", color = { 191, 151, 255 }, ability = "NightVision", lore = "Nem tudo que se perdeu desapareceu. Alguns caminhos apenas aguardavam outros olhos.", runes = { "DeepEcho", "VioletShore", "SilentGate" } },
	RiftCrown = { name = "Juramento do Vento", color = { 172, 217, 235 }, lore = "Do cume, as distâncias parecem convites.", runes = { "CrownSummit", "WhisperShelf", "TwinGates" } },
	SkyReach = { name = "Luz do Zênite", color = { 223, 205, 255 }, ability = "Glide", lore = "Oito vozes. Um só mundo. Falta despertar quem o protege.", runes = { "SkyOrchard", "SkyZenith", "SkyNeedle" } },
}
Journey.fixed = {
	FirstCliff = { 70, 48, 40 }, FirstCave = { -64, 3, 63 }, FirstSky = { 118, 40, -65 },
	ReefEntry = { -675, -45, 830 }, ReefDepth = { -700, -83, 900 }, ReefHeart = { -760, -92, 940 },
	SkyOrchard = { 470, 425, -520 }, SkyZenith = { 300, 602, -610 }, SkyNeedle = { 370, 690, -720 },
}
Journey.campOverrides = {
	Wilds = { -20, 5, 40 }, SkyReach = { 245, 600, -590 },
	-- Keep refuges outside the carved cave mouths (the former debug spawns were above their floors).
	Oldgrowth = { -920, 37.885, -630 }, Hollow = { -1200, 70.477, 440 },
}
Journey.finale = { position = { 288, 602, -575 }, maxHealth = 320, radius = 34, reward = 180 }
function Journey.count(values)
	local n = 0; for _, found in values or {} do if found == true then n += 1 end end; return n
end
function Journey.defaults()
	return { started = false, guardian = false, seals = {}, runes = {}, camps = { Wilds = true }, checkpoint = "Wilds", complete = false, deaths = 0 }
end
function Journey.runeRegion(id)
	for _, area in Journey.order do if table.find(Journey.regions[area].runes, id) then return area end end
	return nil
end
function Journey.sanitize(raw)
	local p = Journey.defaults(); if type(raw) ~= "table" then return p end
	for _, key in { "started", "guardian", "complete" } do p[key] = raw[key] == true end
	for _, key in { "seals", "camps" } do
		if type(raw[key]) == "table" then for id, value in raw[key] do if Journey.regions[id] and value == true then p[key][id] = true end end end
	end
	if type(raw.runes) == "table" then for id, found in raw.runes do if found == true and Journey.runeRegion(id) then p.runes[id] = true end end end
	if type(raw.checkpoint) == "string" and p.camps[raw.checkpoint] then p.checkpoint = raw.checkpoint end
	if type(raw.deaths) == "number" and raw.deaths == raw.deaths then p.deaths = math.clamp(math.floor(raw.deaths), 0, 100000) end
	p.complete = p.complete and Journey.count(p.seals) == 8
	return p
end
function Journey.ready(progress, region)
	if not progress.guardian then return false end
	for _, id in Journey.regions[region].runes do if not progress.runes[id] then return false end end
	return true
end
function Journey.objective(profile)
	local j = profile.journey
	if not j.started then return { title = "Um novo começo", text = "Conheça sua jornada no diário.", kind = "Intro" } end
	if profile.level == 0 then return { title = "Seu primeiro corpo", text = "Toque cinco cristais verdes e escolha uma adaptação.", kind = "Essence", position = { -5, 2.2, 18 } } end
	if not j.guardian then return { title = "O primeiro guardião", text = "Ataque e saia do aviso vermelho. A vitória revela três adaptações.", kind = "Guardian", position = { 20, 4.5, 70 } } end
	if j.complete then return { title = "O mundo despertou", text = "Explore livremente, complete o Codex e experimente novas combinações.", kind = "Complete" } end
	for _, id in Journey.order do
		if not j.seals[id] then
			local region = Journey.regions[id]; local n = 0; local target
			local needs = {
				Tideglass = { slot = "Tail", ids = { "TideTail" }, name = "Cauda das Marés" },
				EmberAtoll = { slot = "Body", ids = { "EmberShell" }, name = "Carapaça de Brasa" },
				Hollow = { slot = "Head", ids = { "NightEyes", "EchoEyes" }, name = "olhos de visão noturna" },
				SkyReach = { slot = "Back", ids = { "SkyWings" }, name = "Asas do Zênite" },
			}
			local need = needs[id]
			if need and not table.find(need.ids, profile.equipped[need.slot]) then
				return { title = "Prepare seu corpo", text = "No refúgio, abra Diário > Corpo e equipe " .. need.name .. ".", kind = "Equip", region = j.checkpoint }
			end
			for _, rune in region.runes do if j.runes[rune] then n += 1 elseif not target then target = rune end end
			return { title = region.name, text = n < 3 and ("Encontre as memórias deste bioma: " .. n .. "/3.") or "Volte ao santuário e restaure a semente.", region = id, kind = n < 3 and "Rune" or "Seal", target = target }
		end
	end
	return { title = "O guardião do Zênite", text = "Aproxime-se do núcleo e desperte o guardião. Desvie dos padrões anunciados.", kind = "Finale", position = Journey.finale.position }
end
return Journey
