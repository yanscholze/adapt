--!nonstrict
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local H = require("./RobloxHarness")
local h = H.new("build/ADAPT.rbxlx")
local Journey = h.require(h.shared.Journey)
local Locations = h.require(h.shared.JourneyLocations)
fs.writeFile("build/campaign-layout.json", serde.encode("json", { order = Journey.order, regions = Journey.regions, camps = Locations.camps, runes = Locations.runes, finale = Journey.finale }, true))
print("Campaign anchors exported from embedded modules")
