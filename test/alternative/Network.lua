
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
				destination = communities,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("lines", "CellularSpace", 2))

		error_func = function()
			local network = Network{
				lines = communities,
				destination = communities,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, "Argument 'lines' should be composed by lines, got points.")

		error_func = function()
			local network = Network{
				lines = roads,
				destination = roads,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, "Argument 'destination' should be composed by points, got lines.")

		error_func = function()
			local network = Network{
				lines = roads,
				destination = 2,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("destination", "CellularSpace", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				strategy = "open",
				destination = communities,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, defaultValueMsg("strategy", "open"))

		error_func = function()
			local network = Network{
				lines = roads,
				destination = communities,
				weight = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("weight", "function", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				destination = communities,
				weight = function() end,
				outside = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("outside", "function", 2))
	end
}
