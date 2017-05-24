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

local terralib = getPackage("terralib")
local tl = terralib.TerraLib{}

local function buildOpenGPM(self)
	local counterCode = 0
	local numberGeometry = #self.origin

	local neighbors = {}

	forEachCell(self.origin, function(geometryOrigin)
		geometryOrigin.code = counterCode
		geometryOrigin.neighbor = 0
		neighbors[geometryOrigin:getId()] = {}

		local geometry = tl.castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))

		counterCode = counterCode + 1

		if self.progress then
			print("Processing origin "..counterCode.."/"..numberGeometry) -- SKIP
		end

		local centroid = geometry:getCentroid()
		local network = self.network

		local distancePointTarget = math.huge
		local target

		forEachElement(network.distance.netpoint, function(point)
			local distance = self.network.outside(centroid:distance(network.distance.netpoint[point].point)) + network.distance.netpoint[point].distance

			target = network.distance.netpoint[point].targetID
			target = self.destination.cells[target]:getId()

			local currentDistance = neighbors[geometryOrigin:getId()][target]
	
			if currentDistance then
				if distance < currentDistance then
					neighbors[geometryOrigin:getId()][target] = distance
				end
			else
				neighbors[geometryOrigin:getId()][target] = distance
			end
		end)
	end)

	self.neighbor = neighbors
end

local function saveGAL(self, file)
	local validates = false
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0")
	table.insert(outputText, #self.neighbor)
	table.insert(outputText, origin.layer)
	table.insert(outputText, "object_id_")
	file:writeLine(outputText, " ")

	forEachElement(self.neighbor, function(neighbor)
		outputText = {}
		table.insert(outputText, neighbor)
		table.insert(outputText, " ")
		table.insert(outputText, self.neighbor[neighbor])
		table.insert(outputText, "\n")

		forEachElement(self.origin.cells, function(cell)
			if self.origin.cells[cell].neighbor == neighbor then
				table.insert(outputText, self.origin.cells[cell].code)
				table.insert(outputText, " ")
				validates = true
			end
		end)

		if validates then
			file:writeLine(table.concat(outputText))
		end
	end)

	file:close()
end

local function saveGPM(self, file)
	local validates = false
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0 ")
	table.insert(outputText, origin.layer)
	table.insert(outputText, " ")
	table.insert(outputText, origin.layer)
	table.insert(outputText, " object_id_")
	file:writeLine(table.concat(outputText))

	forEachElement(self.neighbor, function(neighbor)
		outputText = {}
		table.insert(outputText, neighbor)
		table.insert(outputText, " ")
		table.insert(outputText, self.neighbor[neighbor])
		table.insert(outputText, "\n")

		forEachElement(self.origin.cells, function(cell)
			if self.origin.cells[cell].neighbor == neighbor then
				table.insert(outputText, self.origin.cells[cell].code)
				table.insert(outputText, " ")
				table.insert(outputText, self.origin.cells[cell][self.output.distance])
				table.insert(outputText, " ")
				validates = true
			end
		end)

		if validates then
			file:writeLine(table.concat(outputText))
		end
	end)

	file:close()
end

local function saveGWT(self, file)
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0 ")
	table.insert(outputText, #self.neighbor)
	table.insert(outputText, " ")
	table.insert(outputText, origin.layer)
	table.insert(outputText, " object_id_")
	file:writeLine(table.concat(outputText))

	forEachElement(self.origin.cells, function(cell)
		outputText = {}
		table.insert(outputText, self.origin.cells[cell].neighbor)
		table.insert(outputText, " ")
		table.insert(outputText, self.origin.cells[cell].code)
		table.insert(outputText, " ")
		table.insert(outputText, self.origin.cells[cell][self.output.distance])
		file:writeLine(table.concat(outputText))
	end)

	file:close()
end

local function buildDistanceRelation(self)
	local destination = self.destination
	local maxDistance = self.distance or math.huge
	local counterCode = 0
	local numberGeometry = #self.origin
	local neighbors = {}

	forEachCell(self.origin, function(geometryOrigin)
		counterCode = counterCode + 1

		if self.progress then
			print("Processing distance "..counterCode.."/"..numberGeometry) -- SKIP
		end

		neighbors[geometryOrigin:getId()] = {}

		local geometry = tl.castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))

		forEachCell(destination, function(polygon)
			local targetPolygon = tl.castGeomToSubtype(polygon.geom:getGeometryN(0))
			local distance = targetPolygon:distance(geometry:getCentroid())

			if --[[targetPolygon:contains(geometry) or]] distance < maxDistance then
				neighbors[geometryOrigin:getId()][polygon:getId()] = distance
			end
		end)
	end)

	self.neighbor = neighbors
end

