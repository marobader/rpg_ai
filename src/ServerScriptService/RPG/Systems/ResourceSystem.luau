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
local function buildTree(def, pos): (Model, BasePart)
	local m = Instance.new("Model")
	local th = 15
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"; trunk.Shape = Enum.PartType.Cylinder; trunk.Anchored = true
	trunk.Size = Vector3.new(th, 3, 3)
	trunk.CFrame = CFrame.new(pos) * CFrame.new(0, th/2, 0) * CFrame.Angles(0,0,math.rad(90))
	trunk.Material = Enum.Material.Wood; trunk.Color = rgb(def.trunk)
	trunk.Parent = m
	local foliage = Instance.new("Folder"); foliage.Name = "Foliage"; foliage.Parent = m
	local function ball(dx,dy,dz,s)
		local b = Instance.new("Part"); b.Shape = Enum.PartType.Ball; b.Anchored = true
		b.Size = Vector3.new(s,s,s); b.CFrame = CFrame.new(pos) * CFrame.new(dx, th+dy, dz)
		b.Material = Enum.Material.Grass; b.Color = rgb(def.leaf); b.Parent = foliage
	end
	ball(0,3,0,14); ball(5,1,3,10); ball(-5,1,-3,10); ball(-4,5,4,9); ball(4,5,-4,9)
	m.PrimaryPart = trunk
	return m, trunk
end

local function buildRock(def, pos): (Model, BasePart)
	local m = Instance.new("Model")
	local rock = Instance.new("Part"); rock.Name = "Rock"; rock.Shape = Enum.PartType.Ball; rock.Anchored = true
	rock.Size = Vector3.new(9, 7, 9); rock.CFrame = CFrame.new(pos) * CFrame.new(0, 3, 0)
	rock.Material = Enum.Material.Rock; rock.Color = rgb(def.rock); rock.Parent = m
	local veins = Instance.new("Folder"); veins.Name = "Veins"; veins.Parent = m
	for i=1,5 do
		local v = Instance.new("Part"); v.Anchored = true; v.Shape = Enum.PartType.Ball
		v.Size = Vector3.new(1.6,1.6,1.6)
		local a = math.rad(i*72)
		v.CFrame = CFrame.new(pos) * CFrame.new(math.cos(a)*3.4, 3 + math.sin(a)*2, math.sin(a)*3.4)
		v.Material = Enum.Material.Neon; v.Color = rgb(def.vein); v.Parent = veins
	end
	m.PrimaryPart = rock
	return m, rock
end

local function setDepleted(model: Model, def, depleted: boolean)
	local st = state[model]
	if st then st.depleted = depleted end
	if def.kind == "tree" then
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
	DropSystem.spawn(def.item, def.count, model.PrimaryPart.Position + Vector3.new(0, 2, 0), player)

	QuestSystem.report(player, "harvest", nodeType)

	setDepleted(model, def, true)
	task.delay(def.respawn, function()
		if model.Parent then setDepleted(model, def, false) end
	end)
end

-- ---------- Spawnen ----------
local function spawnNode(nodeType: string, pos: Vector3, parent: Instance)
	local def = Resources.get(nodeType)
	if not def then return end
	pos = Vector3.new(pos.X, groundY(pos.X, pos.Z), pos.Z)
	local model, primary
	if def.kind == "tree" then model, primary = buildTree(def, pos) else model, primary = buildRock(def, pos) end
	model.Name = nodeType
	model:SetAttribute("NodeType", nodeType)
	CollectionService:AddTag(model, "Interactable")
	state[model] = { depleted = false }

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = (def.kind == "tree") and "F\u{00E4}llen" or "Abbauen"
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
	local folder = forest:FindFirstChild("Resources")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder"); folder.Name = "Resources"; folder.Parent = forest

	local layout = {
		{"OakTree", Vector3.new(55,0,1185)}, {"OakTree", Vector3.new(-60,0,1210)},
		{"OakTree", Vector3.new(80,0,1250)}, {"OakTree", Vector3.new(-45,0,1268)},
		{"BirchTree", Vector3.new(115,0,1205)}, {"BirchTree", Vector3.new(-105,0,1185)},
		{"CopperRock", Vector3.new(42,0,1300)}, {"CopperRock", Vector3.new(-72,0,1295)},
		{"CopperRock", Vector3.new(98,0,1315)},
		{"IronRock", Vector3.new(-30,0,1330)}, {"IronRock", Vector3.new(62,0,1345)},
	}
	for _, entry in ipairs(layout) do
		spawnNode(entry[1], entry[2], folder)
	end
	print("[ResourceSystem] initialisiert (" .. #layout .. " Knoten).")
end

return ResourceSystem
