--!strict
local Limiter = {}
Limiter.__index = Limiter
type Bucket = { tokens: number, time: number }
type State = { buckets: { [string]: Bucket } }
function Limiter.new(): any
	return setmetatable({ buckets = {} }, Limiter)
end
function Limiter.allow(self: State, key: string, now: number, rate: number, burst: number): boolean
	local b = self.buckets[key] or { tokens = burst, time = now }
	b.tokens = math.min(burst, b.tokens + math.max(0, now - b.time) * rate)
	b.time = now; self.buckets[key] = b
	if b.tokens < 1 then return false end
	b.tokens -= 1; return true
end
function Limiter.removePrefix(self: State, prefix: string)
	for key in self.buckets do if string.sub(key, 1, #prefix) == prefix then self.buckets[key] = nil end end
end
return Limiter
