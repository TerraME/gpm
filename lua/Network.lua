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

local function getBELine(cell)
	local geometry = tl:castGeomToSubtype(cell.geom:getGeometryN(0))
	local nPoint = geometry:getNPoints()
	local beginPoint = binding.te.gm.Point(geometry:getX(0), geometry:getY(0), geometry:getSRID())
	local endPoint = binding.te.gm.Point(geometry:getX(nPoint - 1), geometry:getY(nPoint - 1), geometry:getSRID())
	local ffPointer = {p1 = beginPoint, p2 = endPoint}

	return ffPointer
end

local function distancePoint(lines, target)
	local arrayTargetLine = {}
	local counter = 0

	forEachCell(target, function(targetPoint)
		local geometry1 = tl:castGeomToSubtype(targetPoint.geom:getGeometryN(0))
		local nPoint1 = geometry1:getNPoints()
		local distance
		local minDistance = math.huge
		local point

		forEachCell(lines, function(line)
			local geometry2 = tl:castGeomToSubtype(line.geom:getGeometryN(0))
			local nPoint2 = geometry2:getNPoints()

			for i = 0, nPoint2 do
				point = tl:castGeomToSubtype(geometry2:getPointN(i))
				distance = geometry1:distance(point)

				if distance < minDistance then
					minDistance = distance
					arrayTargetLine[counter] = point
				end
			end
		end)

		if arrayTargetLine[counter] ~= nil then
			counter = counter + 1
		end
	end)

	return arrayTargetLine
end

local function checksInterconnectedNetwork(lines, arrayTargetLine)
	local counter = 0

	while arrayTargetLine[counter] do
		forEachCell(lines, function(line)
		end)
	end
end
local function checksInterconnectedNetwork(data)
	local ncellRed = 0

	forEachCell(data.lines, function(cellRed)
		local bePoint = getBELine(cellRed)
		local lineValidates = false
		local differance = math.huge
		local distance
		local redPoint

		for j = 0, 1 do
			if j == 0 then
				redPoint = tl:castGeomToSubtype(bePoint.p1)
			else
				redPoint = tl:castGeomToSubtype(bePoint.p2)
			end

			local ncellBlue = 0

			forEachCell(data.lines, function(cellBlue)
				local geometry = tl:castGeomToSubtype(cellBlue.geom:getGeometryN(0))
				local nPoint = geometry:getNPoints()

				for i = 0, nPoint do
					local bluePoint = tl:castGeomToSubtype(geometry:getPointN(i))

					if ncellRed ~= ncellBlue then
						distance = redPoint:distance(bluePoint)

						if distance <= data.error then
							lineValidates = true
						end

						if differance > distance then
							differance = distance
						end
					end
				end

				if lineValidates == true then
					return false
				end

				ncellBlue = ncellBlue + 1
			end)
		end

		if not lineValidates then
			customError("line do not touch, They have a differance of: "..differance)
		end

		ncellRed = ncellRed + 1
	end)
end

Network_ = {
	type_ = "Network",
	--- Creates and validates a network.
	-- @arg data.target File with the path of network end points.
	-- @arg data.lines File with the path of a network.
	-- @usage csCenterspt = CellularSpace{
	--	file = filePath("rondonia_urban_centers_pt.shp", "gpm")
	--}
	--local csLine = CellularSpace{
	--	file = filePath("rondonia_roads_lin.shp", "gpm")
	--}
	--local nt = Network{
	--	target = csCenterspt,
	--	lines = csLine
	--}
	--nt:createOpenNetwork()
	createOpenNetwork = function(self)
		if self.lines.geometry then
			local cell = self.lines:sample()

			if not string.find(cell.geom:getGeometryType(), "Line") then
				incompatibleValueError("cell", "geometry", cell.geom)
			end

			checksInterconnectedNetwork(self)
		end

		if self.target.geometry then
			local cell = self.target:sample()

			if not string.find(cell.geom:getGeometryType(), "Point") then
				incompatibleValueError("cell", "geometry", cell.geom)
			else 
				distancePoint(self.lines, self.target)
			end
		end
	end
}

metaTableNetwork_ = {
	__index = Network_,
	__tostring = _Gtme.tostring
}

--- Type for network creation. Given geometry of the line type,
-- constructs a geometry network. This type is used to calculate the best path.
-- @arg data.target CellularSpace that receives end points of the networks.
-- @arg data.lines CellularSpace that receives a network.
-- this CellularSpace receives a projet with geometry, a layer,
-- and geometry boolean argument, indicating whether the project has a geometry.
-- @arg data.strategy Strategy to be used in the network (optional).
-- @arg data.weight User defined function to change the network distance (optional).
-- If not set a function, will return to own distance.
-- @arg data.outside User-defined function that computes the distance based on an
-- Euclidean to enter and to leave the Network (optional).
-- If not set a function, will return to own distance.
-- @arg data.error Error argument to connect the lines in the Network (optional).
-- If data.error case is not defined , assigned the value 0
-- @output a network based on the geometry.
-- @usage local roads = CellularSpace{
-- 	file = filePath("roads.shp", "gpm"),
-- 	geometry = true
-- }
-- local communities = CellularSpace{
-- 	file = filePath("communities.shp", "gpm"),
-- 	geometry = true
-- }
-- local nt = Network{
--	target = communities,
--	lines = roads
-- }
function Network(data)
	verifyNamedTable(data)

	if type(data.lines) ~= "CellularSpace" then
		incompatibleTypeError("lines", "CellularSpace", data.lines)
	else
		if data.lines.geometry then
			local cell = data.lines:sample()

			if not string.find(cell.geom:getGeometryType(), "Line") then
				customError("Argument 'lines' should be composed by lines, got '"..cell.geom:getGeometryType().."'.")
			end
		end
	end

	if type(data.target) ~= "CellularSpace" then
		incompatibleTypeError("target", "CellularSpace", data.target)
	else
		if data.target.geometry then
			local cell = data.target:sample()

			if not string.find(cell.geom:getGeometryType(), "Point") then
				customError("Argument 'target' should be composed by points, got '"..cell.geom:getGeometryType().."'.")
			end
		end
	end

	optionalTableArgument(data, "strategy", "open")
	defaultTableValue(data, "weight", function(value) return value end)
	defaultTableValue(data, "outside", function(value) return value end)
	defaultTableValue(data, "error", 0)

	setmetatable(data, metaTableNetwork_)
	return data
end