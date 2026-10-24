--!nonstrict
-- Offline data-model adapter, NOT a physics engine or a substitute for Studio.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local Harness = {}
local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			local item = { callback = callback, active = true }; table.insert(callbacks, item)
			return { Disconnect = function() item.active = false end }
		end,
		Fire = function(_, ...) for _, item in callbacks do if item.active then item.callback(...) end end end,
	}
end
local events = {}
local floors = {}
roblox.implementProperty("Humanoid", "FloorMaterial", function(instance) return floors[instance] or roblox.Enum.Material.Air end, function(instance, value) floors[instance] = value end)
local function event(instance, name)
	if not events[instance] then events[instance] = {} end
	if not events[instance][name] then events[instance][name] = signal() end
	return events[instance][name]
end
-- Lune's legacy Font alias needs an explicit FontFace conversion when serializing.
for _, class in { "TextLabel", "TextButton", "TextBox" } do
	roblox.implementProperty(class, "Font", function() return roblox.Enum.Font.GothamMedium end, function(instance, value) instance.FontFace = roblox.Font.fromEnum(value) end)
end
roblox.implementMethod("Instance", "WaitForChild", function(instance, name) return assert(instance:FindFirstChild(name), "Missing child: " .. instance.Name .. "." .. name) end)
roblox.implementMethod("Instance", "GetPropertyChangedSignal", function(instance, name) return event(instance, name) end)
roblox.implementMethod("Instance", "GetAttributeChangedSignal", function(instance, name) return event(instance, "attribute:" .. name) end)
for _, pair in { { "GuiButton", "Activated" }, { "Humanoid", "Died" }, { "Player", "CharacterAdded" }, { "ProximityPrompt", "Triggered" } } do roblox.implementProperty(pair[1], pair[2], function(instance) return event(instance, pair[2]) end) end
for _, name in { "ChildAdded", "AncestryChanged" } do
	roblox.implementProperty("Instance", name, function(instance) return event(instance, name) end)