local function buildBorderRelation(self)
	local origin = self.origin
	local destination = self.destination
	local counterCode = 0
	local numberGeometry = #origin
	local neighbors = {}

	forEachCell(origin, function(polygon)
		counterCode = counterCode + 1

		if self.progress then
			print("Processing intersection "..counterCode.."/"..numberGeometry) -- SKIP
		end

		neighbors[polygon:getId()] = {}

		local geometry = tl.castGeomToSubtype(polygon.geom:getGeometryN(0))
		local geometryPerimeter = geometry:getPerimeter()

		forEachCell(destination, function(neighbor)
			local geometryNeighbor = tl.castGeomToSubtype(neighbor.geom:getGeometryN(0))

			if not geometry:touches(geometryNeighbor) or polygon.FID == neighbor.FID then return end

			local intersection = geometry:intersection(geometryNeighbor)
			local geometryBorder = tl.castGeomToSubtype(intersection)

			if geometryBorder.getLength then
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
	local counterCode = 0
	local numberGeometry = #origin
	local neighbor = {}

	forEachCell(origin, function(polygon)
		local geometryDestination = tl.castGeomToSubtype(polygon.geom:getGeometryN(0))

		counterCode = counterCode + 1

		if self.progress then
			print("Processing contains "..counterCode.."/"..numberGeometry) -- SKIP
		end

		neighbor[polygon:getId()] = {}

		forEachCell(destination, function(point)
			local geometryPoints = tl.castGeomToSubtype(point.geom:getGeometryN(0))

			if geometryDestination:contains(geometryPoints) then
				neighbor[polygon:getId()][point:getId()] = 1
			end
		end)
	end)

	self.neighbor = neighbor
end

local function buildAreaRelation(self)
	local origin = self.origin
	local destination = self.destination
	local counterCode = 0
	local numberGeometry = #origin
	local neighbor = {}

	forEachCell(origin, function(polygon)
		local geometryOrigin = tl.castGeomToSubtype(polygon.geom:getGeometryN(0))

		counterCode = counterCode + 1

		if self.progress then
			print("Processing area "..counterCode.."/"..numberGeometry) -- SKIP
		end

		neighbor[polygon:getId()] = {}

		forEachCell(destination, function(geometric)
			local geometryObject = tl.castGeomToSubtype(geometric.geom:getGeometryN(0))

			if geometryOrigin:touches(geometryObject) or geometryOrigin:intersects(geometryObject) then
				local intersection = geometryOrigin:intersection(geometryObject)
				local geometryIntersection = tl.castGeomToSubtype(intersection)
				local areaIntersection

				if string.find(geometryIntersection:getGeometryType(),"Polygon") then
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
	local counterCode = 0
	local numberGeometry = #origin
	local neighbor = {}

	forEachCell(origin, function(polygon)
		local geometryOrigin = tl.castGeomToSubtype(polygon.geom:getGeometryN(0))

		counterCode = counterCode + 1

		if self.progress then
			print("Processing length "..counterCode.."/"..numberGeometry) -- SKIP
		end

		neighbor[polygon:getId()] = {}

		forEachCell(destination, function(geometric)
			local geometryObject = tl.castGeomToSubtype(geometric.geom:getGeometryN(0))

			if geometryOrigin:touches(geometryObject) or geometryOrigin:intersects(geometryObject) then
				local intersection = geometryOrigin:intersection(geometryObject)
				local geometryIntersection = tl.castGeomToSubtype(intersection)
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
	-- Create attributes in the origin according to the relations established by GPM.
	-- These attributes are created in memory, and must be saved manually
	-- if needed.
	-- @arg data.attribute
	-- @arg data.strategy
	-- @tabular strategy
	-- Strategy & Description & Mandatory Arguments & Optional Arguments \
	-- "count" & Count the number of neighbors & attribute & copy \
	-- "minimum" & Use the minimum value among the available neighbors & attribute & maximum
	-- @arg data.maximum The maximum value.
	-- &arg data.copy An attribute (or a set of attributes) to be copied from the destination
	-- to the origin, given the selected neighbor. It can be a string or a vector of strings
	-- with the attribute names.
	fill = function(self, data)
		verifyNamedTable(data)

		mandatoryTableArgument(data, "attribute", "string")
		mandatoryTableArgument(data, "strategy", "string")
		optionalTableArgument(data, "dummy", "number")
		defaultTableValue(data, "maximum", math.huge)

		if type(data.copy) == "string" then
			data.copy = {data.copy}
		end

		optionalTableArgument(data, "copy", "table")

		local attribute = data.attribute
		local maximum = data.maximum

		switch(data, "strategy"):caseof{
			count = function()
				forEachCell(self.origin, function(cell)
					local value = getn(self.neighbor[cell:getId()])

					if value > maximum then
						value = maximum
					end

					cell[attribute] = value
				end)
			end,
			minimum = function()
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
						value = data.dummy
					end

					if mid ~= nil and data.copy then
						local neigh = self.destination:get(mid)

						forEachElement(data.copy, function(_, value)
							cell[value] = neigh[value]
						end)
					end

					cell[attribute] = value
				end)
			end
		}
	end,
	--- Save the neighborhood into a file.
	-- @arg file A string or a base::File with the name of the file to be saved.
	-- The file can have three extension '.gal', '.gwt', or '.gpm'.
	-- @usage import("gpm")
	-- local roads = CellularSpace{
	--     file = filePath("roads.shp", "gpm"),
	--     geometry = true
	-- }
	--
	-- communities = CellularSpace{
	--     file = filePath("communities.shp", "gpm"),
	--     geometry = true
	-- }
	--
	-- cells = CellularSpace{
	--     file = filePath("cells.shp", "gpm"),
	--     geometry = true
	-- }
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
	--     network = network,
	--     origin = cells,
	--     progress = false,
	--     output = {
	--         id = "id1",
	--         distance = "distance"
	--     }
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

		if self.output.distance == nil or self.output.id == nil then
			mandatoryArgumentError("output.distance and output.id")
		end

		local extension = file:extension()

		-- TODO: switch(extension)
		if extension == "gpm" then
			saveGPM(self, file)
		elseif extension == "gwt" then
			saveGWT(self, file)
		elseif extension == "gal" then
			saveGAL(self, file)
		end
	end
}

metaTableGPM_ = {
	__index = GPM_,
	__tostring = _Gtme.tostring
}

--- Type to create a Generalised Proximity Matrix (GPM).
-- It has several strategies that can use geometry as well as Area, Intersection, Distance and Network.
-- @arg data.distance Distance around to end points (optional).
-- @arg data.destination base::CellularSpace (optional).
-- @arg data.network A Network, containing the destination points (optional).
-- @arg data.origin A base::CellularSpace with geometry representing entry points on the network.
-- @arg data.output Table to receive the output value of the GPM (optional).
-- This table gets two values ID and distance.
-- @arg data.progress print as values are being processed default is true (optional).
-- @arg data.strategy A string with the strategy to be used for creating the GPM (optional).
-- See the table below.
-- @tabular strategy
-- Strategy & Description & Compulsory Arguments & Optional Arguments \
-- "area" & Creates relation between two layer using the intersection areas of their polygons.
-- & destination, origin & progress \
-- "border" & Creates relation between neighboring polygons,
-- each polygon reference his neighbors and the area touched. & strategy, origin & progress \
-- "contains" & Returns which polygons contain the reference points.
-- & destination, origin, strategy & progress \
-- "distance" & Returns the cells within the distance to the nearest centroid,
-- the cells will always be related to the nearest target. &
-- origin, output & distance, network, destination, progress \
-- "length" & Create relations between objects whose intersection is a line.
-- & strategy, origin, destination & progress \
-- @usage import("gpm")
-- local roads = CellularSpace{
--     file = filePath("roads.shp", "gpm"),
--     geometry = true
-- }
--
-- local communities = CellularSpace{
--     file = filePath("communities.shp", "gpm"),
--     geometry = true
-- }
--
-- local cells = CellularSpace{
--     file = filePath("cells.shp", "gpm"),
--     geometry = true
-- }
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
--     network = network,
--     origin = cells,
--     progress = false,
--     output = {
--         id = "id1",
--         distance = "distance"
--     }
-- }
function GPM(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"network", "origin", "distance", "progress", "destination", "strategy"})
	mandatoryTableArgument(data, "origin", "CellularSpace")

	if not data.origin.geometry then
		customError("The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")
	end

	defaultTableValue(data, "progress", true)
	optionalTableArgument(data, "distance", "number")
	optionalTableArgument(data, "strategy", "string")

	if data.output then
		forEachElement(data.output, function(output)
			if output ~= "id" and output ~= "distance" then
				incompatibleValueError("output", "id or distance", output)
			end
		end)
	end

	local function checkDestination()
		mandatoryTableArgument(data, "destination", "CellularSpace")

		if not data.destination.geometry then
			customError("The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")
		end
	end

	if not data.strategy then
		if data.distance or data.network then
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
			if data.destination and data.network then
				customError("It is nos possible to use 'destination' and 'network' arguments together.")
			end

			if data.network then
				mandatoryTableArgument(data, "network", "Network")
				data.destination = data.network.target
				data.neighbors = buildOpenGPM(data)
			else
				defaultTableValue(data, "destination", data.origin)

				checkDestination()

				local cell = data.destination:sample()

				buildDistanceRelation(data)
				return
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
