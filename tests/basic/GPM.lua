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
			strategy = "border",
			quantity = 2,
			progress = false
		}

		forEachCell(gpm.origin, function(polygon)
			unitTest:assert(#polygon.neighbors > 0)
			forEachElement(polygon.neighbors, function(polygonNeighbor)
				unitTest:assert(polygon.intersectionNeighbors[polygon.neighbors[polygonNeighbor]] > 0)
				unitTest:assertType(polygon.perimeterBorder[polygon.neighbors[polygonNeighbor]], "number")
			end)
		end)

		gpm = GPM{
			network = network,
			origin = farms_cells,
			output = {
				id = "id1",
				distance = "distance"
			},
			distance = 200,
			destination = farmsPolygon,
			progress = false
		}

		local map = Map{
			target = gpm.origin,
			select = "pointID",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "polygon_farms_distance.bmp")

		gpm = GPM{
			network = network,
			origin = farms_cells,
			output = {
				id = "id1",
				distance = "distance"
			},
			quantity = 3,
			destination = farmsPolygon,
			progress = false
		}

		map = Map{
			target = gpm.origin,
			select = "pointID",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "polygon_farms_quantity.bmp")

		gpm = GPM{
			network = network,
			origin = farms_cells,
			distance = 2000,
			destination = farmsPolygon,
			progress = false
		}

		local cellOrigin = gpm.origin:sample()

		unitTest:assertType(cellOrigin.distance, "number")

		map = Map{
			target = gpm.origin,
			select = "cellID",
			slices = 10,
			color = "RdYlGn"
		}
		unitTest:assertSnapshot(map, "cellID_farms.bmp")

		map = Map{
			target = gpm.origin,
			select = "pointID",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map, "pointID_farms.bmp")

		gpm = GPM{
			network = network,
			origin = farms_cells,
			output = {
				id = "id1",
				distance = "distance"
			},
			distance = 2000,
			destination = farmsPolygon,
			progress = false
		}

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
			origin = farmsPolygon,
			strategy = "contains",
			destination = communities,
			progress = false
		}

		local counterCommunities = 0

		forEachCell(farmsPolygon, function(cell)
			if #cell.contains > 0 then
				counterCommunities = counterCommunities + 1
			end
		end)

		unitTest:assertEquals(counterCommunities, 2)

		local farms = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		GPM{
			origin = farms,
			strategy = "length",
			destination = farms,
			progress = false
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
			output = {
				id = "id1",
				distance = "distance"
			},
			progress = false
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