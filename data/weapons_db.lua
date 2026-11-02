-- Weapon stats. `kind`: melee | throw | ranged.
-- visual.scale is the size of the "weapon" part of character.collection (Hand_R_Socket).
local M = {}

M.weapons = {
	-- Melee ---------------------------------------------------------------
	rusty_pipe = {
		kind = "melee", title = "Ржавая труба", damage = 12, range = 2.0, arc = 110,
		windup = 0.16, recovery = 0.24, stamina = 8, price = 0,
		visual = { scale = { 0.08, 0.08, 0.9 }, color = "rust" },
	},
	spring_machete = {
		kind = "melee", title = "Мачете из рессоры", damage = 16, range = 2.1, arc = 100,
		windup = 0.14, recovery = 0.22, stamina = 8, price = 250,
		bleed_chance = 0.1,
		visual = { scale = { 0.04, 0.18, 1.0 }, color = "steel" },
	},
	nail_bat = {
		kind = "melee", title = "Бита с гвоздями", damage = 22, range = 2.1, arc = 120,
		windup = 0.22, recovery = 0.3, stamina = 11, price = 500,
		bleed_chance = 0.2,
		visual = { scale = { 0.14, 0.14, 1.05 }, color = "wood" },
	},
	saw_blade = {
		kind = "melee", title = "Пила на рукоятке", damage = 32, range = 2.3, arc = 140,
		windup = 0.28, recovery = 0.36, stamina = 15, price = 1100,
		visual = { scale = { 0.5, 0.06, 0.8 }, color = "steel_dark" },
	},
	-- Throwables (retrievable) --------------------------------------------
	rebar_dart = {
		kind = "throw", title = "Дротики из арматуры", damage = 24, ammo = 3,
		speed = 18, speed_charge = 10, gravity = 9.8, charge_time = 0.6, cooldown = 0.35, price = 0,
		visual = { scale = { 0.05, 0.05, 0.9 }, color = "rust_dark" },
	},
	harpoon = {
		kind = "throw", title = "Охотничьи гарпуны", damage = 36, ammo = 4,
		speed = 20, speed_charge = 12, gravity = 9.8, charge_time = 0.7, cooldown = 0.4, price = 600,
		visual = { scale = { 0.07, 0.07, 1.2 }, color = "steel" },
	},
	-- Ranged (bolts are not retrievable, reload instead) -----------------
	spring_crossbow = {
		kind = "ranged", title = "Рессорный арбалет", damage = 42, ammo = 1, reload = 1.6,
		speed = 38, speed_charge = 0, gravity = 2.0, charge_time = 0.25, cooldown = 0.2, price = 900,
		visual = { scale = { 0.04, 0.04, 0.6 }, color = "brass" },
	},
}

M.melee_order = { "rusty_pipe", "spring_machete", "nail_bat", "saw_blade" }
M.secondary_order = { "rebar_dart", "harpoon", "spring_crossbow" }

-- Shields go to Hand_L_Socket. No shield => parry window instead of block.
M.shields = {
	road_sign = { title = "Дорожный знак", block = 0.7, price = 150, scale = { 0.62, 0.8, 0.05 }, color = "cloth_red" },
	manhole_cover = { title = "Крышка люка", block = 0.85, price = 400, scale = { 0.7, 0.7, 0.07 }, color = "steel_dark" },
}
M.shield_order = { "road_sign", "manhole_cover" }

-- Blacksmith modifiers.
M.mods = {
	barbed_wire = { title = "Колючая проволока", desc = "+25% шанс кровотечения (ближний бой)", price = 300, gears = 1 },
	battery = { title = "Аккумулятор", desc = "Электрошок атакующего при блоке", price = 400, gears = 2 },
	propane = { title = "Баллон с пропаном", desc = "Поджигающие снаряды", price = 450, gears = 2 },
}
M.mod_order = { "barbed_wire", "battery", "propane" }

M.UPGRADE_MAX = 5
M.UPGRADE_DAMAGE = 0.15

function M.upgrade_cost(level)
	return 120 + level * 140
end

function M.get(id)
	return M.weapons[id]
end

return M
