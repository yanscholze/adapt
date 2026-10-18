--!nonstrict
local CollectionService=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Environment={}
local moods={
 ["VERDANT ISLAND"]={Color3.fromRGB(255,250,237),.02},
 ["EMBER ATOLL"]={Color3.fromRGB(255,225,205),.04},
 ["RIFT CROWN"]={Color3.fromRGB(226,242,255),.02},
 ["SKY REACH"]={Color3.fromRGB(235,240,255),.04},
 ["OLDGROWTH SANCTUARY"]={Color3.fromRGB(220,247,230),-.01},
 ["SUNSCAR EXPANSE"]={Color3.fromRGB(255,238,210),.03},
 ["TIDEGLASS REEFS"]={Color3.fromRGB(225,255,250),.02},
 ["VESPER HOLLOW"]={Color3.fromRGB(234,223,255),.02},
}
function Environment.new()
 local self=setmetatable({elapsed=0,emitters={},reduced=false},{__index=Environment})
 self.effect=Instance.new("ColorCorrectionEffect");self.effect.Name="LocalBiomeMood";self.effect.Parent=Lighting
 local function add(emitter) self.emitters[emitter]=true end
 for _, emitter in CollectionService:GetTagged("AmbientEmitter") do add(emitter) end
 self.added=CollectionService:GetInstanceAddedSignal("AmbientEmitter"):Connect(add)
 self.removed=CollectionService:GetInstanceRemovedSignal("AmbientEmitter"):Connect(function(e) self.emitters[e]=nil end)
 return self
end
function Environment:Area(name)
 local mood=moods[name] or {Color3.new(1,1,1),0}
 if self.tween then self.tween:Cancel() end
 self.tween=TweenService:Create(self.effect,TweenInfo.new(self.reduced and 0 or 1.6),{TintColor=mood[1],Brightness=mood[2]});self.tween:Play()
end
function Environment:Step(dt)
 self.elapsed+=dt;if self.elapsed<1 then return end;self.elapsed=0
 local char=Players.LocalPlayer.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
 for emitter in self.emitters do
  local parent=emitter.Parent
  if parent and parent:IsA("BasePart") then emitter.Enabled=root~=nil and not self.reduced and (parent.Position-root.Position).Magnitude<460 end
 end
end
function Environment:Update(state) self.reduced=state.profile.settings.reducedMotion end
function Environment:Destroy()
 self.added:Disconnect();self.removed:Disconnect();if self.tween then self.tween:Cancel() end;self.effect:Destroy();self.emitters={}
end
return Environment
