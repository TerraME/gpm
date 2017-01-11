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

-- Strategy 'network'
local function addOutputID(ID, geometry, polygonID)
	geometry[polygonID] = ID
end

local function addOutputDistance(distanceTarget, geometry, polygonDistance)
	geometry[polygonDistance] = distanceTarget
end

local function addOutput(self, geometry)
	local reference = 0

	if self.output then
		if self.output.id then
			reference = 1

			geometry[self.output.id] = {}
		end

		if self.output.distance then
			geometry[self.output.distance] = {}

			if reference == 1 then
				reference = 3
			else
				reference = 2
			end
		end
	end

	return reference
end

local function buildPointTarget(self, reference, network, centroid, geometry)
	local distancePointTarget = math.huge
	local target

	forEachElement(network.distance.netpoint, function(point)
		local distance = self.network.outside(centroid:distance(network.distance.netpoint[point].point)) + network.distance.netpoint[point].distance

		if distance < distancePointTarget then
			target = network.distance.netpoint[point].targetID
			distancePointTarget = distance
		end

		distance = self.network.outside(centroid:distance(network.distance.netpoint[point].point)) + network.distance.netpoint[point].distanceOutside

		if distance < distancePointTarget then
			target = network.distance.netpoint[point].targetIDOutside
			distancePointTarget = distance
		end
	end)

	geometry.neighbor = target

	if self.neighbor[target] == nil then
		self.neighbor[target] = 1
	else
		self.neighbor[target] = self.neighbor[target] + 1
	end

	if reference == 1 then
		addOutputID(target, geometry, self.output.id)
	elseif reference == 2 then
		addOutputDistance(distancePointTarget, geometry, self.output.distance) -- SKIP
	elseif reference == 3 then
		addOutputID(target, geometry, self.output.id)
		addOutputDistance(distancePointTarget, geometry, self.output.distance)
	end
end

local function getDistanceInputPoint(self, centroid, network, geometry)
	local reference = addOutput(self, geometry)

	buildPointTarget(self, reference, network, centroid, geometry)
end

local function createOpenGPM(self)
	local counterCode = 0
	local numberGeometry = #self.origin

	self.neighbor = {}

	forEachCell(self.origin, function(geometryOrigin)
		geometryOrigin.code = counterCode
		geometryOrigin.neighbor = 0

		local geometry = tl:castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))

		getDistanceInputPoint(self, geometry:getCentroid(), self.network, geometryOrigin)
		counterCode = counterCode + 1

		if self.progress then
			print("Processing origin "..counterCode.."/"..numberGeometry) -- SKIP
		end
	end)
end

local function saveGAL(self, file)
	local validates = false
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0 ")
	table.insert(outputText, #self.neighbor)
	table.insert(outputText, " ")
	table.insert(outputText, origin.layer)
	table.insert(outputText, " object_id_\n")


	forEachElement(self.neighbor, function(neighbor)
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
			table.insert(outputText, "\n")
		end
	end)

	file:write(table.concat(outputText))
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
	table.insert(outputText, " object_id_\n")

	forEachElement(self.neighbor, function(neighbor)
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
			table.insert(outputText, "\n")
		end
	end)

	file:write(table.concat(outputText))
	file:close()
end

local function saveGWT(self, file)
	local origin = self.origin
	local outputText = {}

	table.insert(outputText, "0 ")
	table.insert(outputText, #self.neighbor)
	table.insert(outputText, " ")
	table.insert(outputText, origin.layer)
	table.insert(outputText, " object_id_\n")

	forEachElement(self.origin.cells, function(cell)
		table.insert(outputText, self.origin.cells[cell].neighbor)
		table.insert(outputText, " ")
		table.insert(outputText, self.origin.cells[cell].code)
		table.insert(outputText, " ")
		table.insert(outputText, self.origin.cells[cell][self.output.distance])
		table.insert(outputText, "\n")
	end)

	file:write(table.concat(outputText))
	file:close()
end

-- Strategy 'distance'
local function geometryClosestToPoint(geometryOrigin, target, maxDist)
	local geometry = tl:castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))
	local distanceTarget = math.huge

	forEachCell(target, function(point)
		local targetPoint = tl:castGeomToSubtype(point.geom:getGeometryN(0))
		local distanceToTarget = geometry:distance(targetPoint)

		if distanceToTarget < maxDist and distanceToTarget < distanceTarget then
			distanceTarget = distanceToTarget
			geometryOrigin.pointID = point.pointID
		end
	end)
