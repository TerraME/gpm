-- @example GPM Implementation strategy 'area' and creating map.
-- Create a map based on the cells and polygons.
-- @image farms_cells.png

import("gpm")

farms = CellularSpace{
	file = filePath("cells.shp", "gpm"),
	geometry = true
}

farmsPolygon = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

gpm = GPM{
	origin = farms,
	strategy = "area",
	destination = farmsPolygon
}

gpm:fill{
	strategy = "count",
	attribute = "quantity",
	max = 5
}

map = Map{
	target = gpm.origin,
	select = "quantity",
	min = 0,
	max = 5,
	slices = 6,
	color = "Reds"
}

--map:save("cells.png")
