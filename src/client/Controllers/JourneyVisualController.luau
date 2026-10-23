--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Visual = {}
function Visual.new()
	local self = setmetatable({ objects = {} }, { __index = Visual })
	local function add(object) self.objects[object] = object.Color; self:Apply(object) end
	for _, object in CollectionService:GetTagged("JourneyObject") do add(object) end
	self.added = CollectionService:GetInstanceAddedSignal("JourneyObject"):Connect(add)
	self.removed = CollectionService:GetInstanceRemovedSignal("JourneyObject"):Connect(function(object) self.objects[object] = nil end)
	return self
end
function Visual:Apply(object)
	if not self.progress or not object.Parent then return end
	local id = object:GetAttribute("Memory"); local area = object:GetAttribute("Shrine")
	local done = id and self.progress.runes[id] or area and self.progress.seals[area]
	object.LocalTransparencyModifier = id and done and .8 or 0
	object.Color = done and Color3.fromRGB(248, 223, 146) or self.objects[object]
	local prompt = object:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = not (id and done)
		if area then prompt.ActionText = done and "Restaurado" or "Restaurar" end
	end
end
function Visual:Update(state)
	self.progress = state.profile.journey
	for object in self.objects do self:Apply(object) end
end
function Visual:Destroy() self.added:Disconnect(); self.removed:Disconnect(); self.objects = {} end
return Visual
