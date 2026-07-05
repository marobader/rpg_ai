--!strict
-- Verwaltet Spielerprofile: Laden/Speichern (DataStore mit Memory-Fallback),
-- leaderstats (Gesamtlevel, Gold), und die zentrale AddXp-Funktion.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage.RPG.Config
local Skills = require(Config.Skills)
local XP = require(Config.XP)
local Items = require(Config.Items)
local Progression = require(Config.Progression)

local DataManager = {}

local STORE_KEY = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 120

local store: DataStore? = nil
local storeOk = false

local sessions: { [Player]: any } = {}

-- ---------- Remotes ----------
local function getRemote(name: string): RemoteEvent
	local folder = ReplicatedStorage.RPG.Remotes
	local r = folder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	return r :: RemoteEvent
end

-- ---------- Profil ----------
local function newProfile(): any
	local skillsData = {}
	for _, key in ipairs(Skills.keys()) do
		skillsData[key] = 0
	end
	return {
		skills = skillsData,
		gold = 0,
		inventory = {},   -- Liste von { id = string, count = number }
		maxSlots = 20,
		quests = {},      -- questId -> Fortschritts-State
	}
end

-- Fehlende Felder in geladenem Profil ergaenzen (Vorwaertskompatibilitaet)
local function reconcile(profile: any)
	profile.skills = profile.skills or {}
	for _, key in ipairs(Skills.keys()) do
		if profile.skills[key] == nil then
			profile.skills[key] = 0
		end
	end
	profile.gold = profile.gold or 0
	profile.inventory = profile.inventory or {}
	profile.maxSlots = profile.maxSlots or 20
	profile.quests = profile.quests or {}
end

function DataManager.computeTotalLevel(profile: any): number
	local total = 0
	for _, key in ipairs(Skills.keys()) do
		total += XP.levelForXp(profile.skills[key] or 0)
	end
	return total
end

-- ---------- leaderstats ----------
local function setupLeaderstats(player: Player, profile: any)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"

	local level = Instance.new("IntValue")
	level.Name = "Gesamtlevel"
	level.Value = DataManager.computeTotalLevel(profile)
	level.Parent = ls

	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = profile.gold
	gold.Parent = ls

	ls.Parent = player
end

local function updateLeaderstats(player: Player, profile: any)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local level = ls:FindFirstChild("Gesamtlevel")
	if level then (level :: IntValue).Value = DataManager.computeTotalLevel(profile) end
	local gold = ls:FindFirstChild("Gold")
	if gold then (gold :: IntValue).Value = profile.gold end
end

-- ---------- Laden / Speichern ----------
local function loadProfile(player: Player): any
	local profile = nil
	if storeOk and store then
		local ok, data = pcall(function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok and type(data) == "table" then
			profile = data
		end
	end
	if not profile then
		profile = newProfile()
	end
	reconcile(profile)
	return profile
end

function DataManager.save(player: Player)
	local profile = sessions[player]
	if not profile then return end
	if storeOk and store then
		pcall(function()
			store:SetAsync(tostring(player.UserId), profile)
		end)
	end
end

-- ---------- Oeffentliche API ----------
function DataManager.get(player: Player): any
	return sessions[player]
end

local function pushProfile(player: Player)
	local profile = sessions[player]
	if profile then
		getRemote("ProfileUpdated"):FireClient(player, profile)
	end
end
DataManager.push = pushProfile

-- Fuegt einem Skill XP hinzu. Feuert Level-Up-Benachrichtigung + aktualisiert alles.
function DataManager.addXp(player: Player, skillKey: string, amount: number)
	local profile = sessions[player]
	if not profile then return end
	if not Skills.exists(skillKey) then
		warn("[DataManager] Unbekannter Skill: " .. tostring(skillKey))
		return
	end

	local maxXp = XP.totalForLevel(XP.MaxLevel)
	local before = profile.skills[skillKey] or 0
	local oldLevel = XP.levelForXp(before)
	local after = math.min(before + amount, maxXp)
	profile.skills[skillKey] = after
	local newLevel = XP.levelForXp(after)

	updateLeaderstats(player, profile)

	-- Max-HP mit Kampf-Level erhoehen
	if Progression.CombatSkills[skillKey] and newLevel > oldLevel then
		local char = player.Character
		local phum = char and char:FindFirstChildOfClass("Humanoid")
		if phum then
			local combatLevel = XP.levelForXp(profile.skills.Schwert or 0)
			local newMax = Progression.maxHealth(combatLevel)
			local delta = newMax - phum.MaxHealth
			phum.MaxHealth = newMax
			if delta > 0 then phum.Health = math.min(phum.Health + delta, newMax) end
		end
	end

	getRemote("SkillXpGained"):FireClient(player, {
		skill = skillKey,
		amount = after - before,
		level = newLevel,
		leveledUp = newLevel > oldLevel,
	})
	pushProfile(player)
end

-- Sendet eine kurze Nachricht an den Client (Toast). kind: "info"|"good"|"warn"
function DataManager.notify(player: Player, text: string, kind: string?)
	getRemote("Notify"):FireClient(player, { text = text, kind = kind or "info" })
end

-- Legt Items ins Inventar. Gibt true zurueck, wenn ALLES Platz fand.
function DataManager.addItem(player: Player, itemId: string, count: number?): boolean
	local profile = sessions[player]
	if not profile then return false end
	local def = Items.get(itemId)
	local maxStack = (def and def.maxStack) or 99
	local remaining = count or 1

	-- Erst bestehende Stapel auffuellen
	for _, slot in ipairs(profile.inventory) do
		if slot.id == itemId and slot.count < maxStack then
			local add = math.min(remaining, maxStack - slot.count)
			slot.count += add
			remaining -= add
			if remaining <= 0 then break end
		end
	end
	-- Dann neue Stapel anlegen, solange Slots frei sind
	while remaining > 0 and #profile.inventory < profile.maxSlots do
		local add = math.min(remaining, maxStack)
		table.insert(profile.inventory, { id = itemId, count = add })
		remaining -= add
	end

	pushProfile(player)
	return remaining <= 0
end

function DataManager.addGold(player: Player, amount: number)
	local profile = sessions[player]
	if not profile then return end
	profile.gold = math.max(0, profile.gold + amount)
	updateLeaderstats(player, profile)
	pushProfile(player)
end

-- ---------- Lifecycle ----------
local function onPlayerAdded(player: Player)
	local profile = loadProfile(player)
	sessions[player] = profile
	setupLeaderstats(player, profile)
	-- Kurz warten, bis der Client seine Skripte geladen hat, dann Profil senden
	task.defer(pushProfile, player)
end

local function onPlayerRemoving(player: Player)
	DataManager.save(player)
	sessions[player] = nil
end

function DataManager.init()
	-- DataStore verfuegbar? (im Studio evtl. nicht -> Memory-Fallback)
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_KEY)
	end)
	if ok then
		store = result
		storeOk = true
	else
		storeOk = false
		warn("[DataManager] DataStore nicht verfuegbar - nutze Memory-Fallback (Fortschritt wird in dieser Session nicht dauerhaft gespeichert).")
	end

	-- Remotes anlegen
	getRemote("ProfileUpdated")
	getRemote("SkillXpGained")
	getRemote("Notify")

	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do
			DataManager.save(p)
		end
	end)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, p in ipairs(Players:GetPlayers()) do
				DataManager.save(p)
			end
		end
	end)

	print("[DataManager] initialisiert (DataStore: " .. (storeOk and "aktiv" or "Memory-Fallback") .. ")")
end

return DataManager
