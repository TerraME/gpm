
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
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "Line '7' does not touch any other line. The minimum distance found was: 843.46359196883. If the distance is small, set the error argument, otherwise, correct the line.")

		roads = CellularSpace{
			file = filePath("error/".."roads_overlay_points.shp", "gpm"),
			missing = 0
		}

		error_func = function()
			Network{
				lines = roads,
				target = communities,
				progress = false,
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
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "The CellularSpace in argument 'lines' must be loaded without using argument 'geometry'.")

		error_func = function()
			Network{
				lines = roads,
				target = cs,
				progress = false,
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
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance end,
				error = 900
			}
		end

		unitTest:assertError(disconnWithProjectError, "The network is disconnected. Layer 'neterror' was automatically created with attribute 'net_id' containing the separated networks.")

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
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end,
				error = 900
			}
		end

		unitTest:assertError(disconnectedError, "The network is disconnected. Data 'neterror.shp' was automatically created with attribute 'net_id' containing the separated networks.")

		local neterror = CellularSpace{
			file = "neterror.shp",
			missing = 0
		}

		unitTest:assertNotNil(neterror:sample().net_id)

		File(roadsCurrDir):delete()
		neterror.file:delete()

		local roadsSouth = CellularSpace{
			file = filePath("test/roads_sirgas2000_south3.shp", "gpm")
		}

		local ports = CellularSpace{
			file = filePath("test/porto_alegre_sirgas2000.shp", "gpm"),
			missing = 0
		}

		local errorArgumentError = function()
			Network{
				lines = roadsSouth,
				target = ports,
				progress = false,
				error = 400,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}
		end

		unitTest:assertError(errorArgumentError, "Line '47' was added because the value of argument 'error: 400'. Remove the error argument and correct the lines disconnected.")
	end,
	distances = function(unitTest)
		local roads = CellularSpace{
			file = filePath("test/roads_sirgas2000_south3.shp", "gpm")
		}

		local ports = CellularSpace{
			file = filePath("test/porto_alegre_sirgas2000.shp", "gpm"),
			missing = 0
		}

		local network = Network{
			lines = roads,
			target = ports,
			progress = false,
			inside = function(distance)
				return distance
			end,
			outside = function(distance)
				return distance * 4
			end
		}

		local pointParameterError = function()
			network:distances(123, "lines")
		end
		unitTest:assertError(pointParameterError, incompatibleTypeMsg(1, "Cell", 123))

		local port = ports:get("0")

		local entranceParameterError = function()
			network:distances(port, true)
		end
		unitTest:assertError(entranceParameterError, incompatibleTypeMsg(2, "string", true))

		local invalidEntranceError = function()
			network:distances(port, "rtree")
		end
		unitTest:assertError(invalidEntranceError, "Attribute 'entrance' must be 'lines' or 'points', but received 'rtree'.")
	end
}
