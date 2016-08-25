
return {
	Network = function(unitTest)
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

		unitTest:assertType(network, "Network")
	end,

	createOpenNetwork = function(unitTest)
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
			target = communities
		}

		network:createOpenNetwork{
			lines = filePath("roads.shp", "gpm"),
			target = filePath("communities.shp", "gpm")
		}

		unitTest:assertType(network, "Network")
	end
}

