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

local function getBeginPoint(cell)
	local geometry = tl:castGeomToSubtype(cell.geom:getGeometryN(0))
	local Point = binding.te.gm.Point(geometry:getX(0), geometry:getY(0), geometry:getSRID())

	return Point
end

local function getEndPoint(cell)
	local geometry = tl:castGeomToSubtype(cell.geom:getGeometryN(0))
	local nPoint = geometry:getNPoints()
	local Point = binding.te.gm.Point(geometry:getX(nPoint - 1), geometry:getY(nPoint - 1), geometry:getSRID())
    
	return Point
end

local function hasntValue(tab, val)
	for index, value in ipairs (tab) do
		if value == val then
			return false
		end
	end

	return true
end

local function hasntValueNode(tab, val)
	if tab.point ~= nil then
		forEachElement(tab.point, function(value)
			if value == val then
				return false
			end
		end)
	end

	return true
end

local function addPointsLibe(line)
    line.insidePoint = {}
	local geometry = tl:castGeomToSubtype(line.geom:getGeometryN(0))
	local nPoint = geometry:getNPoints()

	for i = 0, nPoint - 1 do
		local point = tl:castGeomToSubtype(geometry:getPointN(i))

		table.insert(line.insidePoint, point)
	end
end

local function createConnectivity(lines)
	local netpoints = {}

	forEachCell(lines, function(line)
		addPointsLibe(line)

		local geometry = tl:castGeomToSubtype(line.geom:getGeometryN(0))
		local nPoint = geometry:getNPoints()

		for i = 1, nPoint - 1 do
			local point = tl:castGeomToSubtype(geometry:getPointN(i))
			local afterPoint = tl:castGeomToSubtype(geometry:getPointN(i + 1))
			local beforePoint = tl:castGeomToSubtype(geometry:getPointN(i - 1))
			local nameNodes = point:getX()..".."..point:getY()

			netpoints[nameNodes] = {point = point, route = {}, distance = math.huge, targetID, cell = line}
			table.insert(netpoints[nameNodes].route, afterPoint:getX()..".."..afterPoint:getY())
			table.insert(netpoints[nameNodes].route, beforePoint:getX()..".."..beforePoint:getY())
		end

		local points = {getBeginPoint(line), getEndPoint(line)}

		if hasntValueNode(netpoints, points[1]) then
			local nameNodes = points[1]:getX()..".."..points[1]:getY()

			netpoints[nameNodes] = {point = points[1], route = {}, distance = math.huge, targetID, cell = line}
			table.insert(netpoints[nameNodes].route, points[2]:getX()..".."..points[2]:getY())
		end

		if hasntValueNode(netpoints, points[2]) then
			local nameNodes = points[2]:getX()..".."..points[2]:getY()

			netpoints[nameNodes] = {point = points[2], route = {}, distance = math.huge, targetID, cell = line}
			table.insert(netpoints[nameNodes].route, points[1]:getX()..".."..points[1]:getY())
		end
	end)

	return netpoints
end

local function addRoute(netpoint, cell)
	bePoint = {getBeginPoint(cell), getEndPoint(cell)}
	if netpoint.point:equals(bePoint[1]) then
		if hasntValue(netpoint.route, bePoint[2]:getX()..".."..bePoint[2]:getY()) then
			table.insert(netpoint.route, bePoint[2]:getX()..".."..bePoint[2]:getY())
		end
	end

	if netpoint.point:equals(bePoint[2]) then
		if hasntValue(netpoint.route, bePoint[1]:getX()..".."..bePoint[1]:getY()) then
			table.insert(netpoint.route, bePoint[1]:getX()..".."..bePoint[1]:getY())
		end
	end
end

local function joinNetWork(route, firstNW, nw)
	local counterLine = 1
	local conect = {}

	while route[nw][counterLine] do
		if hasntValue(conect, route[nw][counterLine]) then
			table.insert(conect, route[nw][counterLine])
		end

		counterLine = counterLine + 1
	end

	counterLine = 1

	while route[firstNW][counterLine] do
		if hasntValue(conect, route[firstNW][counterLine]) then
			table.insert(conect, route[firstNW][counterLine])
		end

		counterLine = counterLine + 1
	end

	return conect
end

