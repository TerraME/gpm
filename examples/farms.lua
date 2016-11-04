-- @example GPM Implementation creating maps.
-- Creates maps based on distance routes, entry points and exit points.
-- This example creates a 'gpm.gpm' file if you have another file with this name will be deleted.

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
	file = filePath("rfarms_cells2.shp", "gpm"),
	geometry = true
}

-- create a Network with the distance of the end points to routes
local network = Network{
	target = csCenterspt,
	lines = csLine,
	weight = function(distance, cell)
		if cell.CD_PAVIMEN == "pavimentada" then
			return distance / 5
		else
			return distance / 2
		end
	end,
	outside = function(distance, cell) return distance * 2 end
}

-- creating a GPM with the distance of the entry points for the routes
local gpm = GPM{
	network = network,
	origin = farms,
	distance = "distance",
	relation = "community",
	output = {
		id = "id1",
		distance = "distance"
	}
}

-- creating Map with values ​​GPM
map = Map{
	target = gpm.origin,
	select = "distance",
	slices = 20,
	color = "Blues"
}

map = Map{
	target = gpm.origin,
	select = "id1",
	value = {1, 2, 3, 4},
	color = {"red", "blue", "green", "black"}
}

local file = File("gpm.gpm")

file:deleteIfExists()
gpm:save("gpm.gpm")

farms:loadNeighborhood{
	source = "gpm.gpm"
}

