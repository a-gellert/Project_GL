-- Kinematic combat in the XZ plane of the arena. No physics engine:
-- separation, melee hits and projectile hits are radial checks
-- (dx^2 + dz^2 < (r1 + r2)^2) over plain Lua arrays.
-- The module emits events into world.events; the arena turns them into FX.
local stats = require("modules.stats_calculator")

local M = {}

M.GRAVITY = 9.8
M.DASH_SPEED = 13
M.DASH_TIME = 0.22
M.DASH_COST = 25
M.PARRY_WINDOW = 0.4
M.PARRY_COOLDOWN = 0.5
M.STAMINA_REGEN = 32
M.PICKUP_RADIUS = 1.8
M.AUTO_PICKUP_RADIUS = 0.7
M.CHARGE_SPEED = 12
M.CHARGE_TIME = 0.6

local STATE_SPEED = {
	idle = 1, aim = 0.65, block = 0.4, parry = 0.5, attack = 0.15,
	recover = 0.7, stagger = 0, dead = 0, throw = 0, charge = 0, dash = 0,
}

local function emit(world, ev)
	world.events[#world.events + 1] = ev
end

local function wrap_angle(a)
	while a > math.pi do a = a - 2 * math.pi end
	while a < -math.pi do a = a + 2 * math.pi end
	return a
end

-- Character forward is -Z rotated by face around Y.
function M.forward(face)
	return -math.sin(face), -math.cos(face)
end

function M.face_to(dx, dz)
	return math.atan2(-dx, -dz)
end

function M.new_world(radius, props)
	return {
		units = {},
		projectiles = {},
		props = props or {},
		radius = radius,
		events = {},
		time = 0,
	}
end

-- Required fields: team, x, z, hp, r. Everything else has defaults.
function M.add_unit(world, u)
	u.alive = true
	u.max_hp = u.max_hp or u.hp
	u.state = "idle"
	u.t = 0
	u.combo = 1
	u.max_combo = u.max_combo or 1
	u.face = u.face or 0
	u.want_face = u.want_face or u.face
	u.vx, u.vz = 0, 0
	u.move_x, u.move_z = 0, 0
	u.cur_speed = 0
	u.max_stamina = u.max_stamina or 100
	u.stamina = u.max_stamina
	u.atk_rate = u.atk_rate or 1
	u.turn_rate = u.turn_rate or 10
	u.bleed_t, u.burn_t, u.dot_tick = 0, 0, 0
	u.parry_cd = 0
	u.poise_dmg = 0
	u.reload_t = 0
	u.cooldown = 0
	world.units[#world.units + 1] = u
	return u
end

function M.remove_unit(world, u)
	for i = #world.units, 1, -1 do
		if world.units[i] == u then
			table.remove(world.units, i)
			return
		end
	end
end

local function set_state(u, state, dur)
	u.state = state
	u.t = 0
	u.state_dur = dur
end
M.set_state = set_state

function M.stagger(u, dur)
	if not u.alive then return end
	set_state(u, "stagger", dur)
	u.queued = false
end

-- Actions -------------------------------------------------------------------

local function begin_attack(u, combo)
	u.combo = combo
	u.cur_windup = u.windup / u.atk_rate
	u.cur_recovery = u.recovery / u.atk_rate
	u.hit_done = false
	u.queued = false
	set_state(u, "attack")
end

-- Combo: pressing again during recovery queues the next hit.
function M.start_attack(u)
	if not u.alive or u.melee_enabled == false then
		return false
	end
	if u.state == "attack" then
		if u.hit_done and u.combo < u.max_combo then
			u.queued = true
		end
		return false
	end
	if u.state ~= "idle" and u.state ~= "recover" then
		return false
	end
	if u.is_player then
		if u.stamina <= 0 then
			return false
		end
		u.stamina = u.stamina - (u.attack_cost or 8)
	end
	begin_attack(u, 1)
	return true
end

function M.start_dash(u, dx, dz)
	if not u.alive then return false end
	local s = u.state
	if s == "stagger" or s == "dead" or s == "dash" or s == "charge" then
		return false
	end
	if s == "attack" and not u.hit_done then
		return false
	end
	if u.stamina < M.DASH_COST then
		return false
	end
	u.stamina = u.stamina - M.DASH_COST
	local len = math.sqrt(dx * dx + dz * dz)
	if len < 0.1 then
		dx, dz = M.forward(u.face)
		dx, dz = -dx, -dz -- no input: hop backwards
	else
		dx, dz = dx / len, dz / len
	end
	u.dash_x, u.dash_z = dx, dz
	set_state(u, "dash", M.DASH_TIME)
	return true
end

-- With a shield: hold to block. Without: short parry window.
function M.set_block(u, pressed, held)
	if not u.alive then return end
	if u.shield then
		if held and (u.state == "idle" or u.state == "recover") then
			set_state(u, "block")
		elseif not held and u.state == "block" then
			set_state(u, "idle")
		end
	elseif pressed and u.parry_cd <= 0 and (u.state == "idle" or u.state == "recover" or (u.state == "attack" and u.hit_done)) then
		set_state(u, "parry", M.PARRY_WINDOW)
		u.parry_cd = M.PARRY_WINDOW + M.PARRY_COOLDOWN
	end
end

function M.can_aim(u)
	return u.alive and u.secondary ~= nil and u.throw_enabled ~= false and u.ammo > 0 and u.reload_t <= 0
		and (u.state == "idle" or u.state == "recover" or u.state == "block")
end

function M.start_aim(u)
	if not M.can_aim(u) then
		return false
	end
	u.charge = 0
	set_state(u, "aim")
	return true
end

function M.cancel_aim(u)
	if u.state == "aim" then
		set_state(u, "idle")
	end
end

-- Ballistic launch velocity for the current aim (yaw = facing, pitch = elevation).
function M.aim_velocity(u, pitch)
	local w = u.secondary
	local speed = w.speed + w.speed_charge * (u.charge or 0)
	local fx, fz = M.forward(u.face)
	local cp = math.cos(pitch)
	return fx * speed * cp, speed * math.sin(pitch), fz * speed * cp
end

function M.hand_position(u)
	local fx, fz = M.forward(u.face)
	-- right hand: right = (-fz, fx) rotated forward vector
	local rx, rz = -fz, fx
	local s = u.scale or 1
	return u.x + rx * 0.35 * s + fx * 0.4, 1.6 * s, u.z + rz * 0.35 * s + fz * 0.4
end

local function spawn_projectile(world, owner, vx, vy, vz, weapon, extra)
	local x, y, z = M.hand_position(owner)
	local p = {
		x = x, y = y, z = z, vx = vx, vy = vy, vz = vz,
		gravity = weapon.gravity or M.GRAVITY,
		owner = owner, team = owner.team,
		weapon = weapon,
		retrievable = weapon.kind == "throw",
		burn = extra and extra.burn or false,
		state = "fly", life = 0,
	}
	world.projectiles[#world.projectiles + 1] = p
	emit(world, { type = "projectile_spawn", p = p })
	return p
end

function M.release_aim(world, u, pitch)
	if u.state ~= "aim" then
		return false
	end
	local vx, vy, vz = M.aim_velocity(u, pitch)
	spawn_projectile(world, u, vx, vy, vz, u.secondary, { burn = u.secondary.kind == "ranged" and u.propane })
	u.ammo = u.ammo - 1
	if u.secondary.kind == "ranged" and u.ammo <= 0 then
		u.reload_t = u.secondary.reload / u.atk_rate
	end
	set_state(u, "recover", u.secondary.cooldown or 0.3)
	emit(world, { type = "throw", unit = u })
	return true
end

-- AI throw: windup (telegraph), then a ballistic shot at the target.
function M.start_enemy_throw(u, target)
	if u.state ~= "idle" then return false end
	u.throw_target = target
	u.cur_windup = u.windup
	u.cur_recovery = u.recovery
	u.hit_done = false
	set_state(u, "throw")
	return true
end

local function enemy_throw_release(world, u)
	local t = u.throw_target
	if not t or not t.alive then return end
	local hx, hy, hz = M.hand_position(u)
	-- lead the target a little
	local tx, tz = t.x + t.vx * 0.3, t.z + t.vz * 0.3
	local dx, dz = tx - hx, tz - hz
	local dist = math.sqrt(dx * dx + dz * dz)
	local w = u.projectile_weapon
	local speed_h = w.speed
	local time = math.max(dist / speed_h, 0.2)
	local dy = 1.1 - hy
	local vy = (dy + 0.5 * w.gravity * time * time) / time
	spawn_projectile(world, u, dx / dist * speed_h, vy, dz / dist * speed_h, w)
end

function M.start_charge(u, target)
	if u.state ~= "idle" then return false end
	u.cur_windup = 0.6
	u.charge_hit = false
	u.charge_target = target
	set_state(u, "charge")
	return true
end

-- Damage ----------------------------------------------------------------------

local function kill(world, t, attacker, kind)
	t.alive = false
	t.hp = 0
	t.fall_roll = math.random(-25, 25)
	set_state(t, "dead")
	emit(world, { type = "death", unit = t, killer = attacker, kind = kind,
		finisher = attacker and attacker.state == "attack" and attacker.combo >= 2 })
end

-- dmg is final (armor already applied by stats_calculator).
function M.deal_damage(world, t, a, dmg, kind, opts)
	if not t.alive then return false end
	opts = opts or {}
	if t.state == "dash" and kind ~= "dot" then
		emit(world, { type = "dodge", unit = t })
		return false
	end

	local front = true
	if a then
		local fx, fz = M.forward(t.face)
		local dx, dz = a.x - t.x, a.z - t.z
		local len = math.sqrt(dx * dx + dz * dz)
		if len > 0.01 then
			front = (fx * dx + fz * dz) / len >= 0.3
		end
	end

	if kind == "melee" and t.state == "parry" and front and a then
		M.stagger(a, a.boss and 0.7 or 1.1)
		emit(world, { type = "parry", unit = t, attacker = a })
		return false
	end

	local blocked = false
	if t.state == "block" and front and t.shield and kind ~= "dot" then
		blocked = true
		local absorbed = dmg * t.shield.block
		dmg = dmg - absorbed
		t.stamina = t.stamina - absorbed * 0.8
		emit(world, { type = "block", unit = t, attacker = a })
		if t.shock_on_block and kind == "melee" and a and a.alive then
			M.stagger(a, 0.9)
			emit(world, { type = "shock", unit = a })
		end
		if t.stamina <= 0 then
			t.stamina = 0
			M.stagger(t, 0.7)
			emit(world, { type = "guard_break", unit = t })
		end
	end

	t.hp = t.hp - dmg
	emit(world, { type = "hit", target = t, attacker = a, dmg = dmg, kind = kind, blocked = blocked })

	if not blocked and kind ~= "dot" then
		if opts.bleed_chance and math.random() < opts.bleed_chance then
			t.bleed_t = 3
		end
		if opts.burn then
			t.burn_t = 2.5
		end
	end

	if t.hp <= 0 then
		kill(world, t, a, kind)
		return true
	end

	if not blocked and kind ~= "dot" then
		if t.poise then
			t.poise_dmg = t.poise_dmg + dmg
			if t.poise_dmg >= t.max_hp * 0.22 then
				t.poise_dmg = 0
				M.stagger(t, 0.9)
			end
		elseif t.state ~= "dash" then
			M.stagger(t, t.is_player and 0.15 or 0.28)
		end
	end
	return true
end

local function melee_strike(world, a)
	local fx, fz = M.forward(a.face)
	local cos_half = math.cos(math.rad(a.arc or 110) * 0.5)
	local mult = (a.combo == 2 and 1.25) or (a.combo == 3 and 1.6) or 1
	local any = false
	for _, t in ipairs(world.units) do
		if t.alive and t.team ~= a.team then
			local dx, dz = t.x - a.x, t.z - a.z
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= a.reach + t.r then
				local inside = d < 0.6 or (fx * dx + fz * dz) / d >= cos_half
				if inside then
					local dmg
					if a.is_player then
						dmg = stats.calculate_melee_damage(a.dmg_base * mult, a.str, a.agi, t.armor)
					else
						dmg = stats.calculate_flat_damage(a.dmg_base * mult, t.armor)
					end
					M.deal_damage(world, t, a, dmg, "melee", { bleed_chance = a.bleed_chance })
					any = true
				end
			end
		end
	end
	if not any then
		emit(world, { type = "whiff", unit = a })
	end
end

-- Update -------------------------------------------------------------------

local function update_state(world, u, dt)
	local s = u.state
	if s == "attack" then
		if not u.hit_done and u.t >= u.cur_windup then
			u.hit_done = true
			melee_strike(world, u)
		end
		if u.t >= u.cur_windup + u.cur_recovery then
			if u.queued and u.combo < u.max_combo then
				begin_attack(u, u.combo + 1)
			else
				set_state(u, "idle")
				u.combo = 1
			end
		end
	elseif s == "dash" or s == "stagger" or s == "parry" or s == "recover" then
		if u.t >= (u.state_dur or 0) then
			set_state(u, "idle")
		end
	elseif s == "aim" then
		u.charge = math.min(u.t / (u.secondary.charge_time or 0.5), 1)
	elseif s == "throw" then
		if not u.hit_done and u.t >= u.cur_windup then
			u.hit_done = true
			enemy_throw_release(world, u)
		end
		if u.t >= u.cur_windup + u.cur_recovery then
			set_state(u, "idle")
		end
	elseif s == "charge" then
		if u.t >= u.cur_windup then
			if not u.charge_dir_set then
				u.charge_dir_set = true
				u.charge_x, u.charge_z = M.forward(u.face)
			end
			local t = u.charge_target
			if t and t.alive and not u.charge_hit then
				local dx, dz = t.x - u.x, t.z - u.z
				if dx * dx + dz * dz < (u.r + t.r + 0.4) ^ 2 then
					u.charge_hit = true
					local dmg = stats.calculate_flat_damage(u.dmg_base * 1.3, t.armor)
					if M.deal_damage(world, t, u, dmg, "melee") and t.alive and t.state ~= "block" then
						M.stagger(t, 0.6)
					end
				end
			end
		end
		if u.t >= u.cur_windup + M.CHARGE_TIME then
			u.charge_dir_set = false
			set_state(u, "recover", 0.5)
		end
	end

	if u.parry_cd > 0 then u.parry_cd = u.parry_cd - dt end
	if u.cooldown > 0 then u.cooldown = u.cooldown - dt end
	if u.reload_t > 0 then
		u.reload_t = u.reload_t - dt
		if u.reload_t <= 0 and u.secondary then
			u.ammo = u.ammo_max
		end
	end
	if u.state ~= "block" and u.state ~= "dash" then
		u.stamina = math.min(u.max_stamina, u.stamina + M.STAMINA_REGEN * dt)
	end

	-- damage over time: bleed / burn
	if u.bleed_t > 0 or u.burn_t > 0 then
		u.dot_tick = u.dot_tick + dt
		if u.dot_tick >= 0.5 then
			u.dot_tick = 0
			local dmg = 0
			if u.bleed_t > 0 then dmg = dmg + 2.5 end
			if u.burn_t > 0 then dmg = dmg + 3.5 end
			M.deal_damage(world, u, nil, dmg, "dot")
		end
		u.bleed_t = u.bleed_t - dt
		u.burn_t = u.burn_t - dt
	end
end

local function turn_towards(u, target, dt)
	local diff = wrap_angle(target - u.face)
	local step = u.turn_rate * dt
	if math.abs(diff) <= step then
		u.face = target
	else
		u.face = wrap_angle(u.face + (diff > 0 and step or -step))
	end
end

local function move_unit(world, u, dt)
	local s = u.state
	local tx, tz
	if s == "dash" then
		tx, tz = u.dash_x * M.DASH_SPEED, u.dash_z * M.DASH_SPEED
	elseif s == "charge" and u.t >= u.cur_windup then
		tx, tz = u.charge_x * M.CHARGE_SPEED, u.charge_z * M.CHARGE_SPEED
	else
		local mult = STATE_SPEED[s] or 1
		tx, tz = u.move_x * u.speed * mult, u.move_z * u.speed * mult
	end
	local k = math.min(1, dt * ((s == "dash" or s == "charge") and 30 or 12))
	u.vx = u.vx + (tx - u.vx) * k
	u.vz = u.vz + (tz - u.vz) * k
	u.x = u.x + u.vx * dt
	u.z = u.z + u.vz * dt
	u.cur_speed = math.sqrt(u.vx * u.vx + u.vz * u.vz)

	-- facing: attacks keep their direction after the windup
	local can_turn = s == "idle" or s == "aim" or s == "block" or s == "parry" or s == "recover"
		or ((s == "attack" or s == "throw" or s == "charge") and u.t < (u.cur_windup or 0) * 0.7)
	if can_turn then
		turn_towards(u, u.want_face, dt)
	end
end

local function resolve_collisions(world)
	local units = world.units
	local n = #units
	for i = 1, n do
		local a = units[i]
		if a.alive then
			for j = i + 1, n do
				local b = units[j]
				if b.alive then
					local dx, dz = b.x - a.x, b.z - a.z
					local rr = a.r + b.r
					local d2 = dx * dx + dz * dz
					if d2 < rr * rr and d2 > 0.000001 then
						local d = math.sqrt(d2)
						local push = (rr - d) / d
						-- the player is heavier, the crowd flows around him
						local wa = a.is_player and 0.2 or (b.is_player and 0.8 or 0.5)
						a.x = a.x - dx * push * wa
						a.z = a.z - dz * push * wa
						b.x = b.x + dx * push * (1 - wa)
						b.z = b.z + dz * push * (1 - wa)
					end
				end
			end
		end
	end
	local R = world.radius
	for i = 1, n do
		local u = units[i]
		for _, p in ipairs(world.props) do
			local dx, dz = u.x - p.x, u.z - p.z
			local rr = u.r + p.r
			local d2 = dx * dx + dz * dz
			if d2 < rr * rr and d2 > 0.000001 then
				local d = math.sqrt(d2)
				u.x = p.x + dx / d * rr
				u.z = p.z + dz / d * rr
			end
		end
		local d = math.sqrt(u.x * u.x + u.z * u.z)
		local maxd = R - u.r
		if d > maxd then
			u.x = u.x / d * maxd
			u.z = u.z / d * maxd
		end
	end
end

local function land(p, x, y, z)
	p.x, p.y, p.z = x, y, z
	p.vx, p.vy, p.vz = 0, 0, 0
	p.state = p.retrievable and "loot" or "fade"
	p.life = 0
end

local function update_projectiles(world, dt)
	local R = world.radius
	for _, p in ipairs(world.projectiles) do
		p.life = p.life + dt
		if p.state == "fly" then
			p.vy = p.vy - p.gravity * dt
			local nx, ny, nz = p.x + p.vx * dt, p.y + p.vy * dt, p.z + p.vz * dt
			local done = false
			for _, u in ipairs(world.units) do
				if u.alive and u.team ~= p.team then
					local dx, dz = u.x - nx, u.z - nz
					local rr = u.r + 0.2
					local h = 1.9 * (u.scale or 1)
					if dx * dx + dz * dz < rr * rr and ny > 0 and ny < h then
						local o = p.owner
						local w = p.weapon
						local dmg
						if o.is_player then
							dmg = stats.calculate_ranged_damage(o.ranged_mult * w.damage, o.str, o.agi, u.armor)
						else
							dmg = stats.calculate_flat_damage(w.damage * (o.dmg_mult or 1), u.armor)
						end
						local was_block = u.state == "block" and u.shield
						M.deal_damage(world, u, o, dmg, "ranged", { burn = p.burn })
						emit(world, { type = "projectile_hit", p = p, unit = u })
						if was_block or not u.alive then
							land(p, u.x - dx * 0.3, 0.05, u.z - dz * 0.3)
						else
							p.state = "stuck"
							p.stuck_unit = u
							p.ox, p.oy, p.oz = nx - u.x, ny, nz - u.z
							p.x, p.y, p.z = nx, ny, nz
						end
						done = true
						break
					end
				end
			end
			if not done then
				for _, pr in ipairs(world.props) do
					local dx, dz = nx - pr.x, nz - pr.z
					if dx * dx + dz * dz < pr.r * pr.r and ny < pr.h then
						land(p, nx, ny, nz)
						emit(world, { type = "projectile_prop", p = p })
						done = true
						break
					end
				end
			end
			if not done then
				if ny <= 0.05 then
					land(p, nx, 0.05, nz)
					emit(world, { type = "projectile_ground", p = p })
				elseif nx * nx + nz * nz >= (R - 0.1) ^ 2 then
					local d = math.sqrt(nx * nx + nz * nz)
					land(p, nx / d * (R - 0.4), math.max(ny, 0.05), nz / d * (R - 0.4))
					p.y = 0.05
					emit(world, { type = "projectile_prop", p = p })
				else
					p.x, p.y, p.z = nx, ny, nz
				end
			end
		elseif p.state == "stuck" then
			local u = p.stuck_unit
			if u.alive then
				p.x, p.y, p.z = u.x + p.ox, p.oy, u.z + p.oz
			else
				land(p, u.x + p.ox, 0.05, u.z + p.oz)
				p.stuck_unit = nil
			end
		elseif p.state == "fade" then
			if p.life > 3 then
				p.state = "dead"
			end
		end
	end
	for i = #world.projectiles, 1, -1 do
		if world.projectiles[i].state == "dead" then
			emit(world, { type = "projectile_free", p = world.projectiles[i] })
			table.remove(world.projectiles, i)
		end
	end
end

function M.step(world, dt)
	world.time = world.time + dt
	for _, u in ipairs(world.units) do
		u.t = u.t + dt
		if u.alive then
			update_state(world, u, dt)
			move_unit(world, u, dt)
		end
	end
	resolve_collisions(world)
	update_projectiles(world, dt)
end

-- Loot ------------------------------------------------------------------------

function M.nearest_loot(world, u)
	local best, best_d2 = nil, math.huge
	for _, p in ipairs(world.projectiles) do
		if p.state == "loot" then
			local dx, dz = p.x - u.x, p.z - u.z
			local d2 = dx * dx + dz * dz
			if d2 < best_d2 then
				best, best_d2 = p, d2
			end
		end
	end
	return best, math.sqrt(best_d2)
end

-- Picks up every loot projectile within radius. Returns the count.
function M.pickup(world, u, radius)
	local count = 0
	local cap = (u.ammo_max or 0) + 2
	for _, p in ipairs(world.projectiles) do
		if p.state == "loot" and u.ammo < cap then
			local dx, dz = p.x - u.x, p.z - u.z
			if dx * dx + dz * dz <= radius * radius then
				p.state = "dead"
				u.ammo = u.ammo + 1
				count = count + 1
			end
		end
	end
	return count
end

function M.alive_count(world, team)
	local n = 0
	for _, u in ipairs(world.units) do
		if u.alive and u.team == team then
			n = n + 1
		end
	end
	return n
end

return M
