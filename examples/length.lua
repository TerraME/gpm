-- @example GPM Implementation strategy '' and creating map.
-- Returns neighbor states and the relationship of borders.

-- import gpm
import("gpm")

-- create the CellularSpace
local roads = CellularSpace{
	file = filePath("roads.shp", "gpm"),
	geometry = true
}

local farms = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

-- creating a GPM
GPM{
	origin = farms,
	distance = "distance",
	relation = "community",
	minimumLength = 400,
	geometricObject = roads
}

GPM{
	origin = farms,
	distance = "distance",
	relation = "community",
	maximumQuantity = 2,
	geometricObject = roads
}