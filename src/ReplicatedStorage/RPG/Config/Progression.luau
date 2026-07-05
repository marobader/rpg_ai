--!strict
-- Zentrale Progression: Skill-Level -> Effekte (Schaden, HP, Krit, Ausbeute).
-- Wird von Combat-, Mob- und Resource-System gelesen.

local Progression = {}

Progression.CombatSkills = { Schwert = true, Bogen = true, Magie = true }

-- Nahkampfschaden steigt mit dem Skill-Level
function Progression.meleeDamage(level: number): number
	return 12 + math.floor(level * 0.9)
end

-- Maximale Lebensenergie steigt mit dem Kampf-Level
function Progression.maxHealth(combatLevel: number): number
	return 100 + (combatLevel - 1) * 8
end

-- Kritische-Treffer-Chance (5% .. 45%)
function Progression.critChance(level: number): number
	return math.clamp(0.05 + level * 0.006, 0.05, 0.45)
end
Progression.CritMultiplier = 1.8

-- Chance auf Bonus-Ausbeute beim Sammeln (0 .. 50%)
function Progression.bonusYieldChance(level: number): number
	return math.clamp(level * 0.012, 0, 0.5)
end

return Progression
