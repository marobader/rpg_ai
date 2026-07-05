--!strict
-- Gegner-Definitionen fuer den Fluesterwald.

local Mobs = {}

Mobs.Defs = {
	Waldgoblin = {
		display = "Waldgoblin", health = 45, damage = 6, walkSpeed = 11,
		aggroRange = 34, attackRange = 6.5, attackCooldown = 1.7, windup = 0.3,
		xp = 20, gold = {2, 6}, respawn = 12,
		loot = { { item = "GoblinEar", chance = 0.7, count = 1 } },
	},
	Wolf = {
		display = "Wolf", health = 60, damage = 9, walkSpeed = 17,
		aggroRange = 42, attackRange = 6.5, attackCooldown = 1.3, windup = 0.25,
		xp = 28, gold = {3, 8}, respawn = 15,
		loot = { { item = "WolfPelt", chance = 0.6, count = 1 } },
	},
	Waldspinne = {
		display = "Waldspinne", health = 38, damage = 5, walkSpeed = 14,
		aggroRange = 30, attackRange = 6, attackCooldown = 1.1, windup = 0.2,
		xp = 18, gold = {1, 5}, respawn = 12,
		loot = { { item = "SpiderSilk", chance = 0.4, count = 1 } },
	},
}

function Mobs.get(t: string)
	return Mobs.Defs[t]
end

return Mobs
