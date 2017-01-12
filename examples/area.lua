-- @example GPM Implementation strategy 'area' and creating map.
-- Create a map based on the cells and polygons.

-- import gpm
import("gpm")

-- create the CellularSpace
local farms = CellularSpace{
	file = filePath("farms_cells3.shp", "gpm"),
	geometry = true
}

local farmsPolygon = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

-- creating a GPM
local gpm = GPM{
	origin = farms,
	destination = farmsPolygon
}

-- creating Map with values ​​GPM
map = Map{
	target = gpm.origin,
	select = "cellID",
	slices = 10,
	color = "RdYlGn"
}