-- Builds a character look from npc_presets / player equipment on top of a
-- character.collection instance, and drives its procedural animation.
-- Sockets: arm_r = Hand_R_Socket, arm_l = Hand_L_Socket, helmet = Head_Socket, back = Back_Socket.
-- Body meshes (torso, legs, belt) are recoloured, socket parts are resized/toggled.
local palette = require("modules.palette")
local presets = require("data.npc_presets")
local weapons_db = require("data.weapons_db")
local armor_db = require("data.armor_db")

local M = {}

local MODEL_PARTS = {
	"shadow", "leg_l_mesh", "leg_r_mesh", "torso", "belt", "head", "helmet",
	"pad_l", "pad_r", "back", "arm_r_mesh", "weapon", "arm_l_mesh", "shield",
}
local PIVOTS = { "root", "leg_l", "leg_r", "arm_r", "arm_l" }
local OPTIONAL = { helmet = true, pad_l = true, pad_r = true, back = true, shield = true, weapon = true }

local HIDDEN_POS = vmath.vector3(0, -100, 0)
local V_ONE = vmath.vector3(1, 1, 1)
local RAD = math.pi / 180
local FLASH_TIME = 0.08

local function v3(t)
	return vmath.vector3(t[1], t[2], t[3])
end

-- ids: table returned by collectionfactory.create
function M.attach(ids)
	local view = { ids = {}, models = {}, base = {}, visible = {}, flash = 0, telegraph = false }
	for _, name in ipairs(PIVOTS) do
		view.ids[name] = ids[hash("/" .. name)]
	end
	for _, name in ipairs(MODEL_PARTS) do
		local id = ids[hash("/" .. name)]
		view.ids[name] = id
		view.models[name] = msg.url(nil, id, "model")
		view.visible[name] = true
	end
	view.root = view.ids.root
	return view
end

local function set_part_color(view, part, color_name)
	local color = palette.get(color_name)
	view.base[part] = color
	go.set(view.models[part], "tint", color)
end

local function set_part_visible(view, part, visible)
	if view.visible[part] ~= visible then
		view.visible[part] = visible
		msg.post(view.ids[part], visible and "enable" or "disable")
	end
end

local function set_weapon(view, scale, color_name)
	if not scale then
		set_part_visible(view, "weapon", false)
		return
	end
	set_part_visible(view, "weapon", true)
	local s = v3(scale)
	go.set_scale(s, view.ids.weapon)
	go.set_position(vmath.vector3(0, 0, -0.42 - s.z * 0.5), view.ids.weapon)
	set_part_color(view, "weapon", color_name)
end

local function set_item(view, part, item_id)
	local item = item_id and presets.items[item_id]
	if not item then
		set_part_visible(view, part, false)
		return
	end
	if part == "weapon" then
		set_weapon(view, item.scale, item.color)
		return
	end
	set_part_visible(view, part, true)
	go.set_scale(v3(item.scale), view.ids[part])
	set_part_color(view, part, item.color)
end

-- Generic look: { skin, torso, legs, belt, pads?, helmet = {scale,color}?, ... }
local function apply_body(view, body)
	set_part_color(view, "head", body.skin_color)
	set_part_color(view, "arm_r_mesh", body.skin_color)
	set_part_color(view, "arm_l_mesh", body.skin_color)
	set_part_color(view, "torso", body.torso)
	set_part_color(view, "leg_l_mesh", body.legs)
	set_part_color(view, "leg_r_mesh", body.legs)
	set_part_color(view, "belt", body.belt or body.legs)
	set_part_color(view, "shadow", "shadow")
end

local function apply_pads(view, color_name)
	set_part_visible(view, "pad_l", color_name ~= nil)
	set_part_visible(view, "pad_r", color_name ~= nil)
	if color_name then
		set_part_color(view, "pad_l", color_name)
		set_part_color(view, "pad_r", color_name)
	end
end

function M.apply_preset(view, preset_id)
	local p = presets.presets[preset_id] or presets.presets.raider
	apply_body(view, p.body)
	local s = p.sockets or {}
	set_item(view, "helmet", s.head)
	set_item(view, "weapon", s.hand_r)
	set_item(view, "shield", s.hand_l)
	set_item(view, "back", s.back)
	apply_pads(view, s.pads)
	view.scale = p.scale or 1
	go.set_scale(view.scale, view.root)
	return p
