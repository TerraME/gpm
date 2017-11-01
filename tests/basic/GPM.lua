local roads = CellularSpace{
	file = filePath("roads.shp", "gpm")
}

local communities = CellularSpace{
	file = filePath("communities.shp", "gpm")
}

local network = Network{
	lines = roads,
	target = communities,
	progress = false,
	weight = function(distance, cell)
		if cell.STATUS == "paved" then
			return distance * 0.2
		else
			return distance * 0.5
		end
	end,
	outside = function(distance) return distance * 2 end
}

return {
	GPM = function(unitTest)
		local partOfBrazil = CellularSpace{
			file = filePath("partofbrazil.shp", "gpm")
		}

		local gpm = GPM{
			origin = partOfBrazil,
			strategy = "border",
			progress = false
		}

		forEachElement(gpm.neighbor, function(idx, neigh)
			unitTest:assertType(idx, "string")

			unitTest:assert(getn(neigh) >= 0)
			forEachElement(neigh, function(midx, weight)
				unitTest:assertType(midx, "string")
				unitTest:assertType(weight, "number")
				unitTest:assert(weight > 0)
			end)
		end)
	end,
	__tostring = function(unitTest)
		local partOfBrazil = CellularSpace{
			file = filePath("partofbrazil.shp", "gpm")
		}

		local gpm = GPM{
			origin = partOfBrazil,
			strategy = "border",
			progress = false
		}

		unitTest:assertEquals(tostring(gpm), [[destination  CellularSpace
neighbor     named table of size 5
origin       CellularSpace
progress     boolean [false]
strategy     string [border]
]])
	end,
	fill = function(unitTest)
		local partOfBrazil = CellularSpace{
			file = filePath("partofbrazil.shp", "gpm")
		}

		local gpm = GPM{
			origin = partOfBrazil,
			strategy = "border",
			progress = false
		}

		gpm:fill{
			attribute = "msum",
			strategy = "sum"
		}

		gpm:fill{
			attribute = "maverage",
			strategy = "average"
		}

		local msum = 0
		local maverage = 0

		forEachCell(partOfBrazil, function(cell)
			msum = msum + cell.msum
			maverage = maverage + cell.maverage
		end)

		unitTest:assertEquals(msum, 2.61, 0.01)
		unitTest:assertEquals(maverage, 1.18, 0.01)

		local farms_cells = CellularSpace{
			file = filePath("test/farms_cells.shp", "gpm")
		}

		local farmsPolygon = CellularSpace{
			file = filePath("farms.shp", "gpm")
		}

		gpm = GPM{
			origin = farms_cells,
			destination = network,
			distance = 500,
			progress = false
		}

		gpm:fill{
			strategy = "minimum",
			attribute = "dist",
			copy = "LOCALIDADE"
		}

		gpm:fill{
			strategy = "minimum",
			attribute = "dist2",
			copy = {loc = "LOCALIDADE"}
		}

		forEachCell(farms_cells, function(cell)
			unitTest:assertEquals(cell.LOCALIDADE, cell.loc)
		end)

		local map1 = Map{
			target = gpm.origin,
			select = "dist",
			slices = 8,
			color = "YlOrBr"
		}
		unitTest:assertSnapshot(map1, "polygon_farms_distance.bmp")

		local map2 = Map{
			target = gpm.origin,
			select = "LOCALIDADE",
			value = {"Palhauzinho", "Santa Rosa", "Garrafao", "Mojui dos Campos"},
			color = "Set1"
		}
		unitTest:assertSnapshot(map2, "polygon_farms_nearest.bmp")

		forEachCell(gpm.origin, function(cell)
			cell.LOCALIDADE = nil
		end)

		gpm:fill{
			strategy = "maximum",
			attribute = "dist3",
			copy = "LOCALIDADE"
		}

		gpm:fill{
			strategy = "maximum",
			attribute = "mdist",
			copy = {loc2 = "LOCALIDADE"}
		}

		forEachCell(farms_cells, function(cell)
			unitTest:assertEquals(cell.LOCALIDADE, cell.loc2)
		end)

		map1 = Map{
			target = gpm.origin,
			select = "dist3",
			slices = 8,
			color = "YlOrBr"
		}
		unitTest:assertSnapshot(map1, "polygon_farms_mdistance.bmp")

		map2 = Map{
			target = gpm.origin,
			select = "loc2",
			value = {"Palhauzinho", "Santa Rosa", "Garrafao", "Mojui dos Campos"},
			color = "Set1"
		}
		unitTest:assertSnapshot(map2, "polygon_farms_furthest.bmp")

		gpm:fill{
			strategy = "count",
			attribute = "quant"
		}

		local map3 = Map{
			target = gpm.origin,
			select = "quant",
			value = {1, 2, 3, 4},
			color = {"red", "blue", "green", "black"}
		}
		unitTest:assertSnapshot(map3, "polygon_farms_quantity.bmp")

		gpm = GPM{
			origin = farmsPolygon,
			strategy = "contains",
			destination = communities,
			progress = false
		}

		local counterCommunities = 0

		forEachElement(gpm.neighbor, function(_, neigh)
			if getn(neigh) > 0 then
				counterCommunities = counterCommunities + 1
			end
		end)

		unitTest:assertEquals(counterCommunities, 2)

		local cells = CellularSpace{
			file = filePath("cells.shp", "gpm")
		}

		gpm = GPM{
			origin = cells,
			strategy = "length",
			destination = roads,
			progress = false
		}

		gpm:fill{
			strategy = "count",
			attribute = "quantity",
			max = 1
		}

		local map = Map{
			target = cells,
			select = "quantity",
			value = {0, 1},
			color = {"gray", "blue"}
		}

		unitTest:assertSnapshot(map, "gpm_length.bmp")

		gpm = GPM{
			origin = cells,
			destination = communities,
			strategy = "distance",
			progress = false
		}

		gpm:fill{
			strategy = "minimum",
			attribute = "dist",
			copy = "LOCALIDADE"
		}

		map1 = Map{
			target = cells,
			select = "dist",
			slices = 8,
			min = 0,
			max = 7000,
			color = "YlOrRd",
			invert = true
		}
		unitTest:assertSnapshot(map1, "gpm_distance_all_1.png")

		map2 = Map{
			target = cells,
			select = "LOCALIDADE",
			value = {"Palhauzinho", "Santa Rosa", "Garrafao", "Mojui dos Campos"},
			color = "Set1"
		}
		unitTest:assertSnapshot(map2, "gpm_distance_all_2.png")

		gpm:fill{
			strategy = "all",
			attribute = "dist"
		}

		for i = 0, 3 do
			map = Map{
				target = cells,
				select = "dist_"..i,
				slices = 8,
				min = 0,
				max = 10000,
				color = "YlOrRd",
				invert = true
			}

			unitTest:assertSnapshot(map, "gpm_distance_all_dist_"..i..".png")
		end

		gpm = GPM{
			origin = cells,
			destination = communities,
			distance = 4000,
			progress = false
		}

		gpm:fill{
			strategy = "count",
			attribute = "quant2"
		}

		gpm:fill{
			strategy = "minimum",
			attribute = "dist2",
			missing = 7000,
			copy = {loc3 = "LOCALIDADE"}
		}

		-- as there is a limit of 4000m, those cells that are far
		-- from this distance will not have attribute LOCALIDADE
		forEachCell(cells, function(cell)
			if not cell.loc3 then
				cell.loc3 = "<none>"
			end
		end)

		map1 = Map{
			target = cells,
			select = "quant2",
			min = 0,
			max = 5,
			slices = 6,
			color = "RdPu"
		}

		unitTest:assertSnapshot(map1, "gpm_distance_limit_1.png")

		map2 = Map{
			target = cells,
			select = "dist2",
			slices = 8,
			min = 0,
			max = 7000,
			color = "YlOrRd",
			invert = true
		}

		unitTest:assertSnapshot(map2, "gpm_distance_limit_2.png")

		map3 = Map{
			target = cells,
			select = "loc3",
			value = {"Palhauzinho", "Santa Rosa", "Garrafao", "Mojui dos Campos", "<none>"},
			color = "Set1"
		}

		unitTest:assertSnapshot(map3, "gpm_distance_limit_3.png")

		farms_cells = CellularSpace{
			file = filePath("test/farms_cells.shp", "gpm")
		}

		gpm = GPM{
			origin = farms_cells,
			strategy = "area",
			destination = farmsPolygon,
			progress = false
		}

		gpm:fill{
			strategy = "count",
			attribute = "quant3",
			max = 5
		}

		map = Map{
			target = gpm.origin,
			select = "quant3",
			min = 0,
			max = 5,
			slices = 6,
			color = "Reds"
		}

		unitTest:assertSnapshot(map, "gpm_area.png")
	end,
	save = function(unitTest)
		local farms = CellularSpace{
			file = filePath("test/farms_cells.shp", "gpm")
		}

		local gpm = GPM{
			destination = network,
			origin = farms,
			progress = false
		}

		gpm:save("farms.gpm")

		farms:loadNeighborhood{
			file = "farms.gpm"
		}

		unitTest:assertFile("farms.gpm")


		local states = CellularSpace{
			file = filePath("partofbrazil.shp", "gpm")
		}

		gpm = GPM{
			origin = states,
			strategy = "border",
			progress = false
		}

		gpm:save("states.gal")
		unitTest:assertFile("states.gal")

		gpm:save("states.gwt")
		unitTest:assertFile("states.gwt")

		gpm:save("states.gpm")
		unitTest:assertFile("states.gpm")
	end
}
