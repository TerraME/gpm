-- @example GPM Implementation strategy 'distance' and creating map.
-- Create a map based on the endpoints, and the cells.
-- @image polygon_farms_quantity.bmp

-- import gpm
import("gpm")

-- create the CellularSpace
local csCenterspt = CellularSpace{
	file = filePath("communities.shp", "gpm"),
	geometry = true
}

local csLine = CellularSpace{
	file = filePath("roads.shp", "gpm"),
	geometry = true
}

local farms = CellularSpace{
	file = filePath("farms_cells.shp", "gpm"),
	geometry = true
}

local farms_polygons = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

-- create a Network with the distance of the end points to routes
local network = Network{
	target = csCenterspt,
	lines = csLine,
	weight = function(distance, cell)
		if cell.STATUS == "paved" then
			return distance / 5
		else
			return distance / 2
		end
	end,
	outside = function(distance) return distance * 2 end
}

-- creating a GPM Only with distance
GPM{
	network = network,
	origin = farms,
	output = {
		id = "id1",
		distance = "distance"
	},
	distance = 2000
}

-- creating Map with values ​​GPM
map = Map{
	target = farms,
	select = "pointID",
	value = {0, 1, 2, 3, 4},
	color = {"lightGray", "red", "blue", "green", "black"}
}