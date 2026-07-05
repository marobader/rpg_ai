--!strict
-- Zentrale Skill-Definitionen. Alle 12 Skills sind definiert;
-- 'active = true' markiert die Skills, die im Prototyp bereits nutzbar sind.

export type SkillDef = {
	key: string,
	name: string,
	category: string,
	active: boolean,
	color: {number},
}

local Skills = {}

Skills.MaxLevel = 50

Skills.Categories = { "Kampf", "Sammeln", "Handwerk", "Wissen" }

Skills.List = {
	{ key = "Schwert",      name = "Schwert",      category = "Kampf",    active = true,  color = {200, 60, 60} },
	{ key = "Bogen",        name = "Bogen",        category = "Kampf",    active = false, color = {120, 180, 70} },
	{ key = "Magie",        name = "Magie",        category = "Kampf",    active = false, color = {110, 90, 220} },
	{ key = "Holzfaellen",  name = "Holzf\u{00E4}llen",  category = "Sammeln",  active = true,  color = {130, 90, 50} },
	{ key = "Bergbau",      name = "Bergbau",      category = "Sammeln",  active = true,  color = {150, 150, 160} },
	{ key = "Angeln",       name = "Angeln",       category = "Sammeln",  active = false, color = {60, 140, 200} },
	{ key = "Schmieden",    name = "Schmieden",    category = "Handwerk", active = false, color = {200, 120, 40} },
	{ key = "Kochen",       name = "Kochen",       category = "Handwerk", active = false, color = {220, 170, 90} },
	{ key = "Herstellen",   name = "Herstellen",   category = "Handwerk", active = false, color = {170, 140, 110} },
	{ key = "Alchemie",     name = "Alchemie",     category = "Wissen",   active = true,  color = {80, 200, 140} },
	{ key = "Handeln",      name = "Handeln",      category = "Wissen",   active = false, color = {220, 200, 80} },
	{ key = "Archaeologie", name = "Arch\u{00E4}ologie", category = "Wissen",   active = false, color = {180, 150, 90} },
}

Skills.ByKey = {}
for _, s in ipairs(Skills.List) do
	Skills.ByKey[s.key] = s
end

function Skills.exists(key: string): boolean
	return Skills.ByKey[key] ~= nil
end

function Skills.isActive(key: string): boolean
	local s = Skills.ByKey[key]
	return s ~= nil and s.active == true
end

-- Iterator over all skill keys in defined order
function Skills.keys(): {string}
	local t = {}
	for _, s in ipairs(Skills.List) do
		table.insert(t, s.key)
	end
	return t
end

return Skills
