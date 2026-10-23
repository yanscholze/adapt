--!nonstrict
local A = require("../src/shared/Adaptations")
local S = require("../src/shared/Synergies")
local Areas = require("../src/shared/Areas")
local P = require("../src/shared/Progression")
local Harness = require("../scripts/RobloxHarness")
local h = Harness.new("build/ADAPT.rbxlx")
local Schema = h.require(h.shared.ProfileSchema)
local Limiter = require("../src/shared/RateLimiter")
local checks = 0
local function check(name, fn) fn(); checks += 1; print("PASS", name) end
local seed = 41
local random = { NextInteger = function(_, a, b) seed = (seed * 48271) % 2147483647; return a + seed % (b - a + 1) end }
check("first minute: five common Essence produce first evolution", function() assert(P.threshold(0) == 5 * require("../src/shared/Essences").Dew.energyValue) end)
check("thresholds positive and monotonic through level 1000", function()
	local prev = 0
	for level = 0, 1000 do local t = P.threshold(level); assert(t >= prev and t <= 500); prev = t end
end)
check("first evolution presents all three traversal choices", function()
	local p = Schema.defaults(); local options = P.options(p, A, random)
	assert(#options == 3 and table.find(options, "Wings") and table.find(options, "NightEyes") and table.find(options, "GripClaws"))
end)
check("500 successive builds preserve three valid non-equipped choices", function()
	local p = Schema.defaults()
	for _ = 1, 500 do
		local options = P.options(p, A, random); assert(#options == 3)
		local seen = {}
		for _, id in options do
			assert(not seen[id] and p.equipped[A[id].slot] ~= id and A[id].requirements.minLevel <= p.level); seen[id] = true
		end
		local id = options[random:NextInteger(1, 3)]; p.equipped[A[id].slot] = id; p.discovered[id] = true; p.level += 1
	end
end)
check("same-slot replacements retain other anatomy and discoveries", function()
	local p = Schema.defaults(); p.equipped = { Head = "NightEyes", Back = "Wings", Arms = "GripClaws" }; p.discovered.Wings = true
	p.equipped[A.DawnSails.slot] = "DawnSails"
	assert(p.equipped.Back == "DawnSails" and p.equipped.Arms == "GripClaws" and p.discovered.Wings)
	assert(P.hasAbility(p.equipped, A, "Glide").speedMultiplier == 1.15)
end)
check("synergy uses generic tags and works with replacement variants", function()
	assert(#P.synergies({ Back = "Wings" }, A, S) == 0)
	assert(P.synergies({ Back = "DawnSails", Head = "EchoEyes" }, A, S)[1] == "Moondrift")
	assert(#P.synergies({ Arms = "GripClaws", Head = "EchoEyes" }, A, S) == 0)
end)
check("profile defaults never share nested tables", function()
	local p, q = Schema.defaults(), Schema.defaults(); p.discovered.Wings = true; p.settings.sound = false; assert(not q.discovered.Wings and q.settings.sound)
end)
check("profile sanitization rejects corrupt fields and nonfinite numbers", function()
	local p = Schema.sanitize({ level = 0 / 0, energy = math.huge, equipped = { Head = "Wings", Back = "Wings", Arms = "bad" }, discovered = { fake = true, NightEyes = false }, settings = { sound = "yes" } }, A, S, Areas)
	assert(p.level == 0 and p.energy == 0 and p.equipped.Head == nil and p.equipped.Back == "Wings" and p.discovered.Wings and not p.discovered.fake and p.settings.sound)
end)
check("profile roundtrip preserves build, Codex, milestones and settings", function()
	local p = Schema.defaults(); p.level = 8; p.energy = 70; p.equipped.Head = "NightEyes"; p.synergies.Moondrift = true; p.areas.Cave = true; p.milestones.FIRST_ESSENCE = true; p.settings.reducedMotion = true
	local q = Schema.sanitize(p, A, S, Areas)
	assert(q.level == 8 and q.energy == 70 and q.equipped.Head == "NightEyes" and q.synergies.Moondrift and q.areas.Cave and q.milestones.FIRST_ESSENCE and q.settings.reducedMotion)
	q.equipped.Head = nil; assert(p.equipped.Head == "NightEyes")
end)
check("limiter handles bursts, replenishment and per-user cleanup", function()
	local l = Limiter.new(); assert(l:allow("1:attack", 0, 2, 2)); assert(l:allow("1:attack", 0, 2, 2)); assert(not l:allow("1:attack", 0, 2, 2)); assert(l:allow("1:attack", 0.5, 2, 2))
	assert(l:allow("10:attack", 0, 2, 2)); l:removePrefix("1:"); assert(l.buckets["1:attack"] == nil and l.buckets["10:attack"])
end)
print("CORE:", checks, "checks passed")
