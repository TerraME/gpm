-- @example GPM Implementation strategy 'contains' and creating map.
-- Create a map based on relations between a set of polygons and a set of points which the predicate contains is applied.

-- import gpm
import("gpm")

-- create the CellularSpace
local farms = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

local communitiesPoints = CellularSpace{
	file = filePath("communities.shp", "gpm"),
	geometry = true
}

-- creating a GPM with the distance of the entry points for the routes
GPM{
	origin = farms,
	strategy = "contains",
	destination = communitiesPoints
}