end

local function buildRelationBetweenPolygons(self, polygon, pointID, targetPoint)
	forEachCell(self.origin, function(geometryOrigin)
		local geometry = tl:castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))
		local distanceToTarget = geometry:distance(targetPoint)

		if polygon:contains(geometry) or polygon:intersects(geometry) and geometryOrigin.distanceToTarget > distanceToTarget then
			geometryOrigin.pointID = pointID
			geometryOrigin.distanceToTarget = distanceToTarget
		end
	end)
end

local function distancePointToTarget(self)
	local maxDist = self.distance

	if self.destination == nil then
		forEachCell(self.origin, function(geometryOrigin)
			geometryOrigin.pointID = 0
			geometryClosestToPoint(geometryOrigin, self.network.target, maxDist)
		end)
	else
		forEachCell(self.origin, function(geometryOrigin)
			geometryOrigin.pointID = 0
			geometryOrigin.distanceToTarget = math.huge
		end)

		forEachCell(self.destination, function(polygon)
			local geometryPolygon = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))
			local centroid = geometryPolygon:getCentroid()

			polygon.distance = math.huge

			forEachCell(self.network.target, function(point)
				local targetPoint = tl:castGeomToSubtype(point.geom:getGeometryN(0))
				local distanceToTarget = centroid:distance(targetPoint)

				if distanceToTarget <= maxDist and polygon.distance > distanceToTarget then
					buildRelationBetweenPolygons(self, geometryPolygon, point.pointID, targetPoint)
					polygon.distance = distanceToTarget
				end
			end)
		end)
	end
end

local function createRelationByQuantity(self)
	forEachCell(self.origin, function(geometryOrigin)
		geometryOrigin.pointID = 0
		geometryOrigin.distanceToTarget = math.huge
	end)

	local quantity = self.quantity

	forEachCell(self.network.target, function(point)
		local targetPoint = tl:castGeomToSubtype(point.geom:getGeometryN(0))

		point.vectorKeysOfPolygons = {}
		point.polygonVector = {}

		forEachCell(self.destination, function(polygon)
			local geometryPolygon = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))
			local centroid = geometryPolygon:getCentroid()
			local distanceToTarget = centroid:distance(targetPoint)

			point.polygonVector[distanceToTarget] = geometryPolygon
			table.insert(point.vectorKeysOfPolygons, distanceToTarget)
		end)

		table.sort(point.vectorKeysOfPolygons)

		forEachElement(point.vectorKeysOfPolygons, function(keyToPolygon)
			if quantity >= keyToPolygon then
				buildRelationBetweenPolygons(self, point.polygonVector[point.vectorKeysOfPolygons[keyToPolygon]], point.pointID, targetPoint)
			end
		end)
	end)
end
-- Strategy 'area'
local function geometryClosestToCells(geometryOrigin, destination)
	local geometry = tl:castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))

	forEachCell(destination, function(polygon)
		local targetPolygon = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))
		local differenceGeometry = targetPolygon:distance(geometry:getCentroid())

		if targetPolygon:contains(geometry) or differenceGeometry < geometryOrigin.dimensionValue then
			geometryOrigin.cellID = polygon.valueColor
			geometryOrigin.dimensionValue = differenceGeometry
		end
	end)
end

local function distanceCellToTarget(self)
	local valueColor = 1
	local destination = self.destination

	forEachCell(destination, function(polygon)
		polygon.valueColor = valueColor
		valueColor = valueColor + 1

		if valueColor == 5 then
			valueColor = 1
		end
	end)

	forEachCell(self.origin, function(geometryOrigin)
		geometryOrigin.dimensionValue = math.huge
		geometryOrigin.cellID = 0
		geometryClosestToCells(geometryOrigin, destination)
	end)
end

-- Strategy 'intersection'
local function calculateWeightNeighbors(polygon)
	local geometry = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))
	local geometryPerimeter = geometry:getPerimeter()

	forEachElement(polygon.neighbors, function(polygonNeighbor)
		local neighbor = polygon.neighbors[polygonNeighbor]
		local geometryNeighbor = tl:castGeomToSubtype(neighbor.geom:getGeometryN(0))
		local intersection = geometry:intersection(geometryNeighbor)
		local geometryBorder = tl:castGeomToSubtype(intersection)
		local lengthBorder = geometryBorder:getLength()

		polygon.perimeterBorder[neighbor] = (math.modf((lengthBorder / geometryPerimeter) * 100)) / 100
		polygon.intersectionNeighbors[neighbor] = lengthBorder
	end)
