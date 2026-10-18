--!nonstrict
local TweenService = game:GetService("TweenService")
local Gui = {}
Gui.Theme = {
	background = Color3.fromRGB(19, 23, 40), panel = Color3.fromRGB(35, 39, 62), muted = Color3.fromRGB(188, 198, 218),
	text = Color3.fromRGB(245, 248, 255), accent = Color3.fromRGB(170, 151, 255), mint = Color3.fromRGB(101, 240, 200),
	ink = Color3.fromRGB(22, 29, 44), danger = Color3.fromRGB(255, 131, 155), border = Color3.fromRGB(101, 111, 141),
}
function Gui.new(class, props, parent)
	local object = Instance.new(class)
	for key, value in props do object[key] = value end
	object.Parent = parent; return object
end
function Gui.round(object, radius)
	Gui.new("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, object)
	return object
end
function Gui.stroke(object, color)
	return Gui.new("UIStroke", { Color = color or Gui.Theme.border, Thickness = 1.5 }, object)
end
function Gui.label(parent, text, size, position, fontSize, color)
	return Gui.new("TextLabel", { Text = text, Size = size, Position = position, BackgroundTransparency = 1, FontFace = Font.fromEnum(Enum.Font.GothamMedium), TextSize = fontSize or 16, TextColor3 = color or Gui.Theme.text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true }, parent)
end
function Gui.button(parent, text, size, position, callback, color)
	local button = Gui.round(Gui.new("TextButton", { Text = text, Size = size, Position = position, BackgroundColor3 = color or Gui.Theme.panel, TextColor3 = Gui.Theme.text, FontFace = Font.fromEnum(Enum.Font.GothamBold), TextSize = 15, AutoButtonColor = true, Selectable = true }, parent), 12)
	Gui.stroke(button)
	button.Activated:Connect(callback)
	return button
end
function Gui.modal(root, title)
	local scrim = Gui.new("Frame", { Name = title, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.25, Visible = false, Active = true, ZIndex = 5 }, root)
	local panel = Gui.round(Gui.new("Frame", { Size = UDim2.fromOffset(800, 480), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Gui.Theme.background }, scrim), 20)
	Gui.stroke(panel)
	Gui.label(panel, title, UDim2.new(1, -100, 0, 40), UDim2.fromOffset(20, 12), 23)
	return scrim, panel
end
function Gui.tween(object, properties, reduced)
	if reduced then for key, value in properties do object[key] = value end; return end
	TweenService:Create(object, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end
return Gui
