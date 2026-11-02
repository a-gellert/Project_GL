-- Persistent player profile (meta progression). Saved with sys.save,
-- which maps to localStorage on HTML5.
local stats_calculator = require("modules.stats_calculator")

local M = {}

local SAVE_VERSION = 1
local save_path = nil

local function defaults()
	return {
		version = SAVE_VERSION,
		level = 1,
		xp = 0,
		total_xp = 0,
		stat_points = 0,
		points = { hp = 0, str = 0, agi = 0 },
		scrap = 0,
		gears = 0,
		melee = "rusty_pipe",
		secondary = "rebar_dart",
		shield = "",
		armor = "rags",
		owned = { rusty_pipe = true, rebar_dart = true, rags = true },
		upgrades = {},
		mods = {},
		tutorial_done = false,
		fights = 0,
		fights_since_ad = 0,
		series_won = 0,
	}
end

M.data = defaults()

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			merge(dst[k], v)
		else
			dst[k] = v
		end
	end
end

function M.load()
	save_path = save_path or sys.get_save_file("project_gl", "profile")
	local data = defaults()
	local ok, loaded = pcall(sys.load, save_path)
	if ok and type(loaded) == "table" and loaded.version == SAVE_VERSION then
		merge(data, loaded)
	end
	M.data = data
	return data
end

function M.save()
	save_path = save_path or sys.get_save_file("project_gl", "profile")
	local ok, err = pcall(sys.save, save_path, M.data)
	if not ok then
		print("profile save failed", err)
	end
end

function M.reset()
	M.data = defaults()
	M.save()
end

function M.xp_to_next(level)
	return 100 + (level - 1) * 120
end

-- Returns number of levels gained.
function M.add_xp(amount)
	local d = M.data
	d.xp = d.xp + amount
	d.total_xp = d.total_xp + amount
	local gained = 0
	while d.xp >= M.xp_to_next(d.level) do
		d.xp = d.xp - M.xp_to_next(d.level)
		d.level = d.level + 1
		d.stat_points = d.stat_points + stats_calculator.POINTS_PER_LEVEL
		gained = gained + 1
	end
	return gained
end

function M.stats()
	return stats_calculator.player_stats(M.data.points)
end

function M.upgrade_level(weapon_id)
	return M.data.upgrades[weapon_id] or 0
end

function M.has_mod(mod_id)
	return M.data.mods[mod_id] == true
end

function M.owns(item_id)
	return M.data.owned[item_id] == true
end

return M
