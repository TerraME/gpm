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
local gis = getPackage("gis")

local function createPoint(x, y, srid)
	return gis.TerraLib().geometry().Point(x, y, srid)
end

local function isPointEndsConnected(first, last, p1, p2)
	return gis.TerraLib().geometry().LineString.isEndsConnected(first, last, p1, p2) -- TODO(avancinirodrigo): review function name
end

local function createConnectivity(lines)
	local netpoints = {}

	forEachCell(lines, function(line)
		local lineObj = line.geom:getGeometryN(0)
		local nPoints = line.geom:getNPoints()

		line.points = {}

		for i = 0, nPoints - 1 do
			table.insert(line.points, lineObj:getPointN(i))
		end

		for i = 1, nPoints - 1 do
			local currPoint = lineObj:getPointN(i)
			local beforePoint = lineObj:getPointN(i - 1)
			local afterPoint = lineObj:getPointN(i + 1)
			local id = currPoint:asText()

			netpoints[id] = {
				point = currPoint,
				route = {},
				distance = math.huge,
				distanceOutside = math.huge,
				cell = line
			}

			--table.insert(line.points, currPoint)
			table.insert(netpoints[id].route, afterPoint:asText())
			table.insert(netpoints[id].route, beforePoint:asText())
		end

		local firstPoint = lineObj:getStartPoint()
		local lastPoint = lineObj:getEndPoint()
		local fid = firstPoint:asText()
		local lid = lastPoint:asText()

		-- TODO: ifs is always true and is too heavy
		if not belong(firstPoint, netpoints) then
			netpoints[fid] = {
				point = firstPoint,
				route = {},
				distance = math.huge,
				distanceOutside = math.huge,
				--targetID,
				--targetIDOutside,
				cell = line
			}

			table.insert(netpoints[fid].route, lid)
		end

		if not belong(lastPoint, netpoints) then
			netpoints[lid] = {
				point = lastPoint,
				route = {},
				distance = math.huge,
				distanceOutside = math.huge,
				--targetID,
				--targetIDOutside,
				cell = line
			}

			table.insert(netpoints[lid].route, fid)
		end

		line.firstPoint = firstPoint
		line.lastPoint = lastPoint
		line.lineObj = lineObj
	end)

	return netpoints
end

local function addRoute(netpoint, bePoint)
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
		customError("The network is disconected.")
	end
end

local function closestPointFromSegment(line, geometry)
	local x, y
	local points = {line.firstPoint, line.lastPoint}
	local p1x = points[1]:getX()
	local p1y = points[1]:getY()
	local p2 = {points[2]:getX() - p1x, points[2]:getY() - p1y}
	local beginEqualsToEnd = (p2[1] * p2[1]) + (p2[2] * p2[2])

	local p

	if not string.find(geometry:getGeometryType(), "Point") then
		p = geometry:getCentroid():clone()
	else
		p = geometry:getGeometryN(0)
	end

	-- Line already valid. It does not have two points in the same place.
	local u = ((p:getX() - p1x) * p2[1] + (p:getY() - p1y) * p2[2]) / beginEqualsToEnd

	if u > 1 then
		u = 1
	elseif u < 0 then
		u = 0
	end

	x = p1x + u * p2[1]
	y = p1y + u * p2[2]

--	print(type(p))
--	print(vardump(p))
--	if not p.getSRID then p = gis.TerraLib().castGeomToSubtype(p.geom:getGeometryN(0)) end

	local point = createPoint(x, y, geometry:getSRID())

	return point
end

