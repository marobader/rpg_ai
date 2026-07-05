-- Wechselt Licht-/Nebel-Stimmung je nach Zone (Dorf vs. Fluesterwald).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local mood = Lighting:WaitForChild("Mood")           -- ColorCorrectionEffect
local atmosphere = Lighting:WaitForChild("Atmosphere")

-- Stimmungs-Presets
local PRESETS = {
	village = {
		cc = { Brightness = 0.0, Contrast = 0.06, Saturation = 0.12, TintColor = Color3.fromRGB(255, 250, 244) },
		atm = { Density = 0.34, Haze = 1.6, Color = Color3.fromRGB(199, 205, 215), Decay = Color3.fromRGB(106, 112, 125) },
	},
	forest = {
		cc = { Brightness = -0.06, Contrast = 0.13, Saturation = -0.04, TintColor = Color3.fromRGB(212, 232, 210) },
		atm = { Density = 0.46, Haze = 2.6, Color = Color3.fromRGB(150, 176, 150), Decay = Color3.fromRGB(58, 78, 58) },
	},
}

local TWEEN = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local currentZone = nil

local function applyZone(zone)
	if zone == currentZone then return end
	currentZone = zone
	local p = PRESETS[zone]
	TweenService:Create(mood, TWEEN, p.cc):Play()
	TweenService:Create(atmosphere, TWEEN, p.atm):Play()
end

-- Zonen-Erkennung ueber die Z-Position (Wald liegt bei z ~1220, Dorf um 0)
local function zoneForPosition(pos)
	return (pos.Z > 800) and "forest" or "village"
end

applyZone("village")

while true do
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		applyZone(zoneForPosition(root.Position))
	end
	task.wait(0.5)
end
