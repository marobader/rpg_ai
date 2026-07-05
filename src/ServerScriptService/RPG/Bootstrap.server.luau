-- Server-Einstiegspunkt. Initialisiert alle Server-Systeme in Reihenfolge.
local Systems = script.Parent.Systems

local DataManager = require(Systems.DataManager)
DataManager.init()

local QuestSystem = require(Systems.QuestSystem)
QuestSystem.init()

local PortalSystem = require(Systems.PortalSystem)
PortalSystem.init()

local ResourceSystem = require(Systems.ResourceSystem)
ResourceSystem.init()

local MobSystem = require(Systems.MobSystem)
MobSystem.init()

local CombatSystem = require(Systems.CombatSystem)
CombatSystem.init()

print("[RPG] Server-Systeme gestartet.")
