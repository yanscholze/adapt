--!nonstrict
local Schema = {}
local Journey = require(script.Parent.Journey)
local slots = { Head = true, Body = true, Arms = true, Legs = true, Back = true, Tail = true }
function Schema.defaults(): any
	return { version = 2, level = 0, energy = 0, equipped = {}, discovered = {}, synergies = {}, areas = {}, milestones = {}, journey = Journey.defaults(), settings = { sound = true, reducedMotion = false } }
end
local function finite(value: any, fallback: number, maximum: number): number
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return fallback end
	return math.clamp(math.floor(value), 0, maximum)
end
function Schema.sanitize(raw: any, definitions: any, synergies: any, areas: any): any
	local p = Schema.defaults()
	if type(raw) ~= "table" then return p end
	p.level = finite(raw.level, 0, 100000)
	p.energy = finite(raw.energy, 0, 5000)
	p.journey = Journey.sanitize(raw.journey)
	local registries: { [string]: any } = { discovered = definitions, synergies = synergies, areas = areas }
	for field, registry in registries do
		if type(raw[field]) == "table" then
			for id, value in raw[field] do if value == true and registry[id] then p[field][id] = true end end
		end
	end
	if type(raw.equipped) == "table" then
		for slot, id in raw.equipped do
			if slots[slot] and definitions[id] and definitions[id].slot == slot then
				p.equipped[slot] = id; p.discovered[id] = true
			end
		end
	end
	if type(raw.milestones) == "table" then
		for id, value in raw.milestones do
			if type(id) == "string" and #id <= 48 and value == true then p.milestones[id] = true end
		end
	end
	if type(raw.settings) == "table" then
		for key in p.settings do if type(raw.settings[key]) == "boolean" then p.settings[key] = raw.settings[key] end end
	end
	return p
end
return Schema
