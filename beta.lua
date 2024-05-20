-- [[ Stand proud. ]] --
local Modules = loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Gelatek-Hub/main/lib/misc/modules.lua"))()
local Global = getfenv(0).xyzkade

local Tween = game:FindFirstChildOfClass("TweenService")
local BaseTweenInf = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local Color3RGB = Color3.fromRGB
local FalseButton = Color3RGB(204, 107, 107)
local TrueButton = Color3RGB(120, 204, 107)

local LocalPlayer = game:FindFirstChildOfClass("Players").LocalPlayer
local Main = Global.CreateFrame()
local AddScript = Main[1]
local AnimIdPlayer = Main[2]
local ReanimateButton = Main[3]
local SettingButtons = Main[4] -- DP, NC, Fling, FL
local StopScript = Main[5]
local Reanim = nil

local function ChangeSetting(Button, Name)
	Button.MouseButton1Down:Connect(function()
		local Boolean = not Global.Kades_Stuff[Name]
		Global.Kades_Stuff[Name] = Boolean
		
		local ColorTween = Tween:Create(Button, BaseTweenInf, {TextColor3 = Boolean and TrueButton or FalseButton})
		ColorTween:Play()
		
		ColorTween.Completed:Once(function()
			ColorTween:Destroy()
		end)
	end)
end


local CurrentAnimation = nil
local Playing = false
local function PlayAnimation(ID)
	local Character = Global.GelatekRig

	if not Character then
		Global.MessageBox({"Error", "Not Reanimated.", 3})
		return
	end
	local InsertService = game:GetService("InsertService")

	local Joints, Frames, Positions = {}, {}, {}

	Playing = false

	task.wait(1)
	
	local x = ID
	local succ, err = InsertService:LoadLocalAsset("rbxassetid://"..tostring(x))
	
	if err then
		Global.MessageBox({"Error", "No Animation Returned from Roblox.", 3})
		--return
	end

	CurrentAnimation = succ -- for some reason this bypasses some anims not being able to be copied
	CurrentAnimation.Name = "AnimPlayer"
	CurrentAnimation.Parent = Character

	local Sound = Instance.new("Sound"); do
		Sound.Looped = true
		Sound.Name = "Music"
		Sound.Volume = 1

		Sound.Parent = workspace.CurrentCamera
	end
	
	Joints['Head'] = Character:FindFirstChild("Neck", true)

	for _, v in next, Character:GetDescendants() do
		if v:IsA("Motor6D") and v.Name ~= "Neck" then
			Joints[v.Part1.Name] = v
		end
	end
	
	for _, Frame in next, CurrentAnimation:GetChildren() do
		table.insert(Frames, Frame.Time)
		Positions[Frame.Time] = {}

		for _1, Time in pairs(Frame:GetDescendants()) do
			Time.Parent = Frame; 
			table.insert(Positions[Frame.Time],Time)
		end
	end
	
	Playing = true
	task.spawn(function()
		while Playing do
			if not Playing then
				table.clear(Frames)
				table.clear(Positions)
				table.clear(Joints)
				break
			end
	
			for i,v in pairs(Frames) do
				if not Playing then
					break
				end

				if Frames[i-1] then
				   task.wait(Frames[i-1])
				end

				for i2,v2 in pairs(Positions[v]) do
					if not Playing then
						break
					end
					
					if Joints[v2.Name] then
						Joints[v2.Name].Transform = v2.CFrame
					end
				end
			end
			task.wait(Frames[#Frames])
		end

		Sound:Destroy()
		CurrentAnimation:Destroy()
	end)
end

AnimIdPlayer.FocusLost:Connect(function(EnterPress)
	if EnterPress then
		PlayAnimation(AnimIdPlayer.Text)
	end
end)

ReanimateButton.MouseButton1Down:Connect(function()
	if Global.GelatekRig then
		Global.MessageBox({"Error", "Reanimaton should be running already.", 3})
		return
	end

	Reanim = Global.Reanimation()
end)

StopScript.MouseButton1Down:Connect(function()
	if Global.ScriptRunning then
		Reanim[2](true)
		Global.ScriptRunning = false
	else
		Global.MessageBox({"Error", "No Script / Reanimation to stop.", 3})
	end
end)

ChangeSetting(SettingButtons[1], 'DedPoint')
ChangeSetting(SettingButtons[2], 'NCollide')
ChangeSetting(SettingButtons[3], 'Flinging')
ChangeSetting(SettingButtons[4], 'FastLoad')

local function ScriptLoad(Name)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/KadeTheExploiter/Gelatek-Hub/main/lib/scripts/"..Name..".lua"))()
end

AddScript("Sniper", "Unknown Creator", function() 
	ScriptLoad("sniper")
end)
