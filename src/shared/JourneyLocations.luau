--!nonstrict
local Journey = require(script.Parent.Journey)
local Samples = require(script.Parent.WorldSamples)
local Locations = { camps = {}, runes = {} }
for _, area in Journey.order do
	Locations.camps[area] = Journey.campOverrides[area] or Samples.safeSpawns[area]
	for _, id in Journey.regions[area].runes do
		local point = Journey.fixed[id]
		if not point then
			for _, poi in Samples.pois do if poi.id == id then point = { poi.position[1], poi.position[2] + 3, poi.position[3] }; break end end
		end
		assert(point, "Missing campaign anchor " .. id)
		Locations.runes[id] = { position = point, region = area }
	end
end
return Locations
