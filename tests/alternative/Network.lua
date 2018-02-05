
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
			file = filePath("error/roads-invalid.shp", "gpm"),
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

		local gis = getPackage("gis")

		local proj = gis.Project{
			file = "network_alt.tview",
			clean = true,
			author = "Avancini",
			title = "Error Report"
		}

		local roadsLayer =  gis.Layer{
			project = proj,
			name = "roads",
			file = filePath("error/roads-invalid.shp", "gpm")
		}

		local roadsCurrDir = "roads-invalid.shp"

		local data = {
			file = roadsCurrDir,
			overwrite = true
		}

		roadsLayer:export(data)

		local roadsLayerCurrDir = gis.Layer{
			project = proj,
			name = "roadsCurrDir",
			file = roadsCurrDir
		}

		local roadsCs = CellularSpace{project = proj, layer = roadsLayerCurrDir.name, missing = 0}

		local disconnWithProjectError = function()
			Network{
				lines = roadsCs,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance end,
				error = 900
			}
		end

		unitTest:assertError(disconnWithProjectError, "The network is disconnected. It was created a new Layer 'neterror' in the project with a new attribute 'net_id' for analysis.")

		local neterrorLayer = gis.Layer{
			project = proj,
			name = "neterror"
		}

		local attrs = neterrorLayer:attributes()
		unitTest:assertEquals(attrs[19].name, "net_id")

		proj.file:delete()
		File(neterrorLayer.file):delete()

		roads = CellularSpace{
			file = roadsCurrDir,
			missing = 0
		}

		local disconnectedError = function()
			Network{
				lines = roads,
				target = communities,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end,
				error = 900
			}
		end

		unitTest:assertError(disconnectedError, "The network is disconnected. It was created a new data 'neterror.shp' with a new attribute 'net_id' for analysis.")

		local neterror = CellularSpace{
			file = "neterror.shp",
			missing = 0
		}

		unitTest:assertNotNil(neterror:sample().net_id)

		File(roadsCurrDir):delete()
		neterror.file:delete()
	end
}
