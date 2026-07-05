--!strict
-- EINMALIGES Editor-Werkzeug: malt Wege + Plaza/Lichtung direkt ins Terrain
-- (via WriteVoxels — setzt Höhe UND Material exakt, ohne die Fläche anzuheben).
-- Cobblestone/Ground haben keine Gras-Dekoration → Wege bleiben sichtbar.
-- WICHTIG: FillBlock/FillCylinder taugen NICHT (sie heben die Fläche auf die
-- Voxel-Grenze an und lassen sich nicht abtragen). Deshalb WriteVoxels.

local Terrain = workspace.Terrain
local SURFACE = 3   -- Zielhöhe der flachen Kern-Oberfläche

local function writeRegion(minX, maxX, minZ, maxZ, matFn)
	local region = Region3.new(Vector3.new(minX, -34, minZ), Vector3.new(maxX, 10, maxZ)):ExpandToGrid(4)
	local size = region.Size
	local nx, ny, nz = size.X / 4, size.Y / 4, size.Z / 4
	local minc = region.CFrame.Position - size / 2
	local mats, occs = {}, {}
	for xi = 1, nx do
		mats[xi] = {}; occs[xi] = {}
		local wx = minc.X + (xi - 0.5) * 4
		for yi = 1, ny do
			mats[xi][yi] = {}; occs[xi][yi] = {}
			local wy = minc.Y + (yi - 0.5) * 4
			for zi = 1, nz do
				local wz = minc.Z + (zi - 0.5) * 4
				local bot = wy - 2
				local occ
				if wy + 2 <= SURFACE then occ = 1
				elseif bot >= SURFACE then occ = 0
				else occ = (SURFACE - bot) / 4 end
				local mat = matFn(wx, wz)
				if occ <= 0 then mat = Enum.Material.Air end
				mats[xi][yi][zi] = mat
				occs[xi][yi][zi] = occ
			end
		end
	end
	Terrain:WriteVoxels(region, 4, mats, occs)
end

local COB, GR = Enum.Material.Cobblestone, Enum.Material.Grass
local GRD, LG = Enum.Material.Ground, Enum.Material.LeafyGrass

-- Dorf: Plaza-Scheibe (r46) + Hauptweg (z) + Marktweg (x)
writeRegion(-60, 60, -60, 80, function(wx, wz)
	if wx * wx + wz * wz <= 46 * 46 then return COB end
	if math.abs(wx) <= 5 and wz >= -48 and wz <= 74 then return COB end
	if math.abs(wz) <= 5 and wx >= 0 and wx <= 36 then return COB end
	return GR
end)

-- Wald: Lichtung (r32 um z=1150) + Pfad
writeRegion(-52, 52, 1105, 1245, function(wx, wz)
	local dz = wz - 1150
	if wx * wx + dz * dz <= 32 * 32 then return GRD end
	if math.abs(wx) <= 4 and wz >= 1118 and wz <= 1212 then return GRD end
	return LG
end)

print("Wege + Plaza + Lichtung ins Terrain gemalt.")
