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
		local farms = CellularSpace{
			file = filePath("farms_cells.shp", "gpm"),
			geometry = true
		}

		local error_func = function()
			GPM{
				network = 2,
				origin = farms
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("network", "Network", 2))

		farms = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")

		farms = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					d = "distance"
				}
			}
		end
		unitTest:assertError(error_func, incompatibleValueMsg("output", "id or distance", "d"))

		error_func = function()
			GPM{
				network = network,
				origin = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("origin", "CellularSpace", 2))

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
            	distancePoint = "distance"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("distancePoint", "number", "distance"))

		local farmsNeighbor = CellularSpace{
			file = filePath("partofbrasil.shp", "gpm")
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				polygonNeighbor = "distance"
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'polygonNeighbor' must be loaded with 'geometry = true'.")

		local farmsNeighbor = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				polygonNeighbor = farmsNeighbor
			}
		end
		unitTest:assertError(error_func, "Argument 'polygonNeighbor' should be composed by MultiPolygon, got 'MultiLineString'.")

		local farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				polygonOrigin = "distance"
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'polygonNeighbor' must be loaded with 'geometry = true'.")

		local farmsPolygon = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				polygonOrigin = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "Argument 'polygonNeighbor' should be composed by MultiPolygon, got 'MultiLineString'.")
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
			}
		}
		local nameFile = 2

		local error_func = function()
			gpm:save(nameFile)
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("file", "string or File", nameFile))
    
		error_func = function()
			gpm:save("gpm.gpm")
		end
		unitTest:assertError(error_func, mandatoryArgumentMsg("output.distance and output.id"))
	end
}