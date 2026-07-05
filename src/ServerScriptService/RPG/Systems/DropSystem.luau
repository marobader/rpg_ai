--!strict
-- Spawnt eingesammelbare Item-Drops (schwebend, mit Magnet + Auto-Pickup).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage.RPG.Config
local Items = require(Config.Items)
local DataManager = require(script.Parent.DataManager)

local DropSystem = {}

local PICKUP_RADIUS = 4.5
local MAGNET_RADIUS = 12
local DESPAWN = 45

local folder: Folder
local drops: { [BasePart]: any } = {}

-- Wie ein Item als Drop aussieht
local VIS = {
	OakLog     = { c = {120, 85, 50},  shape = Enum.PartType.Block, mat = Enum.Material.Wood },
	BirchLog   = { c = {200, 195, 180}, shape = Enum.PartType.Block, mat = Enum.Material.Wood },
	CopperOre  = { c = {200, 110, 45},  shape = Enum.PartType.Block, mat = Enum.Material.Metal },
	IronOre    = { c = {150, 120, 95},  shape = Enum.PartType.Block, mat = Enum.Material.Metal },
	GoblinEar  = { c = {96, 140, 72},   shape = Enum.PartType.Ball,  mat = Enum.Material.SmoothPlastic },
	WolfPelt   = { c = {120, 120, 128}, shape = Enum.PartType.Ball,  mat = Enum.Material.SmoothPlastic },
	SpiderSilk = { c = {220, 225, 235}, shape = Enum.PartType.Ball,  mat = Enum.Material.SmoothPlastic },
}

local function getRemote(name: string): RemoteEvent
	local f = ReplicatedStorage.RPG.Remotes
	local r = f:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = f end
	return r :: RemoteEvent
end

function DropSystem.spawn(itemId: string, count: number, pos: Vector3, owner: Player)
	local def = Items.get(itemId)
	local vis = VIS[itemId] or { c = Items.RarityColor[def and def.rarity or "gewoehnlich"] or {180,180,180}, shape = Enum.PartType.Ball, mat = Enum.Material.SmoothPlastic }
	local color = Color3.fromRGB(vis.c[1], vis.c[2], vis.c[3])

	local part = Instance.new("Part")
	part.Name = itemId
	part.Shape = vis.shape
	part.Size = Vector3.new(0.95, 0.95, 0.95)
	part.Material = vis.mat
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	local ox, oz = (math.random() - 0.5) * 5, (math.random() - 0.5) * 5
	local base = pos + Vector3.new(ox, 2.5, oz)
	part.CFrame = CFrame.new(base)

	local light = Instance.new("PointLight")
	light.Brightness = 1.4; light.Range = 7; light.Color = color; light.Parent = part

	-- kleines Namensschild
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 20); bb.StudsOffset = Vector3.new(0, 1.3, 0)
	bb.AlwaysOnTop = true; bb.MaxDistance = 40; bb.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.TextStrokeTransparency = 0.3
	lbl.Text = (count > 1 and (count .. "x ") or "") .. (def and def.name or itemId)
	lbl.Parent = bb

	part.Parent = folder
	drops[part] = { ownerId = owner.UserId, itemId = itemId, count = count, spawn = os.clock(), base = base, full = false }
end

local function collect(part: BasePart, d, owner: Player)
	if DataManager.addItem(owner, d.itemId, d.count) then
		DataManager.notify(owner, string.format("+%d %s", d.count, Items.name(d.itemId)), "good")
		drops[part] = nil
		part:Destroy()
	elseif not d.full then
		d.full = true
		DataManager.notify(owner, "Inventar voll!", "warn")
	end
end

local function removeDrop(part: BasePart)
	drops[part] = nil
	if part.Parent then part:Destroy() end
end

function DropSystem.init()
	local old = Workspace.World:FindFirstChild("Drops")
	if old then old:Destroy() end
	folder = Instance.new("Folder"); folder.Name = "Drops"; folder.Parent = Workspace.World
	getRemote("Notify")

	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for part, d in pairs(drops) do
			if not part.Parent then
				drops[part] = nil
			elseif t - d.spawn > DESPAWN then
				removeDrop(part)
			else
				local owner = Players:GetPlayerByUserId(d.ownerId)
				local root = owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
				local targetPos = d.base + Vector3.new(0, math.sin(t * 3) * 0.3, 0)
				if root then
					local dist = (root.Position - part.Position).Magnitude
					if dist <= PICKUP_RADIUS then
						collect(part, d, owner)
						continue
					elseif dist <= MAGNET_RADIUS and not d.full then
						targetPos = part.Position:Lerp(root.Position, 0.18)
					end
				end
				part.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, t * 2.5, 0)
			end
		end
	end)
	print("[DropSystem] initialisiert.")
end

return DropSystem
