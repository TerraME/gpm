-- @example GPM Implementation strategy 'area' and creating map.
-- Create a map based on the cells and polygons.
-- @image farms_cells.png

import("gpm")

cells = CellularSpace{
	file = filePath("cells.shp", "gpm"),
	geometry = true
}

farms = CellularSpace{
	file = filePath("farms.shp", "gpm"),
	geometry = true
}

gpm = GPM{
	origin = cells,
	strategy = "area",
	destination = farms
}

gpm:fill{
	strategy = "count",
	attribute = "quantity",
	max = 5
}

map = Map{
	target = cells,
	select = "quantity",
	min = 0,
	max = 5,
	slices = 6,
	color = "Reds"
}

gpm:fill{
	strategy = "maximum",
	attribute = "max",
	copy = {farm = "id"}
}

-- to paint them with different colores, we use the rest of division by 9
forEachCell(cells, function(cell)
	cell.farm = tonumber(cell.farm) % 9
end)

map = Map{
	target = cells,
	select = "farm",
	min = 0,
	max = 8,
	slices = 9,
	color = "Set1"
}

