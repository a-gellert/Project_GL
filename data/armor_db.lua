-- Armor tiers ("визуальная эволюция"). Heavy armor replaces the torso/legs look,
-- small pieces go to sockets (helmet, shoulder pads). armor is ArmorFactor 0..0.75.
local M = {}

M.order = { "rags", "tire_vest", "sheet_steel", "cyber_barbarian" }

M.armors = {
	rags = {
		title = "Лохмотья раба", armor = 0.0, price = 0,
		look = { torso = "rags", legs = "rags", belt = "leather_dark" },
	},
	tire_vest = {
		title = "Жилет из покрышек", armor = 0.12, price = 350,
		look = { torso = "tire", legs = "leather", belt = "rust", pads = "tire" },
	},
	sheet_steel = {
		title = "Листовая сталь", armor = 0.25, price = 900,
		look = { torso = "steel_dark", legs = "leather_dark", belt = "rust", pads = "steel", helmet = "rust" },
	},
	cyber_barbarian = {
		title = "Кибер-варвар", armor = 0.4, price = 2200, gears = 3,
		look = { torso = "steel", legs = "tire", belt = "brass", pads = "brass", helmet = "steel_dark" },
	},
}

function M.get(id)
	return M.armors[id] or M.armors.rags
end

return M
