-- Combat math from the design doc. Pure functions, no engine calls.
local M = {}

M.BASE_HP = 100
M.BASE_STR = 10
M.BASE_AGI = 10
M.POINTS_PER_LEVEL = 10
M.ARMOR_CAP = 0.75

local function clamp_armor(armor_percent)
	return math.min(math.max(armor_percent or 0, 0.0), M.ARMOR_CAP)
end

local function variance()
	return 0.9 + (math.random() * 0.2)
end

function M.calculate_melee_damage(base_weapon_dmg, str, agi, armor_percent)
	local raw_dmg = base_weapon_dmg * (1 + str / 100) * (1 + agi / 150)
	return raw_dmg * variance() * (1 - clamp_armor(armor_percent))
end

function M.calculate_ranged_damage(base_weapon_dmg, str, agi, armor_percent)
	local raw_dmg = base_weapon_dmg * (1 + str / 150) * (1 + agi / 100)
	return raw_dmg * variance() * (1 - clamp_armor(armor_percent))
end

-- Flat damage (enemies, statuses): only variance and armor.
function M.calculate_flat_damage(dmg, armor_percent)
	return dmg * variance() * (1 - clamp_armor(armor_percent))
end

function M.get_move_speed(base_speed, agi)
	return base_speed * (1 + (agi - 10) / 200)
end

function M.get_attack_rate(agi)
	return 1.0 + (agi - 10) / 100
end

function M.get_max_stamina(agi)
	return 100 + (agi - 10)
end

-- Player stats from invested points: { hp, str, agi }.
function M.player_stats(points)
	return {
		hp = M.BASE_HP + (points.hp or 0),
		str = M.BASE_STR + (points.str or 0),
		agi = M.BASE_AGI + (points.agi or 0),
	}
end

return M
