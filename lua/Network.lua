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

local function createNode(point)
	return {
		point = point,
		adjacents = {},
		distance = math.huge,
		distanceOutside = math.huge,
		arcs = {} -- lines which the point belongs
	}
end

local function connectNodeToAdjacentPoint(node, point)
	table.insert(node.adjacents, point:asText())
end

local function connectNodeToAdjacentPointById(node, pointId)
	table.insert(node.adjacents, pointId)
end

local function addNodeInGraphIfNodeNotExists(graph, id, point)
	local node = createNode(point)
	graph[id] = node
end

local function insertNodeArcRelation(node, arcId, line)
	node.arcs[arcId] = line
end

local function insertNodeInGraph(graph, id, point, line)
	if not graph[id] then
		addNodeInGraphIfNodeNotExists(graph, id, point)
	end

	insertNodeArcRelation(graph[id], line.FID, line)
end

local function connectEndpointsOfLine(graph, line)
	local lineObj = line.geom:getGeometryN(0)
	local firstPoint = lineObj:getStartPoint()
	local lastPoint = lineObj:getEndPoint()
	local fpid = firstPoint:asText()
	local lpid = lastPoint:asText()

	insertNodeInGraph(graph, fpid, firstPoint, line)
	connectNodeToAdjacentPoint(graph[fpid], lastPoint)

	insertNodeInGraph(graph, lpid, lastPoint, line)
	connectNodeToAdjacentPoint(graph[lpid], firstPoint)


	line.firstPoint = {point = firstPoint, id = fpid}
	line.lastPoint = {point = lastPoint, id = lpid}
	line.lineObj = lineObj
end

local function connectInteriorPointsOfLine(graph, line)
	local nPoints = line.lineObj:getNPoints()

	if nPoints > 2 then
		for i = 0, nPoints - 1 do
			local currPoint = line.lineObj:getPointN(i)
			local id = currPoint:asText()

			insertNodeInGraph(graph, id, currPoint, line)

			local afterPoint
			local beforePoint

			if i == 0 then
				afterPoint = line.lineObj:getPointN(i + 1)
				connectNodeToAdjacentPoint(graph[id], afterPoint)
			elseif i == nPoints - 1 then
				beforePoint = line.lineObj:getPointN(i - 1)
				connectNodeToAdjacentPoint(graph[id], beforePoint)
			else
				beforePoint = line.lineObj:getPointN(i - 1)
				afterPoint = line.lineObj:getPointN(i + 1)
				connectNodeToAdjacentPoint(graph[id], beforePoint)
				connectNodeToAdjacentPoint(graph[id], afterPoint)
			end
		end
	end
end

local function hasConnectionWithAnotherLine(line, lines)
	for i = 1, #lines do
		if line.FID ~= lines[i].FID then
			if line.lineObj:touches(lines[i].lineObj) then
				return true
			end
		end
	end

	return false
end

local function checkIfAllLinesAreConnected(lines)
	for i = 1, #lines.cells do
		if not hasConnectionWithAnotherLine(lines.cells[i], lines.cells) then
			customError("The network is disconected.")
		end
	end
end

local function checkIfLineCrossesError(lines)
	for i = 1, #lines.cells do
		for j = i + 1, #lines.cells do
			if lines.cells[i].lineObj:crosses(lines.cells[j].lineObj) then
				customError("Lines '"..lines.cells[i].FID.."' and '"..lines.cells[j].FID.."' cross each other.")
			end
		end
	end
end

-- local cacheDistance = {}

-- local function insertCacheDistance(p1Id, p2Id, distance)
	-- cacheDistance[p1Id] = {}
	-- cacheDistance[p1Id][p2Id] = distance
	-- cacheDistance[p2Id] = {}
	-- cacheDistance[p2Id][p1Id] = distance
-- end

-- TODO(avancinirodrigo): review cache's use
-- local function getDistance(p1, p2)
	-- --local distance

	-- -- if not cacheDistance[p1.id] then --
		-- -- distance = p1.point:distance(p2.point)
		-- -- insertCacheDistance(p1.id, p2.id, distance)
	-- -- elseif cacheDistance[p1.id][p2.id] then
		-- -- distance = cacheDistance[p1.id][p2.id]
	-- -- else
		-- -- --if not cacheDistance[p1.id][p2.id] then
		-- -- distance = p1.point:distance(p2.point)
		-- -- insertCacheDistance(p1.id, p2.id, distance)
	-- -- -- else
		-- -- -- distance = cacheDistance[p1.id][p2.id]
	-- -- end

	-- -- return distance
	-- return p1.point:distance(p2.point)
-- end

local function connectNodesToAdjacentLinesConsideringError(self, graph)
	forEachCell(self.lines, function(lineA)
		local endpointsA = {lineA.firstPoint, lineA.lastPoint}
		local hasAdjacent = false
		local minDistance = math.huge

		for i = 1, #endpointsA do
			local endpointA = endpointsA[i]

			forEachCell(self.lines, function(lineB)
				if lineB.FID ~= lineA.FID then
					local endpointsB = {lineB.firstPoint, lineB.lastPoint}

					for j = 1, #endpointsB do
						local endpointB = endpointsB[j]
						local distance = endpointA.point:distance(endpointB.point)

						if distance <= self.error then
							if j == 1 then
								connectNodeToAdjacentPointById(graph[endpointA.id], endpointsB[2].id)
							else
								connectNodeToAdjacentPointById(graph[endpointA.id], endpointsB[1].id)
							end

							hasAdjacent = true
						end

						if minDistance > distance then
							minDistance = distance
						end
					end
				end
			end)
		end

		if not hasAdjacent then
			customError("Line: '"..lineA.FID.."' does not touch any other line. The minimum distance found was: "..minDistance..".")
		end
	end)
