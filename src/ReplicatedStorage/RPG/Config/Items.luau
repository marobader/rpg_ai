--!strict
-- Zentrale Item-Definitionen. id -> Metadaten.
-- rarity: "gewoehnlich" | "selten" | "episch" | "mystisch"

local Items = {}

Items.RarityColor = {
	gewoehnlich = {180, 180, 180},
	selten      = {80, 150, 235},
	episch      = {170, 90, 220},
	mystisch    = {235, 165, 55},
}

Items.ById = {
	-- Ressourcen: Holz
	OakLog   = { name = "Eichenholz", type = "Ressource", rarity = "gewoehnlich", maxStack = 99, sell = 3 },
	BirchLog = { name = "Birkenholz", type = "Ressource", rarity = "gewoehnlich", maxStack = 99, sell = 6 },
	-- Ressourcen: Erz
	CopperOre = { name = "Kupfererz", type = "Ressource", rarity = "gewoehnlich", maxStack = 99, sell = 5 },
	IronOre   = { name = "Eisenerz",  type = "Ressource", rarity = "selten",      maxStack = 99, sell = 12 },
	-- Beute
	GoblinEar  = { name = "Goblinohr",    type = "Beute", rarity = "gewoehnlich", maxStack = 99, sell = 4 },
	WolfPelt   = { name = "Wolfsfell",    type = "Beute", rarity = "gewoehnlich", maxStack = 99, sell = 6 },
	SpiderSilk = { name = "Spinnenseide", type = "Beute", rarity = "selten",      maxStack = 99, sell = 10 },
}

function Items.get(id: string)
	return Items.ById[id]
end

function Items.name(id: string): string
	local d = Items.ById[id]
	return d and d.name or id
end

return Items
