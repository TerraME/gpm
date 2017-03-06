-- @example GPM Implementation strategy 'border' and creating map.

-- Returns neighbor states and the relationship of borders.

-- import gpm
import("gpm")

-- create the CellularSpace
local farmsNeighbor = CellularSpace{
	file = filePath("partofbrasil.shp", "gpm"),
	geometry = true
}

-- creating a GPM
local gpm = GPM{
	origin = farmsNeighbor,
	strategy = "border",
	progress = false
}

forEachCell(gpm.origin, function(polygon)
	print(polygon.name)
	forEachElement(polygon.neighbors, function(polygonNeighbor)
		print("	"..polygon.neighbors[polygonNeighbor].name.." ("..polygon.perimeterBorder[polygon.neighbors[polygonNeighbor]]..")")
	end)
end)
