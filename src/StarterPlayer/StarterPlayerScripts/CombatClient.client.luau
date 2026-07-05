-- Kampf-Steuerung: Schwert ausruesten, Linksklick = Angriff, Q = Ausweichen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RPG"):WaitForChild("Remotes")
local AttackRequest = remotes:WaitForChild("AttackRequest")
local DodgeRequest = remotes:WaitForChild("DodgeRequest")
local CombatFX = remotes:WaitForChild("CombatFX")

local BASE_GRIP = CFrame.Angles(math.rad(-90), 0, 0)
local SWING_GRIP = CFrame.Angles(math.rad(-90), 0, 0) * CFrame.Angles(math.rad(120), 0, 0)

local function getSword()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("Schwert") -- nur wenn ausgeruestet
end

-- Schwert automatisch ausruesten
local function equipSword()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local sword = (backpack and backpack:FindFirstChild("Schwert")) or char:FindFirstChild("Schwert")
	if sword and not char:FindFirstChild("Schwert") then
		hum:EquipTool(sword)
	end
end

player.CharacterAdded:Connect(function()
	task.wait(0.6)
	equipSword()
end)
if player.Character then task.defer(equipSword) end

-- Schwung-Animation
local function ensureTrail(sword)
	local blade = sword:FindFirstChild("Blade")
	if not blade then return nil end
	local trail = blade:FindFirstChild("SwingTrail")
	if not trail then
		local a0 = Instance.new("Attachment"); a0.Name = "T0"; a0.Position = Vector3.new(0,0,1.6); a0.Parent = blade
		local a1 = Instance.new("Attachment"); a1.Name = "T1"; a1.Position = Vector3.new(0,0,-1.6); a1.Parent = blade
		trail = Instance.new("Trail"); trail.Name = "SwingTrail"; trail.Attachment0 = a0; trail.Attachment1 = a1
		trail.Lifetime = 0.16; trail.Enabled = false; trail.LightEmission = 0.6
		trail.Color = ColorSequence.new(Color3.fromRGB(190,225,255))
		trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,1)})
		trail.Parent = blade
	end
	return trail
end

local swinging = false
local function playSwing()
	local sword = getSword()
	if not sword or swinging then return end
	swinging = true
	sword.Grip = SWING_GRIP
	TweenService:Create(sword, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = BASE_GRIP }):Play()
	local trail = ensureTrail(sword)
	if trail then trail.Enabled = true; task.delay(0.28, function() trail.Enabled = false end) end
	task.delay(0.3, function() swinging = false end)
end

-- Ghost-Effekt beim Ausweichen
local function playDodge()
	local char = player.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.LocalTransparencyModifier = 0.6
		end
	end
	task.delay(0.28, function()
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
		end
	end)
end

-- Eingaben
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if getSword() then
			AttackRequest:FireServer()
			playSwing()
		end
	elseif input.KeyCode == Enum.KeyCode.Q then
		DodgeRequest:FireServer()
	end
end)

-- Server-Effekte
CombatFX.OnClientEvent:Connect(function(data)
	if data.kind == "swing" then
		playSwing()
	elseif data.kind == "dodge" then
		playDodge()
	end
end)
