
return {
	Network = function(unitTest)
		local roads = CellularSpace{
			source = filePath("roads.shp", "gpm"),
			geometry = true
		}

		local communities = CellularSpace{
			source = filePath("communities.shp", "gpm"),
			geometry = true
		}

		local network = Network{
			lines = roads,
			strategy = "open", -- default, this should be removed
			target = communities,
			weight = function(distance, id)
				if roads:get(id).CD_PAVIMEN == "pavimentada" then
					return d / 5
				else
					return d / 2
				end
			end
		}

		unitTest:assertType(network, "Network")
	end

}
