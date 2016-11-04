
return {
	GPM = function(unitTest)
		local roads = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}

		local communities = CellularSpace{
			file = filePath("communities.shp", "gpm"),
			geometry = true
		}
		
		local farms = CellularSpace{
			file = filePath("rfarms_cells2.shp", "gpm"),
			geometry = true
		}

		local network = Network{
			lines = roads,
			target = communities,
			weight = function(distance, cell)
				if cell.CD_PAVIMEN == "pavimentada" then
					return distance / 5
				else
					return distance / 2
				end
			end,
			outside = function(distance)
				return distance * 2
			end
		}

		local error_func = function()
			local gpm = GPM{
				network = 2,
				origin = farms
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("network", "Network", 2))

		farms = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		local error_func = function()
			local gpm = GPM{
				network = network,
				origin = farms
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")

		farms = CellularSpace{
			file = filePath("farms.shp", "gpm"),
			geometry = true
		}

		local error_func = function()
			local gpm = GPM{
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
			local gpm = GPM{
				network = network,
				origin = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("origin", "CellularSpace", 2))
	end,
	save = function(unitTest)
		local roads = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}

		local communities = CellularSpace{
			file = filePath("communities.shp", "gpm"),
			geometry = true
		}
		
		local farms = CellularSpace{
			file = filePath("rfarms_cells2.shp", "gpm"),
			geometry = true
		}

		local network = Network{
			lines = roads,
			target = communities,
			weight = function(distance, cell)
				if cell.CD_PAVIMEN == "pavimentada" then
					return distance / 5
				else
					return distance / 2
				end
			end,
			outside = function(distance)
				return distance * 2
			end
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
		local nameFile = 2

		local error_func = function()
			gpm:save(nameFile)
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("file", "string or File", nameFile))

		local gpm = GPM{
			network = network,
			origin = farms,
			distance = "distance",
			relation = "community",
			output = {
				id = "id1"
			}
		}
    
		error_func = function()
			gpm:save("gpm.gpm")
		end
		unitTest:assertError(error_func, mandatoryArgumentMsg("output.distance"))
	end
}