local function buildPointTarget(lines, target)
	local arrayTargetLine = {}
	local counterTarget = 1
	local targetLine = 0

	forEachCell(target, function(targetPoint)
		local geometry = targetPoint.geom:getGeometryN(0)
		local distance
		local minDistance = math.huge
		local point
		local pointTarget
		targetPoint.pointID = counterTarget

		forEachCell(lines, function(line)
			local geometryLine = line.lineObj
			local pointLine = closestPointFromSegment(line, targetPoint.geom)
			local distancePL = geometry:distance(pointLine)

			for i = 1, #line.points do
				point = line.points[i]
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

local function checksInterconnectedNetwork(self)
	local counterCellRed = 0
	local counterLineError = 0
	local netpoints = createConnectivity(self.lines)

	forEachCell(self.lines, function(cellRed)
		local geometryR = cellRed.lineObj
		local bePointR = {cellRed.firstPoint, cellRed.lastPoint}
		local lineValidates = false
		local differance = math.huge
		local distance
		local redPoint
		local idLineError = 0

		cellRed.route = {}

		for pointRed = 1, 2 do
			redPoint = bePointR[pointRed]

			local counterCellBlue = 0

			forEachCell(self.lines, function(cellBlue)
				local geometryB = cellBlue.lineObj

				if geometryR:crosses(geometryB) then
					counterLineError = counterLineError + 1
					customError("Lines '"..cellRed.FID.."' and '"..cellBlue.FID.."' cross each other.")
				end

				local bePointB = {cellBlue.firstPoint, cellBlue.lastPoint}
				local bluePoint

				for pointBlue = 1, 2 do
					bluePoint = bePointB[pointBlue]

					if counterCellRed == counterCellBlue then break end

					distance = redPoint:distance(bluePoint)

					if distance <= self.error then
						table.insert(cellRed.route, cellBlue)
						lineValidates = true

						-- if pointRed == 1 then -- TODO: unnecessary if
							addRoute(netpoints[redPoint:asText()], bePointB)
						--else
						--	addRoute(netpoints[redPoint:asText()], geometryB)
						--end
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
			customError("Line: '"..idLineError.."' does not touch any other line. The minimum distance found was: "..differance..".")
		end

		counterCellRed = counterCellRed + 1
	end)

	return netpoints
end

local function distanceFromRouteToNode(node, netpoint, weight, lines)
	local change = false

	forEachElement(node.route, function(neighbor)
		local point = node.route[neighbor]

		forEachCell(lines, function(line)
			if line.geom:contains(node.point, netpoint[point].point) then
				local distance = weight(netpoint[point].point:distance(node.point), line)

				if node.distance > netpoint[point].distance + distance then
					node.distance = netpoint[point].distance + distance
					node.targetID = netpoint[point].targetID

					change = true
				end

				if node.targetID == nil then
					change = true
				end
			elseif isPointEndsConnected(line.firstPoint, line.lastPoint, node.point, netpoint[point].point) then
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
			print(table.concat{"Reducing distances ", targetLines, "/", #target}) -- SKIP
		end

		forEachElement(targetLine.points, function(inTarget)
			local point = targetLine.points[inTarget]
			local pointTarget = targetLine.targetPoint
			local referencePoint = netpoint[point:asText()]

			local dist = self.weight(point:distance(pointTarget), targetLine)

			if referencePoint.distance > dist then
				referencePoint.distance = dist
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
	local i = 0

	forEachElement(netpoint, function(inTarget)
		local point = netpoint[inTarget].point

		if self.progress then
			i = i + 1 -- SKIP
			print(table.concat{"Computing distance outside ", i, "/", getn(netpoint)}) -- SKIP
		end

		forEachElement(target, function(targetLines)
			local targetLine = target[targetLines]
			local pointTarget = targetLine.targetPoint
			local referencePoint = netpoint[point:asText()]

			local dist = self.outside(point:distance(pointTarget), targetLine)

			if referencePoint.distanceOutside > dist then
				referencePoint.distanceOutside = dist
				referencePoint.targetIDOutside = targetLines
			end
		end)
	end)
end

local function buildDistancePointTarget(self, target, lines, netpoint)
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
	local targetPoints = buildPointTarget(self.lines, self.target)
	local network = buildDistancePointTarget(self, targetPoints, self.lines, conectedLines)

	return network
end

Network_ = {
	type_ = "Network"
}

metaTableNetwork_ = {
	__index = Network_
}

--- Type for network creation. Given geometry of the line type,
-- constructs a geometry network. This type is used to calculate the best path.
-- @arg data.error Error argument to connect the lines in the Network (optional).
-- If data.error case is not defined , assigned the value 0.
-- @arg data.lines CellularSpace with routes to create network.
-- @arg data.outside User-defined function that computes the distance based on an
-- Euclidean to enter and to leave the Network.
-- If not set a function, will return to own distance.
-- @arg data.progress print as values are being processed (optional).
-- @arg data.strategy Strategy to be used in the network (optional).
-- @arg data.target CellularSpace that receives end points of the networks.
-- @arg data.weight User defined function to change the network distance.
-- If not set a function, will return to own distance.
-- @usage import("gpm")
-- local roads = CellularSpace{
--     file = filePath("roads.shp", "gpm")
-- }
--
-- local communities = CellularSpace{
--     file = filePath("communities.shp", "gpm")
-- }
--
-- network = Network{
--     lines = roads,
--     target = communities,
--     progress = false,
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
function Network(data)
	verifyNamedTable(data)
	verifyUnnecessaryArguments(data, {"target", "lines", "strategy", "weight", "outside", "error", "progress"})
	mandatoryTableArgument(data, "lines", "CellularSpace")

	if data.lines.geometry then
		local cell = data.lines:sample()

		if not string.find(cell.geom:getGeometryType(), "Line") then
			customError("Argument 'lines' should be composed by lines, got '"..cell.geom:getGeometryType().."'.")
		end
	elseif data.lines.geometry == false then
		customError("The CellularSpace in argument 'lines' must be loaded without using argument 'geometry'.")
	end

	mandatoryTableArgument(data, "target", "CellularSpace")
	mandatoryTableArgument(data, "weight", "function")
	mandatoryTableArgument(data, "outside", "function")

	if data.target.geometry == false then
		customError("The CellularSpace in argument 'target' must be loaded without using argument 'geometry'.")
	end

	defaultTableValue(data, "strategy", "open")
	defaultTableValue(data, "error", 0)
	defaultTableValue(data, "progress", true)

	data.distance = createOpenNetwork(data)

	setmetatable(data, metaTableNetwork_)
	return data
end
