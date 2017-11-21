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

-- Support variables
local targetLines
local computedLines -- without taget lines

-- User-defined functions
local weight
local outside

local function createLineInfo(line)
	return {
		id = line.FID,
		geom = line.geom:getGeometryN(0),
		npoints = line.geom:getNPoints(),
		cell = line
	}
end

local function createLinesInfo(lines)
	local linesInfo = {}

	forEachCell(lines, function(line)
		linesInfo[line.FID] = createLineInfo(line)
	end)

	return linesInfo
end

local function addTargetInfoInLine(targetLine, targetPoint, distance)
	local closestPoint = targetPoint:closestPoint(targetLine.geom)
	targetLine.closestPoint = {id = closestPoint:asText(), point = closestPoint} -- closest point info
	targetLine.shortestPath = distance
	targetLines[targetLine.id] = targetLine
end

local function createTargetNode(point, distance, line)
	return {
		target = true,
		id = point:asText(),
		point = point,
		distance = distance,
		line = line, -- lines which the point belongs
		targetId = line.id
	}
end

local function createNode(point, distance, line, position, targetId)
	return {
		id = point:asText(),
		point = point,
		distance = distance,
		line = line, -- lines which the point belongs
		pos = position,
		targetId = targetId
	}
end

-- TODO(avancinirodrigo): this method can be improved by some tree
local function findAndAddTargetNodes(self)
	self.netpoints = {}

	forEachCell(self.target, function(target)
		local targetPoint = target.geom:getGeometryN(0)
		local minDistance = math.huge
		local targetLine

		forEachElement(self.lines, function(_, line)
			local distance = targetPoint:distance(line.geom)

			if distance < minDistance then
				minDistance = distance
				targetLine = line
			end
		end)

		addTargetInfoInLine(targetLine, targetPoint, minDistance)
		local closestPoint = targetLine.closestPoint

		if outside then
			targetLine.shortestPath = outside(targetLine.shortestPath)
		end

		self.netpoints[closestPoint.id] = createTargetNode(closestPoint.point,
												targetLine.shortestPath, targetLine)
	end)
end

-- TODO: review validate functions ------------------------------------------
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
-------------------------------------------------------------------------

local function findFirstPoint(targetNode)
	local line = targetNode.line
	local pointInfo = {}
	pointInfo.distance = math.huge

	for i = 0, line.npoints - 1 do
		local point = line.geom:getPointN(i)
		local distance = targetNode.point:distance(point)

		if pointInfo.distance > distance then
			pointInfo.point = point
			pointInfo.distance = distance
			pointInfo.pos = i
		end
	end

	if weight then
		pointInfo.distance = weight(pointInfo.distance, targetNode.line.cell)
	end

	return pointInfo
end

local function calculateFullDistance(node, point, line)
	local distance = node.point:distance(point) -- TODO: this can be improved using delta distance

	if weight then
		distance = weight(distance, line.cell)
	end

	return node.distance + distance
end

local function linkNodeToNext(node, nextNode)
	node.next = nextNode
	node.targetId = nextNode.targetId

	if nextNode.previous then
		if nextNode.router then
			table.insert(nextNode.previous, node)
		else
			nextNode.router = true
			local nextNodePrevious = nextNode.previous
			nextNode.previous = {}
			table.insert(nextNode.previous, nextNodePrevious)
			table.insert(nextNode.previous, node)
		end
	else
		nextNode.previous = node
	end
end

local function nodeExists(node)
	return node ~= nil
end

local function relinkToNextNode(node, nextNode, newDistance)
	nextNode.distance = newDistance

	linkNodeToNext(nextNode, node)

	if not nextNode.router then
		nextNode.previous = nil
	end
end

local function recalculatePreviousDistances(node, previousNode)
	if not previousNode then
		return
	end

	previousNode.distance = calculateFullDistance(node, previousNode.point, previousNode.line)
	previousNode.targetId = node.targetId
	recalculatePreviousDistances(previousNode, previousNode.previous)
