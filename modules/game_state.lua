-- Shared runtime state between scripts (shared_state = 1 in game.project).
-- The arena writes `hud`, the combat GUI reads it; GUIs push `requests` back.
local M = {}

-- What the arena should run next. mode: tournament | survival | challenge | sparring
M.next_match = { mode = "tournament", arena = 1 }

-- Last match outcome, shown in the camp.
M.last_result = nil

-- Camp camera focus: nil | "blacksmith" | "trainer" | "merchant" | "gate"
M.camp_focus = nil

M.hud = {}
M.requests = {}

function M.reset_hud()
	M.hud = {
		hp = 1, hp_max = 1, stamina = 1, stamina_max = 1,
		ammo = 0, ammo_max = 0, reload = 0, secondary_title = "",
		round_title = "", enemies_left = 0,
		boss_name = nil, boss_hp = 0,
		banner = nil, banner_id = 0,
		hint = nil,
		prompt_pickup = false,
		aiming = false, aim_charge = 0,
		floaters = {},
		window = nil, -- nil | "defeat" | "results" | "pause"
		result = nil,
		can_revive = false,
		melee_enabled = true, throw_enabled = true,
		low_hp = false,
	}
	M.requests = {}
end

function M.push_request(name, args)
	table.insert(M.requests, { name = name, args = args })
end

function M.pop_requests()
	local r = M.requests
	M.requests = {}
	return r
end

-- Floating numbers: world position + text, the GUI projects and animates them.
function M.add_floater(x, y, z, text, color)
	table.insert(M.hud.floaters, { x = x, y = y, z = z, text = text, color = color })
end

M.reset_hud()

return M
