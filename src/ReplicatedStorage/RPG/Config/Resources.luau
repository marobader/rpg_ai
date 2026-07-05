--!strict
-- Definitionen fuer abbaubare Ressourcen-Knoten (Baeume, Erz).
-- kind: "tree" | "rock"

local Resources = {}

Resources.Nodes = {
	OakTree   = { display = "Eiche",       skill = "Holzfaellen", level = 1,  xp = 15, item = "OakLog",   count = 1, duration = 2.0, respawn = 6,  kind = "tree", trunk = {96,64,42},  leaf = {70,120,55} },
	BirchTree = { display = "Birke",       skill = "Holzfaellen", level = 8,  xp = 28, item = "BirchLog", count = 1, duration = 2.6, respawn = 9,  kind = "tree", trunk = {210,205,195}, leaf = {120,170,80} },
	CopperRock = { display = "Kupferader", skill = "Bergbau",     level = 1,  xp = 18, item = "CopperOre", count = 1, duration = 2.4, respawn = 8,  kind = "rock", rock = {110,105,100}, vein = {200,110,45} },
	IronRock   = { display = "Eisenader",  skill = "Bergbau",     level = 15, xp = 42, item = "IronOre",   count = 1, duration = 3.2, respawn = 13, kind = "rock", rock = {95,92,96},   vein = {150,120,95} },
}

function Resources.get(nodeType: string)
	return Resources.Nodes[nodeType]
end

return Resources
