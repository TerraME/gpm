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

		local farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		local farmsNeighbor = CellularSpace{
			file = filePath("partofbrasil.shp", "gpm"),
			geometry = true
		}

		local gpm = GPM{
			origin = farmsNeighbor,
			distance = "distance",
			relation = "community",
			strategy = "border"
		}

		forEachCell(gpm.origin, function(polygon)
			unitTest:assert(#polygon.neighbors > 0)
			forEachElement(polygon.neighbors, function(polygonNeighbor)
				unitTest:assert(polygon.borderNeighbors[polygon.neighbors[polygonNeighbor]] > 0)
				unitTest:assertType(polygon.perimeterBorder[polygon.neighbors[polygonNeighbor]], "number")
			end)
		end)

		gpm = GPM{
			network = network,
			origin = farms_cells,
			distance = "distance",
			relation = "community",
			output = {
				id = "id1",
				distance = "distance"
			},
			maxDist = 2000,
			destination = farmsPolygon
		}

		local cellOrigin = gpm.origin:sample()

		unitTest:assertType(cellOrigin.distance, "number")

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

		gpm = GPM{
			origin = farms_cells,
			distance = "distance",
			relation = "community",
			strategy = "contains",
			targetPoints = communities,
			destination = farmsPolygon
		}

		map = Map{
			target = gpm.origin,
			select = "contains",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "contains_farms.bmp")
		unitTest:assertType(gpm, "GPM")

		local farms = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		GPM{
			origin = farms,
			distance = "distance",
			relation = "community",
			maximumQuantity = 2,
			geometricObject = farms_cells
		}

		forEachCell(farms, function(cell)
			unitTest:assert(cell.intersection ~= nil)
		end)

		GPM{
			origin = farms,
			distance = "distance",
			relation = "community",
			minimumLength = 400,
			geometricObject = roads
		}

		forEachCell(farms, function(cell)
			unitTest:assert(cell.intersection ~= nil)
		end)
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

