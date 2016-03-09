
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

		error_func = function()
			local network = Network{
				lines = 2,
				target = communities,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("lines", "CellularSpace", 2))

		error_func = function()
			local network = Network{
				lines = communities,
				target = communities,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, "Argument 'lines' should be composed by lines, got points.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = roads,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, "Argument 'target' should be composed by points, got lines.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = 2,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("target", "CellularSpace", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				strategy = "open",
				target = communities,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, defaultValueMsg("strategy", "open"))
	end
}
