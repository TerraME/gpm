
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

		local error_func = function()
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
		unitTest:assertError(error_func, "Argument 'lines' should be composed by lines, got 'MultiPoint'.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = roads,
				weight = function() end
			}
		end
		unitTest:assertError(error_func, "Argument 'target' should be composed by points, got 'MultiLineString'.")

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
		unitTest:assertError(error_func, incompatibleTypeMsg("strategy", "open", "string"))

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("weight", "function", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function() end,
				outside = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("outside", "function", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function() end,
				error = "error"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("error", "number", "error"))
	end,

	createOpenNetwork = function(unitTest)
		local roads = CellularSpace{
			file = filePath("error/".."roads-invalid.shp", "gpm"),
			geometry = true
		}

		local communities = CellularSpace{
			file = filePath("communities.shp", "gpm"),
			geometry = true
		}

		local error_func = function()
			local network = Network{
				lines = roads,
				target = communities
			}
		end

		unitTest:assertError(error_func, "line do not touch, They have a differance of: 731.34319968072")
	end
}
