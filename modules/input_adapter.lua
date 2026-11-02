-- Device-agnostic combat input. The combat GUI feeds it from keyboard/mouse
-- (desktop) or from the touch controls (mobile); the arena reads it every frame.
local M = {}

M.is_mobile = false

-- Held state
M.keys = { up = false, down = false, left = false, right = false, cam_left = false, cam_right = false }
M.stick_x = 0
M.stick_y = 0
M.block_held = false
M.throw_held = false

-- Accumulated camera look delta (pixels) since last consume
M.look_dx = 0
M.look_dy = 0

-- Edges since last consume
local edges = {}

function M.press(name)
	edges[name] = true
end

function M.add_look(dx, dy)
	M.look_dx = M.look_dx + dx
	M.look_dy = M.look_dy + dy
end

-- Movement vector in camera space: x = right, y = forward. Length <= 1.
function M.get_move()
	local x, y = M.stick_x, M.stick_y
	if M.keys.left then x = x - 1 end
	if M.keys.right then x = x + 1 end
	if M.keys.up then y = y + 1 end
	if M.keys.down then y = y - 1 end
	local len = math.sqrt(x * x + y * y)
	if len > 1 then
		x, y = x / len, y / len
	end
	return x, y
end

-- Returns edges table (attack, block, dash, pickup, throw_release, throw_cancel, pause) and look delta.
function M.consume()
	local e = edges
	edges = {}
	local dx, dy = M.look_dx, M.look_dy
	M.look_dx, M.look_dy = 0, 0
	return e, dx, dy
end

function M.reset()
	for k in pairs(M.keys) do
		M.keys[k] = false
	end
	M.stick_x, M.stick_y = 0, 0
	M.block_held = false
	M.throw_held = false
	M.look_dx, M.look_dy = 0, 0
	edges = {}
end

-- Best-effort touch device detection (HTML5 + native mobile).
function M.detect_mobile()
	local info = sys.get_sys_info()
	if info.system_name == "Android" or info.system_name == "iPhone OS" then
		return true
	end
	if html5 then
		local ok, res = pcall(html5.run, "(('ontouchstart' in window) || navigator.maxTouchPoints > 0) ? '1' : '0'")
		return ok and res == "1"
	end
	return false
end

return M
