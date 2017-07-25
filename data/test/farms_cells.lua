
import("gis")

farms = Project{
	file = "farms_cells.tview",
	clean = true,
	farms = filePath("farms.shp", "gpm")
}

cells = Layer{
	project = farms,
	file = "farms_cells.shp",
	clean = true,
	input = "farms",
	name = "cells",
	resolution = 1000
}


