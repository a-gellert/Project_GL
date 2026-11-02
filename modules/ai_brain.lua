-- Enemy behaviour. Sets move_x/move_z/want_face and fires combat_system actions.
-- Attack tokens keep crowds fair: only a few enemies swing at the player at once,
-- the rest circle around at a distance.
local combat = require("modules.combat_system")

local M = {}

M.MAX_ATTACKERS = 2

local function dist(a, b)
	local dx, dz = b.x - a.x, b.z - a.z
	return math.sqrt(dx * dx + dz * dz), dx, dz
end

local function set_move(u, dx, dz, k)
	local len = math.sqrt(dx * dx + dz * dz)
	if len < 0.001 then
		u.move_x, u.move_z = 0, 0
	else
		u.move_x, u.move_z = dx / len * k, dz / len * k
	end
end

local function think_melee(world, u, target, d, dx, dz, has_token)
	local range = u.reach + target.r * 0.5
	u.want_face = combat.face_to(dx, dz)
	if not has_token and d < 4.5 then
		-- wait for a slot: circle around the player
		local sx, sz = -dz * u.ai.strafe, dx * u.ai.strafe
		local back = d < 3.2 and -0.6 or 0.15
		set_move(u, sx + dx * back, sz + dz * back, 0.55)
		return
	end
	if d > range * 0.85 then
		-- approach with a slight per-unit offset so the crowd doesn't stack
		local sx, sz = -dz * u.ai.strafe * 0.25, dx * u.ai.strafe * 0.25
		set_move(u, dx + sx, dz + sz, 1)
	else
		u.move_x, u.move_z = 0, 0
		if u.cooldown <= 0 and u.state == "idle" then
			combat.start_attack(u)
			if u.max_combo > 1 and math.random() < 0.6 then
				u.queued = true
			end
			u.cooldown = u.ai.cd_min + math.random() * (u.ai.cd_max - u.ai.cd_min)
		end
	end
end

local function think_thrower(world, u, target, d, dx, dz)
	u.want_face = combat.face_to(dx, dz)
	if d < 5 then
		set_move(u, -dx, -dz, 0.9)
	elseif d > 10 then
		set_move(u, dx, dz, 1)
	else
		local sx, sz = -dz * u.ai.strafe, dx * u.ai.strafe
		set_move(u, sx, sz, 0.4)
		if u.cooldown <= 0 and u.state == "idle" then
			combat.start_enemy_throw(u, target)
			u.cooldown = 1.8 + math.random() * 1.2
		end
	end
	if d < 2.2 and u.cooldown <= 0 and u.state == "idle" then
		combat.start_attack(u)
		u.cooldown = 1.2
	end
end

local function think_boss(world, u, target, d, dx, dz)
	u.ai.charge_cd = (u.ai.charge_cd or 5) - world.dt
	if u.ai.charge_cd <= 0 and d > 5 and d < 14 and u.state == "idle" then
		u.want_face = combat.face_to(dx, dz)
		u.face = u.want_face
		combat.start_charge(u, target)
		u.ai.charge_cd = 6 + math.random() * 3
		return
	end
	think_melee(world, u, target, d, dx, dz, true)
end

function M.init_unit(u, ai_kind)
	u.ai = {
		kind = ai_kind,
		strafe = math.random() < 0.5 and -1 or 1,
		cd_min = 0.6, cd_max = 1.5,
		retarget = 0,
	}
	if ai_kind == "boss" then
		u.ai.cd_min, u.ai.cd_max = 0.4, 1.0
		u.ai.charge_cd = 4
	end
end

function M.update(world, target, dt)
	world.dt = dt
	-- who holds attack tokens: the closest melee enemies
	local candidates = {}
	for _, u in ipairs(world.units) do
		if u.alive and u.ai and u.ai.kind == "melee" then
			local d = dist(u, target)
			candidates[#candidates + 1] = { u = u, d = d }
		end
	end
	table.sort(candidates, function(a, b) return a.d < b.d end)
	local tokens = {}
	for i = 1, math.min(M.MAX_ATTACKERS, #candidates) do
		tokens[candidates[i].u] = true
	end

	for _, u in ipairs(world.units) do
		if u.alive and u.ai then
			u.ai.strafe_t = (u.ai.strafe_t or (2 + math.random() * 3)) - dt
			if u.ai.strafe_t <= 0 then
				u.ai.strafe = -u.ai.strafe
				u.ai.strafe_t = 2 + math.random() * 3
			end
			-- shielded enemies raise the shield when they see a swing coming
			if u.shield then
				if u.state == "block" then
					u.ai.block_t = (u.ai.block_t or 0) - dt
					if u.ai.block_t <= 0 then
						combat.set_block(u, false, false)
					end
				elseif u.state == "idle" and target.state == "attack" and not target.hit_done
					and dist(u, target) < 3.2 and math.random() < 0.35 * dt * 10 then
					combat.set_block(u, true, true)
					u.ai.block_t = 0.9
				end
			end
			if not target.alive then
				u.move_x, u.move_z = 0, 0
			elseif u.state == "idle" or u.state == "recover" then
				local d, dx, dz = dist(u, target)
				local kind = u.ai.kind
				if kind == "thrower" then
					think_thrower(world, u, target, d, dx, dz)
				elseif kind == "boss" then
					think_boss(world, u, target, d, dx, dz)
				else
					think_melee(world, u, target, d, dx, dz, tokens[u])
				end
			else
				u.move_x, u.move_z = 0, 0
				-- keep tracking the target during the telegraph
				local _, dx, dz = dist(u, target)
				u.want_face = combat.face_to(dx, dz)
			end
		end
	end
end

return M
