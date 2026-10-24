--!nonstrict
-- Original, asset-free geometry. All decoration is massless and non-colliding;
-- the R6 skeleton remains the sole movement/collision rig.
local Definitions = require(script.Parent.Adaptations)
local Progression = require(script.Parent.Progression)
local Synergies = require(script.Parent.Synergies)
local Art = {}
local cream = Color3.fromRGB(232, 244, 215)
local jade = Color3.fromRGB(62, 169, 157)
local function part(folder, name, size, cf, color, class)
	local p = Instance.new(class or "Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = Enum.Material.SmoothPlastic; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false; p.Massless = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
	p.CastShadow = true; p.Parent = folder
	return p
end
local function weld(p, root)
	local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = p; w.Parent = p
end
local function oval(folder, root, name, size, offset, color)
	local p = part(folder, name, size, root.CFrame * offset, color)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Scale = Vector3.one; mesh.Parent = p
	weld(p, root); return p, mesh
end
local function pivot(folder, root, name, offset)
	local p = part(folder, name, Vector3.new(.1,.1,.1), root.CFrame * offset, cream); p.Transparency = 1; p.CastShadow = false
	local joint = Instance.new("Motor6D"); joint.Name = name; joint.Part0 = root; joint.Part1 = p; joint.C0 = offset; joint.Parent = p
	return p
end
-- A triangle is split at the altitude onto its longest edge. Each thin wedge
-- supplies a right triangle; this is actual 3D geometry, not a billboard.
local function triangle(folder, root, name, a, b, c, color)
	local ab, ac, bc = b-a, c-a, c-b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then c, a = a, c
	elseif ac:Dot(ac) > bc:Dot(bc) then a, b = b, a end
	ab, ac, bc = b-a, c-a, c-b
	local right = ac:Cross(ab).Unit
	local back = bc.Unit; local up = bc:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	for _, data in { {a+b, math.abs(ab:Dot(back)), right, back}, {a+c, math.abs(ac:Dot(back)), -right, -back} } do
		local p = part(folder, name, Vector3.new(.012, height, data[2]), root.CFrame * CFrame.fromMatrix(data[1]/2, data[3], up, data[4]), color, "WedgePart")
		p.Reflectance = .06; weld(p, root)
	end
end
local function crystal(folder, root, name, start, tip, width, depth, color)
	local direction = (tip-start).Unit
	local side = direction:Cross(Vector3.zAxis)
	if side.Magnitude < .05 then side = direction:Cross(Vector3.yAxis) end
	side = side.Unit; local normal = direction:Cross(side).Unit
	local middle = start:Lerp(tip, .36)
	local ring = { middle+side*width/2, middle+normal*depth/2, middle-side*width/2, middle-normal*depth/2 }
	for i = 1, 4 do
		local nextVertex = ring[i%4+1]
		local tint = color:Lerp(i%2 == 0 and Color3.new(1,1,1) or Color3.fromRGB(58,53,119), i%2 == 0 and .23 or .14)
		triangle(folder, root, name, start, nextVertex, ring[i], tint)
		triangle(folder, root, name, tip, ring[i], nextVertex, color:Lerp(Color3.new(1,1,1), i == 2 and .48 or .08))
	end
end
function Art.build(model, profile)
	local old = model:FindFirstChild("Appearance"); if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = "Appearance"; folder.Parent = model
	local torso, head = model.Torso, model.Head
	oval(folder, torso, "BlankBody", Vector3.new(2.45,2.85,2), CFrame.new(0,-.18,0), cream)
	oval(folder, torso, "Belly", Vector3.new(2,2.4,1.75), CFrame.new(0,-.24,-.18), Color3.fromRGB(244,244,216))
	oval(folder, head, "BlankHead", Vector3.new(3.15,2.95,2.65), CFrame.new(0,.35,-.08), cream)
	local eyeColor = Color3.fromRGB(16,88,94)
	local eyeDef = profile.equipped.Head and Definitions[profile.equipped.Head]
	if eyeDef then eyeColor = Color3.fromRGB(table.unpack(eyeDef.visualData.color)) end
	for _, side in {-1,1} do
		local label = side == -1 and "Left" or "Right"
		local arm, leg = model[label.." Arm"], model[label.." Leg"]
		oval(folder, arm, "Forearm", Vector3.new(.95,1.55,1.08), CFrame.new(0,-.13,0), cream)
		oval(folder, arm, "Paw", Vector3.new(1.08,.85,1.17), CFrame.new(0,-.77,-.13), jade)
		oval(folder, leg, "Haunch", Vector3.new(1.2,1.65,1.25), CFrame.new(0,.08,0), cream)
		oval(folder, leg, "Foot", Vector3.new(1.3,.78,1.7), CFrame.new(0,-.65,-.26), jade)
		for digit = -1, 1 do
			oval(folder, leg, "Toe", Vector3.new(.33,.32,.5), CFrame.new(digit*.34,-.7,-.99), jade:Lerp(cream,.2))
		end
		local eyeFrame = CFrame.new(side*.65,.45,-1.25)*CFrame.Angles(0,side*-.24,side*-.06)
		local _, eye = oval(folder, head, "Eye", Vector3.new(.64,.94,.26), eyeFrame, Color3.fromRGB(10,25,39)); eye:SetAttribute("Blink",true)
		local iris, irisMesh = oval(folder, head, "Iris", Vector3.new(.38,.3,.045), eyeFrame*CFrame.new(0,-.19,-.128), eyeColor)
		irisMesh:SetAttribute("Blink",true); irisMesh:SetAttribute("BlinkOffset",Vector3.new(0,.19,0)); if eyeDef then iris.Material = Enum.Material.Neon end
		local _, shine = oval(folder, head, "EyeGlint", Vector3.new(.18,.23,.065), eyeFrame*CFrame.new(-.1,.22,-.14), Color3.fromRGB(255,255,241)); shine:SetAttribute("Blink",true); shine:SetAttribute("BlinkOffset",Vector3.new(0,-.22,0))
		local _, small = oval(folder, head, "EyeGlintSmall", Vector3.new(.065,.07,.04), eyeFrame*CFrame.new(.12,-.03,-.145), Color3.fromRGB(157,228,222)); small:SetAttribute("Blink",true); small:SetAttribute("BlinkOffset",Vector3.new(0,.03,0))
	end
	for slot, id in profile.equipped do
		local def = Definitions[id]; local visual = def.visualData; local color = Color3.fromRGB(table.unpack(visual.color))
		model:SetAttribute("Slot"..slot,id)
		if visual.kind == "Wings" then
			for _, side in {-1,1} do
				local wing = pivot(folder,torso,side == -1 and "WingLeft" or "WingRight",CFrame.new(side*.85,.45,.8))
				local tint = id == "Wings" and Color3.fromRGB(174,134,239) or color
				for _, blade in {{2.35,2.6,.3,1.4},{2.9,.85,.5,1.15},{2.1,-.65,.65,.8}} do
					crystal(folder,wing,"Wing",Vector3.new(0,0,0),Vector3.new(side*blade[1],blade[2],blade[3])*visual.scale,blade[4]*visual.scale,.45,tint)
				end
				oval(folder,wing,"WingRoot",Vector3.new(.55,.7,.55),CFrame.identity,tint:Lerp(cream,.5))
			end
		elseif visual.kind == "Claws" then
			for _, side in {-1,1} do
				local arm = model[side == -1 and "Left Arm" or "Right Arm"]
				for digit = -1,1 do
					crystal(folder,arm,"Claw",Vector3.new(digit*.31,-.76,-.5),Vector3.new(digit*.4,-1.45,-1.1)*Vector3.new(1,visual.scale,1),.44,.4,color)
				end
			end
		elseif visual.kind == "Tail" then
			local tail = pivot(folder,torso,"TailBase",CFrame.new(0,-.85,.8)*CFrame.Angles(-.25,0,0))
			oval(folder,tail,"TideTail",Vector3.new(.65,.7,1.65),CFrame.new(0,0,.6),color)
			local tip = pivot(folder,tail,"TailTip",CFrame.new(0,0,1.25)*CFrame.Angles(-.2,0,0))
			oval(folder,tip,"TailTaper",Vector3.new(.45,.5,1.3),CFrame.new(0,0,.45),color)
			for _, side in {-1,1} do crystal(folder,tip,"TailFin",Vector3.new(0,0,.75),Vector3.new(side*1.25,.25,2),.75,.13,color:Lerp(cream,.35)) end
		elseif visual.kind == "Shell" then
			oval(folder,torso,"EmberCarapace",Vector3.new(2.65,2.6,1.4),CFrame.new(0,-.2,.65),color:Lerp(Color3.fromRGB(105,61,57),.4))
			for i=-1,1 do crystal(folder,torso,"ShellFacet",Vector3.new(i*.6,-.9,1.25),Vector3.new(i*.7,1.1,1.3),.6,.25,color) end
		elseif visual.kind == "Legs" then
			for _, side in {-1,1} do
				local leg = model[side == -1 and "Left Leg" or "Right Leg"]
				oval(folder,leg,"SpringPaw",Vector3.new(1.38,.85,1.8),CFrame.new(0,-.6,-.25),color)
				oval(folder,leg,"SpringCuff",Vector3.new(1.25,.4,1.3),CFrame.new(0,-.05,0),color:Lerp(jade,.45))
			end
		end
	end
	for _, slot in {"Head","Body","Arms","Legs","Back","Tail"} do if not profile.equipped[slot] then model:SetAttribute("Slot"..slot,nil) end end
	if #Progression.synergies(profile.equipped,Definitions,Synergies) > 0 then
		local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(190,170,255); light.Brightness = .45; light.Range = 6; light.Parent = folder.BlankBody
	end
	if profile.journey and profile.journey.complete then
		for i=1,5 do
			local a = i*math.pi*2/5; local base = Vector3.new(math.cos(a)*.8,1.6,math.sin(a)*.7-.08)
			crystal(folder,head,"WorldkeeperCrown",base,base+Vector3.new(0,.65,0),.28,.28,Color3.fromRGB(255,216,119))
		end
	end
	folder:SetAttribute("ArtVersion",2)
	return folder
end
return Art