end

local function removeOldRoute(routerNode, node) -- TODO: improve this name
	routerNode.line = node.line

	for i = 1, #routerNode.previous do
		if routerNode.previous[i].line.id == node.line.id then
			table.remove(routerNode.previous, i)
			return
		end
	end
end

local function convertRouterNodeToSimple(routerNode)
	local routerNodePrevious =  routerNode.previous[1]
	routerNode.previous = routerNodePrevious
	routerNode.router = nil
end

local function reviewRouterNode(routerNode, node)
	removeOldRoute(routerNode, node)

	for i = 1, #routerNode.previous do
		if routerNode.targetId ~= routerNode.previous[i].targetId then
			recalculatePreviousDistances(routerNode, routerNode.previous[i])
		end
	end

	if #routerNode.previous == 1 then
		convertRouterNodeToSimple(routerNode)
	end
end

local function reviewNextNodes(node, nextNode)
	if nextNode.target then
		if node.id == nextNode.first.id then
			nextNode.first = nil
		elseif node.id == nextNode.second.id then
			nextNode.second = nil
		else
			customError("Unforeseen error!") -- SKIP : TODO: it needs a test
		end

		return
	end

	local newDistance = calculateFullDistance(node, nextNode.point, node.line)

	if nextNode.distance > newDistance then
		local nextNodeNext = nextNode.next
		relinkToNextNode(node, nextNode, newDistance)
		reviewNextNodes(nextNode, nextNodeNext)
	elseif not nextNode.router then
		nextNode.previous = nil
	end

	if nextNode.router then
		reviewRouterNode(nextNode, node)
	end
end

local function reviewExistingNode(existingNode, currNode, newPosition)
	local newDistance = calculateFullDistance(currNode, existingNode.point, currNode.line)

	if existingNode.distance > newDistance then
		local existingNodeNext = existingNode.next
		relinkToNextNode(currNode, existingNode, newDistance)
		existingNode.line = currNode.line
		existingNode.pos = newPosition
		reviewNextNodes(existingNode, existingNodeNext)
	else
		reviewNextNodes(existingNode, currNode)
	end
end

local function createNodeByNextPoint(point, position, currNode, line)
	local totalDistance = calculateFullDistance(currNode, point, line)
	return createNode(point, totalDistance, line, position, currNode.targetId)
end

local function addAllNodesOfLineBackward(graph, line, node, nodePosition)
	if nodePosition == 0 then
		return
	else
		local i = nodePosition - 1
		local currNode = node
		while i >= 0 do
			local point = line.geom:getPointN(i)
			local nodeId = point:asText()

			if graph[nodeId] then
				reviewExistingNode(graph[nodeId], currNode, i)
			else
				local previousNode = createNodeByNextPoint(point, i, currNode, line)
				graph[nodeId] = previousNode
				linkNodeToNext(previousNode, currNode)
				currNode = previousNode
			end
			i = i - 1
		end
	end
end

local function addAllNodesOfLineForward(graph, line, node, nodePosition)
	if nodePosition == line.npoints - 1 then
		return
	else
		local currNode = node
		for i = nodePosition + 1, line.npoints - 1 do
			local point = line.geom:getPointN(i)
			local nodeId = point:asText()

			if nodeExists(graph[nodeId]) then
				reviewExistingNode(graph[nodeId], currNode, i)
			else
				local nextNode = createNodeByNextPoint(point, i, currNode, line)
				graph[nodeId] = nextNode
				linkNodeToNext(nextNode, currNode)
				currNode = nextNode
			end
		end
	end
end

local function findSecondPointInEnds(firstNode, targetNode)
	local line = targetNode.line
	local pointInfo = {}

	if firstNode.pos == 0 then
		pointInfo.point = line.geom:getPointN(1)
		pointInfo.pos = 1
	else
		local npoints = line.npoints
		if firstNode.pos == npoints - 1 then
			pointInfo.point = line.geom:getPointN(npoints - 2)
			pointInfo.pos = npoints - 2
		end
	end

	return pointInfo