local function checkNetworkDisconnected(lines)
	local route = {}
	local counterNetwork = 0

	forEachCell(lines, function(line)
		local crosses = false
		local firstNW

		for i = 1, counterNetwork do
			local counterLine = 1

			while route[i][counterLine] do
				if line.geom:touches(route[i][counterLine].geom) and not crosses then
					table.insert(route[i], line)
					crosses = true
					firstNW = i
				elseif line.geom:touches(route[i][counterLine].geom) and crosses then
					route[firstNW] = joinNetWork(route, firstNW, i)
				end

				counterLine = counterLine + 1
			end
		end

		if not crosses then
			counterNetwork = counterNetwork + 1
			route[counterNetwork] = {}
			table.insert(route[counterNetwork], line)
		end
	end)

	if #route[1] ~= #lines then
		customError("The network disconected.")
	end
end

local function closestPointFromSegment(line, p, lineID)
	local x, y
	local points = {getBeginPoint(line), getEndPoint(line)}
	local p2 = {points[2]:getX() - points[1]:getX(), points[2]:getY() - points[1]:getY()}
	local beginEqualsToEnd = (p2[1] * p2[1]) + (p2[2] * p2[2])

-- Line already validity, does not have two points in the same place.
	local u = ((p:getX() - points[1]:getX()) * p2[1] + (p:getY() - points[1]:getY()) * p2[2]) / beginEqualsToEnd

	if u > 1 then
		u = 1
	elseif u < 0 then
		u = 0
	end

	x = points[1]:getX() + u * p2[1]
	y = points[1]:getY() + u * p2[2]

	local Point = binding.te.gm.Point(x, y, p:getSRID())

	return Point
end

local function buildPointTarget(lines, target)
	local arrayTargetLine = {}
	local counterTarget = 1
	local targetLine = 0

	forEachCell(target, function(targetPoint)
		local geometry1 = tl:castGeomToSubtype(targetPoint.geom:getGeometryN(0))
		local distance
		local minDistance = math.huge
		local point
		local targetPoint

		forEachCell(lines, function(line)
			local geometry2 = tl:castGeomToSubtype(line.geom:getGeometryN(0))
			local nPoint2 = geometry2:getNPoints()
			local pointLine = closestPointFromSegment(line, geometry1, line.FID)
			local distancePL = geometry1:distance(pointLine)

			for i = 0, nPoint2 do
				point = tl:castGeomToSubtype(geometry2:getPointN(i))
				distance = geometry1:distance(point)

				if distancePL < distance and line.geom:contains(pointLine) then
					distance = distancePL
					point = pointLine
				end

				if distance < minDistance then 
					minDistance = distance
					targetLine = line
					targetPoint = point
				end
			end
		end)

		if targetLine ~= nil then
			targetLine.targetPoint = targetPoint
			targetLine.pointDistance = minDistance
			arrayTargetLine[counterTarget] = targetLine
			counterTarget = counterTarget + 1
		end
	end)

	return arrayTargetLine
end

local function checksInterconnectedNetwork(data)
	local ncellRed = 0
	local warning = false
	local nlineError = 0
	local netpoints = createConnectivity(data.lines)

	forEachCell(data.lines, function(cellRed)
		local geometryR = tl:castGeomToSubtype(cellRed.geom:getGeometryN(0))
		local bePointR = {getBeginPoint(cellRed), getEndPoint(cellRed)}
		local lineValidates = false
		local differance = math.huge
		local distance
		local redPoint
		local nConect = 0
		local idLineError = 0
		local P = 1 
		cellRed.route = {}
		cellRed.P1 = {}
		cellRed.P2 = {}

		for j = 0, 1 do
			if j == 0 then
				redPoint = tl:castGeomToSubtype(bePointR[1])
			else
				redPoint = tl:castGeomToSubtype(bePointR[2])
				P = 2
			end

			local ncellBlue = 0

			forEachCell(data.lines, function(cellBlue)
				local geometryB = tl:castGeomToSubtype(cellBlue.geom:getGeometryN(0))

				if geometryR:crosses(geometryB) then
					customWarning("Lines '"..cellRed.FID.."' and '"..cellBlue.FID.."' cross each other.")
					nlineError = nlineError + 1
				end

				local bePointB = {getBeginPoint(cellBlue), getEndPoint(cellBlue)}
				local bluePoint

				for i = 0, 1 do
					if i == 1 then
						bluePoint = tl:castGeomToSubtype(bePointB[1])
					else
						bluePoint = tl:castGeomToSubtype(bePointB[2])
					end

					if ncellRed == ncellBlue then break end 

					distance = redPoint:distance(bluePoint)

					if distance <= data.error then
						table.insert(cellRed.route, cellBlue)
						lineValidates = true
						nConect = nConect + 1
						if P == 1 then
							table.insert(cellRed.P1, cellBlue)
							addRoute(netpoints[redPoint:getX()..".."..redPoint:getY()], cellBlue)
						else
							table.insert(cellRed.P2, cellBlue)
							addRoute(netpoints[redPoint:getX()..".."..redPoint:getY()], cellBlue)
						end
					end

					if differance > distance then
						differance = distance
						idLineError = cellRed.FID
					end
				end

				ncellBlue = ncellBlue + 1
			end)
		end

		if not lineValidates then
			customWarning("Line: '"..idLineError.."' does not touch any other line. The minimum distance found was: "..differance..".")
			nlineError = nlineError + 1
		end

		ncellRed = ncellRed + 1
	end)

	if nlineError >= 1 then
		customError("Cannot create a network from a file with the: "..nlineError.." problemes above.")
	end

	return {
		line = data.lines,
		node = netpoints
	}

