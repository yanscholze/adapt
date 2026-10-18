--!strict
local Progression = {}
function Progression.threshold(level: number): number
	local first = { 30, 48, 72, 100, 130, 165 }
	return first[level + 1] or math.min(200 + math.max(0, level - 6) * 20, 500)
end
function Progression.options(profile: any, definitions: any, random: any): { string }
	local candidates = {}
	for id, definition in definitions do
		if definition.requirements.minLevel <= profile.level and profile.equipped[definition.slot] ~= id then
			table.insert(candidates, id)
		end
	end
	table.sort(candidates)
	for i = #candidates, 2, -1 do
		local j = random:NextInteger(1, i)
		candidates[i], candidates[j] = candidates[j], candidates[i]
	end
	-- Prioritize discoveries, preserve randomized order inside each group.
	local ordered = {}
	for _, discovered in { false, true } do
		for _, id in candidates do
			if (profile.discovered[id] == true) == discovered then table.insert(ordered, id) end
		end
	end
	local result = {}
	for i = 1, math.min(3, #ordered) do table.insert(result, ordered[i]) end
	return result
end
function Progression.hasAbility(equipped: any, definitions: any, kind: string): any
	for _, id in equipped do
		local definition = definitions[id]
		if definition and definition.abilityData.kind == kind then return definition.abilityData end
	end
	return nil
end
function Progression.synergies(equipped: any, definitions: any, synergies: any): { string }
	local tags = {}
	for _, id in equipped do
		if definitions[id] then
			for _, tag in definitions[id].synergyTags do tags[tag] = true end
		end
	end
	local active = {}
	for id, definition in synergies do
		local valid = true
		for _, tag in definition.requiredTags do if not tags[tag] then valid = false end end
		if valid then table.insert(active, id) end
	end
	table.sort(active)
	return active
end
return Progression
