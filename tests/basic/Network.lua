
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
				if cell.CD_PAVIMEN == "paved" then
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
		unitTest:assertEquals(#network.distance.target, #communities.cells)

		forEachElement(network.distance.lines, function(line)
			unitTest:assertType(network.distance.keys[network.distance.lines[line]].P1, "string")
			unitTest:assertType(network.distance.keys[network.distance.lines[line]].P2, "string")
		end)

		forEachElement(network.distance.lines, function(line)
			unitTest:assert(network.distance.distanceOutside[network.distance.target[1]][network.distance.keys[network.distance.lines[line]].P1] >= 0)
			unitTest:assert(network.distance.distanceOutside[network.distance.target[1]][network.distance.keys[network.distance.lines[line]].P2] >= 0)
		end)

		forEachElement(network.distance.lines, function(line)
			unitTest:assert(network.distance.distanceWeight[network.distance.target[1]][network.distance.keys[network.distance.lines[line]].P1] >= 0)
			unitTest:assert(network.distance.distanceWeight[network.distance.target[1]][network.distance.keys[network.distance.lines[line]].P2] >= 0)
		end)

		forEachElement(network.distance.lines, function(line)
			unitTest:assertType(network.distance.points[network.distance.lines[line]].P1, "userdata")
			unitTest:assertType(network.distance.points[network.distance.lines[line]].P2, "userdata")
		end)
	end
}

