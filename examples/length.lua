-- @example Compute a GPM based on the intersection between cells and lines.
-- A Cell is connected to a line if there is some intersection between them.
-- @image length.bmp

import("gpm")

local roads = CellularSpace{
	file = filePath("roads.shp", "gpm")
}

local cells = CellularSpace{
	file = filePath("cells.shp", "gpm")
}

gpm = GPM{
	origin = cells,
	strategy = "length",
	destination = roads
}

gpm:fill{
	strategy = "count",
	attribute = "quantity",
	max = 1
}

map = Map{
	target = cells,
	select = "quantity",
	value = {0, 1},
	label = {"0", "1 or more"},
	color = {"gray", "blue"}
}