end

local function definingNeighbors(polygonOrigin, polygon, quantity)
	local geometry = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))

	forEachCell(polygonOrigin, function(polygonBorder)
		local geometryBorder = tl:castGeomToSubtype(polygonBorder.geom:getGeometryN(0))

		if geometry:touches(geometryBorder) and polygon.FID ~= polygonBorder.FID and quantity > #polygon.neighbors then
			table.insert(polygon.neighbors, polygonBorder)
		end
	end)

	calculateWeightNeighbors(polygon)
end

local function neighborhoodOfPolygon(self)
	local polygonOrigin = self.origin
    local quantity = math.huge

	if self.quantity then
		quantity = self.quantity
	end

	forEachCell(polygonOrigin, function(polygon)
		polygon.neighbors = {}
		polygon.intersectionNeighbors = {}
		polygon.perimeterBorder = {}
		definingNeighbors(polygonOrigin, polygon, quantity)
	end)
end

-- 'contains'
local function relationBetweenPolygonsAndPoints(self)
	local polygonOrigin = self.origin
	local points = self.destination

	forEachCell(polygonOrigin, function(polygon)
		local geometryDestination = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))

		polygon.contains = {}

		forEachCell(points, function(point)
			local geometryPoints = tl:castGeomToSubtype(point.geom:getGeometryN(0))

			if geometryDestination:contains(geometryPoints) then
				table.insert(polygon.contains, point)
			end
		end)
	end)
end

-- 'length'
local function buildRelation(self)
	local polygonOrigin = self.origin
	local geometricObject = self.destination
	local geometricCounter = 0
	local length

	forEachCell(polygonOrigin, function(polygon)
		local geometryOrigin = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))

		polygon.intersection = {}
		polygon.lengthIntersection = {}

		forEachCell(geometricObject, function(geometric)
			local geometryObject = tl:castGeomToSubtype(geometric.geom:getGeometryN(0))

			if geometryOrigin:touches(geometryObject) or geometryOrigin:intersects(geometryObject) then
				local intersection = geometryOrigin:intersection(geometryObject)
				local geometryIntersection = tl:castGeomToSubtype(intersection)
				local lengthIntersection

				if string.find(geometryIntersection:getGeometryType(), "LineString") then
					lengthIntersection = geometryIntersection:getLength()
				elseif string.find(geometryIntersection:getGeometryType(),"Polygon") then
					lengthIntersection = geometryIntersection:getArea()
                else
                    return
				end

				table.insert(polygon.intersection, intersection)
				polygon.lengthIntersection[intersection] = lengthIntersection
			end
		end)

	geometricCounter = 0
	end)
end

GPM_ = {
	type_ = "GPM",
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
	-- farms = CellularSpace{
	--     file = filePath("farms_cells.shp", "gpm"),
	--     geometry = true
	-- }
	--
	-- network = Network{
	--     lines = roads,
	--     target = communities,
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
	--     origin = farms,
	--     relation = "community",
	--     output = {
	--         id = "id1",
	--         distance = "distance"
	--     }
	-- }
	--
	-- gpm:save("farms.gpm")
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
	__index = GPM_
}