end

local function getKey(line)
	return {
		P1 = line.FID.."P1",
		P2 = line.FID.."P2"
	}

end

local function checkLinePoints(line, target)
	local bePoint = {getBeginPoint(line), getEndPoint(line)}

	return {
		P1 = bePoint[1],
		P2 = bePoint[2]
	}

end

local function distanceRouteOutside(target, line, distanceOutside, targetLine, outside)
	local bePoint = {getBeginPoint(line), getEndPoint(line)}

	distanceOutside[targetLine][line.FID.."P1"] = outside(bePoint[1]:distance(targetLine.targetPoint), line)
	distanceOutside[targetLine][line.FID.."P2"] = outside(bePoint[2]:distance(targetLine.targetPoint), line)

	return getKey(line)
end

local function getNextRoute(line, loopRoute)
	forEachElement(line.P1, function(targetLines)
		if hasntValue(loopRoute, line.P1[targetLines]) then
			table.insert(loopRoute, line.P1[targetLines])
		end
	end)

	forEachElement(line.P2, function(targetLines)
		if hasntValue(loopRoute, line.P2[targetLines]) then
			table.insert(loopRoute, line.P2[targetLines])
		end
	end)
end

local function checkInsidePoints(line, point1, point2)
	if line.geom:contains(point1) or line.geom:contains(point2) then
		return true
	end

	return false
end

local function distanceRouteNode(node, netpoint, weight, lines)
	local notChange = false

	forEachElement(node.route, function(neighbor)
		point = node.route[neighbor]
		forEachCell(lines, function(line)
			local bePointLine = {getBeginPoint(line), getEndPoint(line)}

			if checkInsidePoints(line, node.point, netpoint[point].point) then
				local distance = weight(netpoint[point].point:distance(node.point), line)
    
				if node.distance > netpoint[point].distance + distance then
					node.distance = netpoint[point].distance + distance
					node.targetID = netpoint[point].targetID

					notChange = true
				end

				if node.targetID == nil then
					notChange = true
				end
			elseif bePointLine[1]:equals(node.point) and bePointLine[2]:equals(netpoint[point].point) or bePointLine[2]:equals(node.point) and bePointLine[1]:equals(netpoint[point].point) then
				local distance = weight(netpoint[point].point:distance(node.point), line)
    
				if node.distance > netpoint[point].distance + distance then
					node.distance = netpoint[point].distance + distance
					node.targetID = netpoint[point].targetID

					notChange = true
				end

				if node.targetID == nil then
					notChange = true
				end
			end
		end)
	end)

	return notChange
end

local function buildDistanceWeight(target, netpoint, self)
	local distanceWeight = {}
	local loopRoute = true
	local notChange = 0

	forEachElement(target, function(targetLines)
		local targetLine = target[targetLines]

		forEachElement(targetLine.insidePoint, function(inTarget)
			local point = targetLine.insidePoint[inTarget]
			local pointTarget = targetLine.targetPoint
			local pointDistance = targetLine.pointDistance

			if netpoint[point:getX()..".."..point:getY()].distance > self.weight(point:distance(pointTarget), targetLine) then
				netpoint[point:getX()..".."..point:getY()].distance = self.weight(point:distance(pointTarget), targetLine)
				netpoint[point:getX()..".."..point:getY()].targetID = targetLines
			end
		end)
	end)

	while loopRoute do
		forEachElement(netpoint, function(node)
			if distanceRouteNode(netpoint[node], netpoint, self.weight, self.lines) then
				notChange = false
			end
		end)

		if notChange then
			loopRoute = false
		else
			notChange = true
		end
	end

	return netpoint

end

