--!strict
-- Sanft-exponentielle XP-Kurve fuer Skills (Level 1 bis 50).
-- Level 1 = 0 XP. Jedes weitere Level braucht etwas mehr XP als das vorige.

local XP = {}

XP.MaxLevel = 50

local BASE = 50      -- XP von Level 1 -> 2
local GROWTH = 1.12  -- Wachstum pro Level

-- Kumulative XP, die noetig ist, um ein Level zu ERREICHEN. cumulative[1] = 0.
local cumulative = table.create(XP.MaxLevel)
do
	local total = 0
	cumulative[1] = 0
	for lvl = 1, XP.MaxLevel - 1 do
		local need = math.floor(BASE * (GROWTH ^ (lvl - 1)))
		total = total + need
		cumulative[lvl + 1] = total
	end
end
XP.Cumulative = cumulative

-- Gesamte XP, die noetig ist, um `level` zu erreichen.
function XP.totalForLevel(level: number): number
	level = math.clamp(math.floor(level), 1, XP.MaxLevel)
	return cumulative[level]
end

-- Aktuelles Level fuer eine gegebene XP-Menge.
function XP.levelForXp(xp: number): number
	local lvl = 1
	for l = 1, XP.MaxLevel do
		if xp >= cumulative[l] then
			lvl = l
		else
			break
		end
	end
	return lvl
end

-- Detaillierter Fortschritt: Level, XP im aktuellen Level, XP fuers naechste Level, Anteil 0..1.
export type Progress = { level: number, into: number, need: number, fraction: number, max: boolean }
function XP.progress(xp: number): Progress
	local level = XP.levelForXp(xp)
	if level >= XP.MaxLevel then
		return { level = XP.MaxLevel, into = 0, need = 0, fraction = 1, max = true }
	end
	local base = cumulative[level]
	local nextReq = cumulative[level + 1]
	local into = xp - base
	local need = nextReq - base
	return { level = level, into = into, need = need, fraction = into / need, max = false }
end

return XP
