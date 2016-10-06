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

local function buildPointTargetWeight(network, centroid, ID)
	local minimumDistance = math.huge
	local distancePointTraget
	local target

	forEachElement(network.distance.netpoint, function(point)
		local distance = centroid:distance(network.distance.netpoint[point].point)

		if distance < minimumDistance then
			target = network.distance.netpoint[point].targetID
			minimumDistance = distance
			distancePointTraget = network.distance.netpoint[point].distance
		end
	end)

	return{
		target = target,
		distance = distancePointTraget,
		id = ID
	}
end

local function buildPointTargetOutside(network, centroid, ID)
	local minimumDistance = math.huge
	local distancePointTraget
	local target

	forEachElement(network.distance.netpoint, function(point)
		local distance = centroid:distance(network.distance.netpoint[point].point)

		if distance < minimumDistance then
			target = network.distance.netpoint[point].targetIDOutside
			minimumDistance = distance
			distancePointTraget = network.distance.netpoint[point].distance
		end
	end)

	return{
		target = target,
		distance = distancePointTraget,
		id = ID
	}
end

local function getDistanceInputPoint(centroid, network, ID)
	return {
		weight = buildPointTargetWeight(network, centroid, ID),
		outside = buildPointTargetOutside(network, centroid, ID),
	}
end

local function createOpenGPM(origin, network)
	local distance = {}

	forEachCell(origin, function(polygon)
		local geometry = tl:castGeomToSubtype(polygon.geom:getGeometryN(0))

		table.insert(distance, getDistanceInputPoint(geometry:getCentroid(), network, polygon.FID))
	end)

	return distance
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
--	weight = function(distance, cell) return distance end
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
	verifyUnnecessaryArguments(data, {"network", "origin", "quantity", "distance", "relation"})
	mandatoryTableArgument(data, "network", "Network")
	mandatoryTableArgument(data, "origin", "CellularSpace")

	if not data.origin.geometry then
		customError("The CellularSpace in argument 'origin' must be loaded with 'geometry = true'.")
	end

	defaultTableValue(data, "quantity", 1)

	optionalTableArgument(data, "distance", "string")
	optionalTableArgument(data, "relation", "string")

	data.distance = createOpenGPM(data.origin, data.network)

	setmetatable(data, metaTableGPM_)
	return data
end