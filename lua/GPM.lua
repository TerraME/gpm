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
-- @arg data.distance --
-- @arg data.relation --
-- @output GPM based on network and target points.
-- @usage local roads = CellularSpace{
--	file = filePath("roads.shp", "gpm"),
--	geometry = true
-- }
-- local communities = CellularSpace{
--	file = filePath("communities.shp", "gpm"),
--	geometry = true
-- }
-- local farms = CellularSpace{
--	file = filePath("farms.shp", "gpm"),
--	geometry = true
-- }
-- local nt = Network{
--	target = communities,
--	lines = roads
-- }
-- local gpm = GPM{
--	network = network,
--	origin = farms,
--	distance = "distance",
--	relation = "community",
-- }
function GPM(data)
	verifyNamedTable(data)

	if type(data.network) ~= "Network" then
		incompatibleTypeError("network", "Network", data.network)
	end

	if type(data.origin) ~= "CellularSpace" or not data.origin.geometry then
		incompatibleTypeError("geometry", "CellularSpace", data.lines)
	end

	defaultTableValue(data, "quantity", 1)

	optionalTableArgument(data, "distance", "string")
	optionalTableArgument(data, "relation", "string")

	setmetatable(data, metaTableGPM_)
	return data
end