end

local function createInteriorRelationOfLines(self, graph)
	forEachCell(self.lines, function(line)
		connectEndpointsOfLine(graph, line)
		connectInteriorPointsOfLine(graph, line)
	end)
end

local function createConnectivityInfoGraph(self)
	local graph = {}

	createInteriorRelationOfLines(self, graph)
	checkIfLineCrossesError(self.lines)
	connectNodesToAdjacentLinesConsideringError(self, graph)
	checkIfAllLinesAreConnected(self.lines) -- TODO: review this checking

	return graph
end

local function addTargetInfoInLine(line, pointObj, distance)
	line.closestPoint = pointObj:closestPoint(line.lineObj)
	line.shortestPath = distance
end

-- TODO(avancinirodrigo): this method can be improved by some tree
local function createClosestLinesToTargets(self)
	local closestLinesToTargets = {}

	forEachCell(self.target, function(target)
		local pointObj = target.geom:getGeometryN(0)
		local minDistance = math.huge
		local targetLine

		forEachCell(self.lines, function(line)
			local distance = pointObj:distance(line.lineObj)

			if distance < minDistance then
				minDistance = distance
				targetLine = line
			end
		end)

		addTargetInfoInLine(targetLine, pointObj, minDistance)
		table.insert(closestLinesToTargets, targetLine)
	end)

	return closestLinesToTargets
end

local function connectEachNodeToTargetClosestLines(self, graph, closestLinesToTargets)
	local progress = 0
	local graphSize = getn(graph)

	forEachElement(graph, function(_, node)
		local nodePoint = node.point

		if self.progress then
			progress = progress + 1 -- SKIP
			print(table.concat{"Computing distance outside ", progress, "/", graphSize}) -- SKIP
		end

		for i = 1, #closestLinesToTargets do
			local closestLine = closestLinesToTargets[i]
			local distance = nodePoint:distance(closestLine.closestPoint)

			if node.distanceOutside > distance then
				node.distanceOutside = distance
				node.targetIDOutside = i
			end
		end
	end)
end

local function isWeightChanged(node, weight)
	return node.distance > weight
end

local function insertNodeWeightInfo(node, weight, targetId)
	node.distance = weight
	node.targetID = targetId
end

local function calcWeightedDistance(p1Obj, p2Obj, weight, line)
	local distance = p1Obj:distance(p2Obj)
	return weight(distance, line)
end

local function includeWeightToNodesThatBelongClosestLines(self, graph, closestLinesToTargets)
	for i = 1, #closestLinesToTargets do
		local closestLine = closestLinesToTargets[i]

		if self.progress then
			print(table.concat{"Reducing distances ", i, "/", #closestLinesToTargets}) -- SKIP
		end

		local nPoints = closestLine.lineObj:getNPoints()

		for j = 0, nPoints - 1 do
			local point = closestLine.lineObj:getPointN(j)
			local pointId = point:asText()
			local distWeighted = calcWeightedDistance(point, closestLine.closestPoint,
													self.weight, closestLine)
			local node = graph[pointId]

			if isWeightChanged(node, distWeighted) then
				insertNodeWeightInfo(node, distWeighted, i)
			end
		end
	end
end

local function isNodeWeighted(node)
	return node.distance ~= math.huge
end

local function checkIfNodeWeightWasSetOrUpdated(node, adjacentNode, weight, line)
	if isNodeWeighted(adjacentNode) then
		local distWeighted = calcWeightedDistance(node.point, adjacentNode.point, weight, line)
		distWeighted = distWeighted + adjacentNode.distance

		if isWeightChanged(node, distWeighted) then
			insertNodeWeightInfo(node, distWeighted, adjacentNode.targetID) --< insert means create or update
			return true
		end
	end

	return false
end

local function checkInNodeArcs(node, adjacentNode, weight)
	local changed = false
	for _, line in pairs(node.arcs) do
		changed = checkIfNodeWeightWasSetOrUpdated(node, adjacentNode, weight, line)
	end
	return changed
end

local function checkInAdjancentNodeArcs(node, adjacentNode, weight)
	local changed = false

	for id, line in pairs(adjacentNode.arcs) do
		if not node.arcs[id] then --< don't need to check again, it was already checked above
			changed = checkIfNodeWeightWasSetOrUpdated(node, adjacentNode, weight, line)
		end
	end

	return changed
end

local function checkIfNodeWeightWasChangedByAdjacentNode(node, adjacentNode, weight)
	return checkInNodeArcs(node, adjacentNode, weight) or
			checkInAdjancentNodeArcs(node, adjacentNode, weight)
end

local function checkIfNodeWeightWasChanged(self, graph, node)
	local changed = false

	for i = 1, #node.adjacents do
		local adjacentId = node.adjacents[i]
		local adjacentNode = graph[adjacentId]
		changed = checkIfNodeWeightWasChangedByAdjacentNode(node, adjacentNode, self.weight)
	end

	return changed
end

local function hasWeightToInclude(self, graph)
	local changed = false

	forEachElement(graph, function(_, node)
		if checkIfNodeWeightWasChanged(self, graph, node) then
			changed = true
		end
	end)

	return changed
end

local function includeWeightToAllNodes(self, graph)
	while hasWeightToInclude(self, graph) do end
end

local function createOpenNetwork(self)
	local graph = createConnectivityInfoGraph(self)
	local closestLinesToTargets = createClosestLinesToTargets(self)

	connectEachNodeToTargetClosestLines(self, graph, closestLinesToTargets)
	includeWeightToNodesThatBelongClosestLines(self, graph, closestLinesToTargets)
	includeWeightToAllNodes(self, graph)

	return {
		netpoint = graph,
		target = closestLinesToTargets,
		lines = self.lines
	}
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
