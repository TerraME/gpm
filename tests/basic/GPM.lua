
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

		local gpm = GPM{
			network = network,
			origin = farms,
			distance = "distance",
			relation = "community",
		}

		unitTest:assertType(gpm, "GPM")
		unitTest:assertType(gpm.result, "table")
		unitTest:assertEquals(#gpm.result.distance, #farms)
		unitTest:assertEquals(#gpm.result.relation, #farms)
		unitTest:assertEquals(#gpm, #farms)
	end,
	save = function(unitTest)
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

		local gpm = GPM{
			network = network,
			destination = farms
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
}