--- Type to create a Generalised Proximity Matrix (GPM).
-- It has several strategies that can use geometry as well as Area, Intersection, Distance and Network.
-- @arg data.distance Distance around to end points (optional).
-- @arg data.destination base::CellularSpace (optional).
-- @arg data.network A base::CellularSpace that receives end points of the networks (optional).
-- @arg data.origin A base::CellularSpace with geometry representing entry points on the network.
-- @arg data.output Table to receive the output value of the GPM (optional).
-- This table gets two values ID and distance.
-- @arg data.progress print as values are being processed (optional).
-- @arg data.quantity relation between geometries (optional).
-- @arg data.relation --.
-- @arg data.strategy A string with the strategy to be used for creating the GPM (optional).
-- See the table below.
-- @tabular strategy
-- Strategy & Description & Compulsory Arguments & Optional Arguments \
-- "area" & Creates relation between two layer using the intersection areas of their polygons.
-- & destination, origin & \
-- "intersection" & Creates relation between neighboring polygons,
-- each polygon reference his neighbors and the area touched. & strategy, origin & quantity \
-- "contains" & Returns which polygons contain the reference points.
-- & destination, origin, strategy & \
-- "distance" & Returns the cells within the distance to the nearest centroid,
-- the cells will always be related to the nearest target. &
-- distance, origin, network, destination, output, quantity & progress \
-- "length" & Create relations between objects whose intersection is a line.
-- & strategy, origin, destination & \
-- "network" & Creates relation between network and cellularSpace,
-- each point of the network receives the reference to the nearest destination.
-- & output, network, distance, origin, relation & progress, quantity \
-- @output GPM based on network and target points.
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
-- local farms = CellularSpace{
--     file = filePath("farms_cells.shp", "gpm"),
--     geometry = true
-- }
--
-- network = Network{
--     lines = roads,
--     target = communities,
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
-- local gpm = GPM{
--     network = network,
--     origin = farms,
--     relation = "community",
--     output = {
--         id = "id1",
--         distance = "distance"
--     }
-- }
function GPM(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"network", "origin", "quantity", "distance", "relation", "output", "progress", "destination", "strategy"})
	mandatoryTableArgument(data, "origin", "CellularSpace")

	if not data.origin.geometry then
		customError("The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")
	end

	if data.network then
		mandatoryTableArgument(data, "network", "Network")
		data.neighbors = createOpenGPM(data)
	end

	defaultTableValue(data, "progress", false)

	mandatoryTableArgument(data, "progress", "boolean")

	optionalTableArgument(data, "relation", "string")

	if data.output then
		forEachElement(data.output, function(output)
			if output ~= "id" and output ~= "distance" then
				incompatibleValueError("output", "id or distance", output)
			end
		end)
	end

	if data.destination and data.strategy == "length" then
		if data.destination.geometry then
			local cell = data.destination:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiPolygon") and not string.find(cell.geom:getGeometryType(), "MultiLineString") then
				customError("Argument 'destination' should be composed by MultiPolygon or MultiLineString, got '"..cell.geom:getGeometryType().."'.")
			end
		else
			customError("The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")
		end

		buildRelation(data)
	end

	if data.strategy == "intersection" or data.strategy == "contains" then
		if data.origin.geometry then
			local cell = data.origin:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiPolygon") then
				customError("Argument 'origin' should be composed by MultiPolygon, got '"..cell.geom:getGeometryType().."'.")
			end
		end

		if data.strategy == "intersection" then
			if data.quantity then
				mandatoryTableArgument(data, "quantity", "number")
			end

			neighborhoodOfPolygon(data)
		else
			mandatoryTableArgument(data, "destination", "CellularSpace")

			if data.destination.geometry then
				local cell = data.destination:sample()

				if  not string.find(cell.geom:getGeometryType(), "MultiPoint") then
					customError("Argument 'destination' should be composed by MultiPoint, got '"..cell.geom:getGeometryType().."'.")
				end
			else
				customError("The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")
			end

			relationBetweenPolygonsAndPoints(data)
		end
	end

	if data.distance or data.quantity and data.destination then
		if data.destination then
		mandatoryTableArgument(data, "destination", "CellularSpace")

			if data.destination.geometry then
				local cell = data.destination:sample()

				if not string.find(cell.geom:getGeometryType(), "MultiPolygon") then
					customError("Argument 'destination' should be composed by MultiPolygon, got '"..cell.geom:getGeometryType().."'.")
				end
			else
				customError("The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")
			end
		end

		if data.distance and data.quantity == nil then
			mandatoryTableArgument(data, "distance", "number")
			distancePointToTarget(data)
		elseif data.quantity and data.distance == nil and data.destination then
			mandatoryTableArgument(data, "quantity", "number")
			createRelationByQuantity(data)
		else
			customError("Use quantity or distance as parameters, not both.")
		end
	end

	if data.destination and data.strategy ~= "contains" then
		if data.destination.geometry then
			local cell = data.destination:sample()

			if not string.find(cell.geom:getGeometryType(), "MultiPolygon") then
				customError("Argument 'destination' should be composed by MultiPolygon, got '"..cell.geom:getGeometryType().."'.")
			end
		else
			customError("The CellularSpace in argument 'destination' must be loaded with 'geometry = true'.")
		end

		distanceCellToTarget(data)
	end

	setmetatable(data, metaTableGPM_)

	return data
end