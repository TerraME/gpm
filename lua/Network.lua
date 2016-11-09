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
	local point = binding.te.gm.Point(geometry:getX(0), geometry:getY(0), geometry:getSRID())

	return point
end

local function getEndPoint(cell)
	local geometry = tl:castGeomToSubtype(cell.geom:getGeometryN(0))
	local counterPoint = geometry:getNPoints()
	local point = binding.te.gm.Point(geometry:getX(counterPoint - 1), geometry:getY(counterPoint - 1), geometry:getSRID())
    
	return point
end

local function addPointsLine(line)
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
		addPointsLine(line)

		local geometry = tl:castGeomToSubtype(line.geom:getGeometryN(0))
		local nPoint = geometry:getNPoints()

		for i = 1, nPoint - 1 do
			local point = tl:castGeomToSubtype(geometry:getPointN(i))
			local nameNodes = point:asText()
			local beforePoint = tl:castGeomToSubtype(geometry:getPointN(i - 1))
			local afterPoint = tl:castGeomToSubtype(geometry:getPointN(i + 1))

			netpoints[nameNodes] = {
				point = point, 
				route = {}, 
				distance = math.huge, 
				distanceOutside = math.huge,    
				cell = line
			}

			table.insert(netpoints[nameNodes].route, afterPoint:asText())
			table.insert(netpoints[nameNodes].route, beforePoint:asText())
		end

		local points = {getBeginPoint(line), getEndPoint(line)}

		if not belong(points[1], netpoints) then
			local nameNodes = points[1]:asText()

			netpoints[nameNodes] = {point = points[1], route = {}, distance = math.huge, distanceOutside = math.huge, targetID, targetIDOutside, cell = line}
			table.insert(netpoints[nameNodes].route, points[2]:asText())
		end

		if not belong(points[2], netpoints) then
			local nameNodes = points[2]:asText()

			netpoints[nameNodes] = {point = points[2], route = {}, distance = math.huge, distanceOutside = math.huge, targetID, targetIDOutside, cell = line}
			table.insert(netpoints[nameNodes].route, points[1]:asText())
		end
	end)

	return netpoints
end

local function addRoute(netpoint, cell)
	local bePoint = {getBeginPoint(cell), getEndPoint(cell)}

	if netpoint.point:equals(bePoint[1]) then
		local nameNodes = bePoint[2]:asText()

		if not belong(nameNodes, netpoint.route) then
			table.insert(netpoint.route, nameNodes)
		end
	end

	if netpoint.point:equals(bePoint[2]) then
		local nameNodes = bePoint[1]:asText()

		if not belong(nameNodes, netpoint.route) then
			table.insert(netpoint.route, nameNodes)
		end
	end
end

local function joinNetWork(route, firstNW, nw)
	local counterLine = 1
	local conect = {}

	while route[nw][counterLine] do
		if not belong(route[nw][counterLine], conect) then
			table.insert(conect, route[nw][counterLine])
		end

		counterLine = counterLine + 1
	end

	counterLine = 1

	while route[firstNW][counterLine] do
		if not belong(route[firstNW][counterLine], conect) then
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

local function closestPointFromSegment(line, p)
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
		local geometry = tl:castGeomToSubtype(targetPoint.geom:getGeometryN(0))
		local distance
		local minDistance = math.huge
		local point
		local pointTarget

		forEachCell(lines, function(line)
			local geometryLine= tl:castGeomToSubtype(line.geom:getGeometryN(0))
			local counterPoint = geometryLine:getNPoints()
			local pointLine = closestPointFromSegment(line, geometry)
			local distancePL = geometry:distance(pointLine)

			for i = 0, counterPoint do
				point = tl:castGeomToSubtype(geometryLine:getPointN(i))
				distance = geometry:distance(point)

				if distancePL < distance and line.geom:distance(pointLine) <= 0 then
					distance = distancePL
					point = pointLine
				end

				if distance < minDistance then 
					minDistance = distance
					targetLine = line
					pointTarget = point
				end
			end
		end)

		if targetLine ~= nil then
			targetLine.targetPoint = pointTarget
			targetLine.pointDistance = minDistance
			arrayTargetLine[counterTarget] = targetLine
			counterTarget = counterTarget + 1
		end
	end)

	return arrayTargetLine
end

local function checksInterconnectedNetwork(data)
	local counterCellRed = 0
	local counterLineError = 0
	local netpoints = createConnectivity(data.lines)

	forEachCell(data.lines, function(cellRed)
		local geometryR = tl:castGeomToSubtype(cellRed.geom:getGeometryN(0))
		local bePointR = {getBeginPoint(cellRed), getEndPoint(cellRed)}
		local lineValidates = false
		local differance = math.huge
		local distance
		local redPoint
		local idLineError = 0

		cellRed.route = {}

		for pointRed = 1, 2 do
			if pointRed == 1 then
				redPoint = tl:castGeomToSubtype(bePointR[1])
			else
				redPoint = tl:castGeomToSubtype(bePointR[2])
			end

			local counterCellBlue = 0

			forEachCell(data.lines, function(cellBlue)
				local geometryB = tl:castGeomToSubtype(cellBlue.geom:getGeometryN(0))

				if geometryR:crosses(geometryB) then
					customWarning("Lines '"..cellRed.FID.."' and '"..cellBlue.FID.."' cross each other.")
					counterLineError = counterLineError + 1
				end

				local bePointB = {getBeginPoint(cellBlue), getEndPoint(cellBlue)}
				local bluePoint

				for pointBlue = 1, 2 do
					if pointBlue == 1 then
						bluePoint = tl:castGeomToSubtype(bePointB[1])
					else
						bluePoint = tl:castGeomToSubtype(bePointB[2])
					end

					if counterCellRed == counterCellBlue then break end 

					distance = redPoint:distance(bluePoint)

					if distance <= data.error then
						table.insert(cellRed.route, cellBlue)
						lineValidates = true

						if pointRed == 1 then
							addRoute(netpoints[redPoint:asText()], cellBlue)
						else
							addRoute(netpoints[redPoint:asText()], cellBlue)
						end
					end

					if differance > distance then
						differance = distance
						idLineError = cellRed.FID
					end
				end

				counterCellBlue = counterCellBlue + 1
			end)
		end

		if not lineValidates then
			counterLineError = counterLineError + 1
			customWarning("Line: '"..idLineError.."' does not touch any other line. The minimum distance found was: "..differance..".")
		end

		counterCellRed = counterCellRed + 1
	end)

	return {
		line = data.lines,
		node = netpoints
	}
