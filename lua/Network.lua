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
local computedLines -- without target lines
local nonAdjacentLinesCache
local adjacentLines
local targetNodes
local nodesList
local linesList
local linesNodesList

-- User-defined functions
local inside
local outside

local Direction = {
	forward = 0,
	backward = 1
}

local LineAdjancency = {
	firstTofirst = 1,
	firstTolast = 2,
	lastTofirst = 3,
	lastTolast = 4,
}

local function addLineEndpointsInfo(line)
	line.first = {}
	line.last = {}
	line.first.point = line.geom:getStartPoint()
	line.last.point = line.geom:getEndPoint()
	line.first.id = line.first.point:asText()
	line.last.id = line.last.point:asText()
end

local function createLineInfo(line)
	local lineInfo = {
		id = line.FID,
		geom = line.geom:getGeometryN(0),
		npoints = line.geom:getNPoints(),
		cell = line,
	}

	addLineEndpointsInfo(lineInfo)
	table.insert(linesList, lineInfo)

	return lineInfo
end

local function createLinesInfo(lines)
	local linesInfo = {}

	forEachCell(lines, function(line)
		linesInfo[line.FID] = createLineInfo(line)
	end)

	return linesInfo
end

local function fixTargetPointIfEqualsToEndpoint(closestPoint, targetLine)
	local closestPointId = closestPoint:asText()
	if (closestPointId == targetLine.first.id) or (closestPointId == targetLine.last.id) then
		if targetLine.last.point:getX() > targetLine.first.point:getX() then
			closestPoint:setX(closestPoint:getX() + 1)
		else
			closestPoint:setX(closestPoint:getX() - 1)
		end
		return closestPoint:asText()
	end

	return closestPointId
end

local function createClosestPointInLine(targetPoint, targetLine)
	local closestPoint = targetPoint:closestPoint(targetLine.geom)
	local closestPointId = fixTargetPointIfEqualsToEndpoint(closestPoint, targetLine)
	return {id = closestPointId, point = closestPoint}
end

local function addTargetInfoInLine(targetLine, closestPoint, distance)
	targetLine.closestPoint = closestPoint
	targetLine.shortestPath = distance
	targetLines[targetLine.id] = targetLine
end

