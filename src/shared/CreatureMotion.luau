--!nonstrict
-- Pure pose sampler shared by runtime, regression tests and model previews.
local Motion = {}
function Motion.sample(state, time, phase, reduced)
	local speed = math.clamp(state.speed or 0,0,32)
	local weight = math.clamp(speed/16,0,1)
	local soft = reduced and .25 or 1
	local swing = math.sin(phase)*.62*weight
	local breathe = math.sin(time*1.9)*.035*soft
	local pose = {
		RootJoint = CFrame.new(0,breathe+math.abs(math.cos(phase))*.07*weight*soft,0)*CFrame.Angles(-.07*weight,0,math.sin(phase)*.035*weight*soft),
		Neck = CFrame.Angles(.025*math.sin(time*1.3)*soft, .055*math.sin(time*.65)*soft, 0),
	}
	for _, side in {-1,1} do
		local label = side == -1 and "Left" or "Right"
		pose[label.." Hip"] = CFrame.Angles(swing*side,0,side*.035)
		pose[label.." Shoulder"] = CFrame.Angles(-swing*side*.8,0,side*.12)
		local wingYaw, wingRoll = side*.68, side*-.12
		if state.mode == "Glide" then
			pose.RootJoint = CFrame.new(0,breathe,0)*CFrame.Angles(-.22,0,0)
			pose[label.." Hip"] = CFrame.Angles(.38,0,side*.15)
			pose[label.." Shoulder"] = CFrame.Angles(-.35,0,side*-.6)
			wingYaw = side*.08; wingRoll = side*(.12+math.sin(time*4)*.16*soft)
		elseif state.mode == "Climb" then
			pose[label.." Shoulder"] = CFrame.Angles(-2+math.sin(time*7+side)*.45,0,side*.14)
			pose[label.." Hip"] = CFrame.Angles(.35+math.sin(time*7+side)*.45,0,side*.1)
			pose.RootJoint = CFrame.new(0,math.sin(time*14)*.035*soft,0)*CFrame.Angles(.08,0,0)
			wingYaw = side*1.05
		elseif state.swim then
			pose.RootJoint = CFrame.Angles(-.65,0,math.sin(time*3)*.04*soft)
			pose[label.." Shoulder"] = CFrame.Angles(math.sin(time*4+side)*.7,side*.2,side*-.65)
			pose[label.." Hip"] = CFrame.Angles(math.sin(time*5)*side*.35,0,side*.15)
			wingYaw = side*1.15
		elseif state.air then
			local rising = (state.vertical or 0) > 1
			pose.RootJoint = CFrame.Angles(rising and -.12 or .12,0,0)
			pose[label.." Hip"] = CFrame.Angles(rising and -.4 or .2,0,side*.12)
			pose[label.." Shoulder"] = CFrame.Angles(-.3,0,side*(rising and -.3 or -.55))
		end
		pose["Wing"..label] = CFrame.Angles(0,wingYaw,wingRoll)
	end
	local attack = state.attackAge
	if attack and attack >= 0 and attack < .5 then
		local strike = math.sin(math.min(1,attack/.32)*math.pi)
		pose["Right Shoulder"] = CFrame.Angles(-1.4*strike,.25*strike,-.2)
		pose.RootJoint *= CFrame.Angles(0,-.22*strike,0)
	end
	local landing = state.landAge
	if landing and landing >= 0 and landing < .25 and not state.air then
		pose.RootJoint *= CFrame.new(0,-math.sin(landing/.25*math.pi)*.18*soft,0)
	end
	local tailSpeed = state.swim and 6 or 2.1
	pose.TailBase = CFrame.Angles(math.sin(time*1.4)*.08*soft,math.sin(time*tailSpeed)*.23*soft,0)
	pose.TailTip = CFrame.Angles(0,math.sin(time*tailSpeed-.7)*.32*soft,0)
	local blinkPhase = time%4.7
	local blink = blinkPhase < .16 and (1-.94*math.sin(blinkPhase/.16*math.pi)) or 1
	return pose, blink
end
return Motion
