-- @example GPM Implementation strategy 'length' and creating map.
-- Create relations between objects whose intersection is a line.

-- import gpm
import("gpm")

-- create the CellularSpace
local farms = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

-- creating a GPM
local gpm = GPM{
	origin = farms,
	strategy = "length",
	destination = farms
}