-- Character looks: body colours per mesh + socket items.
-- Used by modules/character_builder.lua for NPCs, enemies and bosses.
local M = {}

M.presets = {
	blacksmith = {
		name = "Вулкан",
		body = { skin_color = "dark_soot", torso = "leather", legs = "leather_dark", belt = "rust" },
		sockets = { head = "goggles", hand_r = "smith_hammer" },
		scale = 1.15,
	},
	trainer = {
		name = "Кассий",
		body = { skin_color = "tan", torso = "leather", legs = "cloth_red", belt = "brass" },
		sockets = { head = "centurion_helmet", hand_r = "wooden_spatha", hand_l = "round_shield" },
		scale = 1.05,
	},
	merchant = {
		name = "Шайтан",
		body = { skin_color = "pale", torso = "cloth_blue", legs = "leather_dark", belt = "brass" },
		sockets = { head = "turban_gasmask", back = "large_junk_pack" },
		scale = 0.95,
	},
	boss_tier_1 = {
		name = "Мясник Свалки",
		body = { skin_color = "mutant_pale", torso = "rust_dark", legs = "tire", belt = "rust" },
		sockets = { head = "welding_mask", hand_r = "circular_saw_machete", hand_l = "car_door_shield", pads = "rust" },
		scale = 1.3,
	},
	boss_tier_2 = {
		name = "Королева Дюн",
		body = { skin_color = "tan", torso = "brass", legs = "leather_dark", belt = "steel" },
		sockets = { head = "centurion_helmet", hand_r = "circular_saw_machete", pads = "brass" },
		scale = 1.25,
	},
	boss_tier_3 = {
		name = "Реактор-Кулак",
		body = { skin_color = "mutant_green", torso = "steel", legs = "steel_dark", belt = "copper" },
		sockets = { head = "welding_mask", hand_r = "smith_hammer", hand_l = "car_door_shield", pads = "copper" },
		scale = 1.4,
	},
	-- regular enemies
	runner = {
		name = "Бегун",
		body = { skin_color = "tan", torso = "rags", legs = "rags", belt = "leather_dark" },
		sockets = { hand_r = "shiv" },
		scale = 0.9,
	},
	minion = {
		name = "Миньон",
		body = { skin_color = "pale", torso = "rags", legs = "rags", belt = "rags" },
		sockets = { hand_r = "shiv" },
		scale = 0.85,
	},
	raider = {
		name = "Рейдер",
		body = { skin_color = "tan", torso = "leather", legs = "leather_dark", belt = "rust" },
		sockets = { hand_r = "pipe", head = "bandana" },
		scale = 1.0,
	},
	thrower = {
		name = "Метатель",
		body = { skin_color = "pale", torso = "cloth_blue", legs = "leather", belt = "leather_dark" },
		sockets = { hand_r = "dart", back = "quiver" },
		scale = 0.95,
	},
	mutant = {
		name = "Мутант",
		body = { skin_color = "mutant_green", torso = "mutant_green", legs = "rags", belt = "rags" },
		sockets = { hand_r = "claw" },
		scale = 1.1,
	},
	brute = {
		name = "Громила",
		body = { skin_color = "dark_soot", torso = "tire", legs = "leather_dark", belt = "rust" },
		sockets = { hand_r = "nail_bat", hand_l = "manhole_cover", pads = "tire", head = "welding_mask" },
		scale = 1.2,
	},
	-- camp background gladiators
	gladiator_a = {
		name = "Гладиатор",
		body = { skin_color = "tan", torso = "leather", legs = "rags", belt = "rust" },
		sockets = { hand_r = "pipe" },
		scale = 1.0,
	},
	gladiator_b = {
		name = "Гладиатор",
		body = { skin_color = "dark_soot", torso = "rags", legs = "leather_dark", belt = "leather" },
		sockets = { hand_r = "wooden_spatha", hand_l = "round_shield" },
		scale = 1.05,
	},
}

-- Socket items: which part of character.collection they use, its size and colour.
M.items = {
	goggles = { part = "helmet", scale = { 0.38, 0.1, 0.38 }, color = "brass" },
	centurion_helmet = { part = "helmet", scale = { 0.42, 0.24, 0.42 }, color = "brass" },
	turban_gasmask = { part = "helmet", scale = { 0.46, 0.28, 0.46 }, color = "cloth_blue" },
	welding_mask = { part = "helmet", scale = { 0.42, 0.36, 0.44 }, color = "steel_dark" },
	bandana = { part = "helmet", scale = { 0.38, 0.1, 0.38 }, color = "cloth_red" },
	smith_hammer = { part = "weapon", scale = { 0.26, 0.2, 0.7 }, color = "steel_dark" },
	wooden_spatha = { part = "weapon", scale = { 0.04, 0.14, 0.95 }, color = "wood" },
	circular_saw_machete = { part = "weapon", scale = { 0.55, 0.06, 0.9 }, color = "steel" },
	shiv = { part = "weapon", scale = { 0.04, 0.08, 0.5 }, color = "steel_dark" },
	pipe = { part = "weapon", scale = { 0.08, 0.08, 0.9 }, color = "rust" },
	nail_bat = { part = "weapon", scale = { 0.14, 0.14, 1.05 }, color = "wood" },
	dart = { part = "weapon", scale = { 0.05, 0.05, 0.8 }, color = "rust_dark" },
	claw = { part = "weapon", scale = { 0.2, 0.06, 0.4 }, color = "mutant_pale" },
	round_shield = { part = "shield", scale = { 0.62, 0.62, 0.08 }, color = "wood" },
	car_door_shield = { part = "shield", scale = { 0.8, 0.7, 0.08 }, color = "barrel_red" },
	manhole_cover = { part = "shield", scale = { 0.7, 0.7, 0.07 }, color = "steel_dark" },
	large_junk_pack = { part = "back", scale = { 0.6, 0.7, 0.36 }, color = "rags" },
	quiver = { part = "back", scale = { 0.22, 0.6, 0.18 }, color = "leather" },
}

return M
