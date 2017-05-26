-- @example Computes neighborhoods based on Euclidean distances from cells to communities within 4km of distance.
-- It considers a neighbor only a community is less or equals than 4km from the centroid of
-- the cell. The output image shows how many neighbors each cell has.
-- @image polygon_farms_quantity.bmp

import("gpm")

local communities = CellularSpace{
	file = filePath("communities.shp", "gpm"),
	geometry = true
}

local cells = CellularSpace{
	file = filePath("cells.shp", "gpm"),
	geometry = true
}

gpm = GPM{
	origin = cells,
	destination = communities,
	distance = 4000
}

gpm:fill{
	strategy = "count",
	attribute = "quantity"
}

gpm:fill{
	strategy = "minimum",
	attribute = "dist",
	dummy = 7000,
	copy = "LOCALIDADE"
}

-- as there is a limit of 4000m, those cells that are far
-- from this distance will not have attribute LOCALIDADE
forEachCell(cells, function(cell)
	if not cell.LOCALIDADE then
		cell.LOCALIDADE = "<none>"
	end
end)

map1 = Map{
	target = cells,
	select = "quantity",
	min = 0,
	max = 5,
	slices = 6,
	color = "RdPu"
}

map2 = Map{
	target = cells,
	select = "dist",
	slices = 8,
	min = 0,
	max = 7000,
	color = "YlOrRd",
	invert = true
}

map3 = Map{
	target = cells,
	select = "LOCALIDADE",
	value = {"Palhauzinho", "Santa Rosa", "Garrafao", "Mojui dos Campos", "<none>"},
	color = "Set1"
}