end

-- Player look: armor tier decides torso/legs replacement and socket armour.
function M.apply_player(view, profile_data)
	local armor = armor_db.get(profile_data.armor)
	local look = armor.look
	apply_body(view, { skin_color = "tan", torso = look.torso, legs = look.legs, belt = look.belt })
	apply_pads(view, look.pads)
	if look.helmet then
		set_part_visible(view, "helmet", true)
		go.set_scale(vmath.vector3(0.42, 0.26, 0.42), view.ids.helmet)
		set_part_color(view, "helmet", look.helmet)
	else
		set_part_visible(view, "helmet", false)
	end
	local melee = weapons_db.get(profile_data.melee) or weapons_db.get("rusty_pipe")
	set_weapon(view, melee.visual.scale, melee.visual.color)
	local shield = weapons_db.shields[profile_data.shield or ""]
	if shield then
		set_part_visible(view, "shield", true)
		go.set_scale(v3(shield.scale), view.ids.shield)
		set_part_color(view, "shield", shield.color)
	else
		set_part_visible(view, "shield", false)
	end
	local secondary = weapons_db.get(profile_data.secondary)
	if secondary and secondary.kind == "throw" then
		set_item(view, "back", "quiver")
	else
		set_part_visible(view, "back", false)
	end
	view.scale = 1
	go.set_scale(1, view.root)
end

function M.set_weapon_visual(view, weapon_id)
	local w = weapons_db.get(weapon_id)
	if w then
		set_weapon(view, w.visual.scale, w.visual.color)
	end
end

function M.hide(view)
	go.set_position(HIDDEN_POS, view.root)
	for _, name in ipairs(MODEL_PARTS) do
		view.visible[name] = false
		msg.post(view.ids[name], "disable")
	end
end

-- Enables the body; optional sockets are toggled by apply_* afterwards.
function M.show(view)
	for _, name in ipairs(MODEL_PARTS) do
		if not OPTIONAL[name] then
			view.visible[name] = true
			msg.post(view.ids[name], "enable")
		end
	end
	view.flash = 0
	view.telegraph = false
	go.set_rotation(vmath.quat(), view.root)
end

local function restore_colors(view)
	for part, color in pairs(view.base) do
		go.set(view.models[part], "tint", color)
	end
end

function M.flash(view, color)
	local c = color or palette.get("white")
	for part in pairs(view.base) do
		if part ~= "shadow" then
			go.set(view.models[part], "tint", c)
		end
	end
	view.flash = FLASH_TIME
end

local function set_telegraph(view, on)
	if view.telegraph == on then
		return
	end
	view.telegraph = on
	if view.flash > 0 then
		return
	end
	local c = on and palette.get("telegraph") or view.base.weapon
	if c and view.visible.weapon then
		go.set(view.models.weapon, "tint", c)
	end
	if view.visible.helmet or view.base.head then
		go.set(view.models.head, "tint", on and palette.get("telegraph") or view.base.head)
	end
end

local function quat_yx(yaw_deg, pitch_deg)
	return vmath.quat_rotation_y(yaw_deg * RAD) * vmath.quat_rotation_x(pitch_deg * RAD)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function ease_out(t)
	return 1 - (1 - t) * (1 - t)
end

-- Arm-R pose (yaw, pitch) for an attack. combo 1: right-to-left, combo 2/3: back.
local function attack_pose(u)
	local windup = u.cur_windup or 0.2
	local recovery = u.cur_recovery or 0.3
	local side = (u.combo % 2 == 1) and 1 or -1
	local wind_yaw, end_yaw = -85 * side, 75 * side
	if u.combo == 3 then
		-- overhead slam
		if u.t < windup then
			local k = ease_out(u.t / windup)
			return lerp(-15, 0, k), lerp(-35, 110, k)
		end
		local k = math.min((u.t - windup) / (recovery * 0.35), 1)
		return 0, lerp(110, -60, ease_out(k))
	end
	if u.t < windup then
		local k = ease_out(u.t / windup)
		return lerp(-15, wind_yaw, k), lerp(-35, 10, k)
	end
	local k = (u.t - windup) / (recovery * 0.4)
	if k <= 1 then
		return lerp(wind_yaw, end_yaw, ease_out(k)), lerp(10, -10, k)
	end
	local back = math.min((u.t - windup - recovery * 0.4) / (recovery * 0.6), 1)
	return lerp(end_yaw, -15, back), lerp(-10, -35, back)
