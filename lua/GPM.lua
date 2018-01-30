-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2016 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.

-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this software and its documentation.
--
-------------------------------------------------------------------------------------------

local function buildOpenGPM(self)
	local neighbors = {}
	local progress = 0

	forEachCell(self.origin, function(cell)
		neighbors[cell:getId()] = {}
		local cellGeom = cell.geom:getGeometryN(0)
		progress = progress + 1

		if self.progress then
			print(table.concat{"Processing origin ", progress, "/", #self.origin}) -- SKIP
		end

		local centroid = cellGeom:getCentroid()
		local network = self.network

		forEachElement(network.netpoints, function(_, netpoint)
			local distance = self.network.outside(centroid:distance(netpoint.point)) + netpoint.distance
			local targetId = tostring(netpoint.targetId)
			local currentDistance = neighbors[cell:getId()][targetId]

			if currentDistance then
				if distance < currentDistance then
					neighbors[cell:getId()][targetId] = distance
				end
			else
				neighbors[cell:getId()][targetId] = distance
			end
		end)
	end)

	self.neighbor = neighbors
end

local function saveGAL(self, file)
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0")
	table.insert(outputText, getn(self.neighbor))
	table.insert(outputText, origin.layer or origin.file)
	table.insert(outputText, "object_id_")
	file:writeLine(table.concat(outputText, " "))

	forEachOrderedElement(self.neighbor, function(idx, neighbor)
		if getn(neighbor) == 0 then return end

		outputText = {}

		table.insert(outputText, idx)
		table.insert(outputText, getn(neighbor))
		file:writeLine(table.concat(outputText, " "))

		outputText = {}

		forEachOrderedElement(neighbor, function(midx)
			table.insert(outputText, midx)
		end)

		file:writeLine(table.concat(outputText, " "))
	end)

	file:close()
end

local function saveGPM(self, file)
	local origin = self.origin
	local destination = self.destination
	local outputText = {}

	table.insert(outputText, getn(self.neighbor))
	table.insert(outputText, origin.layer or origin.file)
	table.insert(outputText, destination.layer or destination.file)
	table.insert(outputText, "object_id_")
	file:writeLine(table.concat(outputText, " "))

	forEachOrderedElement(self.neighbor, function(idx, neighbor)
		if getn(neighbor) == 0 then return end

		outputText = {}

		table.insert(outputText, idx)
		table.insert(outputText, getn(neighbor))
		file:writeLine(table.concat(outputText, " "))

		outputText = {}

		forEachOrderedElement(neighbor, function(midx, weight)
			table.insert(outputText, midx)
			table.insert(outputText, weight)
		end)

		file:writeLine(table.concat(outputText, " "))
	end)

	file:close()
end

local function saveGWT(self, file)
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0")
	table.insert(outputText, getn(self.neighbor))
	table.insert(outputText, origin.layer or origin.file)
	table.insert(outputText, "object_id_")
	file:writeLine(table.concat(outputText, " "))

	forEachOrderedElement(self.neighbor, function(idx, neighbor)
		if getn(neighbor) == 0 then return end

		forEachOrderedElement(neighbor, function(midx, weight)
			outputText = {}

			table.insert(outputText, idx)
			table.insert(outputText, midx)
			table.insert(outputText, weight)
			file:writeLine(table.concat(outputText, " "))
		end)
	end)

	file:close()
end

local function buildDistanceRelation(self)
	local destination = self.destination
	local maxDistance = self.distance or math.huge
	local progress = 0
	local numberGeometry = #self.origin
	local neighbors = {}

	forEachCell(self.origin, function(originCell)
		progress = progress + 1

		if self.progress then
			print(table.concat{"Processing distance ", progress, "/", numberGeometry}) -- SKIP
		end

		neighbors[originCell:getId()] = {}

		local geometry = originCell.geom:getGeometryN(0)

		forEachCell(destination, function(polygon)
			local targetPolygon = polygon.geom:getGeometryN(0)
			local distance = targetPolygon:distance(geometry:getCentroid())

			if --[[targetPolygon:contains(geometry) or]] distance < maxDistance then
				neighbors[originCell:getId()][polygon:getId()] = distance
			end
		end)
	end)

	self.neighbor = neighbors
end

local function buildBorderRelation(self)
	local origin = self.origin
	local destination = self.destination
	local progress = 0
	local numberGeometry = #origin
	local neighbors = {}

	forEachCell(origin, function(polygon)
		progress = progress + 1

		if self.progress then
			print(table.concat{"Processing intersection ", progress, "/", numberGeometry}) -- SKIP
		end

		neighbors[polygon:getId()] = {}

		local geometry = polygon.geom:getGeometryN(0)
		local geometryPerimeter = geometry:getPerimeter()

		forEachCell(destination, function(neighbor)
			local geometryNeighbor = neighbor.geom:getGeometryN(0)

			if not geometry:touches(geometryNeighbor) or polygon.FID == neighbor.FID then return end

			local geometryBorder = geometry:intersection(geometryNeighbor) -- TODO: intersection works with different returns from a same geometry type

			if geometryBorder:getLength() then
				local lengthBorder = geometryBorder:getLength()

				neighbors[polygon:getId()][neighbor:getId()] = lengthBorder / geometryPerimeter
			end
		end)
	end)

	self.neighbor = neighbors
end

local function buildContainsRelation(self)
	local origin = self.origin
	local destination = self.destination
	local progress = 0
	local numberGeometry = #origin
	local neighbor = {}

	forEachCell(origin, function(polygon)
		local geometryOrigin = polygon.geom:getGeometryN(0)

		progress = progress + 1

		if self.progress then
			print(table.concat{"Processing contains ", progress, "/", numberGeometry}) -- SKIP
		end

		neighbor[polygon:getId()] = {}

		forEachCell(destination, function(dest)
			local geometryDestination = dest.geom:getGeometryN(0)

			if geometryOrigin:contains(geometryDestination) then
				neighbor[polygon:getId()][dest:getId()] = 1
			end
		end)
	end)

	self.neighbor = neighbor
end

local function buildAreaRelation(self)
	local origin = self.origin
	local destination = self.destination
	local progress = 0
	local numberGeometry = #origin
	local neighbor = {}

	forEachCell(origin, function(polygon)
		local geometryOrigin = polygon.geom:getGeometryN(0)

		progress = progress + 1

		if self.progress then
			print(table.concat{"Processing area ", progress, "/", numberGeometry}) -- SKIP
		end

		neighbor[polygon:getId()] = {}

		forEachCell(destination, function(geometric)
			local geometryObject = geometric.geom:getGeometryN(0)

			if geometryOrigin:touches(geometryObject) or geometryOrigin:intersects(geometryObject) then
				local geometryIntersection = geometryOrigin:intersection(geometryObject)
				local areaIntersection

				if string.find(geometryIntersection:getGeometryType(), "Polygon") then
					areaIntersection = geometryIntersection:getArea()
				else
					return
				end

				neighbor[polygon:getId()][geometric:getId()] = areaIntersection
			end
		end)
	end)

	self.neighbor = neighbor
end

local function buildLengthRelation(self)
	local origin = self.origin
	local destination = self.destination
	local progress = 0
	local numberGeometry = #origin
	local neighbor = {}

	forEachCell(origin, function(polygon)
		local geometryOrigin = polygon.geom:getGeometryN(0)

		progress = progress + 1

		if self.progress then
			print(table.concat{"Processing length ", progress, "/", numberGeometry}) -- SKIP
		end

		neighbor[polygon:getId()] = {}

		forEachCell(destination, function(geometric)
			local geometryObject = geometric.geom:getGeometryN(0)

			if geometryOrigin:touches(geometryObject) or geometryOrigin:intersects(geometryObject) then
				local geometryIntersection = geometryOrigin:intersection(geometryObject) -- TODO: see above
				local lengthIntersection

				if string.find(geometryIntersection:getGeometryType(), "LineString") then
					lengthIntersection = geometryIntersection:getLength()
				else
					return
				end

				neighbor[polygon:getId()][geometric:getId()] = lengthIntersection
			end
		end)
	end)

	self.neighbor = neighbor
end

GPM_ = {
	type_ = "GPM",
	--- Create attributes in the origin according to the relations established by GPM.
	-- The values of each created attribute is always related to the weights of the
	-- connections in the GPM.
	-- These attributes are created in memory, and must be saved manually afterwards if needed.
	-- @arg data.attribute Name of the attribute to be created.
	-- @arg data.strategy The strategy used to create attributes. See the table below.
	-- @tabular strategy
	-- Strategy & Description & Mandatory Arguments & Optional Arguments \
	-- "all" & Create one attribute for each available destination. The selected attribute name
	-- to be created will be the prefix for the attributes to be created. For each connection
	-- with unique identifier x, one attribute with the selected attribute name followed by _x
	-- will be created. If an origin is not connected to a given destination, the output for
	-- the attribute for the origin will be the value of missing. & attribute & missing \
	-- "average" & Average of all connection weights into one single attribute. Missing values
	-- are set to zero. & attribute & \
	-- "count" & Count the number of neighbors. & attribute & max \
	-- "maximum" & Create an attribute using the maximum value among the weights of the
	-- connections. & attribute & missing, copy \
	-- "minimum" & Create an attribute using the minimum value among the weights of the
	-- connections. & attribute & missing, copy \
	-- "sum" & Sum all the weights into one single attribute. Missing values are set to zero. & attribute & \
	-- @arg data.max An optional number with the maximum output value. If it is greater than max,
	-- then it will be max. The default is math.huge, meaning that there is no limitation on the
	-- maximum value.
	-- @arg data.missing Value of the output used when there is no input value available. The
	-- default value is math.huge for strategy "minimum" and -math.huge for strategy "maximum".
	-- @arg data.copy An attribute (or a set of attributes) to be copied from the destination
	-- to the origin, given the selected neighbor. It can be a string, a vector of strings
	-- with the attribute names, or a named table, where the values represent the attribute names from
	-- the destination and the indexes are the attribute names to be created in the origin.
	-- @usage
	-- import("gpm")
	--
	-- cells = CellularSpace{file = filePath("cells.shp", "gpm")}
	-- farms = CellularSpace{file = filePath("farms.shp", "gpm")}
	--
	-- gpm = GPM{
	--     origin = cells,
	--     strategy = "area",
	--     destination = farms,
	--     progress = false
	-- }
	--
	-- gpm:fill{
	--     strategy = "count",
	--     attribute = "quantity",
	--     max = 5
	-- }
	--
	-- map = Map{
	--     target = gpm.origin,
	--     select = "quantity",
	--     min = 0,
	--     max = 5,
	--     slices = 6,
	--     color = "Reds"
	-- }
	fill = function(self, data)
		verifyNamedTable(data)

		mandatoryTableArgument(data, "attribute", "string")
		mandatoryTableArgument(data, "strategy", "string")

		verifyUnnecessaryArguments(data, {"attribute", "missing", "copy", "max", "strategy"})

		if type(data.copy) == "string" then
			data.copy = {data.copy}
		end

		optionalTableArgument(data, "copy", "table")

		local attribute = data.attribute

		if data.strategy ~= "all" and self.origin.cells[1][data.attribute] ~= nil then
			customWarning("Attribute '"..data.attribute.."' already exists in 'origin'.")
		end

		if data.copy then
			forEachOrderedElement(data.copy, function(idx, name)
				if type(idx) == "number" then
					if self.origin.cells[1][name] ~= nil then
						customWarning("Attribute '"..name.."' already exists in 'origin'.")
					end
				elseif self.origin.cells[1][idx] ~= nil then
					customWarning("Attribute '"..idx.."' already exists in 'origin'.")
				end

				if self.destination.cells[1][name] == nil then
					customWarning("Attribute '"..name.."' to be copied does not exist in 'destination'.")
				end
			end)
		end

		switch(data, "strategy"):caseof{
			all = function()
				verifyUnnecessaryArguments(data, {"attribute", "missing", "strategy"})
				local tattr = {}

				forEachCell(self.origin, function(cell)
					forEachElement(self.neighbor[cell:getId()], function(id, dist)
						if not tattr[id] then
							tattr[id] = attribute.."_"..id
						end

						cell[tattr[id]] = dist
					end)
				end)

				forEachCell(self.origin, function(cell)
					forEachElement(tattr, function(_, attr)
						if cell[attr] == nil then
							cell[attr] = data.missing -- SKIP
						end
					end)
				end)
			end,
			count = function()
				defaultTableValue(data, "max", math.huge)
				local max = data.max

				verifyUnnecessaryArguments(data, {"attribute", "max", "strategy"})

				forEachCell(self.origin, function(cell)
					local value = getn(self.neighbor[cell:getId()])

					if value > max then
						value = max
					end

					cell[attribute] = value
				end)
			end,
			minimum = function()
				defaultTableValue(data, "missing", math.huge)

				verifyUnnecessaryArguments(data, {"attribute", "missing", "copy", "strategy"})

				forEachCell(self.origin, function(cell)
					local value = math.huge
					local mid

					forEachElement(self.neighbor[cell:getId()], function(id, dist)
						if dist < value then
							value = dist
							mid = id
						end
					end)

					if value == math.huge then
						value = data.missing
					end

					if mid ~= nil and data.copy then
						local neigh = self.destination:get(mid)

						forEachElement(data.copy, function(idx, mvalue)
							if type(idx) == "number" then
								cell[mvalue] = neigh[mvalue]
							else
								cell[idx] = neigh[mvalue]
							end
						end)
					end

					cell[attribute] = value
				end)
			end,
			maximum = function()
				defaultTableValue(data, "missing", -math.huge)

				verifyUnnecessaryArguments(data, {"attribute", "missing", "copy", "strategy"})

				forEachCell(self.origin, function(cell)
					local value = -math.huge
					local mid

					forEachElement(self.neighbor[cell:getId()], function(id, dist)
						if dist > value then
							value = dist
							mid = id
						end
					end)

					if value == -math.huge then
						value = data.missing -- SKIP
					end

					if mid ~= nil and data.copy then
						local neigh = self.destination:get(mid)

						forEachElement(data.copy, function(idx, mvalue)
							if type(idx) == "number" then
								cell[mvalue] = neigh[mvalue]
							else
								cell[idx] = neigh[mvalue]
							end
						end)
					end

					cell[attribute] = value
				end)
			end,
			sum = function()
				verifyUnnecessaryArguments(data, {"attribute", "strategy"})

				forEachCell(self.origin, function(cell)
					local sum = 0

					forEachElement(self.neighbor[cell:getId()], function(_, dist)
						sum = sum + dist
					end)

					cell[attribute] = sum
				end)
			end,
			average = function()
				verifyUnnecessaryArguments(data, {"attribute", "strategy"})

				forEachCell(self.origin, function(cell)
					local sum = 0
					local neighbor = self.neighbor[cell:getId()]

					forEachElement(neighbor, function(_, dist)
						sum = sum + dist
					end)

					cell[attribute] = sum / getn(neighbor)
				end)
			end
		}
	end,
	--- Save the GPM into a neighborhood file.
	-- @arg file A string or a base::File with the name of the file to be saved.
	-- Three extensions are allowed: '.gal', '.gwt', or '.gpm'.
	-- @usage import("gpm")
	--
	-- roads = CellularSpace{file = filePath("roads.shp", "gpm")}
	-- communities = CellularSpace{file = filePath("communities.shp", "gpm")}
	-- cells = CellularSpace{file = filePath("cells.shp", "gpm")}
	--
	-- network = Network{
	--     lines = roads,
	--     target = communities,
	--     progress = false,
	--     weight = function(distance, cell)
	--         if cell.STATUS == "paved" then
	--             return distance / 5
	--         else
	--             return distance / 2
	--         end
	--     end,
	--     outside = function(distance)
	--         return distance * 2
	--     end
	-- }
	--
	-- gpm = GPM{
	--     destination = network,
	--     origin = cells,
	--     progress = false,
	-- }
	--
	-- gpm:save("cells.gpm")
	save = function(self, file)
		if type(file) == "string" then
			file = File(file)
		end

		if type(file) ~= "File" then
			incompatibleTypeError("file", "string or File", file)
		end

		local data = {extension = file:extension()}

		local singleLayer = function()
			if self.origin ~= self.destination then
				customError("File type '"..file:extension().."' does not support connections between two CellularSpaces. Use 'gpm' format instead.")
			end
		end

		switch(data, "extension"):caseof{
			gpm = function()               saveGPM(self, file) end,
			gwt = function() singleLayer() saveGWT(self, file) end,
			gal = function() singleLayer() saveGAL(self, file) end
		}
	end
}

metaTableGPM_ = {
	__index = GPM_,
	__tostring = _Gtme.tostring
}

--- Type to create a Generalised Proximity Matrix (GPM).
-- GPM is a concept used to establish relations between geographical objects.
-- It has several strategies to define how two objects are connected, from basic
-- geographical relations such as intersection area and border to (for instance) road Networks.
-- The relations created by GPM are not stored in extenal sources nor in attributes of the
-- CellularSpaces it connects. It is necessary to use some functions of this type in order
-- to create attributes or neighborhoods and to save the output.
-- @arg data.distance Maximum distance allowed to connect an origin to a destination.
-- @arg data.destination A base::CellularSpace or a Network, containing the destination points.
-- The GPM will connect the objects from the origin to the destination.
-- It is possible to use the origin as destination as well.
-- @arg data.origin A base::CellularSpace representing the objects to be connected.
-- @arg data.progress Optional boolean value indicating whether GPM will print messages
-- while processing values. The default value is true.
-- @arg data.strategy An optional string with the strategy to create a GPM.
-- See the table below.
-- @tabular strategy
-- Strategy & Description & Compulsory Arguments & Optional Arguments \
-- "area" & Create relations between objects that have intersection areas. This
-- strategy can only be used with objects represented as polygons.
-- The weight of each relation is the intersection area.
-- & destination, origin & progress \
-- "border" & Create relations between polygons that share borders. The weight
-- of each relation is the length of the intersection border divided by the perimeter
-- of the origin, which is a value between zero and one. & strategy, origin & progress \
-- "contains" & Connect a destination to an origin that contains it. It requires that
-- both origin and destination are represented as polygons. The weight of each relation
-- will be one. & destination, origin, strategy & progress \
-- "distance" & Connects all objects from the origin to the destination according to their
-- distances. If the argument distance is used, then only the objects that have distance
-- less than this value are connected. The weight of the relation will be the distance
-- between the two objects. & origin, destination & distance, progress \
-- "length" & Create relations between polygons that share borders. The weight
-- of each relation is the length of the intersection border. &
-- strategy, origin, destination & progress \
-- @usage import("gpm")
--
-- roads = CellularSpace{file = filePath("roads.shp", "gpm")}
-- communities = CellularSpace{file = filePath("communities.shp", "gpm")}
-- cells = CellularSpace{file = filePath("cells.shp", "gpm")}
--
-- network = Network{
--     lines = roads,
--     target = communities,
--     progress = false,
--     weight = function(distance, cell)
--         if cell.STATUS == "paved" then
--             return distance / 5
--         else
--             return distance / 2
--         end
--     end,
--     outside = function(distance)
--         return distance * 2
--     end
-- }
--
-- gpm = GPM{
--     destination = network,
--     origin = cells,
--     progress = false,
--     output = {
--         id = "id1",
--         distance = "distance"
--     }
-- }
function GPM(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"origin", "distance", "progress", "destination", "strategy"})
	mandatoryTableArgument(data, "origin", "CellularSpace")

	if data.origin.geometry == false then
		customError("The CellularSpace in argument 'origin' must be loaded without using argument 'geometry'.")
	end

	defaultTableValue(data, "progress", true)
	optionalTableArgument(data, "distance", "number")
	optionalTableArgument(data, "strategy", "string")

	local function checkDestination()
		mandatoryTableArgument(data, "destination", "CellularSpace")

		if data.destination.geometry == false then
			customError("The CellularSpace in argument 'destination' must be loaded without using argument 'geometry'.")
		end
	end

	if not data.strategy then
		if data.distance or type(data.destination) == "Network" then
			data.strategy = "distance"
		else
			customError("Could not infer value for mandatory argument 'strategy'.")
		end
	end

	switch(data, "strategy"):caseof{
		border = function()
			defaultTableValue(data, "destination", data.origin)
			verifyUnnecessaryArguments(data, {"origin", "progress", "destination", "strategy"})
			checkDestination()
			local cell = data.origin:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiPolygon") then
				customError("Argument 'origin' should be composed by 'MultiPolygon', got '"..cell.geom:getGeometryType().."'.")
			end

			buildBorderRelation(data)
		end,
		contains = function()
			checkDestination()
			verifyUnnecessaryArguments(data, {"origin", "progress", "destination", "strategy"})
			local cell = data.origin:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiPolygon") then
				customError("Argument 'origin' should be composed by 'MultiPolygon', got '"..cell.geom:getGeometryType().."'.")
			end

			cell = data.destination:sample()

			if  not string.find(cell.geom:getGeometryType(), "MultiPoint") then
				customError("Argument 'destination' should be composed by 'MultiPoint', got '"..cell.geom:getGeometryType().."'.")
			end

			buildContainsRelation(data)
		end,
		length = function()
			checkDestination()
			verifyUnnecessaryArguments(data, {"origin", "progress", "destination", "strategy"})
			local cell = data.destination:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiLineString") then
				customError("Argument 'destination' should be composed by 'MultiLineString', got '"..cell.geom:getGeometryType().."'.")
			end

			buildLengthRelation(data)
		end,
		distance = function()
			if type(data.destination) == "Network" then
				data.network = data.destination
				data.destination = data.network.target
				buildOpenGPM(data)
			else
				defaultTableValue(data, "destination", data.origin)
				checkDestination()
				buildDistanceRelation(data)
			end
		end,
		area = function()
			defaultTableValue(data, "destination", data.origin)
			verifyUnnecessaryArguments(data, {"origin", "progress", "destination", "strategy"})
			checkDestination()
			local cell = data.destination:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiPolygon") then
				customError("Argument 'destination' should be composed by 'MultiPolygon', got '"..cell.geom:getGeometryType().."'.")
			end

			buildAreaRelation(data)
		end
	}

	setmetatable(data, metaTableGPM_)

	return data
end
