--!strict
-- Verwaltet Quests: Annehmen, Fortschritt, Belohnung, NPC-Dialoge.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = ReplicatedStorage.RPG.Config
local Quests = require(Config.Quests)
local Skills = require(Config.Skills)
local DataManager = require(script.Parent.DataManager)

local QuestSystem = {}

local function getRemote(name: string): RemoteEvent
	local folder = ReplicatedStorage.RPG.Remotes
	local r = folder:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = folder end
	return r :: RemoteEvent
end

-- ---------- Zustands-Helfer ----------
local function ensureEntry(profile, questId)
	profile.quests = profile.quests or {}
	local e = profile.quests[questId]
	if not e then
		e = { status = "active", progress = {} }
		local def = Quests.get(questId)
		if def then
			for _, obj in ipairs(def.objectives) do e.progress[obj.key] = 0 end
		end
		profile.quests[questId] = e
	end
	return e
end

local function isComplete(profile, questId): boolean
	local def = Quests.get(questId)
	local e = profile.quests and profile.quests[questId]
	if not def or not e then return false end
	for _, obj in ipairs(def.objectives) do
		if (e.progress[obj.key] or 0) < obj.amount then return false end
	end
	return true
end
QuestSystem.isComplete = isComplete

-- ---------- Annehmen ----------
function QuestSystem.give(player: Player, questId: string)
	local profile = DataManager.get(player)
	local def = Quests.get(questId)
	if not profile or not def then return end
	if profile.quests and profile.quests[questId] then return end -- schon vorhanden
	ensureEntry(profile, questId)
	DataManager.notify(player, "Quest angenommen: " .. def.title, "info")
	DataManager.push(player)
end

-- ---------- Fortschritt melden (von Resource-/Mob-System) ----------
function QuestSystem.report(player: Player, kind: string, target: string)
	local profile = DataManager.get(player)
	if not profile or not profile.quests then return end
	for questId, e in pairs(profile.quests) do
		if e.status == "active" then
			local def = Quests.get(questId)
			if def then
				local changed = false
				for _, obj in ipairs(def.objectives) do
					if obj.kind == kind and obj.target == target then
						local cur = e.progress[obj.key] or 0
						if cur < obj.amount then
							e.progress[obj.key] = cur + 1
							changed = true
							if e.progress[obj.key] >= obj.amount then
								DataManager.notify(player, string.format("Ziel erf\u{00FC}llt: %s", obj.text), "good")
							end
						end
					end
				end
				if changed then
					if isComplete(profile, questId) then
						DataManager.notify(player, def.title .. ": abgeschlossen! Kehre zu " .. def.giver .. " zur\u{00FC}ck.", "good")
					end
					DataManager.push(player)
				end
			end
		end
	end
end

-- ---------- Abschliessen / Belohnung ----------
function QuestSystem.complete(player: Player, questId: string)
	local profile = DataManager.get(player)
	local def = Quests.get(questId)
	if not profile or not def then return false end
	local e = profile.quests and profile.quests[questId]
	if not e or e.status ~= "active" or not isComplete(profile, questId) then return false end
	e.status = "done"
	local r = def.rewards or {}
	if r.gold then DataManager.addGold(player, r.gold) end
	if r.xp then
		for skill, amount in pairs(r.xp) do DataManager.addXp(player, skill, amount) end
	end
	if r.items then
		for _, it in ipairs(r.items) do DataManager.addItem(player, it.id, it.count or 1) end
	end
	DataManager.notify(player, string.format("Quest abgeschlossen: %s  (+%d Gold)", def.title, r.gold or 0), "good")
	DataManager.push(player)
	return true
end

-- ---------- Dialog ----------
local function buildDialogue(player: Player, npcId: string, questId: string)
	local profile = DataManager.get(player)
	local def = Quests.get(questId)
	if not def then return nil end
	local e = profile.quests and profile.quests[questId]
	local payload = { npcId = npcId, npcName = def.giver, title = def.title }

	if not e then
		payload.lines = {
			"Sei gegr\u{00FC}\u{00DF}t, Reisender!",
			def.summary,
			"F\u{00E4}lle 5 Eichen und vertreibe 3 Waldgoblins. Hilfst du mir?",
		}
		payload.options = { { id = "accept", label = "Annehmen" }, { id = "close", label = "Sp\u{00E4}ter" } }
	elseif e.status == "active" and not isComplete(profile, questId) then
		local parts = {}
		for _, obj in ipairs(def.objectives) do
			table.insert(parts, string.format("%s %d/%d", obj.text, e.progress[obj.key] or 0, obj.amount))
		end
		payload.lines = { "Wie l\u{00E4}uft es im Wald?", table.concat(parts, "   \u{2022}   ") }
		payload.options = { { id = "close", label = "Bin dran" } }
	elseif e.status == "active" and isComplete(profile, questId) then
		payload.lines = { "Hervorragende Arbeit!", "Der Wald atmet auf. Hier ist dein wohlverdienter Lohn." }
		payload.options = { { id = "claim", label = "Belohnung abholen" } }
	else
		payload.lines = { "Danke nochmal, Held. Der Wald ist ruhiger dank dir." }
		payload.options = { { id = "close", label = "Tsch\u{00FC}ss" } }
	end
	return payload
end

local function openDialogue(player: Player, npcPart: BasePart)
	local npcId = npcPart:GetAttribute("NpcId") or "NPC"
	local questId = npcPart:GetAttribute("QuestId")
	if not questId then return end
	local payload = buildDialogue(player, npcId, questId)
	if payload then
		payload.questId = questId
		getRemote("OpenDialogue"):FireClient(player, payload)
	end
end

local function onChoice(player: Player, data)
	if type(data) ~= "table" then return end
	local questId = data.questId
	local choice = data.choice
	if not questId or not choice then return end
	if choice == "accept" then
		QuestSystem.give(player, questId)
	elseif choice == "claim" then
		QuestSystem.complete(player, questId)
	end
end

-- ---------- NPC-Interaktion ----------
local function hookNpc(part: Instance)
	if not part:IsA("BasePart") then return end
	local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Sprechen"
		prompt.ObjectText = part:GetAttribute("NpcId") or "NPC"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end
	prompt.Triggered:Connect(function(player) openDialogue(player, part) end)
end

function QuestSystem.init()
	getRemote("OpenDialogue")
	getRemote("DialogueChoice").OnServerEvent:Connect(onChoice)
	for _, p in ipairs(CollectionService:GetTagged("NPC")) do hookNpc(p) end
	CollectionService:GetInstanceAddedSignal("NPC"):Connect(hookNpc)
	print("[QuestSystem] initialisiert (" .. #CollectionService:GetTagged("NPC") .. " NPCs).")
end

return QuestSystem
