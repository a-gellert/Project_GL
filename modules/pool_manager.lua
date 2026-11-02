-- Object pools: everything is created up front, nothing is created or deleted in combat.
-- Inactive objects are parked under the arena (y = -100) and disabled.
local M = {}

M.HIDDEN_POS = vmath.vector3(0, -100, 0)

-- create_fn(index) -> object, hide_fn(object), show_fn(object)
function M.new(size, create_fn, hide_fn, show_fn)
	local pool = { free = {}, all = {}, hide_fn = hide_fn, show_fn = show_fn }
	for i = 1, size do
		local obj = create_fn(i)
		pool.all[i] = obj
		pool.free[#pool.free + 1] = obj
		hide_fn(obj)
	end
	return pool
end

function M.acquire(pool)
	local obj = table.remove(pool.free)
	if obj then
		obj.pool_active = true
		pool.show_fn(obj)
	end
	return obj
end

function M.release(pool, obj)
	if not obj.pool_active then
		return
	end
	obj.pool_active = false
	pool.hide_fn(obj)
	pool.free[#pool.free + 1] = obj
end

function M.release_all(pool)
	for _, obj in ipairs(pool.all) do
		M.release(pool, obj)
	end
end

function M.free_count(pool)
	return #pool.free
end

-- Simple single-model object pool (props, projectiles, fx bits) on top of a factory.
function M.new_model_pool(factory_url, size)
	return M.new(size, function()
		local id = factory.create(factory_url, M.HIDDEN_POS)
		return { id = id, model = msg.url(nil, id, "model") }
	end, function(obj)
		go.set_position(M.HIDDEN_POS, obj.id)
		msg.post(obj.id, "disable")
	end, function(obj)
		msg.post(obj.id, "enable")
	end)
end

function M.set_tint(obj, color)
	go.set(obj.model, "tint", color)
end

return M
