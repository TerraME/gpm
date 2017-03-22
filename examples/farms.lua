-- @example GPM Implementation creating maps.
-- Creates maps based on distance routes, entry points and exit points.
-- This test has commented lines, to create and validate files.
-- This example creates a 'gpm.gpm' file if you have another file with this name will be deleted.
-- @image id_farms.png

-- import gpm
import("gpm")

-- create the CellularSpace
csCenterspt = CellularSpace{
	file = filePath("communities.shp", "gpm"),
	geometry = true
}

csLine = CellularSpace{
	file = filePath("roads.shp", "gpm"),
	geometry = true
}

farms = CellularSpace{
	file = filePath("farms_cells.shp", "gpm"), -- also try 'farms_cells3.shp'
	geometry = true
}

network = Network{
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

gpm = GPM{
	network = network,
	origin = farms,
	output = {
		id = "id1",
		distance = "distance"
	}
}

-- creating Map with the output of GPM
map1 = Map{
	target = gpm.origin,
	select = "distance",
	slices = 8,
	color = "YlOrBr"
}

map2 = Map{
	target = gpm.origin,
	select = "id1",
	slices = 4,
	color = "Dark" -- {"red", "blue", "green", "black"}
}

-- Uncomment the line below if you want to save the output into a file
-- gpm:save("gpm.gpm")

map1:save("distance.png")
map2:save("community.png")

