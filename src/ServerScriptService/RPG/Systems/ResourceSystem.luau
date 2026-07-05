--!strict
-- Erzeugt abbaubare Ressourcen-Knoten (Baeume/Erz) und regelt Ernte + Respawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = ReplicatedStorage.RPG.Config
local Resources = require(Config.Resources)
local XP = require(Config.XP)
local Items = require(Config.Items)
local Skills = require(Config.Skills)
local DataManager = require(script.Parent.DataManager)
local QuestSystem = require(script.Parent.QuestSystem)
local DropSystem = require(script.Parent.DropSystem)
local Progression = require(Config.Progression)

local ResourceSystem = {}

local function rgb(c) return Color3.fromRGB(c[1], c[2], c[3]) end

local terrainRay = RaycastParams.new()
terrainRay.FilterType = Enum.RaycastFilterType.Include
terrainRay.FilterDescendantsInstances = { workspace.Terrain }
local function groundY(x, z): number
	local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), terrainRay)
	return r and r.Position.Y or 0
end

local state: { [Model]: { depleted: boolean } } = {}

-- ---------- Visuals ----------
local function buildTree(def, pos, scale): (Model, BasePart)
	scale = scale or 1
	local m = Instance.new("Model")
	local th = 15 * scale
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"; trunk.Shape = Enum.PartType.Cylinder; trunk.Anchored = true
	trunk.Size = Vector3.new(th, 3*scale, 3*scale)
	trunk.CFrame = CFrame.new(pos) * CFrame.new(0, th/2, 0) * CFrame.Angles(0,0,math.rad(90))
	trunk.Material = Enum.Material.Wood; trunk.Color = rgb(def.trunk)
	trunk.Parent = m
	local foliage = Instance.new("Folder"); foliage.Name = "Foliage"; foliage.Parent = m
	local function ball(dx,dy,dz,s)
		local b = Instance.new("Part"); b.Shape = Enum.PartType.Ball; b.Anchored = true
		b.Size = Vector3.new(s,s,s)*scale; b.CFrame = CFrame.new(pos) * CFrame.new(dx*scale, th+dy*scale, dz*scale)
		b.Material = Enum.Material.Grass; b.Color = rgb(def.leaf); b.Parent = foliage
	end
	ball(0,3,0,14); ball(5,1,3,10); ball(-5,1,-3,10); ball(-4,5,4,9); ball(4,5,-4,9)
	m.PrimaryPart = trunk
	return m, trunk
end

local function buildRock(def, pos, scale): (Model, BasePart)
	scale = scale or 1
	local m = Instance.new("Model")
	local rock = Instance.new("Part"); rock.Name = "Rock"; rock.Shape = Enum.PartType.Ball; rock.Anchored = true
	rock.Size = Vector3.new(9, 7, 9)*scale; rock.CFrame = CFrame.new(pos) * CFrame.new(0, 3*scale, 0)
	rock.Material = Enum.Material.Rock; rock.Color = rgb(def.rock); rock.Parent = m
	local veins = Instance.new("Folder"); veins.Name = "Veins"; veins.Parent = m
	for i=1,5 do
		local v = Instance.new("Part"); v.Anchored = true; v.Shape = Enum.PartType.Ball
		v.Size = Vector3.new(1.6,1.6,1.6)*scale
		local a = math.rad(i*72)
		v.CFrame = CFrame.new(pos) * CFrame.new(math.cos(a)*3.4*scale, (3 + math.sin(a)*2)*scale, math.sin(a)*3.4*scale)
		v.Material = Enum.Material.Neon; v.Color = rgb(def.vein); v.Parent = veins
	end
	m.PrimaryPart = rock
	return m, rock
end

local function buildHerb(def, pos, scale): (Model, BasePart)
	scale = scale or 1
	local m = Instance.new("Model")
	local h = 2.6 * scale
	local stem = Instance.new("Part")
	stem.Name = "Stem"; stem.Anchored = true; stem.CanCollide = false
	stem.Size = Vector3.new(0.4*scale, h, 0.4*scale)
	stem.CFrame = CFrame.new(pos) * CFrame.new(0, h/2, 0)
	stem.Material = Enum.Material.Grass; stem.Color = rgb(def.stem)
	stem.Parent = m
	local foliage = Instance.new("Folder"); foliage.Name = "Foliage"; foliage.Parent = m
	local fc = rgb(def.flower)
	for i = 1, 3 do
		local a = math.rad(i*120)
		local b = Instance.new("Part"); b.Anchored = true; b.CanCollide = false; b.Shape = Enum.PartType.Ball
		b.Size = Vector3.new(1,1,1)*scale
		b.CFrame = CFrame.new(pos) * CFrame.new(math.cos(a)*0.5*scale, h, math.sin(a)*0.5*scale)
		b.Material = Enum.Material.Neon; b.Color = fc; b.Parent = foliage
	end
	m.PrimaryPart = stem
	return m, stem
end

local function setDepleted(model: Model, def, depleted: boolean)
	local st = state[model]
	if st then st.depleted = depleted end
	if def.kind == "tree" or def.kind == "forage" then
		local foliage = model:FindFirstChild("Foliage")
		if foliage then for _, b in ipairs(foliage:GetChildren()) do (b :: BasePart).Transparency = depleted and 1 or 0 end end
		if model.PrimaryPart then model.PrimaryPart.Transparency = depleted and 0.55 or 0 end
	else
		local veins = model:FindFirstChild("Veins")
		if veins then for _, v in ipairs(veins:GetChildren()) do (v :: BasePart).Transparency = depleted and 1 or 0 end end
		if model.PrimaryPart then (model.PrimaryPart :: BasePart).Color = depleted and Color3.fromRGB(70,70,72) or rgb(def.rock) end
	end
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChildWhichIsA("ProximityPrompt")
	if prompt then prompt.Enabled = not depleted end