end

local function findSecondPointInInterior(firstNode, targetNode)
	local line = targetNode.line
	local pointInfo = {}
	local pAfter = line.geom:getPointN(firstNode.pos + 1)
	local pBefore = line.geom:getPointN(firstNode.pos - 1)
	local xb = pBefore:getX()
	local xa = pAfter:getX()
	local xf = firstNode.point:getX()
	local xt = targetNode.point:getX()

	if xf > xb then
		if (xt > xb) and (xf > xt) then
			pointInfo.point = pBefore
			pointInfo.pos = firstNode.pos - 1
		elseif (xt < xa) and (xf < xt) then
			pointInfo.point = pAfter
			pointInfo.pos = firstNode.pos + 1
		else
			customError("Same x", xt, xb, xa, x1) -- TODO: needs test
		end
	else -- inverted line
		customError("Inverted line") -- TODO: needs test
	end

	return pointInfo
end

local function findSecondPoint(firstNode, targetNode)
	local pointInfo = findSecondPointInEnds(firstNode, targetNode)

	if #pointInfo == 0 then
		pointInfo = findSecondPointInInterior(firstNode, targetNode)
	end

	pointInfo.distance = calculateFullDistance(targetNode, pointInfo.point, targetNode.line)

	return pointInfo
end

local function linkFirstAndSecondNodes(targetNode, firstNode, secNode)
	targetNode.first = firstNode
	targetNode.second = secNode
	firstNode.next = targetNode
	secNode.next = targetNode
end

local function addAllNodesOfTargetLines(graph, firstNode, targetNode)
	local line = targetNode.line
	local secPoint = findSecondPoint(firstNode, targetNode)
	local secNode = createNode(secPoint.point, secPoint.distance, line, secPoint.pos, targetNode.targetId)
	graph[secNode.id] = secNode

	linkFirstAndSecondNodes(targetNode, firstNode, graph[secNode.id])

	if firstNode.pos == 0 then
		addAllNodesOfLineForward(graph, line, graph[secNode.id], graph[secNode.id].pos)
	else
		if firstNode.pos == line.npoints - 1 then
			addAllNodesOfLineBackward(graph, targetNode, firstNode, graph[secNode.id], firstNode.pos)
		else
			if secPoint.pos > firstNode.pos then
				addAllNodesOfLineForward(graph, line, graph[secNode.id], graph[secNode.id].pos)
				addAllNodesOfLineBackward(graph, line, firstNode, firstNode.pos)
			else
				addAllNodesOfLineForward(graph, line, firstNode, firstNode.pos)
				addAllNodesOfLineBackward(graph, line, graph[secNode.id], graph[secNode.id].pos)
			end
		end
	end
end

local function createFirstNode(targetNode)
	local firstPoint = findFirstPoint(targetNode)
	local totalDistance = targetNode.distance + firstPoint.distance
	return createNode(firstPoint.point, totalDistance, targetNode.line, firstPoint.pos, targetNode.targetId)
end

local function addFirstNodes(graph, node)
	local firstNode = createFirstNode(node)
	graph[firstNode.id] = firstNode

	addAllNodesOfTargetLines(graph, graph[firstNode.id], node)
end

local function copyGraphToNetpoints(netpoints, graph)
	forEachElement(graph, function(id, node)
		netpoints[id] = node
	end)
end

local function addNodesFromTargetLines(self)
	local graph = {}

	forEachElement(self.netpoints, function(id, node)
		graph[id] = node --< I don't want to change self.netpoints in this loop
		addFirstNodes(graph, node)
	end)

	copyGraphToNetpoints(self.netpoints, graph)
end

local function isAdjacentByPoints(p1, p2)
	return p1:distance(p2) == 0
end

local function isNodeBelongingToTargetLine(node, targetLine)
	return node.line.id == targetLine.id
