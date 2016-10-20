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
			distancePointTarget = network.distance.netpoint[point].distance
		end

		distance = self.network.outside(centroid:distance(network.distance.netpoint[point].point)) + network.distance.netpoint[point].distanceOutside

		if distance < minimumDistance then
			target = network.distance.netpoint[point].targetIDOutside
			minimumDistance = distance
			distancePointTarget = network.distance.netpoint[point].distanceOutside
		end
	end)

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
	forEachCell(self.origin, function(geometryOrigin)
		local geometry = tl:castGeomToSubtype(geometryOrigin.geom:getGeometryN(0))

		getDistanceInputPoint(self, geometry:getCentroid(), self.network, geometry.FID, geometryOrigin)
	end)
end

GPM_ = {
	type_ = "GPM"
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