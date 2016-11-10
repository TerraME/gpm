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

local function addOutputID(ID, geometry, polygonID)
	geometry[polygonID] = ID
end

local function addOutputDistance(distanceTarget, geometry, polygonDistance)
	geometry[polygonDistance] = distanceTarget
end

local function addOutput(self, geometry)
	local reference = 0

	if self.output then
		if self.output.id ~= nil then
			reference = 1

			geometry[self.output.id] = {}
		end

		if self.output.distance ~= nil then
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
		addOutputDistance(distancePointTarget, geometry, self.output.distance)
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
			print("Processing origin "..counterCode.."/"..numberGeometry) --SKIP
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

GPM_ = {
	type_ = "GPM",
	--- Save the GPM values ​​for use in '.shp'.
	-- @arg file The names of the file to be saved,
	-- this name is a string or a base::File.
	-- This file can have three extension '.gal', '.gwt' and '.gpm''.
	-- The values ID_Neighborhood ​​and Attribute are defined by the output parameter.
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
	--     distance = "distance",
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

--- Compute a generalised proximity matrix from a Network.
-- It gets a Network and a target as parameters and compute the distance
-- from the targets to the targets of the Network.
-- @arg data.network CellularSpace that receives end points of the networks.
-- @arg data.origin CellularSpace with geometry representing entry points on the network.
-- @arg data.quantity Number of points for target.
-- @arg data.distance --.
-- @arg data.relation --.
-- @arg data.output Table to receive the output value of the GPM (optional).
-- This table gets two values ​​ID and distance.
-- @arg data.progress print as values are being processed(optional).
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
--     distance = "distance",
--     relation = "community",
--     output = {
--         id = "id1",
--         distance = "distance"
--     },
--     progress = true
-- }
function GPM(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"network", "origin", "quantity", "distance", "relation", "output", "progress"})
	mandatoryTableArgument(data, "network", "Network")
	mandatoryTableArgument(data, "origin", "CellularSpace")

	if not data.origin.geometry then
		customError("The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")
	end

	defaultTableValue(data, "quantity", 1)
	defaultTableValue(data, "progress", false)

	mandatoryTableArgument(data, "progress", "boolean")

	optionalTableArgument(data, "distance", "string")
	optionalTableArgument(data, "relation", "string")

	if data.output ~= nil then
		forEachElement(data.output, function(output)
			if output ~= "id" and output ~= "distance" then
				incompatibleValueError("output", "id or distance", output) 
			end
		end)
	end

	data.distance = createOpenGPM(data)
	setmetatable(data, metaTableGPM_)

	return data
end