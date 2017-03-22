
import("terralib")

farms = Project{
	file = "farms_cells3.tview",
	clean = true,
	farms = filePath("farms.shp", "gpm")
}

cells = Layer{
	project = farms,
	file = "farms_cells3.shp",
	clean = true,
	input = "farms",
	name = "cells",
	resolution = 100
}


