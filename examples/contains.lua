-- @example GPM Implementation strategy 'contains' and creating map.
-- Create a map based on relations between a set of polygons and a set of points which the predicate contains is applied.

-- import gpm
import("gpm")

-- create the CellularSpace
local farms_cells = CellularSpace{
	file = filePath("farms_cells.shp", "gpm"),
	geometry = true
}

local farms = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

local communitiesPoints = CellularSpace{
	file = filePath("communities.shp", "gpm"),
	geometry = true
}

-- creating a GPM with the distance of the entry points for the routes
local gpm = GPM{
	origin = farms_cells,
	distance = "distance",
	relation = "community",
	strategy = "contains",
	targetPoints = communitiesPoints,
	destination = farms
}

-- creating Map with values ​​GPM
map = Map{
	target = gpm.origin,
	select = "contains",
	value = {1, 2, 3, 4},
	color = {"red", "blue", "green", "black"}
}