end

local function isTargetLine(line)
	return targetLines[line.id] ~= nil
end

local function addNodesForward(self, targetLine, point, line)
	local nid = point:asText()
	local node = self.netpoints[nid]

	if isNodeBelongingToTargetLine(node, targetLine) then
		addAllNodesOfLineForward(self.netpoints, line, node, 0)
		computedLines[line.id] = line
	end
end

local function addNodesBackward(self, targetLine, point, line)
	local nid = point:asText()
	local node = self.netpoints[nid]

	if isNodeBelongingToTargetLine(node, targetLine) then
		addAllNodesOfLineBackward(self.netpoints, line, node, line.npoints - 1)
		computedLines[line.id] = line
	end
end

local function isLineUncomputed(line)
	return not (isTargetLine(line) or computedLines[line.id])
end

local function addNodesFromAdjacentsToTargetLines(self)
	forEachElement(targetLines, function(_, targetLine)
		local endpointsTarget = {first = targetLine.geom:getStartPoint(), last = targetLine.geom:getEndPoint()}

		forEachElement(self.lines, function(_, line)
			if isLineUncomputed(line) then
				local endpointsLine = {first = line.geom:getStartPoint(), last = line.geom:getEndPoint()}

				if isAdjacentByPoints(endpointsTarget.first, endpointsLine.first) then
					addNodesForward(self, targetLine, endpointsTarget.first, line)
				elseif isAdjacentByPoints(endpointsTarget.first, endpointsLine.last) then
					addNodesBackward(self, targetLine, endpointsTarget.first, line)
				elseif isAdjacentByPoints(endpointsTarget.last, endpointsLine.first) then
					addNodesForward(self, targetLine, endpointsTarget.last, line)
				elseif isAdjacentByPoints(endpointsTarget.last, endpointsLine.last) then
					addNodesBackward(self, targetLine, endpointsTarget.last, line)
				end
			end
		end)
	end)
end

local function isLineAlreadyComputed(line)
	return computedLines[line.id] ~= nil
end

local function hasUncomputedLines(self)
	return getn(computedLines) + getn(targetLines) ~= getn(self.lines)
end

local function addNodesFromNonAdjacentsToTargetLines(self)
	forEachElement(self.lines, function(_, line)
		if isLineAlreadyComputed(line) then
			local endpointsLine = {first = line.geom:getStartPoint(), last = line.geom:getEndPoint()}

			forEachElement(self.lines, function(_, uline)
				if isLineUncomputed(uline) then
					local endpointsULine = {first = uline.geom:getStartPoint(), last = uline.geom:getEndPoint()}

					if isAdjacentByPoints(endpointsLine.first, endpointsULine.first) then
						addNodesForward(self, line, endpointsLine.first, uline)
					elseif isAdjacentByPoints(endpointsLine.first, endpointsULine.last) then
						addNodesBackward(self, line, endpointsLine.first, uline)
					elseif isAdjacentByPoints(endpointsLine.last, endpointsULine.first) then
						addNodesForward(self, line, endpointsLine.last, uline)
					elseif isAdjacentByPoints(endpointsLine.last, endpointsULine.last) then
						addNodesBackward(self, line, endpointsLine.last, uline)
					end
				end
			end)
		end
	end)

	if hasUncomputedLines(self) then
		addNodesFromNonAdjacentsToTargetLines(self)
	end
end

local function createConnectivityInfoGraph(self)
	addNodesFromTargetLines(self)
	addNodesFromAdjacentsToTargetLines(self)
	addNodesFromNonAdjacentsToTargetLines(self)
end

local function createOpenNetwork(self)
	weight = self.weight
	outside = self.outside
	self.lines = createLinesInfo(self.lines)
	findAndAddTargetNodes(self)
	createConnectivityInfoGraph(self)
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

	targetLines = {}
	computedLines = {}

	createOpenNetwork(data)

	setmetatable(data, metaTableNetwork_)
	return data
end
