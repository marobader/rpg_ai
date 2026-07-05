--!strict
-- Erzeugt Gegner, steuert ihre KI, Schaden, Tod, Beute und Respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage.RPG.Config
local MobsCfg = require(Config.Mobs)
local DataManager = require(script.Parent.DataManager)
local QuestSystem = require(script.Parent.QuestSystem)
local DropSystem = require(script.Parent.DropSystem)
local Items = require(Config.Items)

local MobSystem = {}

local STEP = 0.12
local folder: Folder

local terrainRay = RaycastParams.new()
terrainRay.FilterType = Enum.RaycastFilterType.Include
terrainRay.FilterDescendantsInstances = { workspace.Terrain }
local function groundY(x, z): number
	local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), terrainRay)
	return r and r.Position.Y or 0
end

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function P(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = false
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

-- ---------- Modell-Bauer (bauen am Weltpunkt `pos`, Fuesse auf y=0) ----------
local function commonRig(m: Model, rootCF: CFrame, display: string, maxHp: number)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2,2,1); root.CFrame = rootCF
	root.Transparency = 1; root.Anchored = true; root.CanCollide = false; root.Parent = m
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = maxHp; hum.Health = maxHp
	hum.DisplayName = display
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	hum.Parent = m
	m.PrimaryPart = root
	return root, hum
end

