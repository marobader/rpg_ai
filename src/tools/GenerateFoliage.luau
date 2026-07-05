--!strict
-- EINMALIGES Editor-Werkzeug: streut Foliage (Büsche, Bäumchen, Stämme,
-- Stöcke, Steine, Farne, Blumen, Grasbüschel) per Raycast auf das Terrain.
-- Spart die Baukerne der Zonen aus.

local ws = workspace
local World = ws.World
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function P(parent, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Size = size; p.CFrame = cf; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { ws.Terrain }
local function ground(x, z)
	local res = ws:Raycast(Vector3.new(x, 250, z), Vector3.new(0, -500, 0), rp)
	return res and res.Position.Y or nil
end

local function bush(f, pos)
	local s = 1.8 + math.random() * 1.6
	local col = rgb(48 + math.random(0,26), 96 + math.random(0,34), 44 + math.random(0,18))
	P(f, Vector3.new(s*1.7,s*1.4,s*1.7), CFrame.new(pos + Vector3.new(0, s*0.5, 0)), col, Enum.Material.LeafyGrass, Enum.PartType.Ball)
	P(f, Vector3.new(s*1.2,s,s*1.2), CFrame.new(pos + Vector3.new(s*0.6, s*0.4, s*0.3)), col, Enum.Material.LeafyGrass, Enum.PartType.Ball)
	P(f, Vector3.new(s*1.1,s*0.9,s*1.1), CFrame.new(pos + Vector3.new(-s*0.5, s*0.35, -s*0.4)), col, Enum.Material.LeafyGrass, Enum.PartType.Ball)
end
local function sapling(f, pos)
	local h = 3 + math.random() * 2.5
	P(f, Vector3.new(0.5, h, 0.5), CFrame.new(pos + Vector3.new(0, h/2, 0)), rgb(96,64,42), Enum.Material.Wood)
	local col = rgb(56 + math.random(0,20), 110 + math.random(0,26), 50)
	P(f, Vector3.new(3.4,3.4,3.4), CFrame.new(pos + Vector3.new(0, h+0.6, 0)), col, Enum.Material.LeafyGrass, Enum.PartType.Ball)
	P(f, Vector3.new(2.4,2.4,2.4), CFrame.new(pos + Vector3.new(1, h-0.4, 0.6)), col, Enum.Material.LeafyGrass, Enum.PartType.Ball)
end
local function log(f, pos)
	local len = 5 + math.random() * 5
	local ang = math.random() * math.pi * 2
	local cf = CFrame.new(pos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, ang, 0) * CFrame.Angles(0, 0, math.rad(90))
	P(f, Vector3.new(len, 1.5, 1.5), cf, rgb(92, 66, 44), Enum.Material.Wood, Enum.PartType.Cylinder)
	P(f, Vector3.new(len*0.5, 0.4, 1.3), CFrame.new(pos + Vector3.new(0, 1.35, 0)) * CFrame.Angles(0, ang, 0), rgb(70,110,55), Enum.Material.Grass)
end
local function stick(f, pos)
	local ang = math.random() * math.pi * 2
	P(f, Vector3.new(1.6 + math.random()*1.5, 0.28, 0.28), CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, ang, 0), rgb(78, 55, 38), Enum.Material.Wood)
end
local function rock(f, pos)
	local s = 1.2 + math.random() * 2.5
	P(f, Vector3.new(s, s*0.8, s*1.1), CFrame.new(pos + Vector3.new(0, s*0.25, 0)) * CFrame.Angles(math.rad(math.random(-12,12)),0,math.rad(math.random(-12,12))), rgb(108,105,110), Enum.Material.Rock, Enum.PartType.Ball)
end
local function fern(f, pos)
	local c = rgb(44 + math.random(0,18), 104 + math.random(0,28), 44)
	for i = 1, 4 do
		local a = math.rad(i*90 + math.random(-20,20))
		P(f, Vector3.new(0.4, 3, 1.6), CFrame.new(pos + Vector3.new(0, 1.3, 0)) * CFrame.Angles(math.rad(38), a, 0), c, Enum.Material.LeafyGrass)
	end
end
local function flower(f, pos)
	P(f, Vector3.new(0.18, 1.4, 0.18), CFrame.new(pos + Vector3.new(0, 0.7, 0)), rgb(80,130,60), Enum.Material.Grass)
	local petals = { rgb(240,240,250), rgb(240,210,80), rgb(230,120,170), rgb(160,120,220), rgb(230,120,90) }
	P(f, Vector3.new(0.55,0.55,0.55), CFrame.new(pos + Vector3.new(0, 1.5, 0)), petals[math.random(#petals)], Enum.Material.SmoothPlastic, Enum.PartType.Ball)
end
local function tuft(f, pos)
	local c = rgb(70 + math.random(0,20), 120 + math.random(0,24), 52)
	for i = 1, 5 do
		local a = math.rad(i*72 + math.random(-15,15))
		P(f, Vector3.new(0.22, 1.6 + math.random()*0.8, 0.22), CFrame.new(pos + Vector3.new(0, 0.8, 0)) * CFrame.Angles(math.rad(math.random(8,22)), a, 0), c, Enum.Material.Grass)
	end
end

local function scatter(zoneParent, center, avoidR, spread, counts)
	local old = zoneParent:FindFirstChild("Foliage")
	if old then old:Destroy() end
	local f = Instance.new("Folder"); f.Name = "Foliage"; f.Parent = zoneParent
	for builder, n in pairs(counts) do
		local placed, tries = 0, 0
		while placed < n and tries < n * 6 do
			tries += 1
			local x = center.X + (math.random() - 0.5) * spread
			local z = center.Z + (math.random() - 0.5) * spread
			local dx, dz = x - center.X, z - center.Z
			if (dx*dx + dz*dz) >= avoidR*avoidR then
				local gy = ground(x, z)
				if gy and gy < 20 then builder(f, Vector3.new(x, gy, z)); placed += 1 end
			end
		end
	end
end

math.randomseed(2024)
scatter(World.Village, Vector3.new(0,0,0), 56, 360, { [bush]=34,[sapling]=18,[log]=10,[stick]=34,[rock]=24,[flower]=42,[tuft]=46 })
scatter(World.Fluesterwald, Vector3.new(0,0,1220), 64, 440, { [bush]=40,[sapling]=22,[log]=16,[stick]=40,[rock]=22,[fern]=48,[tuft]=40 })
print("Foliage platziert.")
