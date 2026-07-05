--!strict
-- Quest-Definitionen. Objektive: kind = "harvest" (target=NodeType) | "kill" (target=MobType).

local Quests = {}

Quests.Defs = {
	waldrand = {
		title = "Der Waldrand",
		giver = "Alwin",
		summary = "Alwin, der Dorf\u{00E4}lteste, bittet dich, den Wald etwas auszud\u{00FC}nnen.",
		objectives = {
			{ key = "oak",    kind = "harvest", target = "OakTree",    amount = 5, text = "Eichen f\u{00E4}llen" },
			{ key = "goblin", kind = "kill",    target = "Waldgoblin", amount = 3, text = "Waldgoblins besiegen" },
		},
		rewards = { gold = 50, xp = { Schwert = 35, Holzfaellen = 25 } },
	},
}

function Quests.get(id: string)
	return Quests.Defs[id]
end

return Quests
