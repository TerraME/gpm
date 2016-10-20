
return {
	GPM = function(unitTest)
		local roads = CellularSpace{
			file = filePath("roads.shp", "gpm"),
			geometry = true
		}
print("1")
		local communities = CellularSpace{
			file = filePath("communities.shp", "gpm"),
			geometry = true
		}
print("2")
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
			outside = function(distance) return distance * 2 end
		}
print("3")
		local farms = CellularSpace{
			file = filePath("rfarms_cells2.shp", "gpm"),
			geometry = true
		}
print("4")
--[[		local gpm = GPM{
			network = network,
			origin = farms,
			distance = "distance",
			relation = "community",
			output = {
				distance = "distance"
			}
		}
print("4.5")
		local cell = gpm.origin:sample()
print("5")
		--unitTest:assertType(cell.distance, "number")--]]
print("6")
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
print("7")
		local map = Map{
			target = gpm.origin,
			select = "id1",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
print("8")
		--unitTest:assertType(map, "Map")
		unitTest:assertSnapshot(map, "id_farms.bmp")

		map = Map{
			target = farms,
			select = "distance",
			slices = 20,
			color = "Blues"
		}
		--unitTest:assertType(map, "Map")
		unitTest:assertSnapshot(map, "distance_farms.bmp")

		unitTest:assertType(gpm, "GPM")
		unitTest:assertType(gpm.result, "table")
		unitTest:assertEquals(#gpm.result.distance, #farms)
		unitTest:assertEquals(#gpm.result.relation, #farms)
		unitTest:assertEquals(#gpm, #farms)
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
			file = filePath("farms.shp", "gpm"),
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
    end
}

