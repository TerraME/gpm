
return {
	Network = function(unitTest)
		local argumentErrorTests = function()
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
		end

		argumentErrorTests()

		local error_func = function()
			local roads = CellularSpace{
				file = filePath("error/roads-invalid.shp", "gpm"),
				missing = 0
			}

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "Line '7' does not touch any other line. The minimum distance found was: 843.46359196883. If this distance can be ignored, use argument 'error'. Otherwise, fix the line.")

		error_func = function()
			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local roads = CellularSpace{
				file = filePath("error/".."roads_overlay_points.shp", "gpm"),
				missing = 0
			}

			Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "Lines '6' and '14' cross each other.")

		error_func = function()
			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local cs = CellularSpace{
				xdim = 20,
				ydim = 25,
				geometry = false
			}

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
			local cs = CellularSpace{
				xdim = 20,
				ydim = 25,
				geometry = false
			}

			local roads = CellularSpace{
				file = filePath("error/".."roads_overlay_points.shp", "gpm"),
				missing = 0
			}

			Network{
				lines = roads,
				target = cs,
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(error_func, "The CellularSpace in argument 'target' must be loaded without using argument 'geometry'.")

		local disconnectedNetworkTest = function()
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

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

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

			local disconnectedError = function()
				local roads = CellularSpace{
					file = roadsCurrDir,
					missing = 0
				}

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
		end

		disconnectedNetworkTest()

		local lineCrossesError = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_south8.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/port_antonina_sirgas2000.shp", "gpm"),
				missing = 0
			}

			Network{
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
		end

		unitTest:assertError(lineCrossesError, "Line '26' crosses touching lines '20' and '18' in their endpoints. Please, split line '26' in two where they cross.")

		local unexpecteError = function()
			local roads = CellularSpace{
				file = filePath("error/roads-invalid.shp", "gpm"),
				missing = 0
			}

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			Network{
				lines = roads,
				target = communities,
				validate = false,
				progress = false,
				inside = function(distance) return distance end,
				outside = function(distance) return distance * 2 end
			}
		end

		unitTest:assertError(unexpecteError, "Unexpected error with lines {2, 3, 7, 13}. If you have already validated your data, report this error to system developers.")

		local unexpecteError2 = function()
			local roadsSouth = CellularSpace{
				file = filePath("test/roads_invalid_sirgas2000_south1.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/port_antonina_sirgas2000.shp", "gpm"),
				missing = 0
			}

			Network{
				lines = roadsSouth,
				target = ports,
				progress = false,
				validate = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}
		end

		unitTest:assertError(unexpecteError2, "Unexpected error with line '1'. If you have already validated your data, report this error to system developers.")
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
		unitTest:assertError(invalidEntranceError, "Attribute 'entrance' must be 'closest' or 'lightest', but received 'rtree'.")
	end
}