end


local function checkInsidePoints(line, point1, point2)
	return line.geom:contains(point1) or line.geom:contains(point2)
end

local function distanceFromRouteToNode(node, netpoint, weight, lines)
	local change = false

	forEachElement(node.route, function(neighbor)
		local point = node.route[neighbor]

		forEachCell(lines, function(line)
			local bePointLine = {getBeginPoint(line), getEndPoint(line)}

			if checkInsidePoints(line, node.point, netpoint[point].point) then
				local distance = weight(netpoint[point].point:distance(node.point), line)
    
				if node.distance > netpoint[point].distance + distance then
					node.distance = netpoint[point].distance + distance
					node.targetID = netpoint[point].targetID

					change = true
				end

				if node.targetID == nil then
					change = true
				end
			elseif bePointLine[1]:equals(node.point) and bePointLine[2]:equals(netpoint[point].point) or bePointLine[2]:equals(node.point) and bePointLine[1]:equals(netpoint[point].point) then
				local distance = weight(netpoint[point].point:distance(node.point), line)
    
				if node.distance > netpoint[point].distance + distance then
					node.distance = netpoint[point].distance + distance
					node.targetID = netpoint[point].targetID

					change = true
				end

				if node.targetID == nil then
					change = true
				end
			end
		end)
	end)

	return change
end

local function buildDistanceWeight(target, netpoint, self)
	local loopRoute = true
	local change

	forEachElement(target, function(targetLines)
		local targetLine = target[targetLines]

		if self.progress then
			print("Reducing distances "..targetLines.."/"..#target) --SKIP
		end

		forEachElement(targetLine.insidePoint, function(inTarget)
			local point = targetLine.insidePoint[inTarget]
			local pointTarget = targetLine.targetPoint
			local referencePoint = netpoint[point:asText()]

			if referencePoint.distance > self.weight(point:distance(pointTarget), targetLine) then
				referencePoint.distance = self.weight(point:distance(pointTarget), targetLine)
				referencePoint.targetID = targetLines
			end
		end)
	end)

	while loopRoute do
		forEachElement(netpoint, function(node)
			if distanceFromRouteToNode(netpoint[node], netpoint, self.weight, self.lines) then
				change = false
			end
		end)

		if change then
			loopRoute = false
		else
			change = true
		end
	end
end

local function buildDistanceOutside(target, netpoint, self)
	forEachElement(netpoint, function(inTarget)
		local point = netpoint[inTarget].point

		forEachElement(target, function(targetLines)
			local targetLine = target[targetLines]
			local pointTarget = targetLine.targetPoint
			local referencePoint = netpoint[point:asText()]

			if referencePoint.distanceOutside > self.outside(point:distance(pointTarget), targetLine) then
				referencePoint.distanceOutside = self.outside(point:distance(pointTarget), targetLine)
				referencePoint.targetIDOutside = targetLines
			end
		end)
	end)
end

local function buildDistancePointTarget(target, lines, self, netpoint)
	buildDistanceOutside(target, netpoint, self)
	buildDistanceWeight(target, netpoint, self)

	return {
		netpoint = netpoint,
		target = target,
		lines = lines
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
	__index = Network_
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
-- Euclidean to enter and to leave the Network.
-- If not set a function, will return to own distance.
-- @arg data.error Error argument to connect the lines in the Network (optional).
-- If data.error case is not defined , assigned the value 0.
-- @arg data.progress print as values are being processed(optional).
-- @output a network based on the geometry.
-- @usage import("gpm")
-- local roads = CellularSpace{
--  file = filePath("roads.shp", "gpm"),
--  geometry = true
-- }
--
-- local communities = CellularSpace{
--  geometry = true,
--  file = filePath("communities.shp", "gpm")
-- }
--
-- local nt = Network{
--  target = communities,
--  lines = roads,
--  weight = function(distance) return distance end,
--  outside = function(distance) return distance * 2 end,
--  progress = true
-- }
function Network(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"target", "lines", "strategy", "weight", "outside", "error", "progress"})
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
	mandatoryTableArgument(data, "outside", "function")

	if data.target.geometry then
		local cell = data.target:sample()

		if not string.find(cell.geom:getGeometryType(), "Point") then
			customError("Argument 'target' should be composed by points, got '"..cell.geom:getGeometryType().."'.")
		end
	else
		customError("The CellularSpace in argument 'target' must be loaded with 'geometry = true'.")
	end

	optionalTableArgument(data, "strategy", "open")
	defaultTableValue(data, "error", 0)
	defaultTableValue(data, "progress", false)

	mandatoryTableArgument(data, "error", "number")
	mandatoryTableArgument(data, "progress", "boolean")

	data.distance = createOpenNetwork(data)

	setmetatable(data, metaTableNetwork_)
	return data
end