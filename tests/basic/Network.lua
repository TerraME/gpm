
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
					return distance / 5
				else
					return distance / 2
				end
			end,
			outside = function(distance, cell)
				return distance * 2
			end
		}

		unitTest:assertType(network, "Network")
		unitTest:assertEquals(#network.distance.lines, #roads.cells)
		unitTest:assertEquals(#network.distance.target + 1, #communities.cells)

	end
}

