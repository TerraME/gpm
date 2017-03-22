-- @example GPM Implementation strategy 'area' and creating map.
-- Create a map based on the cells and polygons.
-- @image farms_cells.png

import("gpm")

farms = CellularSpace{
	file = filePath("farms_cells.shp", "gpm"),
	geometry = true
}

farmsPolygon = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

gpm = GPM{
	origin = farms,
	destination = farmsPolygon
}

-- creating Map with GPM values
map = Map{
	target = gpm.origin,
	select = "cellID",
	slices = 7,
	color = "Accent"
}

map:save("farms_cells.png")
