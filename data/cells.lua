
import("terralib")

farms = Project{
	file = "cells.tview",
	clean = true,
	farms = filePath("farms.shp", "gpm")
}

cells = Layer{
	project = farms,
	file = "cells.shp",
	clean = true,
	input = "farms",
	name = "cells",
	resolution = 200
}