end
roblox.implementMethod("Humanoid", "GetState", function(instance) return instance:GetAttribute("TestSwimming") and roblox.Enum.HumanoidStateType.Swimming or roblox.Enum.HumanoidStateType.Running end)
roblox.implementMethod("BasePart", "SetNetworkOwner", function() end)
roblox.implementMethod("BasePart", "SetNetworkOwnershipAuto", function() end)
roblox.implementMethod("Humanoid", "TakeDamage", function(h, amount) h.Health = math.max(0, h.Health - amount) end)
roblox.implementMethod("Player", "Kick", function(player, message) player:SetAttribute("Kicked", message) end)
roblox.implementMethod("Model", "PivotTo", function(model, cf)
	local delta = cf * model.PrimaryPart.CFrame:Inverse()
	for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end end
end)
roblox.implementMethod("Players", "GetPlayers", function(players)
	local result = {}; for _, child in players:GetChildren() do if child:IsA("Player") then table.insert(result, child) end end; return result
end)
local randomSeed = 17
local random = { NextInteger = function(_, a, b) randomSeed = (randomSeed * 48271) % 2147483647; return a + randomSeed % (b - a + 1) end }
function Harness.new(path)
	local self = { game = roblox.deserializePlace(fs.readFile(path)), cache = {}, loading = {}, overrides = {}, delayed = {}, messages = {}, ids = 0 }
	self.workspace = self.game:GetService("Workspace")
	-- Contract adapter only: this clones the template and emits CharacterAdded.
	-- It does NOT simulate Roblox injecting PlayerScripts, controls or physics.
	self.characterLoads = {}
	roblox.implementMethod("Player", "LoadCharacterAsync", function(player)
		self.characterLoads[player] = (self.characterLoads[player] or 0) + 1
		if self.loadCharacterHook then self.loadCharacterHook(player) end
		if player.Character then player.Character:Destroy() end
		local model = assert(self.game:GetService("StarterPlayer"):FindFirstChild("StarterCharacter")):Clone()
		model.Name = player.Name; model.Parent = self.workspace; player.Character = model
		model.Humanoid.FloorMaterial = roblox.Enum.Material.Air
		model.Humanoid.MoveDirection = roblox.Vector3.zero
		model.Humanoid.PlatformStand = false; model.Humanoid.AutoRotate = true
		player.CharacterAdded:Fire(model)
	end)
	roblox.implementMethod("Workspace", "Raycast", function(_, ...) if self.raycast then return self.raycast(...) end; return nil end)
	local collection = {
		AddTag = function(_, instance, tag) instance:AddTag(tag) end,
		HasTag = function(_, instance, tag) return instance:HasTag(tag) end,
		GetTagged = function(_, tag)
			local result = {}; for _, instance in self.game:GetDescendants() do if instance:HasTag(tag) then table.insert(result, instance) end end; return result
		end,
		GetInstanceAddedSignal = function() return signal() end,
		GetInstanceRemovedSignal = function() return signal() end,
	}
	self.overrides.CollectionService = collection
	self.overrides.HttpService = {
		GenerateGUID = function() self.ids += 1; return "offline-token-" .. self.ids end,
		JSONEncode = function(_, value) return require("@lune/serde").encode("json", value) end,
	}
	self.overrides.RunService = { IsStudio = function() return true end, Heartbeat = signal(), RenderStepped = signal(), PreSimulation = signal() }
	self.overrides.UserInputService = { TouchEnabled = false, GetFocusedTextBox = function() return nil end }
	self.overrides.GuiService = {}
	self.bindings = {}; self.touchButtons = {}
	self.overrides.ContextActionService = {
		BindAction = function(_, name, callback) self.bindings[name] = callback; self.touchButtons[name] = roblox.Instance.new("TextButton") end,
		BindActionAtPriority = function(_, name, callback) self.bindings[name] = callback end,
		UnbindAction = function(_, name) self.bindings[name] = nil end,
		SetTitle = function() end, SetPosition = function() end,
		GetButton = function(_, name) return self.touchButtons[name] end,
	}
	self.overrides.DataStoreService = { GetDataStore = function() return assert(self.store, "Offline store not configured") end }
	self.overrides.TweenService = { Create = function(_, instance, _, properties) return { Play = function() for key, value in properties do instance[key] = value end end } end }
	self.require = function(module)
		if self.cache[module] then return self.cache[module] end
		assert(not self.loading[module], "Circular require: " .. module:GetFullName())
		assert(module:IsA("ModuleScript"), "Require target is not a module")
		self.loading[module] = true
		local environment = {
			game = { GetService = function(_, name) return self.overrides[name] or self.game:GetService(name) end },
			workspace = self.workspace, script = module, require = self.require,
			Instance = { new = function(class)
				local instance = roblox.Instance.new(class)
				if class == "Humanoid" then instance.FloorMaterial = roblox.Enum.Material.Air; instance.MoveDirection = roblox.Vector3.zero; instance.PlatformStand = false; instance.AutoRotate = true end
				if instance:IsA("BasePart") then instance.AssemblyLinearVelocity = roblox.Vector3.zero end
				return instance
			end }, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, CFrame = roblox.CFrame, Color3 = roblox.Color3,
			NumberRange = roblox.NumberRange, NumberSequence = roblox.NumberSequence, ColorSequence = roblox.ColorSequence, UDim = roblox.UDim, UDim2 = roblox.UDim2, Enum = roblox.Enum, Font = roblox.Font, TweenInfo = { new = function(...) return { ... } end },
			RaycastParams = { new = function() return {} end }, Random = { new = function() return random end },
			task = {
				wait = function() return 0 end,
				spawn = function(callback, ...) return callback(...) end,
				delay = function(seconds, callback) table.insert(self.delayed, { seconds = seconds, callback = callback }) end,
			},
		}
		local result = luau.load(module.Source, { environment = environment, debugName = module:GetFullName() })()
		self.loading[module] = nil; self.cache[module] = result; return result
	end
	self.shared = self.game:GetService("ReplicatedStorage").Shared
	self.services = self.game:GetService("ServerScriptService").Server.Services
	self.controllers = self.game:GetService("StarterPlayer").StarterPlayerScripts.Client.Controllers
	self.remotes = {}
	for _, name in self.require(self.shared.Config).Remotes do
		self.remotes[name] = { FireClient = function(_, player, ...) table.insert(self.messages, { remote = name, player = player, args = { ... } }) end, FireServer = function(_, ...) table.insert(self.messages, { remote = name, args = { ... } }) end }
	end
	return self
end
Harness.roblox = roblox
Harness.signal = signal
return Harness
