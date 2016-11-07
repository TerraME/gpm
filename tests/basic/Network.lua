
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
			outside = function(distance)
				return distance * 2
			end
		}

		unitTest:assertType(network, "Network")
		unitTest:assertEquals(#network.distance.lines, #roads.cells)
		unitTest:assertEquals(#network.distance.target, #communities.cells)

		forEachElement(network.distance.netpoint, function(neighbor)
			unitTest:assert(network.distance.netpoint[neighbor].distance >= 0)
			unitTest:assert(network.distance.netpoint[neighbor].distanceOutside >= 0)
			unitTest:assertType(network.distance.netpoint[neighbor].targetIDOutside, "number")
			unitTest:assertType(network.distance.netpoint[neighbor].targetID, "number")
			unitTest:assertType(network.distance.netpoint[neighbor].point, "userdata")
		end)
	end
}

