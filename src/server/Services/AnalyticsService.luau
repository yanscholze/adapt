--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Analytics = {}
function Analytics:Init() self.sink = nil end
function Analytics:SetSink(callback) self.sink = callback end
function Analytics:Once(player, profile, event)
	if profile.milestones[event] then return end
	profile.milestones[event] = true
	if Config.AnalyticsEnabled and self.sink then
		task.spawn(function()
			local ok = pcall(self.sink, player, event, { level = profile.level })
			if not ok then warn("[ADAPT] Analytics sink failed:", event) end
		end)
	end
end
return Analytics
