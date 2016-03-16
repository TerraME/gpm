
return {
	GPM = function(unitTest)
		local roads = CellularSpace{
			source = filePath("roads.shp", "gpm"),
			geometry = true
		}

		local communities = CellularSpace{
			source = filePath("communities.shp", "gpm"),
			geometry = true
		}
		
		local farms = CellularSpace{
			source = filePath("farms.shp", "gpm"),
			geometry = true
		}

		local network = Network{
			lines = roads,
			destination = communities,
			weight = function(distance, cell)
				if cell.CD_PAVIMEN == "pavimentada" then
					return d / 5
				else
					return d / 2
				end
			end,
			outside = function(distance, cell)
				return distance * 2
			end
		}

		error_func = function()
			local gpm = GPM{
				network = 2,
				origin = farms
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("network", "Network", 2))

		error_func = function()
			gpm:save(2)
			local gpm = GPM{
				network = network,
				origin = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("origin", "CellularSpace", 2))
	end,
}

