-- Tiny builder for code-created GUI nodes, wired to Druid components.
-- Nodes are created at runtime so the .gui files stay minimal; Druid gives
-- buttons, texts, progress bars, blockers and the back handler on top of them.
local M = {}

M.FONT = "bold"

M.colors = {
	panel = vmath.vector4(0.10, 0.08, 0.07, 0.92),
	panel_light = vmath.vector4(0.20, 0.16, 0.13, 0.95),
	shade = vmath.vector4(0, 0, 0, 0.6),
	button = vmath.vector4(0.55, 0.32, 0.16, 1),
	button_green = vmath.vector4(0.28, 0.50, 0.22, 1),
	button_blue = vmath.vector4(0.22, 0.38, 0.58, 1),
	button_gray = vmath.vector4(0.30, 0.28, 0.26, 1),
	button_red = vmath.vector4(0.62, 0.20, 0.16, 1),
	text = vmath.vector4(1, 0.95, 0.85, 1),
	text_dim = vmath.vector4(0.75, 0.68, 0.58, 1),
	gold = vmath.vector4(1, 0.80, 0.30, 1),
	hp = vmath.vector4(0.85, 0.20, 0.15, 1),
	stamina = vmath.vector4(0.95, 0.75, 0.20, 1),
	xp = vmath.vector4(0.35, 0.70, 0.95, 1),
	bar_bg = vmath.vector4(0.08, 0.06, 0.05, 0.85),
	transparent = vmath.vector4(1, 1, 1, 0),
}

local OUTLINE = vmath.vector4(0, 0, 0, 1)

local function finish(node, parent, pivot)
	gui.set_inherit_alpha(node, false)
	if pivot then
		gui.set_pivot(node, pivot)
	end
	if parent then
		gui.set_parent(node, parent)
	end
	return node
end

function M.box(parent, x, y, w, h, color, pivot)
	local n = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(w, h, 0))
	gui.set_color(n, color or M.colors.panel)
	return finish(n, parent, pivot)
end

-- Rounded rectangle / circle skins from druid.atlas (the gui must declare texture "druid").
function M.rounded(node)
	gui.set_texture(node, "druid")
	gui.play_flipbook(node, "ui_circle_32")
	gui.set_slice9(node, vmath.vector4(15, 15, 15, 15))
	return node
end

function M.circle(node)
	gui.set_texture(node, "druid")
	gui.play_flipbook(node, "ui_circle_64")
	return node
end

function M.panel(parent, x, y, w, h, color, pivot)
	return M.rounded(M.box(parent, x, y, w, h, color, pivot))
end

-- Invisible container, used for anchoring groups of nodes to screen edges.
function M.anchor(x, y, xanchor, yanchor)
	local n = M.box(nil, x, y, 1, 1, M.colors.transparent)
	if xanchor then gui.set_xanchor(n, xanchor) end
	if yanchor then gui.set_yanchor(n, yanchor) end
	return n
end

function M.text(parent, x, y, str, scale, color, w, h, pivot)
	local n = gui.new_text_node(vmath.vector3(x, y, 0), str or "")
	gui.set_font(n, M.FONT)
	scale = scale or 1
	gui.set_scale(n, vmath.vector3(scale, scale, 1))
	gui.set_color(n, color or M.colors.text)
	gui.set_outline(n, OUTLINE)
	if w then
		gui.set_size(n, vmath.vector3(w / scale, (h or 60) / scale, 0))
	end
	return finish(n, parent, pivot)
end

function M.multiline(parent, x, y, str, scale, color, w, h, pivot)
	local n = M.text(parent, x, y, str, scale, color, w, h, pivot)
	gui.set_line_break(n, true)
	return n
end

-- Druid button: coloured box + label. callback(self) where self is the gui script context.
function M.button(druid, parent, x, y, w, h, label, color, callback, text_scale)
	local box = M.panel(parent, x, y, w, h, color or M.colors.button)
	local txt = M.text(box, 0, 0, label, text_scale or 0.8, M.colors.text, w - 16, h - 8)
	local btn = druid:new_button(box, function(self)
		callback(self)
	end)
	return { button = btn, node = box, label = txt }
end

function M.set_button_label(b, label)
	gui.set_text(b.label, label)
end

function M.set_button_enabled(b, enabled, color)
	b.button:set_enabled(enabled)
	if enabled then
		gui.set_color(b.node, color or M.colors.button)
	else
		gui.set_color(b.node, M.colors.button_gray)
	end
end

-- Druid progress bar. x,y is the left-middle point.
function M.bar(druid, parent, x, y, w, h, color)
	local bg = M.box(parent, x, y, w, h, M.colors.bar_bg, gui.PIVOT_W)
	local fill = M.box(bg, 2, 0, w - 4, h - 4, color, gui.PIVOT_W)
	local progress = druid:new_progress(fill, "x", 1)
	return { progress = progress, bg = bg, fill = fill }
end

-- Fullscreen modal: shade with a Druid blocker + centered panel.
function M.modal(druid, w, h, title)
	local shade = M.box(nil, 960, 540, 4000, 4000, M.colors.shade)
	local blocker = druid:new_blocker(shade)
	local panel = M.panel(shade, 0, 0, w, h, M.colors.panel)
	local title_node = M.text(panel, 0, h / 2 - 50, title or "", 1.1, M.colors.gold, w - 40, 70)
	return { shade = shade, panel = panel, title = title_node, components = { blocker } }
end

-- Button that lives inside a modal and is cleaned up with it.
function M.modal_button(druid, modal, parent, x, y, w, h, label, color, callback, text_scale)
	local b = M.button(druid, parent or modal.panel, x, y, w, h, label, color, callback, text_scale)
	modal.components[#modal.components + 1] = b.button
	return b
end

-- Deletes the modal nodes and removes the Druid components that were created for it.
function M.close_modal(druid, modal)
	if not modal then return end
	for _, c in ipairs(modal.components) do
		druid:remove(c)
	end
	gui.delete_node(modal.shade)
end

return M