local function createTargetNode(point, distance, line, targetId, targetPoint)
	return {
		target = true,
		id = point:asText(),
		point = point,
		distance = distance,
		line = line, -- lines which the point belongs
		targetId = targetId,
		targetPoint = targetPoint
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

local function findClosestLine(lines, point)
	local minDistance = math.huge
	local closestLine
	forEachElement(lines, function(_, line)
		local distance = point:distance(line.geom)
		if minDistance > distance then
			minDistance = distance
			closestLine = line
		end
	end)

	if outside then
		minDistance = outside(minDistance)
	end

	return {line = closestLine, distance = minDistance}
end

local function checkAndRemoveTargetIfLineHasMoreThanOneOfIt(targets)
	local targetList = {}
	for _, node in pairs(targets) do
		table.insert(targetList, node)
	end

	local targetsToRemove = {}

	for i = 1, #targetList do
		local n1 = targetList[i]
		if not targetsToRemove[n1.id] then
			for j = i + 1, #targetList do
				local n2 = targetList[j]
				if not targetsToRemove[n2.id] then
					if n1.line.id == n2.line.id then
						local dist = n1.point:distance(n2.point)

						if inside then
							dist = inside(dist, n1.line.cell)
						end

						if (n1.distance > dist) and (n1.distance > n2.distance) then
							targetsToRemove[n1.id] = true
						elseif (n2.distance > dist) and (n2.distance > n1.distance) then
							targetsToRemove[n2.id] = true
						end
					end
				end
			end
		end
	end

	for id, node in pairs(targets) do
		if targetsToRemove[id] then
			customWarning("Line '"..node.line.id.."' has more than one target. Target '"..node.targetId
							.."' is too far with distance '"..node.distance.."' and it was removed.")
			targets[id] = nil
		end
	end
end

-- TODO(avancinirodrigo): this method can be improved by some tree
local function findAndAddTargetNodes(self)
	self.netpoints = {}

	forEachCell(self.target, function(target)
		local targetPoint = target.geom:getGeometryN(0)
		local targetId = tonumber(target:getId())
		local closestLine = findClosestLine(self.lines, targetPoint)
		local targetLine = closestLine.line
		local closestPoint = createClosestPointInLine(targetPoint, closestLine.line)

		addTargetInfoInLine(closestLine.line, closestPoint, closestLine.distance)

		self.netpoints[closestPoint.id] = createTargetNode(closestPoint.point,
												targetLine.shortestPath, targetLine, targetId, targetPoint)
	end)

	checkAndRemoveTargetIfLineHasMoreThanOneOfIt(self.netpoints)

	for _, node in pairs(self.netpoints) do
		table.insert(targetNodes, node)
		table.insert(nodesList, node)
	end
end

local function checkIfLineCrosses(lineA, lineB)
	return lineA.geom:crosses(lineB.geom)
end

local function calculateMinDistance(endpointsA, endpointsB)
	local distances = {}
	distances[LineAdjancency.firstTofirst] = endpointsA.first.point:distance(endpointsB.first.point)
	distances[LineAdjancency.firstTolast] = endpointsA.first.point:distance(endpointsB.last.point)
	distances[LineAdjancency.lastTofirst] = endpointsA.last.point:distance(endpointsB.first.point)
	distances[LineAdjancency.lastTolast] = endpointsA.last.point:distance(endpointsB.last.point)

	local minDistance = math.huge
	local lineAdjacency
	for i = 1, 4 do
		if minDistance > distances[i] then
			minDistance = distances[i]
			lineAdjacency = i
		end
	end

	return {distance = minDistance, adjacency = lineAdjacency}
end

local function addAdjacentLineInfo(line, oline, minDistanceInfo)
	table.insert(adjacentLines[line.id], {id = oline.id, distance = minDistanceInfo.distance, adjacency = minDistanceInfo.adjacency})
end

local function invertAdjacentLineInfo(minDistanceInfo)
	if minDistanceInfo.adjacency == LineAdjancency.firstTolast then
		minDistanceInfo.adjacency = LineAdjancency.lastTofirst
	elseif minDistanceInfo.adjacency == LineAdjancency.lastTofirst then
		minDistanceInfo.adjacency = LineAdjancency.firstTolast
	end
	return minDistanceInfo
end

local function progressMsg(current, total, action)
	return "Network "..action.." "..getn(current).." of "..getn(total).." lines."
end

local function updateProgressMsg(self, current, action)
	if self.progress then
		io.write(progressMsg(current, self.lines, action), "\r")
		io.flush()
	end
end

local function finalizeProgressMsg(self, current, action)
	if self.progress then
		io.write("                                               ", "\r")
		io.flush()
		print(progressMsg(current, self.lines, action))
	end
end

local function addTableKeyIfNotExists(tbl, key)
	if not tbl[key] then
		tbl[key] = {}
	end
end

local function findAndAddAjacentLines(self)
	for i = 1, #linesList do
		updateProgressMsg(self, adjacentLines, "reading")
		addTableKeyIfNotExists(adjacentLines, linesList[i].id)
		for j = i + 1, #linesList do
			local minDistanceInfo = calculateMinDistance(linesList[i], linesList[j])
			if minDistanceInfo.distance <= self.error then
				addAdjacentLineInfo(linesList[i], linesList[j], minDistanceInfo)
				addTableKeyIfNotExists(adjacentLines, linesList[j].id)
				addAdjacentLineInfo(linesList[j], linesList[i], invertAdjacentLineInfo(minDistanceInfo))
			end
		end
	end

	finalizeProgressMsg(self, adjacentLines, "reading")
end

local function addNonAdjacentLinesCache(lineAId, lineBId)
	if not nonAdjacentLinesCache[lineAId] then
		nonAdjacentLinesCache[lineAId] = {}
	end

	if not nonAdjacentLinesCache[lineBId] then
		nonAdjacentLinesCache[lineBId] = {}
	end

	nonAdjacentLinesCache[lineAId][lineBId] = true
	nonAdjacentLinesCache[lineBId][lineAId] = true
end

local function isLinesNonAdjacent(lineAId, lineBId)
	if nonAdjacentLinesCache[lineAId] and nonAdjacentLinesCache[lineAId][lineBId] then
		return true
	end

	return false
end

local function validateLine(self, line, linesValidated, linesConnected)
	local lineMinDistance = math.huge
	adjacentLines[line.id] = {}

	for _, oline in pairs(self.lines) do
		if oline.id ~= line.id then
			if checkIfLineCrosses(line, oline) then
				customError("Lines '"..line.id.."' and '"..oline.id.."' cross each other.")
			end

			if not isLinesNonAdjacent(line.id, oline.id) then
				local minDistanceInfo = calculateMinDistance(line, oline)

				if minDistanceInfo.distance <= self.error then
					linesValidated[line.id] = true
					if not linesConnected[oline.id] then
						linesConnected[oline.id] = {}
						table.insert(linesConnected[oline.id], oline.id)
					end

					table.insert(linesConnected[oline.id], line.id)
					addAdjacentLineInfo(line, oline, minDistanceInfo)
				elseif lineMinDistance > minDistanceInfo.distance then
					lineMinDistance = minDistanceInfo.distance
				else
					addNonAdjacentLinesCache(line.id, oline.id)
				end
			end
		end
	end

	if not linesValidated[line.id] then
		customError("Line '"..line.id.."' does not touch any other line. The minimum distance found was: "..lineMinDistance..". "
				.."If this distance can be ignored, use argument 'error'. Otherwise, fix the line.")
	end
end

local function hasConnection(linesA, linesB)
	for a = 1, #linesA do
		for b = 1, #linesB do
			if linesA[a] == linesB[b] then
				return true
			end
		end
	end

	return false
end

local function valueExists(tbl, value)
	for i = 1, #tbl do
		if tbl[i] == value then
			return true
		end
	end

	return false
end

local function joinLines(linesA, linesB)
	for i = 1, #linesB do
		if not valueExists(linesA, linesB[i]) then
			table.insert(linesA, linesB[i])
		end
	end
end

local function progressConnectingMsg(linesConnected)
	return "Network number of networks "..getn(linesConnected).."."
end

local function joinConnectedLines(self, linesConnected)
	local hadSomeJunction = false

	if self.progress then
		io.write(progressConnectingMsg(linesConnected), "\r")
		io.flush()
	end

	forEachElement(linesConnected, function(a, linesA)
		if not linesA then return end

		forEachElement(linesConnected, function(b, linesB)
			if a ~= b and linesB and hasConnection(linesA, linesB) then
				joinLines(linesA, linesB)
				linesConnected[b] = false
				hadSomeJunction = true
			end
		end)
	end)

	if hadSomeJunction then
		forEachElement(linesConnected, function(id)
			if not linesConnected[id] then
				linesConnected[id] = nil
			end
		end)

		joinConnectedLines(self, linesConnected)
	end
end

local function isNetworkConnected(self, linesConnected)
	joinConnectedLines(self, linesConnected)

	if self.progress then
		io.write("                                               ", "\r")
		io.flush()
		print(progressConnectingMsg(linesConnected))
	end

	if getn(linesConnected) > 1 then
		return false
	end

	return true
end

local function addNetIdInfo(netIdName, cs, linesConnected)
	local netId = 0
	for _, v in pairs(linesConnected) do
		forEachCell(cs, function(cell)
			if not cell[netIdName] then
				for i = 1, #v do
					if cell.FID == v[i] then
						cell[netIdName] = netId
					end
				end
			end
		end)
		netId = netId + 1
	end
end

local function saveErrorInfo(self, linesConnected)
	local gis = getPackage("gis")
	local linesCs = self.linesCs
	local errorLayerName = "neterror"
	local netIdName = "net_id"
	local errMsg

	if linesCs.project then
		addNetIdInfo(netIdName, linesCs, linesConnected)
		linesCs:save(errorLayerName, netIdName)
		errMsg = "Layer '"..errorLayerName.."' was automatically created with attribute '"
				..netIdName.."' containing the separated networks."
	else
		local proj = gis.Project{
			file = "network_report.tview",
			clean = true,
			author = "TerraME-Network",
			title = "Error Report"
		}

		local linesCsLayer = gis.Layer{
			project = proj,
			name = errorLayerName,
			file = linesCs.file
		}

		local cs = CellularSpace{
			project = proj,
			layer = linesCsLayer.name,
			missing = linesCs.missing
		}

		addNetIdInfo(netIdName, cs, linesConnected)
		cs:save(linesCsLayer.name, netIdName)
		proj.file:delete()
		errMsg = "Data '"..errorLayerName.."."..File(linesCsLayer.file):extension()
				.. "' was automatically created with attribute '"
				..netIdName.."' containing the separated networks."
	end

	return errMsg
end

local function validateLines(self)
	local linesValidated = {}
	local linesConnected = {}

	for _, line in pairs(self.lines) do
		updateProgressMsg(self, linesValidated, "validating")
		validateLine(self, line, linesValidated, linesConnected)
	end

	nonAdjacentLinesCache = nil

	finalizeProgressMsg(self, linesValidated, "validating")

	if not isNetworkConnected(self, linesConnected) then
		local errMsg = saveErrorInfo(self, linesConnected)
		customError("The network is disconnected. "..errMsg)
	end
end

local function findFirstPoint(closetPoint, line)
	local pointInfo = {}
	pointInfo.distance = math.huge

	for i = 0, line.npoints - 1 do
		local point = line.geom:getPointN(i)
		local distance = closetPoint:distance(point)

		if (pointInfo.distance > distance) and (distance > 0) then
			pointInfo.point = point
			pointInfo.distance = distance
			pointInfo.pos = i
		end
	end

	if inside then
		pointInfo.distance = inside(pointInfo.distance, line.cell)
	end

	return pointInfo
end

local function calculateFullDistance(node, point, line)
	local distance = node.point:distance(point) -- TODO: this can be improved using delta distance

	if inside then
		distance = inside(distance, line.cell)
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

local reviewRouterNode -- forward function

local function recalculatePreviousDistances(node, previousNode)
	if not previousNode then
		return
	end

	if previousNode.router then
		reviewRouterNode(previousNode, node)
		return
	end

	previousNode.distance = calculateFullDistance(node, previousNode.point, previousNode.line)
	previousNode.targetId = node.targetId
	recalculatePreviousDistances(previousNode, previousNode.previous)
end

local function adjustRouterNodeLine(routerNode, newLine)
	routerNode.line = newLine

	if routerNode.id == newLine.geom:getPointAsTextAt(0) then
		routerNode.pos = 0
	else
		routerNode.pos = newLine.npoints - 1
	end
end

local function removeOldRoute(routerNode, lineToRemove) -- TODO: improve this name
	for i = 1, #routerNode.previous do
		if routerNode.previous[i].line.id == lineToRemove.id then
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

reviewRouterNode = function(routerNode, node)
	adjustRouterNodeLine(routerNode, node.line)
	removeOldRoute(routerNode, node.line)

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

local function reviewExistingNode(existingNode, currNode, newPosition, newLine)
	local newDistance = calculateFullDistance(currNode, existingNode.point, currNode.line)

	if existingNode.distance > newDistance then
		local existingNodeNext = existingNode.next
		relinkToNextNode(currNode, existingNode, newDistance)

		if newLine.npoints == 2 then
			existingNode.line = newLine
		elseif existingNodeNext.router and (existingNode.line.npoints == 2) and
				(existingNodeNext.line.id ~= existingNode.line.id) then
			removeOldRoute(existingNodeNext, existingNode.line)
			existingNode.line = currNode.line
			existingNode.pos = newPosition
			return
		else
			existingNode.line = currNode.line
		end

		existingNode.pos = newPosition
		reviewNextNodes(existingNode, existingNodeNext)
	else
		reviewNextNodes(existingNode, currNode)
	end
end

local function createNodeByNextPoint(point, position, currNode, line)
	local totalDistance = calculateFullDistance(currNode, point, line)
	local node = createNode(point, totalDistance, line, position, currNode.targetId)
	table.insert(nodesList, node)
	return node
end

local function addAllNodesOfLineBackward(graph, line, node, nodePosition)
	if nodePosition == 0 then return end

	local i = nodePosition - 1
	local currNode = node
	while i >= 0 do
		local point = line.geom:getPointN(i)
		local nodeId = point:asText()

		if graph[nodeId] then
			reviewExistingNode(graph[nodeId], currNode, i, line)
		else
			local previousNode = createNodeByNextPoint(point, i, currNode, line)
			graph[nodeId] = previousNode
			linkNodeToNext(previousNode, currNode)
			currNode = previousNode
		end

		i = i - 1
	end
end

local function addAllNodesOfLineForward(graph, line, node, nodePosition)
	if nodePosition == line.npoints - 1 then return end

	local currNode = node
	for i = nodePosition + 1, line.npoints - 1 do
		local point = line.geom:getPointN(i)
		local nodeId = point:asText()

		if nodeExists(graph[nodeId]) then
			reviewExistingNode(graph[nodeId], currNode, i, line)
		else
			local nextNode = createNodeByNextPoint(point, i, currNode, line)
			graph[nodeId] = nextNode
			linkNodeToNext(nextNode, currNode)
			currNode = nextNode
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

local function isPointBetween(pTarget, pFirst, pOther)
	local xt = pTarget:getX()
	local xf = pFirst:getX()
	local xo = pOther:getX()

	if ((xo < xt) and (xt < xf)) or ((xo > xt) and (xt > xf)) then
		return true
	end

	return false
end

local function findSecondPointInInterior(firstNode, targetNode)
	local line = targetNode.line
	local pointInfo = {}
	local pAfter = line.geom:getPointN(firstNode.pos + 1)
	local pBefore = line.geom:getPointN(firstNode.pos - 1)

	if isPointBetween(targetNode.point, firstNode.point, pAfter) then
		pointInfo.point = pAfter
		pointInfo.pos = firstNode.pos + 1
	else
		pointInfo.point = pBefore
		pointInfo.pos = firstNode.pos - 1
	end

	return pointInfo
end

local function findSecondPoint(firstNode, targetNode)
	local pointInfo = findSecondPointInEnds(firstNode, targetNode)

	local hasNotFound = not pointInfo.point
	if hasNotFound then
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
	table.insert(nodesList, secNode)

	linkFirstAndSecondNodes(targetNode, firstNode, graph[secNode.id])

	if firstNode.pos == 0 then
		addAllNodesOfLineForward(graph, line, graph[secNode.id], graph[secNode.id].pos)
	elseif firstNode.pos == line.npoints - 1 then
		addAllNodesOfLineBackward(graph, line, graph[secNode.id], graph[secNode.id].pos)
	elseif secPoint.pos > firstNode.pos then
		addAllNodesOfLineForward(graph, line, graph[secNode.id], graph[secNode.id].pos)
		addAllNodesOfLineBackward(graph, line, firstNode, firstNode.pos)
	else
		addAllNodesOfLineForward(graph, line, firstNode, firstNode.pos)
		addAllNodesOfLineBackward(graph, line, graph[secNode.id], graph[secNode.id].pos)
	end
end

local function createFirstNode(targetNode)
	local firstPoint = findFirstPoint(targetNode.point, targetNode.line)
	local totalDistance = targetNode.distance + firstPoint.distance
	return createNode(firstPoint.point, totalDistance, targetNode.line, firstPoint.pos, targetNode.targetId)
end

local function addFirstNodes(graph, node)
	local firstNode = createFirstNode(node)
	graph[firstNode.id] = firstNode
	table.insert(nodesList, firstNode)

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

local function isNodeBelongingToTargetLine(node, targetLine)
	return node.line.id == targetLine.id
end

local function isTargetLine(line)
	return targetLines[line.id] ~= nil
end

local function isNodeEndpoint(node)
	return (node.pos == 0) or (node.pos == node.line.npoints - 1)
end

local function totalComputedLines()
	return getn(computedLines) + getn(targetLines)
end

local function progressProcessingMsg(lines)
	return "Network processing "..totalComputedLines().." of "..getn(lines).." lines."
end

local function addNodesInDirection(self, line, lineEndpointId, lineToAdd, direction)
	local node = self.netpoints[lineEndpointId]

	if not node then
		customError("Line '"..line.id.."' was added due to the value of argument 'error' ("..self.error
					.."). Please, remove the argument 'error' and fix the disconnected lines.")
	elseif not isNodeEndpoint(node) then
		customError("Line '"..node.line.id.."' crosses touching lines '"..line.id
					.."' and '"..lineToAdd.id.."' in their endpoints. Please, split line '"..node.line.id
					.."' in two where they cross.")
	elseif isNodeBelongingToTargetLine(node, line) then
		if direction == Direction.forward then
			addAllNodesOfLineForward(self.netpoints, lineToAdd, node, 0)
		else
			addAllNodesOfLineBackward(self.netpoints, lineToAdd, node, lineToAdd.npoints - 1)
		end
		computedLines[lineToAdd.id] = lineToAdd

		if self.progress then
			io.write(progressProcessingMsg(self.lines), "\r")
			io.flush()
		end
	end
end

local function isLineUncomputed(line)
	return not (isTargetLine(line) or computedLines[line.id])
end

local function addAdjacentLinesAndItsPoints(self, line, adjacents)
	for i = 1, #adjacents do
		local adjacent = self.lines[adjacents[i].id]
		if isLineUncomputed(adjacent) then
			if adjacents[i].adjacency == LineAdjancency.firstTofirst then
				addNodesInDirection(self, line, line.first.id, adjacent, Direction.forward)
			elseif adjacents[i].adjacency == LineAdjancency.firstTolast then
				addNodesInDirection(self, line, line.first.id, adjacent, Direction.backward)
			elseif adjacents[i].adjacency == LineAdjancency.lastTofirst then
				addNodesInDirection(self, line, line.last.id, adjacent, Direction.forward)
			elseif adjacents[i].adjacency == LineAdjancency.lastTolast then
				addNodesInDirection(self, line, line.last.id, adjacent, Direction.backward)
			end
		end
	end
end

local function addNodesFromAdjacentsToTargetLines(self)
	for _, targetLine in pairs(targetLines) do
		addAdjacentLinesAndItsPoints(self, targetLine, adjacentLines[targetLine.id])
	end
end

local function isLineAlreadyComputed(line)
	return computedLines[line.id] ~= nil
end

local function hasUncomputedLines(self)
	return totalComputedLines() ~= getn(self.lines)
end

local function unexpectedError(self)
	local uncomputedLinesIds = {}
	for _, line in pairs(self.lines) do
		if isLineUncomputed(line) then
			table.insert(uncomputedLinesIds, line.id)
		end
	end

	if self.progress then
		io.write("                                               ", "\r")
		io.flush()
	end

	local errorAppendMsg = "If you have already validated your data, report this error to system developers."

	if #uncomputedLinesIds > 1 then
		local linesListIds = "{"..uncomputedLinesIds[1]
		for i = 2, #uncomputedLinesIds do
			linesListIds = linesListIds..", "..uncomputedLinesIds[i]
		end
		linesListIds = linesListIds.."}"
		customError("Unexpected error with lines "..linesListIds..". "..errorAppendMsg)
	else
		customError("Unexpected error with line '"..uncomputedLinesIds[1].."'. "..errorAppendMsg)
	end
end

local function addNodesFromNonAdjacentsToTargetLines(self)
	local numOfComputedLines = totalComputedLines()

	for _, line in pairs(self.lines) do
		if isLineAlreadyComputed(line) then
			addAdjacentLinesAndItsPoints(self, line, adjacentLines[line.id])
		end
	end

	if hasUncomputedLines(self) then
		if numOfComputedLines == totalComputedLines() then
			unexpectedError(self)
		end
		addNodesFromNonAdjacentsToTargetLines(self)
	elseif self.progress then
		io.write("                                               ", "\r")
		io.flush()
		print(progressProcessingMsg(self.lines))
	end
end

local function createConnectivityInfoGraph(self)
	addNodesFromTargetLines(self)
	addNodesFromAdjacentsToTargetLines(self)
	addNodesFromNonAdjacentsToTargetLines(self)
end

local function createOpenNetwork(self)
	inside = self.inside
	outside = self.outside
	self.linesCs = self.lines
	self.lines = createLinesInfo(self.lines)
	if self.validate then
		validateLines(self)
	else
		findAndAddAjacentLines(self)
	end
	findAndAddTargetNodes(self)
	createConnectivityInfoGraph(self)

	if self.progress then
		print("Network built with "..getn(self.netpoints).." points.")
	end
end

local function calculateDistanceAndSetIfLesser(point, currNode, minDistances)
	local distanceOut = point:distance(currNode.point)
	if outside then
		distanceOut = outside(distanceOut)
	end

	local distance = distanceOut + currNode.distance

	if minDistances[currNode.targetId] >= distance then
		minDistances[currNode.targetId] = distance
		return true
	end

	return false
end

local function findShortestDistanceInLine(self, point, line, minDistances)
	if linesNodesList[line.id] then
		for i = 1, #linesNodesList[line.id] do
			local currNode = linesNodesList[line.id][i]
			calculateDistanceAndSetIfLesser(point, currNode, minDistances)
		end
	else
		linesNodesList[line.id] = {}
		for i = 0, line.npoints - 1 do
			local currPointId = line.geom:getPointAsTextAt(i)
			local currNode = self.netpoints[currPointId]
			table.insert(linesNodesList[line.id], currNode)
			calculateDistanceAndSetIfLesser(point, currNode, minDistances)
		end
	end
end

local function calculateDistanceInTargetsAndSetIfLesser(point, targetNode, minDistances)
	local distance = point:distance(targetNode.targetPoint)
	if outside then
		distance = outside(distance)
	end

	if minDistances[targetNode.targetId] >= distance then
		minDistances[targetNode.targetId] = distance
	end
end

Network_ = {
	type_ = "Network",
	--- Returns a table with the minimal distances from a cell to all targets.
	-- The keys are the target ids and the values are the minimal distances to the targets through the Network.
	-- @arg cell A cell with a geometry.
	-- @arg entrance A name which indicates if the distances will be calculated using point-to-point
	-- or by the lines.
	-- Point-to-point means that the function is going to calculate the distances from the cell centroid to
	-- all points of the Network to find the minimal ones. Lines find the minimal distances using their lines.
	-- Although "points" can be more accurate, the performance using "lines" is faster than "points".
	-- @usage -- DONTRUN
	-- distances = network:distances(cell, "lines")
	-- cell.distance = distances[0].distance
	-- cell.target = distances.targetId
	distances = function(self, cell, entrance)
		mandatoryArgument(1, "Cell", cell)
		if not cell.geom then
			customError("Argument 'cell' must be associated with a geometry.")
		end
		mandatoryArgument(2, "string", entrance)

		local cellGeom = cell.geom:getGeometryN(0)
		local point = cellGeom
		if cellGeom:getGeometryType() ~= "Point" then
			point = cellGeom:getCentroid()
		end

		local minDistances = {}
		for i = 1, #targetNodes do
			minDistances[targetNodes[i].targetId] = math.huge
		end


		if entrance == "lines" then
			for i = 1, #targetNodes do
				local targetNode = targetNodes[i]
				calculateDistanceInTargetsAndSetIfLesser(point, targetNode, minDistances)
				calculateDistanceAndSetIfLesser(point, targetNode, minDistances)
				findShortestDistanceInLine(self, point, targetNode.line, minDistances)
			end

			for i = 1, #linesList do
				local line = linesList[i]
				local firtNodeOfLine = self.netpoints[line.first.id]
				local lastNodeOfLine = self.netpoints[line.last.id]
				if firtNodeOfLine.targetId ~= lastNodeOfLine.targetId then
					findShortestDistanceInLine(self, point, line, minDistances)
				else
					local closestPointId = point:getClosestPointOfLineAsText(line.geom)
					local currNode = self.netpoints[closestPointId]
					if calculateDistanceAndSetIfLesser(point, currNode, minDistances) then
						findShortestDistanceInLine(self, point, line, minDistances)
					elseif currNode.next and calculateDistanceAndSetIfLesser(point, currNode.next, minDistances) and
							(currNode.next.line.id ~= currNode.line.id) then
						findShortestDistanceInLine(self, point, currNode.next.line, minDistances)
					elseif currNode.previous and (not currNode.router) and
							calculateDistanceAndSetIfLesser(point, currNode.previous, minDistances) then
						findShortestDistanceInLine(self, point, currNode.previous.line, minDistances)
					end
				end
			end
		elseif entrance == "points" then
			for i = 1, #targetNodes do
				local currNode = targetNodes[i]
				calculateDistanceInTargetsAndSetIfLesser(point, currNode, minDistances)
			end

			for i = 1, #nodesList do
				local currNode = nodesList[i]
				calculateDistanceAndSetIfLesser(point, currNode, minDistances)
			end
		else
			customError("Attribute 'entrance' must be 'lines' or 'points', but received '"..entrance.."'.")
		end

		return minDistances
	end
}

metaTableNetwork_ = {
	__index = Network_
}

--- Type that represents a network. It uses a set of lines and a set of destinations
-- that will be the end points of the network. This type requires that the network
-- is fully connected, meaning that it is possible to
-- reach any line from any other line of the network.
-- Distances within and without the network are computed in different ways.
-- In this sense, the distances inside the network should be proportionally
-- shorter then the distances outside the network in order to allow the shortest
-- paths to be within the network. Typically, using the Network
-- changes the representation from space to time, meaning that traveling within
-- the network is faster than outside.
-- A Network can then be used to create a GPM, using a set of origins.
-- @arg data.error As default, two lines are connected in the Network only if they share
-- exactly the same point. This argument allows two lines to be connected when there is a
-- maximum error in the distance up to the its value.
-- The maximum error must be just a insignificant value, otherwise, the Network might connect
-- lines that are parallels or so close or another collateral effect.
-- Therefore, the ideal solution for it is to correct the data.
-- The default value for this argument is zero.
-- @arg data.lines A base::CellularSpace with lines to create network. It can be for example a set of roads.
-- @arg data.outside User-defined function that converts the distance based on an
-- Euclidean distance to a distance in the geographical space. This function is
-- applied to enter and to leave the network, as well as to try to see whether
-- the distance without using the network is shorter than using the network.
-- If not set a function, will return the distance itself.
-- This function gets one argument with the distance in Euclidean space
-- and must return the distance in the geographical space.
-- @arg data.progress Optional boolean value indicating whether Network will print messages
-- while processing values. The default value is true.
-- @arg data.target A base::CellularSpace with the destinations of the network.
-- @arg data.inside User defined function that converts the distance based on
-- an Euclidean distance to a distance in the geographical space. This function
-- is applied to every path within the network.
-- If not set a function, will return the distance itself. Note that,
-- if the user does not use this argument neither outside function, the
-- paths will never use the network, as the distance within the network will always
-- be greater than the distance outside the network.
-- This function gets two arguments, the distance in Euclidean space and the
-- line, and must return the distance in the geographical space. This means
-- that it is possible to use properties from the lines such as paved or
-- non-paved roads.
-- @arg data.validate A boolean value that check if the lines is valid to build the Network.
-- It is recommended that the lines be validated once at least. The default value is true.
-- @usage import("gpm")
--
-- roads = CellularSpace{file = filePath("roads.shp", "gpm")}
-- communities = CellularSpace{file = filePath("communities.shp", "gpm")}
--
-- network = Network{
--     lines = roads,
--     target = communities,
--     progress = false,
--     inside = function(distance, cell)
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
	verifyUnnecessaryArguments(data, {"target", "lines", "inside", "outside", "error", "progress", "validate"})
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
	mandatoryTableArgument(data, "inside", "function")
	mandatoryTableArgument(data, "outside", "function")

	if data.target.geometry == false then
		customError("The CellularSpace in argument 'target' must be loaded without using argument 'geometry'.")
	end

	defaultTableValue(data, "error", 0)
	defaultTableValue(data, "progress", true)
	defaultTableValue(data, "validate", true)

	targetLines = {}
	computedLines = {}
	nonAdjacentLinesCache = {}
	adjacentLines = {}
	targetNodes = {}
	nodesList = {}
	linesList = {}
	linesNodesList = {}

	createOpenNetwork(data)

	setmetatable(data, metaTableNetwork_)
	return data
end
