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

local function calculateDistancePointSegment(line, p)
	local x, y
	local points = getBELine(line)
	local p2 = {points.p2:getX() - points.p1:getX(), points.p2:getY() - points.p1:getY()}
	local something = (p2[1] * p2[1]) + (p2[2] * p2[2])

	if something == 0 then
		x = points.p1:getX()
		y = points.p1:getY()
	else

		local u = ((p:getX() - points.p1:getX()) * p2[1] + (p:getY() - points.p1:getY()) * p2[2]) / something

		if u > 1 then
			u = 1
		elseif u < 0 then
			u = 0
		end

		x = points.p1:getX() + u * p2[1]
		y = points.p1:getY() + u * p2[2]
	end

	local Point = binding.te.gm.Point(x, y, p:getSRID())

	return Point
end

local function distancePointTarget(lines, target)
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
			local pointLine = calculateDistancePointSegment(line, geometry1)
			local distancePL = geometry1:distance(pointLine)

			for i = 0, nPoint2 do
				point = tl:castGeomToSubtype(geometry2:getPointN(i))
				distance = geometry1:distance(point)

				if distancePL < distance then
					distance = distancePL
				end

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

local function checkDistance(line, finalDistance, target)
	local result = {
		lines = {},
		finalDistance = finalDistance
	}

	while true do
		local distance1 = 0
		local distance2 = 0
		local countline = 1
		local bePoint1 = getBELine(line)
		local PointA1
		local PointB1
		local PointB2
		local finalDistance2 = 0

		PointA1 = tl:castGeomToSubtype(bePoint1.p1)
		distance1 = PointA1:distance(target)

		local distance3 = distance1
		local nextLine

		while line.route[countline] do
			local bePoint2 = getBELine(line.route[countline])

			PointB1 = tl:castGeomToSubtype(bePoint2.p1)
			distance2 = PointB1:distance(target)
			PointB2 = tl:castGeomToSubtype(bePoint2.p2)

			if distance3 > distance2 then
				finalDistance2 = PointB1:distance(PointB2)
				nextLine = line.route[countline]
				distance3 = distance2
			end

			countline = countline + 1

			if distance1 > distance3 and not (line.route[countline]) then
				finalDistance = finalDistance2 + finalDistance
				line = nextLine
				countline = 0
				table.insert(result.lines, nextLine)
				break
			end

			if distance1 <= distance3 and not (line.route[countline]) then
				result.finalDistance = finalDistance + distance1

				return result
			end
		end
	end
end

local function checkDistance2(line, finalDistance, target)
	local result = {
		lines = 0,
		finalDistance = finalDistance
	}

	while true do
		local distance1 = 0
		local distance2 = 0
		local countline = 1
		local bePoint1 = getBELine(line)
		local PointA2
		local PointB1
		local PointB2
		local finalDistance2 = 0
		local lineA = tl:castGeomToSubtype(line.geom)

		PointA2 = tl:castGeomToSubtype(bePoint1.p2)
		distance1 = PointA2:distance(target)

		local distance3 = math.huge
		local nextLine

		while line.routeBegin[countline] do
			local bePoint2 = getBELine(line.routeBegin[countline])

			PointB1 = tl:castGeomToSubtype(bePoint2.p1)
			PointB2 = tl:castGeomToSubtype(bePoint2.p2)
			distance2 = PointB2:distance(target)

			if distance3 > distance2 and result.lines ~= distance2 then
				finalDistance2 = PointB1:distance(PointB2)
				nextLine = line.routeBegin[countline]
				distance3 = distance2
			end

			countline = countline + 1

			if (distance1 > distance3 or not lineA:contains(target)) and not (line.routeEnd[countline]) then
				finalDistance = finalDistance2 + finalDistance
				line = nextLine
				countline = 0
				result.lines = distance1
				break
			end

			if distance1 <= distance2 and not (line.routeBegin[countline]) then
				result.finalDistance = finalDistance + distance1

				return result
			end
		end
	end
end

local function distanceLine(lines)
	local vectorDistance = {}

	forEachCell(lines, function(cell)
		local bePoint = getBELine(cell)
		local Point1 = tl:castGeomToSubtype(bePoint.p1)
		local Point2 = tl:castGeomToSubtype(bePoint.p2)
		local distance = Point1:distance(Point2)

		vectorDistance[returnReferenceDL(cell)] = distance
	end)

	return vectorDistance
