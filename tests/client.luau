--!nonstrict
local H = require("../scripts/RobloxHarness")
local h = H.new("build/ADAPT.rbxlx")
local r = H.roblox
local p = r.Instance.new("Player"); p.Name = "LocalTester"; p.Parent = h.game:GetService("Players")
h.game:GetService("Players").LocalPlayer = p
local playerGui = r.Instance.new("PlayerGui"); playerGui.Parent = p
local World = h.require(h.services.WorldService); World:Init()
local players = { records = {} }
local Essence = h.require(h.services.EssenceService); Essence:Init(World, players, h.remotes, function() return true end)
local Schema = h.require(h.shared.ProfileSchema)
local profile = Schema.defaults()
local state = { profile = profile, threshold = 30, persistence = "StudioMemory", activeSynergies = {}, debug = true }
local Hud = h.require(h.controllers.HudController)
local hud = Hud.new(h.remotes)
local checks = 0
local function check(name, fn) fn(); checks += 1; print("PASS", name) end
check("HUD, choice, Codex and debug UI construct successfully", function()
	hud:Update(state)
	assert(hud.screen.Parent == playerGui and hud.debugButton.Visible and #hud.choice.cards == 0)
end)
check("portrait, landscape, tablet and desktop modal bounds fit viewport", function()
	for _, size in { r.Vector2.new(375, 667), r.Vector2.new(667, 375), r.Vector2.new(360, 640), r.Vector2.new(768, 1024), r.Vector2.new(1440, 900) } do
		hud:Resize(size)
		for _, panel in { hud.choice.panel, hud.codex.panel } do assert(panel.Size.X.Offset <= size.X - 24 and panel.Size.Y.Offset <= size.Y - 24) end
		assert(hud.codexButton.Size.Y.Offset >= 44 and hud.hud.Size.X.Offset + hud.codexButton.Size.X.Offset + 36 <= size.X)
		assert(hud.choice.layout.CellSize.Y.Offset >= 150 or hud.choice.layout.CellSize.Y.Scale == 1)
	end
end)
check("touch guidance clears the movement and jump controls", function()
	h.overrides.UserInputService.TouchEnabled = true; hud:Resize(r.Vector2.new(375, 667))
	assert(hud.guide.Position.Y.Offset == 170 and hud.guide.AnchorPoint.Y == 0 and not hud.mode.Visible)
	h.overrides.UserInputService.TouchEnabled = false
end)
check("choice submits server token exactly once while waiting for response", function()
	state.pending = { token = "test-choice", options = { "Wings", "GripClaws", "NightEyes" } }; hud:Update(state)
	assert(#hud.choice.cards == 3 and hud.choice.scrim.Visible)
	local before = #h.messages; hud.choice:Pick(1); hud.choice:Pick(2)
	assert(#h.messages == before + 1 and h.messages[#h.messages].args[1] == "test-choice" and h.messages[#h.messages].args[2] == "Wings")
end)
check("server state closes choice and discovered Codex rows reveal only unlocked data", function()
	state.pending = nil; profile.discovered.Wings = true; hud:Update(state)
	assert(not hud.choice.scrim.Visible)
	local hidden, found = false, false
	for _, row in hud.codex.list:GetDescendants() do
		if row:IsA("TextLabel") then if row.Text == "???" then hidden = true elseif row.Text == "Wings" then found = true end end
	end
	assert(hidden and found)
end)
check("local Night Eyes reveals hidden objects and respects unavailable Essence", function()
	local Night = h.require(h.controllers.NightVisionController); local night = Night.new()
	local orb = Essence.nodes[19].part
	night:Update(state); assert(orb.Transparency == 1)
	profile.equipped.Head = "NightEyes"; night:Update(state); assert(orb.Transparency < 1)
	orb:SetAttribute("Available", false); night:Update(state); assert(orb.Transparency == 1)
	profile.equipped.Head = nil; night:Update(state); assert(World.model.Core.HiddenGlyph.Transparency == 1)
	night:Destroy()
end)
check("client cleanup disconnects reveal subscriptions", function()
	local Night = h.require(h.controllers.NightVisionController); local night = Night.new(); night:Destroy()
	assert(night.added and night.removed)
end)
check("touch ability buttons unlock with anatomy and modal blocks attacks", function()
	local Ability = h.require(h.controllers.AbilityController); local modal = false
	local ability = Ability.new(h.remotes, function() return modal end); ability:Update(state)
	assert(not h.touchButtons.AdaptGlide.Visible and not h.touchButtons.AdaptClimb.Visible and h.touchButtons.AdaptAttack.Visible)
	profile.equipped.Back = "Wings"; ability:Update(state); assert(h.touchButtons.AdaptGlide.Visible and h.touchButtons.AdaptGlide.Size.Y.Offset >= 44)
	local count = #h.messages; modal = true; h.bindings.AdaptAttack(nil, r.Enum.UserInputState.Begin); assert(#h.messages == count)
	modal = false; h.bindings.AdaptAttack(nil, r.Enum.UserInputState.Begin); assert(#h.messages == count + 1)
	ability:Destroy(); assert(not h.bindings.AdaptGlide)
end)
check("closing the actual intro releases movement and does not reopen on state refresh", function()
	local Ability = h.require(h.controllers.AbilityController)
	hud.journal.introShown = nil; hud:Update(state)
	local ability = Ability.new(h.remotes, function() return hud:IsModal() end)
	assert(h.bindings.AdaptModalMovement() == r.Enum.ContextActionResult.Sink)
	h.overrides.GuiService.SelectedObject = hud.journal.primary
	hud.journal.primary.Activated:Fire()
	assert(not hud:IsModal() and h.overrides.GuiService.SelectedObject == nil)
	assert(h.bindings.AdaptModalMovement() == r.Enum.ContextActionResult.Pass)
	hud:Update(state); assert(not hud:IsModal())
	hud.journal:Toggle(); assert(hud:IsModal())
	hud.journal:Toggle(); assert(not hud:IsModal() and h.overrides.GuiService.SelectedObject == nil)
	ability:Destroy()
end)
local function rig()
	local model = r.Instance.new("Model"); model.Parent = h.workspace
	local root = r.Instance.new("Part"); root.Name = "HumanoidRootPart"; root.CFrame = r.CFrame.new(21, 5, 40); root.Parent = model
	local humanoid = r.Instance.new("Humanoid"); humanoid.Parent = model
	return model
end
local cameraController
check("camera binds an existing character and leaves the editor aerial view", function()
	p.Character = rig()
	local camera = r.Instance.new("Camera"); camera.Parent = h.workspace
	camera.CameraType = r.Enum.CameraType.Scriptable; camera.CFrame = r.CFrame.new(-1150, 1600, -2050)
	h.workspace.CurrentCamera = camera
	cameraController = h.require(h.controllers.CameraController).new()
	assert(camera.CameraType == r.Enum.CameraType.Custom and camera.CameraSubject == p.Character.Humanoid)
	assert((camera.CFrame.Position - p.Character.HumanoidRootPart.CFrame.Position).Magnitude < 25)
end)
check("camera waits for replicated rig parts and ignores an obsolete character", function()
	local old = p.Character
	local model = r.Instance.new("Model"); p.Character = model; p.CharacterAdded:Fire(model)
	local root = r.Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = model; model.ChildAdded:Fire(root)
	local humanoid = r.Instance.new("Humanoid"); humanoid.Parent = model; model.ChildAdded:Fire(humanoid)
	model.Parent = h.workspace; model.AncestryChanged:Fire()
	assert(h.workspace.CurrentCamera.CameraSubject == humanoid)
	old.ChildAdded:Fire(root); assert(h.workspace.CurrentCamera.CameraSubject == humanoid)
end)
check("replacement camera and respawn rebind but ordinary updates preserve user orbit", function()
	local camera = r.Instance.new("Camera"); camera.Parent = h.workspace; h.workspace.CurrentCamera = camera
	h.workspace:GetPropertyChangedSignal("CurrentCamera"):Fire()
	assert(camera.CameraSubject == p.Character.Humanoid and camera.CameraType == r.Enum.CameraType.Custom)
	local orbit = r.CFrame.new(8, 9, 10); camera.CFrame = orbit; cameraController:Refresh()
	assert(camera.CFrame == orbit)
	p.Character = rig(); p.CharacterAdded:Fire(p.Character)
	assert(camera.CameraSubject == p.Character.Humanoid and camera.CFrame ~= orbit)
end)
check("camera disconnects on cleanup", function()
	local camera = h.workspace.CurrentCamera
	cameraController:Destroy(); p.Character = rig(); p.CharacterAdded:Fire(p.Character)
	assert(camera.CameraSubject ~= p.Character.Humanoid)
end)
print("CLIENT:", checks, "checks passed (UI and camera contracts; no engine input/physics verification)")