end

-- ---------- Ernte-Partikel ----------
local function harvestFX(model: Model, def)
	local part = model.PrimaryPart
	if not part then return end
	local col
	if def.kind == "rock" then col = Color3.fromRGB(150,145,140)
	elseif def.kind == "forage" then col = Color3.fromRGB(150,240,180)
	else col = Color3.fromRGB(150,110,60) end
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(col); e.Size = NumberSequence.new(0.4)
	e.Lifetime = NumberRange.new(0.3,0.6); e.Speed = NumberRange.new(4,9)
	e.SpreadAngle = Vector2.new(60,60); e.Rate = 0; e.Acceleration = Vector3.new(0,-20,0)
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	e.Parent = part
	e:Emit(12)
	task.delay(0.9, function() e:Destroy() end)
end

-- ---------- Ernte ----------
local function harvest(player: Player, model: Model, nodeType: string)
	local def = Resources.get(nodeType)
	if not def then return end
	local st = state[model]
	if not st or st.depleted then return end

	local profile = DataManager.get(player)
	if not profile then return end
	local level = XP.levelForXp(profile.skills[def.skill] or 0)
	if level < def.level then
		local skillName = Skills.ByKey[def.skill] and Skills.ByKey[def.skill].name or def.skill
		DataManager.notify(player, string.format("Ben\u{00F6}tigt %s Level %d (du hast %d).", skillName, def.level, level), "warn")
		return
	end

	DataManager.addXp(player, def.skill, def.xp)
	DataManager.notify(player, string.format("+%d %s XP", def.xp,
		Skills.ByKey[def.skill] and Skills.ByKey[def.skill].name or def.skill), "good")
	local qty = def.count
	if math.random() < Progression.bonusYieldChance(level) then qty += math.random(1, 2) end
	local dropPos = model.PrimaryPart.Position + Vector3.new(0, 2, 0)
	DropSystem.spawn(def.item, qty, dropPos, player)
	if def.kind == "tree" and math.random() < 0.03 then
		DropSystem.spawn("Amber", 1, dropPos, player)
	end
	harvestFX(model, def)

	QuestSystem.report(player, "harvest", nodeType)

	setDepleted(model, def, true)
	task.delay(def.respawn, function()
		if model.Parent then setDepleted(model, def, false) end
	end)
end

-- ---------- Spawnen ----------
local function spawnNode(nodeType: string, pos: Vector3, parent: Instance, scale: number?)
	local def = Resources.get(nodeType)
	if not def then return end
	pos = Vector3.new(pos.X, groundY(pos.X, pos.Z), pos.Z)
	local model, primary
	if def.kind == "tree" then model, primary = buildTree(def, pos, scale)
	elseif def.kind == "forage" then model, primary = buildHerb(def, pos, scale)
	else model, primary = buildRock(def, pos, scale) end
	model.Name = nodeType
	model:SetAttribute("NodeType", nodeType)
	CollectionService:AddTag(model, "Interactable")
	state[model] = { depleted = false }

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = def.kind == "tree" and "F\u{00E4}llen" or def.kind == "forage" and "Sammeln" or "Abbauen"
	prompt.ObjectText = def.display
	prompt.HoldDuration = def.duration
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary
	prompt.Triggered:Connect(function(player) harvest(player, model, nodeType) end)

	model.Parent = parent
end

function ResourceSystem.init()
	local forest = Workspace.World:FindFirstChild("Fluesterwald")
	if not forest then warn("[ResourceSystem] Fluesterwald nicht gefunden"); return end
	-- Alte dekorative (nicht faellbare) Baeume entfernen -> alle Baeume werden Ressourcen
	local oldTrees = forest:FindFirstChild("Trees")
	if oldTrees then oldTrees:Destroy() end
	local folder = forest:FindFirstChild("Resources")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder"); folder.Name = "Resources"; folder.Parent = forest

	math.randomseed(777)
	local function farFromClearing(x, z)
		local dx, dz = x, z - 1150
		return (dx*dx + dz*dz) > 70*70
	end
	local trees, ores, tries = 0, 0, 0
	while trees < 40 and tries < 500 do
		tries += 1
		local x, z = math.random(-240, 240), math.random(980, 1470)
		if farFromClearing(x, z) then
			local nodeType = (math.random() < 0.78) and "OakTree" or "BirchTree"
			spawnNode(nodeType, Vector3.new(x, 0, z), folder, 0.85 + math.random() * 0.7)
			trees += 1
		end
	end
	tries = 0
	while ores < 12 and tries < 400 do
		tries += 1
		local x, z = math.random(-230, 230), math.random(1000, 1460)
		if farFromClearing(x, z) then
			local nodeType = (math.random() < 0.65) and "CopperRock" or "IronRock"
			spawnNode(nodeType, Vector3.new(x, 0, z), folder, 0.85 + math.random() * 0.5)
			ores += 1
		end
	end
	local herbs = 0; tries = 0
	while herbs < 22 and tries < 400 do
		tries += 1
		local x, z = math.random(-240, 240), math.random(980, 1470)
		if farFromClearing(x, z) then
			local nodeType = (math.random() < 0.8) and "HealHerb" or "GlowShroom"
			spawnNode(nodeType, Vector3.new(x, 0, z), folder, 0.9 + math.random() * 0.4)
			herbs += 1
		end
	end
	print(string.format("[ResourceSystem] initialisiert (%d Baeume, %d Erz, %d Kraeuter).", trees, ores, herbs))
end

return ResourceSystem
