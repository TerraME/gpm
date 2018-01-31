
return {
	Network = function(unitTest)
		local roads = CellularSpace{
			file = filePath("roads.shp", "gpm")
		}

		local communities = CellularSpace{
			file = filePath("communities.shp", "gpm")
		}

		local error_func = function()
			Network{
				lines = 2,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, incompatibleTypeMsg("lines", "CellularSpace", 2))

		error_func = function()
			Network{
				lines = communities,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "Argument 'lines' should be composed by lines, got 'MultiPoint'.")

		error_func = function()
			Network{
				lines = roads,
				target = 2,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, incompatibleTypeMsg("target", "CellularSpace", 2))

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				inside = 2,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, incompatibleTypeMsg("inside", "function", 2))

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				inside = function(distance) return distance end,
				outside = 2
			}
		end

		unitTest:assertError(error_func, incompatibleTypeMsg("outside", "function", 2))

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end,
				error = "error"
			}
		end

		unitTest:assertError(error_func, incompatibleTypeMsg("error", "number", "error"))

		roads = CellularSpace{
			file = filePath("error/".."roads-invalid.shp", "gpm"),
			missing = 0
		}

		communities = CellularSpace{
			file = filePath("communities.shp", "gpm")
		}

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "Line: '7' does not touch any other line. The minimum distance found was: 843.46359196883.")

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end,
				error = 900
			}
		end

		unitTest:assertError(error_func, "The network is disconected.")

		roads = CellularSpace{
			file = filePath("error/".."roads_overlay_points.shp", "gpm"),
			missing = 0
		}

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "Lines '6' and '14' cross each other.")

		local cs = CellularSpace{
			xdim = 20,
			ydim = 25,
			geometry = false
		}

		error_func = function()
			Network{
				lines = cs,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "The CellularSpace in argument 'lines' must be loaded without using argument 'geometry'.")

		error_func = function()
			Network{
				lines = roads,
				target = cs,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "The CellularSpace in argument 'target' must be loaded without using argument 'geometry'.")
	end
}
