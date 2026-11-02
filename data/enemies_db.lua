-- Enemy archetypes: combat stats + AI behaviour. `preset` points to npc_presets.
-- ai: "melee" (approach and swing), "thrower" (keep distance, throw darts), "boss" (combo + charge).
local M = {}

M.enemies = {
	runner = {
		preset = "runner", hp = 40, damage = 8, speed = 5.2, armor = 0.0,
		windup = 0.42, recovery = 0.5, range = 1.7, ai = "melee",
		scrap = 12, xp = 15,
	},
	minion = {
		preset = "minion", hp = 22, damage = 6, speed = 4.4, armor = 0.0,
		windup = 0.5, recovery = 0.6, range = 1.6, ai = "melee",
		scrap = 6, xp = 6,
	},
	raider = {
		preset = "raider", hp = 70, damage = 12, speed = 4.0, armor = 0.1,
		windup = 0.5, recovery = 0.55, range = 2.0, ai = "melee",
		scrap = 20, xp = 25,
	},
	thrower = {
		preset = "thrower", hp = 50, damage = 14, speed = 3.8, armor = 0.0,
		windup = 0.7, recovery = 1.6, range = 11, ai = "thrower",
		scrap = 18, xp = 22,
	},
	mutant = {
		preset = "mutant", hp = 90, damage = 15, speed = 4.6, armor = 0.05,
		windup = 0.38, recovery = 0.5, range = 1.9, ai = "melee",
		scrap = 25, xp = 30,
	},
	brute = {
		preset = "brute", hp = 220, damage = 22, speed = 3.0, armor = 0.25, shield = true,
		windup = 0.75, recovery = 0.8, range = 2.4, ai = "melee",
		scrap = 70, xp = 80, gears = 1, semi_boss = true,
	},
	boss = {
		-- preset is chosen per arena (arenas_db.boss)
		hp = 420, damage = 26, speed = 3.6, armor = 0.3, shield = true,
		windup = 0.6, recovery = 0.7, range = 2.6, ai = "boss",
		scrap = 160, xp = 200, gears = 2, boss = true,
	},
}

-- Stat multiplier per arena tier.
function M.tier_mult(tier)
	return 1 + (tier - 1) * 0.6
end

return M