local function buildDistancePointTarget(target, lines, self, netpoint)
	local distanceOutside = {}
	local distanceWeight = {}
	local keyRouts = {}
	local linekey = {}
	local points = {}

	forEachElement(target, function(targetLines)
		local targetLine = target[targetLines]
		local bePoint = {getBeginPoint(targetLine), getEndPoint(targetLine)}
		local loopRoute = true
		local lineRoute = {}
		distanceWeight[targetLine] = {}
		distanceOutside[targetLine] = {}

		table.insert(lineRoute, targetLine)
		getNextRoute(targetLine, lineRoute)

		distanceOutside[targetLine][targetLine.FID.."P1"] = self.outside(bePoint[1]:distance(targetLine.targetPoint), targetLine)
		distanceOutside[targetLine][targetLine.FID.."P2"] = self.outside(bePoint[2]:distance(targetLine.targetPoint), targetLine)

		keyRouts[targetLine] = getKey(targetLine)

		local countLine = 1
		local target = targetLine
		local countRoute = 1

		while loopRoute do
			points[target] = checkLinePoints(target)

			if target.P1[countLine] ~= nil then
				keyRouts[target.P1[countLine]] = distanceRouteOutside(target, target.P1[countLine],  distanceOutside, targetLine, self.outside)
			end

			if target.P2[countLine] ~= nil then
				keyRouts[target.P2[countLine]] = distanceRouteOutside(target, target.P2[countLine], distanceOutside, targetLine, self.outside)
			end

			countLine = countLine + 1

			if target.P1[countLine] == nil and target.P2[countLine] == nil and lineRoute[countRoute] ~= nil then
				target = lineRoute[countRoute]
				getNextRoute(target, lineRoute)
				countRoute = countRoute + 1
				countLine = 1
			elseif lineRoute[countRoute] == nil then
				loopRoute = false
			end
		end
	end)

	forEachCell(lines, function(line)
		table.insert(linekey, line)
	end)

	buildDistanceWeight(target, netpoint, self)

	return {
        netpoint = netpoint,
		target = target,
		lines = linekey,
		keys = keyRouts,
		points = points,
		distanceOutside = distanceOutside
	}

end

local function createOpenNetwork(self)
	local conectedLines = checksInterconnectedNetwork(self)
	checkNetworkDisconnected(self.lines)
	local targetPoints = buildPointTarget(conectedLines.line, self.target)
	local netWork = buildDistancePointTarget(targetPoints, conectedLines.line, self, conectedLines.node)

	return netWork
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
-- @arg data.weight User defined function to change the network distance.
-- If not set a function, will return to own distance.
-- @arg data.outside User-defined function that computes the distance based on an
-- Euclidean to enter and to leave the Network (optional).
-- If not set a function, will return to own distance.
-- @arg data.error Error argument to connect the lines in the Network (optional).
-- If data.error case is not defined , assigned the value 0.
-- @output a network based on the geometry.
-- @usage import("gpm")
-- local roads = CellularSpace{
--	file = filePath("roads.shp", "gpm"),
--	geometry = true
-- }
--
-- local communities = CellularSpace{
--	geometry = true,
--	file = filePath("communities.shp", "gpm")
-- }
--
-- local nt = Network{
--	target = communities,
--	lines = roads,
--	weight = function(distance, cell) return distance end
-- }
function Network(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"target", "lines", "strategy", "weight", "outside", "error"})
	mandatoryTableArgument(data, "lines", "CellularSpace")

	if data.lines.geometry then
		local cell = data.lines:sample()

		if not string.find(cell.geom:getGeometryType(), "Line") then
			customError("Argument 'lines' should be composed by lines, got '"..cell.geom:getGeometryType().."'.")
		end
	else
		customError("The CellularSpace in argument 'lines' must be loaded with 'geometry = true'.")
	end

	mandatoryTableArgument(data, "target", "CellularSpace")
	mandatoryTableArgument(data, "weight", "function")

	if data.target.geometry then
		local cell = data.target:sample()

		if not string.find(cell.geom:getGeometryType(), "Point") then
			customError("Argument 'target' should be composed by points, got '"..cell.geom:getGeometryType().."'.")
		end
	else
		customError("The CellularSpace in argument 'target' must be loaded with 'geometry = true'.")
	end

	optionalTableArgument(data, "strategy", "open")
	defaultTableValue(data, "outside", function(value, line) return 0 end)
	defaultTableValue(data, "error", 0)
    
	data.distance = createOpenNetwork(data)

	setmetatable(data, metaTableNetwork_)
	return data
end