end

local function checksDistancePointTarget(lines, arrayTargetLine)
	local countTarget = 0
	local point = {}
	local pointTarget = {}
	local savePoint = true

	while arrayTargetLine[countTarget] do
		forEachCell(lines, function(line)
			local bePoint = getBELine(line)
			local result
			pointTarget[arrayTargetLine[countTarget]] = {}

			local Point1 = tl:castGeomToSubtype(bePoint.p1)
			local Point2 = tl:castGeomToSubtype(bePoint.p2)

			local finalDistanceA = Point1:distance(Point2)
			local finalDistanceB = 0

			result = checkDistance(line, finalDistanceB, arrayTargetLine[countTarget])

			pointTarget[arrayTargetLine[countTarget]][Point1] = result

			table.insert(point, Point1)

			result = checkDistance(line, finalDistanceA, arrayTargetLine[countTarget])

			pointTarget[arrayTargetLine[countTarget]][Point2] = result

			table.insert(point, Point2)

		end)

		countTarget = countTarget + 1
	end

	local network = {
		target = arrayTargetLine,
		points = point,
		distanceTarget = pointTarget
	}

	return network
end

local function checksInterconnectedNetwork(data)
	local ncellRed = 0
	local warning = false

	forEachCell(data.lines, function(cellRed)
		local geometryR = tl:castGeomToSubtype(cellRed.geom:getGeometryN(0))
		local bePointR = getBELine(cellRed)
		local lineValidates = false
		local differance = math.huge
		local distance
		local redPoint
		local nConect = 0
		cellRed.route = {}

		for j = 0, 1 do
			if j == 0 then
				redPoint = tl:castGeomToSubtype(bePointR.p1)
			else
				redPoint = tl:castGeomToSubtype(bePointR.p2)
			end

			local ncellBlue = 0

			forEachCell(data.lines, function(cellBlue)
				local geometryB = tl:castGeomToSubtype(cellBlue.geom:getGeometryN(0))

				if geometryR:crosses(geometryB) then
					customWarning("The lines '"..geometryB:toString().."' and '"..geometryR:toString().."' crosses")
					warning = true
				end

				local bePointB = getBELine(cellBlue)
				local bluePoint

				for i = 0, 1 do

					if i == 1 then
						bluePoint = tl:castGeomToSubtype(bePointB.p1)
					else
						bluePoint = tl:castGeomToSubtype(bePointB.p2)
					end

					if ncellRed == ncellBlue then break end 

					distance = redPoint:distance(bluePoint)

					if distance <= data.error then
						table.insert(cellRed.route, cellBlue)
						lineValidates = true
						nConect = nConect + 1
					end

					if differance > distance then
						differance = distance
					end
				end

				ncellBlue = ncellBlue + 1
			end)
		end

		if not lineValidates then
			customError("line do not touch, They have a differance of: "..differance)
		end

		ncellRed = ncellRed + 1
	end)

	if warning then
		customError("Invalid file, it has overlapping line")
	end

	return data.lines
end

local function createOpenNetwork(self)
	if self.lines.geometry then
		local cell = self.lines:sample()

		if not string.find(cell.geom:getGeometryType(), "Line") then
			incompatibleValueError("cell", "geometry", cell.geom)
		end

		if self.target.geometry then
			local cell = self.target:sample()

			if not string.find(cell.geom:getGeometryType(), "Point") then
				incompatibleValueError("cell", "geometry", cell.geom)
			end
		end
	end

	local distanceTarget = distancePointTarget(self.lines, self.target)
	local checksIN = checksInterconnectedNetwork(self)
	local checksDT = checksDistancePointTarget(checksIN, distanceTarget)

	return checksDT
end

Network_ = {
	type_ = "Network"

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
--	file = filePath("roads.shp", "gpm"),
--	geometry = true
-- }
-- local communities = CellularSpace{
--	file = filePath("communities.shp", "gpm"),
--	geometry = true
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
    
	createOpenNetwork(data)

	setmetatable(data, metaTableNetwork_)
	return data
end