end

-- Procedural animation from unit state. Called every frame for near units,
-- every second frame for far ones (animation throttling).
-- flash_dt: real frame time, so the hit flash fades even while hit stop freezes dt.
function M.animate(view, u, dt, flash_dt)
	if view.flash > 0 then
		view.flash = view.flash - (flash_dt or dt)
		if view.flash <= 0 then
			restore_colors(view)
			view.telegraph = false
		end
	end

	local state = u.state
	local speed = u.cur_speed or 0
	u.walk_phase = (u.walk_phase or 0) + dt * (4 + speed * 2.2) * math.min(speed, 1.5)

	-- legs
	local swing = math.sin(u.walk_phase) * 38 * math.min(speed / 3.5, 1)
	go.set_rotation(vmath.quat_rotation_x(swing * RAD), view.ids.leg_l)
	go.set_rotation(vmath.quat_rotation_x(-swing * RAD), view.ids.leg_r)

	-- arms
	local r_yaw, r_pitch = -15, -35 + math.sin(u.walk_phase) * 8 * math.min(speed, 1)
	local l_yaw, l_pitch = 15, -40
	local lean = 0
	if state == "attack" then
		r_yaw, r_pitch = attack_pose(u)
		lean = -6
	elseif state == "throw" then
		local k = math.min(u.t / (u.cur_windup or 0.4), 1)
		r_yaw, r_pitch = lerp(-15, 10, k), lerp(-35, 120, k)
	elseif state == "aim" then
		r_yaw, r_pitch = 10, 120 - math.min(u.charge or 0, 1) * 15
		l_yaw, l_pitch = -10, 0
	elseif state == "block" then
		if view.visible.shield then
			l_yaw, l_pitch = -40, 0
		else
			r_yaw, r_pitch = -40, 35
		end
	elseif state == "parry" then
		r_yaw, r_pitch = -45, 40
	elseif state == "stagger" then
		r_yaw, r_pitch = 30, -60
		l_yaw, l_pitch = -30, -60
		lean = 14
	elseif state == "dash" then
		lean = -22
	elseif state == "charge" then
		lean = -18
		r_yaw, r_pitch = -60, 40
	elseif state == "dead" then
		r_yaw, r_pitch = 0, 80
		l_yaw, l_pitch = 0, 80
	end
	go.set_rotation(quat_yx(r_yaw, r_pitch), view.ids.arm_r)
	go.set_rotation(quat_yx(l_yaw, l_pitch), view.ids.arm_l)

	local telegraph = (state == "attack" or state == "throw" or state == "charge") and u.team ~= 1
		and u.t < (u.cur_windup or 0)
	set_telegraph(view, telegraph)

	-- body
	if state == "dead" then
		-- ragdoll-ish fall backwards, then sink into the sand
		local k = math.min(u.t / 0.45, 1)
		local fall = ease_out(k) * 88
		local q = vmath.quat_rotation_y(u.face) * vmath.quat_rotation_x(fall * RAD)
			* vmath.quat_rotation_z((u.fall_roll or 0) * k * RAD)
		go.set_rotation(q, view.root)
	else
		go.set_rotation(vmath.quat_rotation_y(u.face) * vmath.quat_rotation_x(lean * RAD), view.root)
	end
end

-- Static pose helper for camp idlers: plays an endless attack loop.
function M.idle_loop(view, u, dt)
	u.t = u.t + dt
	local cycle = (u.cur_windup or 0.4) + (u.cur_recovery or 0.6) + 0.8
	if u.t > cycle then
		u.t = 0
		u.combo = u.combo % 2 + 1
	end
	if u.t < (u.cur_windup or 0.4) + (u.cur_recovery or 0.6) then
		u.state = "attack"
	else
		u.state = "idle"
	end
	M.animate(view, u, dt)
end

return M
