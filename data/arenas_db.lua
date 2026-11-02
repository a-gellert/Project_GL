local M = {}

-- team_size caps the size of the horde round and survival waves on this arena.
M.arenas = {
	[1] = {
		id = "scrap_pit",
		title = "Яма Металлолома",
		required_xp = 0,
		team_size = 5,
		win_credits = 150,
		unlocked_by_default = true,
		radius = 16,
		tier = 1,
		floor = "sand",
		boss = "boss_tier_1",
	},
	[2] = {
		id = "dune_colosseum",
		title = "Песчаный Каркас",
		required_xp = 1200,
		team_size = 8,
		win_credits = 450,
		unlocked_by_default = false,
		radius = 19,
		tier = 2,
		floor = "sand_dark",
		boss = "boss_tier_2",
	},
	[3] = {
		id = "grand_reactor",
		title = "Реакторная Сечь",
		required_xp = 5000,
		team_size = 12,
		win_credits = 1200,
		unlocked_by_default = false,
		radius = 22,
		tier = 3,
		floor = "concrete",
		boss = "boss_tier_3",
	},
}

-- Covers: stop projectiles and push units. { kind, x, z }
M.props = {
	{ "barrel", 5, 3 }, { "barrel", -6, 4 }, { "block", 0, 8 }, { "block", -8, -5 },
	{ "barrel", 7, -6 }, { "block", 9, 2 }, { "barrel", -3, -9 },
}

-- Tournament series, sawtooth difficulty: 4 = semi-boss, 5 = boss, 6 = cool-down horde.
M.series = {
	{ title = "Раунд 1", enemies = { "runner" } },
	{ title = "Раунд 2", enemies = { "raider", "runner" } },
	{ title = "Раунд 3", enemies = { "raider", "thrower", "runner" } },
	{ title = "Полубосс", enemies = { "brute", "runner" } },
	{ title = "БОСС", enemies = { "boss" } },
	{ title = "Разрядка: толпа", enemies = { "minion", "minion", "minion", "minion", "minion", "minion" }, horde = true },
}

-- Survival: 4 growing waves of raiders and mutants.
M.survival = {
	{ "runner", "runner", "raider" },
	{ "raider", "raider", "mutant", "thrower" },
	{ "mutant", "mutant", "raider", "thrower", "runner" },
	{ "brute", "mutant", "mutant", "raider", "thrower", "runner" },
}

-- Gunsmith challenges with a fixed setup.
M.challenges = {
	darts_runners = {
		title = "10 бегунов — только дротики",
		desc = "Ближний бой отключён. Убей 10 бегунов дротиками.",
		kills = 10, enemy = "runner", melee = false, reward_gears = 2, reward_scrap = 200,
	},
	shield_60 = {
		title = "Выжить 60 сек",
		desc = "Только блок и рывок. Продержись 60 секунд.",
		survive = 60, enemy = "raider", melee = false, throw = false, reward_gears = 2, reward_scrap = 200,
	},
}
M.challenge_order = { "darts_runners", "shield_60" }

function M.is_unlocked(index, xp)
	local a = M.arenas[index]
	return a ~= nil and (a.unlocked_by_default or xp >= a.required_xp)
end

return M
