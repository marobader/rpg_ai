--!strict
-- EINMALIGES Editor-Werkzeug (kein Runtime-Script).
-- Generiert Perlin-Noise-Terrain fuer Dorf + Fluesterwald:
--   - flacher Kern (Bauten sitzen eben)
--   - sanfte Hügel im Mittelring
--   - Bergwall am Rand (verdeckt die Terrain-Kante)
-- Ausfuehren im Studio-Command-Bar oder via execute_luau (Edit-Modus).
-- Vorher: alte flache Boden-Parts (Baseplate, Fluesterwald.Ground) entfernen.

local Terrain = workspace.Terrain
local RES = 8       -- Voxel-Rasterweite (Vielfaches von 4)
local FLOOR = -30   -- Untergrenze der Fuellsaeulen

local function setup()
	Terrain:Clear()
	Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(86, 128, 62))
	Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(112, 108, 104))
	Terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(118, 94, 64))
	Terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(74, 118, 54))
end

-- cx,cz: Zonenzentrum | S: Halbgroesse (Quadrat) | flatR..hillR: Hügel- Rampe
-- hillAmp: Hügelhöhe | mountBand: Randbreite der Berge | mountH: Berghöhe
local function genZone(cx, cz, S, flatR, hillR, hillAmp, mountBand, mountH, seed, grassMat)
	for x = -S, S, RES do
		for z = -S, S, RES do
			local wx, wz = cx + x, cz + z
			local dist = math.sqrt(x * x + z * z)
			local flatten = math.clamp((dist - flatR) / (hillR - flatR), 0, 1)
			local n = math.noise(wx * 0.013 + seed, wz * 0.013 - seed)
			local hill = n * hillAmp * flatten
			local edgeDist = S - math.max(math.abs(x), math.abs(z))
			local mount = 0
			if edgeDist < mountBand then
				local m = 1 - edgeDist / mountBand
				mount = m * m * mountH + math.noise(wx * 0.03, wz * 0.03) * 8 * m
			end
			local h = math.max(hill + mount, 1)
			local mat = grassMat
			if h > 46 then
				mat = Enum.Material.Rock
			elseif h > 26 and math.noise(wx * 0.05, wz * 0.05) > 0.05 then
				mat = Enum.Material.Rock
			end
			Terrain:FillBlock(CFrame.new(wx, (FLOOR + h) / 2, wz), Vector3.new(RES, h - FLOOR, RES), mat)
		end
	end
end

setup()
-- Dorf Eichhain (Zentrum 0,0)
genZone(0, 0, 256, 95, 200, 11, 68, 78, 0, Enum.Material.Grass)
-- Fluesterwald (Zentrum 0,1220)
genZone(0, 1220, 312, 160, 255, 10, 80, 90, 100, Enum.Material.LeafyGrass)

print("Terrain generiert.")
