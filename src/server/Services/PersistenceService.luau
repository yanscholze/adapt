--!nonstrict
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Schema = require(Shared.ProfileSchema)
local Adaptations = require(Shared.Adaptations)
local Synergies = require(Shared.Synergies)
local Areas = require(Shared.Areas)
local Persistence = {}
function Persistence:Init()
	self.sessions = {}; self.closing = false
	self.enabled = not RunService:IsStudio() or Config.StudioPersistence
	if self.enabled then self.store = DataStoreService:GetDataStore(Config.DataStoreName) end
end
function Persistence:Load(player)
	local session = { id = HttpService:GenerateGUID(false), writable = false, saving = false, releasing = false }
	self.sessions[player] = session
	if not self.enabled then return Schema.defaults(), "StudioMemory" end
	local loaded; local locked = false
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return self.store:UpdateAsync("u_" .. player.UserId, function(record)
				if record ~= nil and type(record) ~= "table" then error("Invalid stored envelope") end
				if record and (record.version or 0) > Config.SchemaVersion then error("Newer schema: refusing downgrade") end
				local lease = record and record.session
				if lease and lease.id ~= session.id and (lease.expires or 0) > os.time() then locked = true; return nil end
				if record and type(record.data) ~= "table" then error("Invalid stored profile") end
				loaded = Schema.sanitize(record and record.data, Adaptations, Synergies, Areas)
				return { version = Config.SchemaVersion, data = loaded, session = { id = session.id, expires = os.time() + Config.SessionLeaseSeconds } }
			end)
		end)
		if locked then self.sessions[player] = nil; return nil, "Locked" end
		if ok and result and loaded then session.writable = true; return loaded, "Cloud" end
		warn("[ADAPT] Profile load failed, attempt", attempt, "user", player.UserId)
		if attempt < 3 then task.wait(attempt) end
	end
	-- A failed load must never overwrite a real cloud save with defaults.
	return Schema.defaults(), "ReadOnly"
end
function Persistence:Save(player, profile, release)
	local session = self.sessions[player]
	if not session then return false end
	if release then session.releasing = true end
	local deadline = os.clock() + 12
	while session.saving and os.clock() < deadline do task.wait(0.1) end
	if session.saving then return false end
	if self.sessions[player] ~= session then return true end
	if not self.enabled or not session.writable then
		if release then self.sessions[player] = nil end
		return not self.enabled
	end
	-- An autosave scheduled before removal cannot reclaim a released lease.
	if session.releasing and not release then return false end
	session.saving = true
	local snapshot = Schema.sanitize(profile, Adaptations, Synergies, Areas)
	local success = false
	for attempt = 1, 3 do
		local leaseLost = false
		local ok, result = pcall(function()
			return self.store:UpdateAsync("u_" .. player.UserId, function(record)
				if not record or not record.session or record.session.id ~= session.id then leaseLost = true; return nil end
				return { version = Config.SchemaVersion, data = snapshot, session = not release and { id = session.id, expires = os.time() + Config.SessionLeaseSeconds } or nil }
			end)
		end)
		if leaseLost then session.writable = false; player:Kick("Sua sessão de dados mudou. Entre novamente para proteger seu progresso."); break end
		if ok and result then success = true; break end
		if attempt < 3 then task.wait(attempt) end
	end
	session.saving = false
	if release then self.sessions[player] = nil end
	if not success then warn("[ADAPT] Save failed for", player.UserId, "(previous cloud data preserved)") end
	return success
end
return Persistence
