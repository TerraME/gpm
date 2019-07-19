-- @example GPM Implementation creating maps.
-- Creates maps based on distance routes, entry points and exit points.
-- This test has commented lines, to create and validate files.
-- This example creates a 'gpm.gpm' file if you have another file with this name will be deleted.
-- @image id_farms.png

import("gpm")

communities = CellularSpace{
	file = filePath("communities.shp", "gpm")
}

roads = CellularSpace{
	file = filePath("roads.shp", "gpm")
}

cells = CellularSpace{
	file = filePath("cells.shp", "gpm")
}

network = Network{
	target = communities,
	lines = roads,
	inside = function(distance, cell)
		if cell.STATUS == "paved" then
			return distance / 5
		else
			return distance / 2
		end
	end,
	outside = function(distance) return distance * 4 end
}

gpm = GPM{
	destination = network,
	origin = cells,
	entrance = "lightest",
	by = "points",
}

gpm:fill{
	strategy = "minimum",
	attribute = "dist",
	copy = "LOCALIDADE"
}

map1 = Map{
	target = cells,
	select = "dist",
	slices = 10,
	min = 0,
	max = 14000,
	color = "YlOrBr"
}

map2 = Map{
	target = cells,
	select = "LOCALIDADE",
	value = {"Palhauzinho", "Santa Rosa", "Garrafao", "Mojui dos Campos"},
	color = "Set1"
}

-- Uncomment the line below if you want to save the output into a file
-- gpm:save("gpm.gpm")

gpm:fill{
	strategy = "all",
	attribute = "d"
}

for i = 0, 3 do
	Map{
		target = cells,
		select = "d_"..i,
		slices = 10,
		min = 0,
		max = 14000,
		color = "YlOrRd"
	}
end

