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
				origin = farms,
				distance = "distance",
				relation = "community",
				output = {
					id = "id1",
					distance = "distance"
				},
				maxDist = "distance"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("maxDist", "number", "distance"))

		error_func = function()
			GPM{
				origin = 2,
				distance = "distance",
				relation = "community",
				strategy = "border"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("origin", "CellularSpace", 2))

		local farmsNeighbor = CellularSpace{
			file = filePath("roads.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farmsNeighbor,
				distance = "distance",
				relation = "community",
				strategy = "border"
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
				distance = "distance",
				relation = "community",
				strategy = "border"
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
				distance = "distance",
				relation = "community",
				strategy = "border",
				maximumQuantity = ""
			}
		end
		unitTest:assertError(error_func, "Incompatible types. Argument 'maximumQuantity' expected number, got string.")

		error_func = function()
			GPM{
				origin = farmsNeighbor,
				distance = "distance",
				relation = "community",
				strategy = 2
			}
		end
		unitTest:assertError(error_func, incompatibleValueMsg("strategy", "border", 2))

		error_func = function()
			GPM{
				origin = farms,
				distance = "distance",
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
				distance = "distance",
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
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
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
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
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
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "Argument 'destination' should be composed by MultiPolygon, got 'MultiLineString'.")

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "Argument 'destination' should be composed by MultiPolygon, got 'MultiLineString'.")

		farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")

		communities = ""

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("targetPoints", "CellularSpace", ""))

		communities = CellularSpace{
			file = filePath("communities.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'targetPoints' must be loaded with 'geometry = true'.")

		communities = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				strategy = "contains",
				targetPoints = communities,
				destination = farmsPolygon
			}
		end
		unitTest:assertError(error_func, "Argument 'targetPoints' should be composed by points, got 'MultiPolygon'.")

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				maximumQuantity = "",
				geometricObject = farms_cells
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("maximumQuantity", "number", ""))

		error_func = function()
			GPM{
				origin = farms_cells,
				distance = "distance",
				relation = "community",
				minimumLength = "",
				geometricObject = farms_cells
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("minimumLength", "number", ""))

		farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		error_func = function()
			GPM{
				origin = farmsPolygon,
				distance = "distance",
				relation = "community",
				minimumLength = "",
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
				distance = "distance",
				relation = "community",
				minimumLength = "",
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
				distance = "distance",
				relation = "community",
				minimumLength = 2,
				geometricObject = communitiesCs
			}
		end
		unitTest:assertError(error_func, "Argument 'geometricObject' should be composed by MultiPolygon or MultiLineString, got 'MultiPoint'.")

		error_func = function()
			GPM{
				origin = farms,
				distance = "distance",
				relation = "community",
				minimumLength = 2,
				maximumQuantity = 2,
				geometricObject = farms
			}
		end
		unitTest:assertError(error_func, "Use maximumQuantity or minimumLength as parameters, not both.")
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