-- @example GPM Implementation strategy 'border' and creating map.
-- Returns neighbor states and the relationship of borders.

-- import gpm
import("gpm")

-- create the CellularSpace
local farms = CellularSpace{
	file = filePath("farms_cells.shp", "gpm"),
	geometry = true
}

local farmsNeighbor = CellularSpace{
	file = filePath("partofbrasil.shp", "gpm"),
	geometry = true
}

-- creating a GPM with the distance of the entry points for the routes
local gpm = GPM{
	origin = farms,
	distance = "distance",
	relation = "community",
	polygonNeighbor = farmsNeighbor
}

forEachCell(gpm.polygonNeighbor, function(polygon)
	print(polygon.NOME_UF)
	forEachElement(polygon.neighbors, function(polygonNeighbor)
		print("	"..polygon.neighbors[polygonNeighbor].NOME_UF.."("..polygon.perimeterBorder[polygon.neighbors[polygonNeighbor]]..")")
	end)
end)