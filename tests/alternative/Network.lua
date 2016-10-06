
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
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("lines", "CellularSpace", 2))

		error_func = function()
			local network = Network{
				lines = communities,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, "Argument 'lines' should be composed by lines, got 'MultiPoint'.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = roads,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, "Argument 'target' should be composed by points, got 'MultiLineString'.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = 2,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("target", "CellularSpace", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				strategy = "open",
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("strategy", "open", "string"))

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = 2,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("weight", "function", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = 2
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("outside", "function", 2))

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end,
				error = "error"
			}
		end
		unitTest:assertError(error_func, incompatibleTypeMsg("error", "number", "error"))

		roads = CellularSpace{
			file = filePath("error/".."roads-invalid.shp", "gpm"),
			geometry = true
		}

		communities = CellularSpace{
			file = filePath("communities.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, "Line: '7' does not touch any other line. The minimum distance found was: 843.46359196883.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end,
				error = 9000
			}
		end
		unitTest:assertError(error_func, "The network disconected.")

		local roads = CellularSpace{
			file = filePath("error/".."roads_overlay_points.shp", "gpm"),
			geometry = true
		}

		error_func = function()
			local network = Network{
				lines = roads,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, "Lines '6' and '14' cross each other.")

		local cs = CellularSpace{
			xdim = 20,
			ydim = 25
		}

		error_func = function()
			local network = Network{
				lines = cs,
				target = communities,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'lines' must be loaded with 'geometry = true'.")

		error_func = function()
			local network = Network{
				lines = roads,
				target = cs,
				weight = function(distance, cell) return distance end,
				outside = function(distance, cell) return distance * 2 end
			}
		end
		unitTest:assertError(error_func, "The CellularSpace in argument 'target' must be loaded with 'geometry = true'.")

	end
}
