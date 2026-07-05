-- Spielt UI-Sound-Effekte auf Kampf-, Level-Up- und Pickup-Ereignisse.
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("RPG"):WaitForChild("Remotes")
local CombatFX = remotes:WaitForChild("CombatFX")
local SkillXpGained = remotes:WaitForChild("SkillXpGained")
local Notify = remotes:WaitForChild("Notify")

local function mkSound(id, vol)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = vol or 0.5
	s.Parent = SoundService
	return s
end

local sSwing  = mkSound("118431566107728", 0.35)
local sHit    = mkSound("96278024968375", 0.5)
local sPickup = mkSound("7381723941", 0.5)
local sLevel  = mkSound("92852865488633", 0.6)

local function play(s, pitch)
	s.PlaybackSpeed = pitch or 1
	s.TimePosition = 0
	s:Play()
end

CombatFX.OnClientEvent:Connect(function(data)
	if data.kind == "swing" then
		play(sSwing, 0.95 + math.random() * 0.1)
		if data.hits and data.hits > 0 then
			task.delay(0.06, function() play(sHit, data.crit and 1.25 or 1) end)
		end
	end
end)

SkillXpGained.OnClientEvent:Connect(function(data)
	if data.leveledUp then play(sLevel) end
end)

Notify.OnClientEvent:Connect(function(data)
	-- Pickup-"Plopp" bei Item-Aufnahme ("+N Item"), nicht bei XP-Meldungen
	if data.kind == "good" and data.text:sub(1,1) == "+" and not data.text:find("XP$") then
		play(sPickup)
	end
end)
