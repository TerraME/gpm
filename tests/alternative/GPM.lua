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
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				distance = "distance"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("distance", "number", "distance"))

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				distance = 100,
				destination = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("destination", "CellularSpace", 2))

		local polygons = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				distance = 100,
				destination = polygons
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")

		polygons = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				network = network,
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				distance = 100,
				quantity = 2,
				destination = polygons
			}
		end
		unitTest:assertError(error_func, "Use quantity or distance as parameters, not both.")

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				quantity = " ",
				destination = polygons
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("quantity", "number", " "))

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				distance = 100,
				destination = roads
			}
		end
		unitTest:assertError(error_func, "Argument 'destination' should be composed by MultiPolygon, got 'MultiLineString'.")

		error_func = function()
			GPM{
				origin = 2,
				relation = "community",
				strategy = "intersection"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("origin", "CellularSpace", 2))

		local farmsNeighbor = CellularSpace{
			file = filePath("roads.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farmsNeighbor,
				relation = "community",
				strategy = "intersection"
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")

		farmsNeighbor = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = farmsNeighbor,
				relation = "community",
				strategy = "intersection"
			}
		end
		unitTest:assertError(error_func, "Argument 'origin' should be composed by MultiPolygon, got 'MultiLineString'.")

		farmsNeighbor = CellularSpace{
			file = filePath("partofbrasil.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = farmsNeighbor,
				relation = "community",
				strategy = "intersection",
				quantity = ""
			}
		end
		unitTest:assertError(error_func, "Incompatible types. Argument 'quantity' expected number, got string.")

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				destination = "distance"
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")

		local farmsPolygon = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "Argument 'destination' should be composed by MultiPolygon, got 'MultiLineString'.")

		error_func = function()
			GPM{
				origin = farms_cells,
				relation = "community",
				strategy = "contains",
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, mandatoryArgumentMsg("origin"))

		local farms_cells = CellularSpace{
			file = filePath("farms_cells.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farms_cells,
				relation = "community",
				strategy = "contains",
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")

		farms_cells = CellularSpace{
			file = filePath("farms_cells.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = farms_cells,
				relation = "community",
				strategy = "contains",
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "Argument 'destination' should be composed by MultiPoint, got 'MultiLineString'.")

		farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farms_cells,
				relation = "community",
				strategy = "contains",
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")

		communities = CellularSpace{
			file = filePath("communities.shp", "gpm")
		}

		communities = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farmsPolygon,
				relation = "community",
				strategy = "length",
				geometricObject = farms_cells
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")

		farms = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		communities = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = communities,
				relation = "community",
				strategy = "length",
				geometricObject = farms
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'geometricObject' must be loaded with 'geometry = true'.")

		farms = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		local communitiesCs = CellularSpace{
			file = filePath("communities.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = farms,
				relation = "community",
				strategy = "length",
				geometricObject = communitiesCs
			}
		end
		unitTest:assertError(error_func, "Argument 'geometricObject' should be composed by MultiPolygon or MultiLineString, got 'MultiPoint'.")
	end,
	save = function(unitTest)
		local farms = CellularSpace{
			file = filePath("farms_cells.shp", "gpm"),
			geometry = true
		}

		local gpm = GPM{
			network = network,
			origin = farms,
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