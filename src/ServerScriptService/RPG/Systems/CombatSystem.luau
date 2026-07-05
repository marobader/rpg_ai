--!strict
-- Schwert-Nahkampf (server-autoritativ) + Ausweichen mit i-Frames.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = ReplicatedStorage.RPG.Config
local XP = require(Config.XP)
local Progression = require(Config.Progression)
local DataManager = require(script.Parent.DataManager)
local MobSystem = require(script.Parent.MobSystem)

local CombatSystem = {}

local ATTACK_CD = 0.6
local MELEE_RANGE = 9
local ARC_DOT = 0.35        -- ~70 Grad Kegel vor dem Spieler
local DODGE_CD = 1.3
local IFRAME = 0.45
local DASH_SPEED = 70

local lastAttack: { [Player]: number } = {}
local lastDodge: { [Player]: number } = {}

local function getRemote(name: string): RemoteEvent
	local folder = ReplicatedStorage.RPG.Remotes
	local r = folder:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = folder end
	return r :: RemoteEvent
end

local function swordLevel(player: Player): number
	local profile = DataManager.get(player)
	return profile and XP.levelForXp(profile.skills.Schwert or 0) or 1
end

local function onAttack(player: Player)
	local now = os.clock()
	if lastAttack[player] and now - lastAttack[player] < ATTACK_CD then return end
	lastAttack[player] = now

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	local origin = root.Position
	local look = root.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.01 then return end
	look = look.Unit

	local level = swordLevel(player)
	local base = Progression.meleeDamage(level)
	local critCh = Progression.critChance(level)
	local hits, anyCrit = 0, false
	for _, mob in ipairs(CollectionService:GetTagged("Mob")) do
		if mob:IsA("Model") and not mob:GetAttribute("Dead") and mob.PrimaryPart then
			local to = mob.PrimaryPart.Position - origin
			local flat = Vector3.new(to.X, 0, to.Z)
			local dist = flat.Magnitude
			if dist <= MELEE_RANGE and dist > 0.01 and flat.Unit:Dot(look) >= ARC_DOT then
				local crit = math.random() < critCh
				local dmg = crit and math.floor(base * Progression.CritMultiplier) or base
				MobSystem.damageMob(mob, dmg, player, crit)
				hits += 1
				if crit then anyCrit = true end
			end
		end
	end
	getRemote("CombatFX"):FireClient(player, { kind = "swing", hits = hits, crit = anyCrit })
end

local function onDodge(player: Player)
	local now = os.clock()
	if lastDodge[player] and now - lastDodge[player] < DODGE_CD then return end
	lastDodge[player] = now

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	player:SetAttribute("Invulnerable", true)
	local look = root.CFrame.LookVector
	local dir = Vector3.new(look.X, 0, look.Z)
	if dir.Magnitude > 0.01 then
		root.AssemblyLinearVelocity = dir.Unit * DASH_SPEED + Vector3.new(0, 8, 0)
	end
	task.delay(IFRAME, function()
		if player then player:SetAttribute("Invulnerable", false) end
	end)
	getRemote("CombatFX"):FireClient(player, { kind = "dodge" })
end

function CombatSystem.init()
	getRemote("CombatFX")
	getRemote("AttackRequest").OnServerEvent:Connect(onAttack)
	getRemote("DodgeRequest").OnServerEvent:Connect(onDodge)

	local function reset(player: Player)
		player:SetAttribute("Invulnerable", false)
		local function onChar(char)
			player:SetAttribute("Invulnerable", false)
			task.spawn(function()
				local phum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
				local profile = DataManager.get(player)
				if phum and profile then
					local lvl = XP.levelForXp(profile.skills.Schwert or 0)
					phum.MaxHealth = Progression.maxHealth(lvl)
					phum.Health = phum.MaxHealth
				end
			end)
		end
		player.CharacterAdded:Connect(onChar)
		if player.Character then onChar(player.Character) end
	end
	for _, p in ipairs(Players:GetPlayers()) do reset(p) end
	Players.PlayerAdded:Connect(reset)
	Players.PlayerRemoving:Connect(function(p)
		lastAttack[p] = nil; lastDodge[p] = nil
	end)
	print("[CombatSystem] initialisiert.")
end

return CombatSystem
