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
local binding = _Gtme.terralib_mod_binding_lua
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

local function buildPointTarget(self, reference, network, centroid, ID, geometry)
	local minimumDistance = math.huge
	local distancePointTarget
	local target

	forEachElement(network.distance.netpoint, function(point)
		local distance = self.network.outside(centroid:distance(network.distance.netpoint[point].point)) + network.distance.netpoint[point].distance

		if distance < minimumDistance then
			target = network.distance.netpoint[point].targetID
			minimumDistance = distance
			distancePointTarget = distance
		end

		distance = self.network.outside(centroid:distance(network.distance.netpoint[point].point)) + network.distance.netpoint[point].distanceOutside

		if distance < minimumDistance then
			target = network.distance.netpoint[point].targetIDOutside
			minimumDistance = distance
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

local function getDistanceInputPoint(self, centroid, network, ID, geometry)
	local reference = addOutput(self, geometry)

	buildPointTarget(self, reference, network, centroid, ID, geometry)
end

local function createOpenGPM(self)
	local counterCode = 0

	self.neighbor = {}

	forEachCell(self.origin, function(geometryOrigin)
		geometryOrigin.code = counterCode
		geometryOrigin.neighbor = 0

		local geometry = tl:castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))

		getDistanceInputPoint(self, geometry:getCentroid(), self.network, geometry.FID, geometryOrigin)
		counterCode = counterCode + 1
	end)
end

local function saveGAL(self, fileName)
	local validates = false
	local origin = self.origin
	local outputText = "0 "..#self.neighbor.." "..origin.layer.." object_id_\n"

	forEachElement(self.neighbor, function(neighbor)
		outputText = outputText..(neighbor).." "..self.neighbor[neighbor].."\n"

		forEachElement(self.origin.cells, function(cell)
			if self.origin.cells[cell].neighbor == neighbor then
				outputText = outputText..self.origin.cells[cell].code.." "
				validates = true
			end
		end)

		if validates then
			outputText = outputText.."\n"
		end
	end)

	file:write(outputText)
	file:close()
end

local function saveGPM(self, fileName)
	local validates = false
	local origin = self.origin
	local outputText = "0 "..origin.layer.." "..origin.layer.." object_id_\n"

	if self.output.distance == nil then
		mandatoryArgumentError("output.distance")
	end

	forEachElement(self.neighbor, function(neighbor)
		outputText = outputText..(neighbor).." "..self.neighbor[neighbor].."\n"

		forEachElement(self.origin.cells, function(cell)
			if self.origin.cells[cell].neighbor == neighbor then
				outputText = outputText..self.origin.cells[cell].code.." "..self.origin.cells[cell][self.output.distance].." "
				validates = true
			end
		end)

		if validates then
			outputText = outputText.."\n"
		end
	end)

	file:write(outputText)
	file:close()
end

local function saveGWT(self, fileName)
	local validates = false
	local origin = self.origin
	local outputText = "0 "..#self.neighbor.." "..origin.layer.." object_id_\n"

	if self.output.distance == nil then
		mandatoryArgumentError("output.distance")
	end

	if file:exists() then
		customError("A file with name '"..fileName.."' already exists.")
	end

	forEachElement(self.origin.cells, function(cell)
		outputText = outputText..self.origin.cells[cell].neighbor.." "..self.origin.cells[cell].code.." "..self.origin.cells[cell][self.output.distance].."\n"
	end)

	file:write(outputText)
	file:close()
end

GPM_ = {
	type_ = "GPM",
	--- Save the GPM values ​​for use in '.shp'.
	-- @arg fileName The names of the attributes to be saved,
	-- this name is a string.
	-- This file can have three extension '.gal', '.gwt' and '.gpm''.
	-- @usage roads = CellularSpace{
	-- 	file = filePath("roads.shp", "gpm"),
	-- 	geometry = true
	-- }
	--
	-- communities = CellularSpace{
	-- 	file = filePath("communities.shp", "gpm"),
	-- 	geometry = true
	-- }
	--
	-- farms = CellularSpace{
	-- 	file = filePath("farms.shp", "gpm"),
	-- 	geometry = true
	-- }
	--
	-- network = Network{
	-- 	lines = roads,
	-- 	target = communities,
	-- 	weight = function(distance, cell)
	-- 		if cell.CD_PAVIMEN == "pavimentada" then
	-- 			return distance / 5
	-- 		else
	-- 			return distance / 2
	-- 		end
	-- 	end,
	-- 	outside = function(distance)
	-- 		return distance * 2
	-- 	end
	-- }
	--
	-- gpm = GPM{
	-- 	network = network,
	-- 	destination = farms,
	--	distance = "distance",
	--	relation = "community",
	--	output = {
	--		id = "id1",
	--		distance = "distance"
	--	}
	-- }
	--
	-- gpm:save("farms.gpm")
	save = function(self, fileName)
		if type(fileName) ~= "string" then
			incompatibleTypeError("nameFile", "string", fileName)
		end

		local file = File(fileName)

		if file:exists() then
			customError("A file with name '"..fileName.."' already exists.")
		end

		local extension = string.sub(fileName, -4)

		if extension == ".gpm" then
			saveGPM(self, fileName)
		elseif extension == ".gwt" then
			saveGWT(self, fileName)
		elseif extension == ".gal" then
			saveGAL(self, fileName)
		end
	end
}
metaTableGPM_ = {
	__index = GPM_,
	__tostring = _Gtme.tostring
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
-- @output GPM based on network and target points.
-- @usage import("gpm")
-- local roads = CellularSpace{
--	file = filePath("roads.shp", "gpm"),
--	geometry = true
-- }
--
-- local communities = CellularSpace{
--	file = filePath("communities.shp", "gpm"),
--	geometry = true
-- }
--
-- local farms = CellularSpace{
--	file = filePath("farms.shp", "gpm"),
--	geometry = true
-- }
--
-- local network = Network{
--	target = communities,
--	lines = roads,
--	weight = function(distance) return distance end,
--	outside = function(distance) return distance * 2 end
-- }
--
-- local gpm = GPM{
--	network = network,
--	origin = farms,
--	distance = "distance",
--	relation = "community"
-- }
function GPM(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"network", "origin", "quantity", "distance", "relation", "output"})
	mandatoryTableArgument(data, "network", "Network")
	mandatoryTableArgument(data, "origin", "CellularSpace")

	if not data.origin.geometry then
		customError("The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")
	end

	defaultTableValue(data, "quantity", 1)

	optionalTableArgument(data, "distance", "string")
	optionalTableArgument(data, "relation", "string")

	if data.output ~= nil then
		local cell = data.origin:sample()

		forEachElement(data.output, function(output)
			if output ~= 'id' and output ~= 'distance' then
				incompatibleValueError("output", "id or distance", output) 
			end

			if cell[output] == nil then
				customError("Argument '"..data.output[output].."' already exists in the Cell.")
			end
		end)
	else
		data.output = false
	end

	data.distance = createOpenGPM(data)
	setmetatable(data, metaTableGPM_)
	return data
end