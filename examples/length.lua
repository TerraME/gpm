-- @example GPM Implementation strategy 'length' and creating map.
-- Create relations between objects whose intersection is a line.
-- @image length.bmp

-- import gpm
import("gpm")

-- create the CellularSpace
local farms = CellularSpace{
	file = filePath("roads.shp", "gpm"),
	geometry = true
}

local farms_cells = CellularSpace{
	file = filePath("farms_cells3.shp", "gpm"),
	geometry = true
}

-- creating a GPM
GPM{
	origin = farms_cells,
	strategy = "length",
	destination = farms
}

-- creating Map with values ​​GPM
map = Map{
	target = farms_cells,
	select = "length",
	value = {1, 2},
	color = {"green", "blue"}
}