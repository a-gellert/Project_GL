-- Named colours of the shared palette. Every model is tinted from this table,
-- so a future 256x256 palette atlas can replace it one-to-one.
local M = {}

local function c(r, g, b)
	return vmath.vector4(r / 255, g / 255, b / 255, 1)
end

M.colors = {
	-- skin
	tan = c(196, 140, 98),
	pale = c(222, 196, 170),
	dark_soot = c(92, 66, 52),
	mutant_pale = c(170, 190, 150),
	mutant_green = c(110, 150, 80),
	-- cloth / leather
	rags = c(140, 120, 92),
	leather = c(110, 72, 44),
	leather_dark = c(70, 48, 32),
	cloth_red = c(150, 52, 40),
	cloth_blue = c(60, 80, 110),
	-- metals
	rust = c(150, 78, 40),
	rust_dark = c(100, 52, 30),
	steel = c(150, 152, 156),
	steel_dark = c(88, 92, 98),
	brass = c(190, 150, 70),
	tire = c(40, 38, 38),
	copper = c(176, 100, 60),
	wood = c(128, 92, 56),
	-- environment
	sand = c(206, 170, 118),
	sand_dark = c(170, 132, 86),
	concrete = c(150, 144, 136),
	wall = c(118, 98, 82),
	crowd = c(80, 66, 60),
	barrel = c(70, 92, 70),
	barrel_red = c(140, 50, 36),
	-- fx
	shadow = c(70, 52, 36),
	spark = c(255, 210, 90),
	blood = c(150, 20, 20),
	shock = c(120, 200, 255),
	fire = c(255, 120, 30),
	aim = c(255, 240, 200),
	white = c(255, 255, 255),
	telegraph = c(255, 150, 60),
}

function M.get(name)
	return M.colors[name] or M.colors.white
end

return M
