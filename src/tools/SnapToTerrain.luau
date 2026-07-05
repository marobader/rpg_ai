--!strict
-- EINMALIGES Editor-Werkzeug: setzt alle statischen Bauten/Deko exakt auf die
-- Terrain-Oberfläche (Unterkante = Boden per Raycast). Nötig, wenn das Terrain
-- neu generiert wurde (Roblox-Terrain rundet die Kern-Höhe auf ~y=3).
-- Laufzeit-Objekte (Ressourcen/Mobs) rastern selbst per groundY beim Spawn.

local ws = workspace
local World = ws.World
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { ws.Terrain }
local function groundY(x, z)
	local r = ws:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rp)
	return r and r.Position.Y or nil
end

local function snap(inst)
	if inst:IsA("Model") then
		local cf, size = inst:GetBoundingBox()
		local gy = groundY(cf.Position.X, cf.Position.Z)
		if gy then
			inst:PivotTo(inst:GetPivot() + Vector3.new(0, gy - (cf.Position.Y - size.Y / 2) + 0.05, 0))
		end
	elseif inst:IsA("BasePart") then
		local gy = groundY(inst.Position.X, inst.Position.Z)
		if gy then
			inst.CFrame = inst.CFrame + Vector3.new(0, gy - (inst.Position.Y - inst.Size.Y / 2) + 0.05, 0)
		end
	end
end

local SKIP = { Foliage = true, Mobs = true, Resources = true, Drops = true, Paths = true }

for _, c in ipairs(World.Village:GetChildren()) do
	if not SKIP[c.Name] then snap(c) end
end
for _, c in ipairs(World.Fluesterwald:GetChildren()) do
	if c.Name == "Trees" then
		for _, t in ipairs(c:GetChildren()) do snap(t) end
	elseif not SKIP[c.Name] then
		snap(c)
	end
end
print("Alle Bauten/Deko auf Terrain gesetzt.")
