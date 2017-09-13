-- @example Example that connects cells to the communities located within them. In this example,
-- there are only two communities locaded within the cells.
-- The output image shows how many neighbors each cell has.
-- @image contains.bmp

import("gpm")

local cells = CellularSpace{
	file = filePath("cells.shp", "gpm")
}

local communities = CellularSpace{
	file = filePath("communities.shp", "gpm")
}

gpm = GPM{
	origin = cells,
	strategy = "contains",
	destination = communities
}

gpm:fill{
	strategy = "count",
	attribute = "quantity"
}

map = Map{
	target = cells,
	select = "quantity",
	value = {0, 1},
	color = {"lightGray", "blue"}
}