local function buildGoblin(pos: Vector3): (Model, number)
	local m = Instance.new("Model")
	local skin = rgb(96,140,72)
	local rootCF = CFrame.new(pos + Vector3.new(0,3.2,0))
	commonRig(m, rootCF, "Waldgoblin", 45)
	P(m, "Torso", Vector3.new(2.6,2.8,1.5), CFrame.new(pos+Vector3.new(0,3.2,0)), skin, Enum.Material.SmoothPlastic)
	P(m, "Head", Vector3.new(1.8,1.8,1.8), CFrame.new(pos+Vector3.new(0,5.3,0)), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	P(m, "Ear", Vector3.new(0.4,1.4,0.4), CFrame.new(pos+Vector3.new(-1,5.6,0))*CFrame.Angles(0,0,math.rad(35)), skin)
	P(m, "Ear", Vector3.new(0.4,1.4,0.4), CFrame.new(pos+Vector3.new(1,5.6,0))*CFrame.Angles(0,0,math.rad(-35)), skin)
	P(m, "Eye", Vector3.new(0.3,0.3,0.3), CFrame.new(pos+Vector3.new(-0.4,5.5,0.8)), rgb(200,40,40), Enum.Material.Neon, Enum.PartType.Ball)
	P(m, "Eye", Vector3.new(0.3,0.3,0.3), CFrame.new(pos+Vector3.new(0.4,5.5,0.8)), rgb(200,40,40), Enum.Material.Neon, Enum.PartType.Ball)
	P(m, "Arm", Vector3.new(0.8,2.4,0.8), CFrame.new(pos+Vector3.new(-1.7,3.1,0)), skin)
	P(m, "Arm", Vector3.new(0.8,2.4,0.8), CFrame.new(pos+Vector3.new(1.7,3.1,0)), skin)
	P(m, "Leg", Vector3.new(0.9,2,0.9), CFrame.new(pos+Vector3.new(-0.7,1,0)), rgb(70,60,45))
	P(m, "Leg", Vector3.new(0.9,2,0.9), CFrame.new(pos+Vector3.new(0.7,1,0)), rgb(70,60,45))
	P(m, "Club", Vector3.new(0.7,3,0.7), CFrame.new(pos+Vector3.new(2.2,3.4,0.6))*CFrame.Angles(math.rad(30),0,0), rgb(90,62,40), Enum.Material.Wood)
	return m, 3.2
end

local function buildWolf(pos: Vector3): (Model, number)
	local m = Instance.new("Model")
	local fur = rgb(105,105,112)
	local rootCF = CFrame.new(pos + Vector3.new(0,2.4,0))
	commonRig(m, rootCF, "Wolf", 60)
	P(m, "Body", Vector3.new(2.2,2,4.6), CFrame.new(pos+Vector3.new(0,2.4,0)), fur)
	P(m, "Head", Vector3.new(1.8,1.8,1.8), CFrame.new(pos+Vector3.new(0,2.8,2.8)), fur, Enum.Material.SmoothPlastic)
	P(m, "Snout", Vector3.new(1,0.9,1.2), CFrame.new(pos+Vector3.new(0,2.5,3.8)), rgb(80,80,86))
	P(m, "Ear", Vector3.new(0.5,0.9,0.3), CFrame.new(pos+Vector3.new(-0.6,3.9,2.7)), fur)
	P(m, "Ear", Vector3.new(0.5,0.9,0.3), CFrame.new(pos+Vector3.new(0.6,3.9,2.7)), fur)
	P(m, "Eye", Vector3.new(0.25,0.25,0.25), CFrame.new(pos+Vector3.new(-0.5,3,3.6)), rgb(240,210,60), Enum.Material.Neon, Enum.PartType.Ball)
	P(m, "Eye", Vector3.new(0.25,0.25,0.25), CFrame.new(pos+Vector3.new(0.5,3,3.6)), rgb(240,210,60), Enum.Material.Neon, Enum.PartType.Ball)
	for _, dx in ipairs({-0.9,0.9}) do for _, dz in ipairs({-1.6,1.6}) do
		P(m, "Leg", Vector3.new(0.7,2.4,0.7), CFrame.new(pos+Vector3.new(dx,1.2,dz)), rgb(85,85,92))
	end end
	P(m, "Tail", Vector3.new(0.6,0.6,2.2), CFrame.new(pos+Vector3.new(0,2.8,-2.8))*CFrame.Angles(math.rad(30),0,0), fur)
	return m, 2.4
end

local function buildSpider(pos: Vector3): (Model, number)
	local m = Instance.new("Model")
	local chitin = rgb(35,32,40)
	local rootCF = CFrame.new(pos + Vector3.new(0,1.8,0))
	commonRig(m, rootCF, "Waldspinne", 38)
	P(m, "Abdomen", Vector3.new(3,2.4,3.4), CFrame.new(pos+Vector3.new(0,1.8,-1)), chitin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	P(m, "Head", Vector3.new(2,1.8,2), CFrame.new(pos+Vector3.new(0,1.8,1.6)), chitin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	for _, dx in ipairs({-0.5,0.5}) do
		P(m, "Eye", Vector3.new(0.3,0.3,0.3), CFrame.new(pos+Vector3.new(dx,2,2.5)), rgb(220,50,50), Enum.Material.Neon, Enum.PartType.Ball)
	end
	for i=-1,1 do for _, side in ipairs({-1,1}) do
		local ang = math.rad(side*90)
		P(m, "Leg", Vector3.new(0.35,0.35,4), CFrame.new(pos+Vector3.new(side*1.6, 1.9, i*1.2))*CFrame.Angles(0, ang, math.rad(20*side)), rgb(25,22,28))
	end end
	return m, 1.8
end

local builders = { Waldgoblin = buildGoblin, Wolf = buildWolf, Waldspinne = buildSpider }

-- ---------- Hilfen ----------
local function nearestPlayer(pos: Vector3, range: number): (Player?, BasePart?)
	local best, bestRoot, bestD = nil, nil, range
	for _, pl in ipairs(Players:GetPlayers()) do
		local char = pl.Character
		local r = char and char:FindFirstChild("HumanoidRootPart")
		local h = char and char:FindFirstChildOfClass("Humanoid")
		if r and h and h.Health > 0 then
			local d = (r.Position - pos).Magnitude
			if d < bestD then best, bestRoot, bestD = pl, r, d end
		end
	end
	return best, bestRoot
end

local function rollLoot(player: Player, def, pos: Vector3)
	for _, entry in ipairs(def.loot or {}) do
		if math.random() <= entry.chance then
			DropSystem.spawn(entry.item, entry.count or 1, pos, player)
		end
	end
end

-- ---------- Schaden von aussen (vom Kampfsystem) ----------
function MobSystem.damageMob(model: Model, amount: number, player: Player?)
	if not model or not model.Parent then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if player then model:SetAttribute("LastHitBy", player.UserId) end
	hum:TakeDamage(amount)
end

-- ---------- Angriff des Mobs ----------
local function mobAttack(model: Model, def, target: Player)
	local root = model.PrimaryPart
	if not root then return end
	model:SetAttribute("Winding", true)
	task.delay(def.windup, function()
		model:SetAttribute("Winding", false)
		if not model.Parent then return end
		local char = target.Character
		local tRoot = char and char:FindFirstChild("HumanoidRootPart")
		local tHum = char and char:FindFirstChildOfClass("Humanoid")
		if not tRoot or not tHum or tHum.Health <= 0 then return end
		local dist = (tRoot.Position - root.Position).Magnitude
		if dist <= def.attackRange + 2 and not target:GetAttribute("Invulnerable") then
			tHum:TakeDamage(def.damage)
		end
	end)
end

-- ---------- KI-Schleife pro Mob ----------
local function runMob(model: Model, def, mobType: string, spawnPos: Vector3)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	if not hum or not root then return end
	local groundY = root.Position.Y
	local lastAttack = 0
	while model.Parent and hum.Health > 0 do
		local _, tRoot = nearestPlayer(root.Position, def.aggroRange)
		local myPos = root.Position
		if tRoot then
			local tPos = tRoot.Position
			local flatMy = Vector3.new(myPos.X, 0, myPos.Z)
			local flatT = Vector3.new(tPos.X, 0, tPos.Z)
			local dist = (flatT - flatMy).Magnitude
			local lookAt = Vector3.new(tPos.X, groundY, tPos.Z)
			if dist > def.attackRange then
				local dir = (flatT - flatMy).Unit
				local stepLen = math.min(def.walkSpeed * STEP, math.max(dist - def.attackRange * 0.5, 0))
				local newPos = myPos + dir * stepLen
				model:PivotTo(CFrame.lookAt(Vector3.new(newPos.X, groundY, newPos.Z), lookAt))
			else
				model:PivotTo(CFrame.lookAt(Vector3.new(myPos.X, groundY, myPos.Z), lookAt))
				local target = nearestPlayer(root.Position, def.aggroRange)
				if target and os.clock() - lastAttack >= def.attackCooldown then
					lastAttack = os.clock()
					mobAttack(model, def, target)
				end
			end
		else
			local toSpawn = Vector3.new(spawnPos.X - myPos.X, 0, spawnPos.Z - myPos.Z)
			if toSpawn.Magnitude > 3 then
				local dir = toSpawn.Unit
				local newPos = myPos + dir * (def.walkSpeed * 0.4 * STEP)
				model:PivotTo(CFrame.lookAt(Vector3.new(newPos.X, groundY, newPos.Z), Vector3.new(spawnPos.X, groundY, spawnPos.Z)))
			end
		end
		task.wait(STEP)
	end
end

-- ---------- Tod ----------
local function onDied(model: Model, def, mobType: string, spawnPos: Vector3)
	if model:GetAttribute("Dead") then return end
	model:SetAttribute("Dead", true)
	local killerId = model:GetAttribute("LastHitBy")
	local killer = killerId and Players:GetPlayerByUserId(killerId)
	if killer then
		DataManager.addXp(killer, "Schwert", def.xp)
		DataManager.addGold(killer, math.random(def.gold[1], def.gold[2]))
		local pos = (model.PrimaryPart and model.PrimaryPart.Position) or spawnPos
		rollLoot(killer, def, pos)
		QuestSystem.report(killer, "kill", mobType)
		DataManager.notify(killer, string.format("%s besiegt!  (+%d Schwert XP)", def.display, def.xp), "good")
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
	task.delay(0.5, function() if model.Parent then model:Destroy() end end)
	task.delay(def.respawn, function() MobSystem.spawn(mobType, spawnPos) end)
end

-- ---------- Spawnen ----------
function MobSystem.spawn(mobType: string, pos: Vector3)
	local def = MobsCfg.get(mobType)
	local builder = builders[mobType]
	if not def or not builder then warn("[MobSystem] Unbekannter Mob: "..tostring(mobType)); return end
	pos = Vector3.new(pos.X, groundY(pos.X, pos.Z), pos.Z)
	local model = builder(pos)
	model.Name = mobType
	model:SetAttribute("MobType", mobType)
	CollectionService:AddTag(model, "Mob")
	model.Parent = folder
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.Died:Connect(function() onDied(model, def, mobType, pos) end)
	task.spawn(runMob, model, def, mobType, pos)
	return model
end

function MobSystem.init()
	local forest = Workspace.World:FindFirstChild("Fluesterwald")
	if not forest then warn("[MobSystem] Fluesterwald fehlt"); return end
	local old = forest:FindFirstChild("Mobs")
	if old then old:Destroy() end
	folder = Instance.new("Folder"); folder.Name = "Mobs"; folder.Parent = forest

	local layout = {
		{"Waldgoblin", Vector3.new(30, 0, 1210)}, {"Waldgoblin", Vector3.new(-40, 0, 1240)}, {"Waldgoblin", Vector3.new(15, 0, 1270)},
		{"Wolf", Vector3.new(120, 0, 1260)}, {"Wolf", Vector3.new(-120, 0, 1280)},
		{"Waldspinne", Vector3.new(70, 0, 1330)}, {"Waldspinne", Vector3.new(-60, 0, 1350)},
	}
	for _, e in ipairs(layout) do
		MobSystem.spawn(e[1], e[2])
	end
	print("[MobSystem] initialisiert ("..#layout.." Mobs).")
end

return MobSystem
