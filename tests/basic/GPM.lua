local roads = CellularSpace{
	file = filePath("roads.shp", "gpm"),
	geometry = true
}

local communities = CellularSpace{
	file = filePath("communities.shp", "gpm"),
	geometry = true
}

local network = Network{
	lines = roads,
	target = communities,
	weight = function(distance, cell)
		if cell.STATUS == "paved" then
			return distance / 5
		else
			return distance / 2
		end
	end,
	outside = function(distance) return distance * 2 end
}

return {
	GPM = function(unitTest)
		local farms_cells = CellularSpace{
			file = filePath("farms_cells.shp", "gpm"),
			geometry = true
		}

		local farms = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		local farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		local farmsNeighbor = CellularSpace{
			file = filePath("partofbrasil.shp", "gpm"),
			geometry = true
		}

		local gpm = GPM{
			network = network,
			origin = farms_cells,
			distance = "distance",
			relation = "community",
			output = {
				id = "id1",
				distance = "distance"
			},
			distancePoint = 2000,
			polygonOrigin = farmsPolygon,
			polygonNeighbor  = farmsNeighbor
		}

		forEachCell(gpm.polygonNeighbor, function(polygon)
			unitTest:assert(#polygon.neighbors > 0)
			forEachElement(polygon.neighbors, function(polygonNeighbor)
				unitTest:assert(polygon.borderNeighbors[polygon.neighbors[polygonNeighbor]] > 0)
			end)
		end)

		local cell = gpm.origin:sample()

		unitTest:assertType(cell.distance, "number")

		local map = Map{
			target = gpm.origin,
			select = "cellID",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "cellID_farms.bmp")

		map = Map{
			target = gpm.origin,
			select = "pointID",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "pointID_farms.bmp")

		map = Map{
			target = gpm.origin,
			select = "id1",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "id_farms.bmp")

		map = Map{
			target = farms_cells,
			select = "distance",
			slices = 20,
			color = "Blues"
		}
		unitTest:assertSnapshot(map, "distance_farms.bmp")

		unitTest:assertType(gpm, "GPM")
	end,
	save = function(unitTest)
		local farms = CellularSpace{
			file = filePath("farms_cells.shp", "gpm"),
			geometry = true
		}

		local gpm = GPM{
			network = network,
			origin = farms,
			distance = "distance",
			relation = "community",
			output = {
				id = "id1",
				distance = "distance"
			}
		}

		gpm:save("farms.gpm")

		farms:loadNeighborhood{
			source = "farms.gpm"
		}

		unitTest:assertFile("farms.gpm")

		gpm:save("farms.gal")
		unitTest:assertFile("farms.gal")

		gpm:save("farms.gwt")
		unitTest:assertFile("farms.gwt")

		local fileGPM = File("farms.gpm")
		local fileGAL = File("farms.gal")
		local fileGWT = File("farms.gwt")

		fileGPM:deleteIfExists()
		fileGAL:deleteIfExists()
		fileGWT:deleteIfExists()
	end
}

