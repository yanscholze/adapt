--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local folder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {}
for _, name in Config.Remotes do remotes[name] = folder:WaitForChild(name) end
local Controllers = script.Controllers
local Hud = require(Controllers.HudController)
local Ability = require(Controllers.AbilityController)
local Night = require(Controllers.NightVisionController)
local Feedback = require(Controllers.FeedbackController)
local Animation = require(Controllers.AnimationController)
local Environment = require(Controllers.EnvironmentController)
local hud = Hud.new(remotes)
local ability = Ability.new(remotes, function() return hud.choice.scrim.Visible or hud.codex.scrim.Visible end)
local night = Night.new()
local feedback = Feedback.new(hud)
local animation = Animation.new()
local environment = Environment.new()
local receivedState = false
remotes.State.OnClientEvent:Connect(function(state)
	receivedState = true; hud:Update(state); ability:Update(state); night:Update(state); feedback:Update(state); animation:Update(state); environment:Update(state)
end)
remotes.Feedback.OnClientEvent:Connect(function(kind, value, extra) feedback:Event(kind, value, extra); if kind == "Area" then environment:Area(value) end end)
CAS:BindAction("AdaptCodex", function(_, input)
	if input == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() and not hud.choice.scrim.Visible then hud.codex:Toggle() end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.C, Enum.KeyCode.ButtonSelect)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local index = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 })[input.KeyCode]
	if index and hud.choice.scrim.Visible then hud.choice:Pick(index) end
	if input.KeyCode == Enum.KeyCode.Escape then hud.codex.scrim.Visible = false; hud.debug.Visible = false end
end)

local viewportConnection
local function cameraChanged()
	if viewportConnection then viewportConnection:Disconnect() end
	local camera = workspace.CurrentCamera; if not camera then return end
	local function resize() hud:Resize(camera.ViewportSize) end
	viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()
	local char = Players.LocalPlayer.Character; local h = char and char:FindFirstChildOfClass("Humanoid")
	if h then camera.CameraSubject = h end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged); cameraChanged()
Players.LocalPlayer.CharacterAdded:Connect(function(char)
	local h = char:WaitForChild("Humanoid", 10)
	if h and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = h end
end)

local accumulated = 0
RunService.Heartbeat:Connect(function(dt)
	environment:Step(dt)
	accumulated += dt; if accumulated < 0.2 then return end; accumulated = 0
	local char = Players.LocalPlayer.Character; local h = char and char:FindFirstChildOfClass("Humanoid")
	if h then hud:Vitals(h.Health, char:GetAttribute("AbilityStamina") or 1, char:GetAttribute("AbilityMode") or "None") end
	feedback:Step()
end)
task.spawn(function()
	for _ = 1, 15 do
		if receivedState then break end
		remotes.RequestState:FireServer(); task.wait(1)
	end
	if not receivedState then hud:Message("Não foi possível carregar o estado. Confira o Output do servidor e reinicie o teste.") end
end)
