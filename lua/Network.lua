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

local targetLines = {}

local function createLineInfo(line)
	return {
		id = line.FID,
		geom = line.geom:getGeometryN(0),
		npoints = line.geom:getNPoints()
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
		--distanceOutside = math.huge,
		line = line, -- lines which the point belongs
		targetId = line.id
	}
end

local function createNode(point, distance, line, position, targetId)
	return {
		id = point:asText(),
		point = point,
		distance = distance,
		--distanceOutside = math.huge,
		line = line, -- lines which the point belongs
		pos = position,
		targetId = targetId
	}
end

-- TODO(avancinirodrigo): this method can be improved by some tree
local function findAndAddTargetNodes(self)
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

local function findClosestPoint(node)
	local line = node.line
	local pointInfo = {}
	pointInfo.distance = math.huge

	for i = 0, line.npoints - 1 do
		local point = line.geom:getPointN(i)
		local distance = node.point:distance(point)

		if pointInfo.distance > distance then
			pointInfo.point = point
			pointInfo.distance = distance
			pointInfo.pos = i
		end
	end

	return pointInfo
end

local function calculateFullDistance(refNode, nextNode)
	local distance = refNode.point:distance(nextNode.point) -- TODO: this can be improved using delta distance
	return refNode.distance + distance
end

local function reviewPreviousDistances(node, previousNode)
	while previousNode do
		local distance = calculateFullDistance(node, previousNode)

		if previousNode.distance > distance then
			previousNode.distance = distance
			previousNode.next = node
			node.previous = previousNode

			node = previousNode
			previousNode = previousNode.previous

			if previousNode.target then
				return
			end

			previousNode.previous = nil
			node.next = nil
		else
			return
		end
	end
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

	local newDistance = calculateFullDistance(node, previousNode)
	previousNode.distance = newDistance
	previousNode.targetId = node.targetId
	recalculatePreviousDistances(previousNode, previousNode.previous)
end

local function removeOldRoute(routerNode, node) -- TODO: improve this name
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
	routerNode.line = node.line

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

local function reviewNextNodes(node, nextNode) -----------*************************************************************
	if nextNode.target then
		if node.id == nextNode.first.id then
			nextNode.first = nil
		elseif node.id == nextNode.second.id then
			nextNode.second = nil
		else
			customError("unforeseen error!") -- SKIP : TODO: it needs a test
		end

		return
	end

	local newDistance = calculateFullDistance(node, nextNode)

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

local function reviewExistingNode(graph, existingNode, currNode, newPosition)
	local newDistance = calculateFullDistance(currNode, existingNode)
	-- if currNode.line.id == 32 then
		-- _Gtme.print("review", newDistance, existingNode.distance, currNode.pos)
	-- end
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

--local acum = 0
local function createNodeByNextPoint(graph, point, position, currNode, line) -- TODO ESTÁ INSERINDO NO GRAPH TAMBÉM
	local distance = currNode.point:distance(point)
	local totalDistance = currNode.distance + distance
	local newNodeId = point:asText()
	--if currNode.targetId == 18 then
	-- if line.id == 32 then
		-- -- acum = acum + distance
	-- _Gtme.print("distance", distance, line.id, currNode.pos, position)
	-- end
	graph[newNodeId] = createNode(point, totalDistance, line, position, currNode.targetId)

	return graph[newNodeId]
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
			--_Gtme.print(targetLine.id, i)

			if graph[nodeId] then
				--if line.id == 32 then
				_Gtme.print("node exists to left", graph[nodeId].line.id, graph[nodeId].targetId, currNode.line.id, currNode.targetId)
				--end
				reviewExistingNode(graph, graph[nodeId], currNode, i)
			else
				local previousNode = createNodeByNextPoint(graph, point, i, currNode, line)
				linkNodeToNext(previousNode, currNode)
				currNode = previousNode
			end
			i = i - 1
		end
	end
end

local function addAllNodesOfLineForward(graph, line, node, nodePosition)
	local npoints = line.npoints
	-- if line.id == 3 then
		-- _Gtme.print("$$$$$$$$$$$$$$$$$$$$$$$")
		-- _Gtme.print(line.id, npoints)
	-- end
	if nodePosition == npoints - 1 then
		return
	else
		local currNode = node
		for i = nodePosition + 1, npoints - 1 do
			local point = line.geom:getPointN(i)
			local nodeId = point:asText()

			if nodeExists(graph[nodeId]) then
				_Gtme.print("node exists to right", currNode.targetId, currNode.line.id, graph[nodeId].line.id)
				reviewExistingNode(graph, graph[nodeId], currNode, i)
			else
				--_Gtme.print(i)
				local nextNode = createNodeByNextPoint(graph, point, i, currNode, line)
				linkNodeToNext(nextNode, currNode)
				currNode = nextNode
			end
		end
	end
end

-- local function addAllNodesFromLine(graph, line, firstPointIdx, firstNode)
	-- addAllNodesFromLineLeft(graph, line, firstPointIdx, firstNode)
	-- addAllNodesFromLineRight(graph, line, firstPointIdx, firstNode)
-- end

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
			customError("same x", xt, xb, xa, x1)
		end
	else -- inverted line
		customError("inverted line")
	end

	return pointInfo
end

local function getDistanceToTargetNode(point, targetNode)
	return targetNode.distance + targetNode.point:distance(point)
end

local function findSecondPoint(firstNode, targetNode)
	local pointInfo = {}

	pointInfo = findSecondPointInEnds(firstNode, targetNode)

	if #pointInfo == 0 then
		pointInfo = findSecondPointInInterior(firstNode, targetNode)
	end

	pointInfo.distance = getDistanceToTargetNode(pointInfo.point, targetNode)

	return pointInfo
end

-- local function linkNodesWhenFirstNodeIsLeft(graph, targetNode, firstNode, secNode)
	-- targetNode.next = secNode
	-- targetNode.previous = firstNode
	-- firstNode.next = targetNode
	-- secNode.previous = targetNode
	-- firstNode.direction = "left"
	-- secNode.direction = "right"
-- end

-- local function linkNodesWhenFirstNodeIsRight(graph, targetNode, firstNode, secNode)
	-- targetNode.next = firstNode
	-- targetNode.previous = secNode
	-- firstNode.previous = targetNode
	-- secNode.next = targetNode
	-- firstNode.direction = "right"
	-- secNode.direction = "left"
-- end

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
	_Gtme.print(secPoint.pos, secPoint.distance - targetNode.distance, firstNode.pos, targetNode.line.npoints, targetNode.line.id)

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

	--uncomputedLines[targetNode.line.id] = nil
end

local function createFirstNode(targetNode)
	local firstPoint = findClosestPoint(targetNode)
	local totalDistance = targetNode.distance + firstPoint.distance --< shortestPath + first point distance
	--local firstNodeId = firstPoint.point:asText()
	--graph[firstNodeId] = createNode(firstPoint.point, totalDistance, node.line, node)
	return createNode(firstPoint.point, totalDistance, targetNode.line, firstPoint.pos, targetNode.targetId)
end

-- local function createSecondNode(targetNode, firstNode)
	-- if firstNode.pos == 0 then
		-- local secPoint = line.geom:getPointN(1)
		-- --local distance = targetNode.point:distance(secPoint)
		-- --local totalDistance = targetNode.distance + distance
		-- --local secNodeId = secPoint:asText()
		-- --graph[secNodeId] = createNode(secPoint, totalDistance, line, targetNode)
		-- local distance = getDistanceToTargetNode(secPoint, targetNode)
		-- return createNode(secPoint, distance, line, targetNode, 1)
		-- -- targetNode.next = graph[secNodeId]
		-- -- addAllNodesFromLineRight(graph, line, 1, graph[secNodeId])
	-- else
		-- local line = targetNode.line
		-- local npoints = line.geom:getNPoints()

		-- if firstNode.pos == npoints - 1 then
			-- local secPoint = line.geom:getPointN(npoints - 2)
			-- --local distance = targetNode.point:distance(line.geom:getPointN(1))
			-- --local totalDistance = targetNode.distance + distance
			-- --local secNodeId = secPoint:asText()
			-- --graph[secNodeId] = createNode(secPoint, totalDistance, line, targetNode)
			-- --targetNode.next = graph[secNodeId]
			-- --addAllNodesFromLineLeft(graph, line, npoints - 2, graph[secNodeId])
			-- local distance = getDistanceToTargetNode(secPoint, targetNode)
			-- createNode(secPoint, totalDistance, line, targetNode, npoints - 2)
		-- else
			-- local secPoint, secPointIdx = getSecondPoint(targetNode.line, firstNode.id, firstNode, targetNode)
			-- --local distance = targetNode.point:distance(line.geom:getPointN(secPointIdx))
			-- --local totalDistance = targetNode.distance + distance
			-- --local secNodeId = secPoint:asText()

			-- local distance = getDistanceToTargetNode(secPoint, targetNode)

			-- if secPointIdx > firstPointIdx then
				-- graph[secNodeId] = createNode(secPoint, totalDistance, line, nil)
				-- targetNode.next = graph[secNodeId]
				-- addAllNodesFromLineRight(graph, line, secPointIdx, graph[secNodeId])
				-- addAllNodesFromLineLeft(graph, line, firstPointIdx, firstNode)
			-- else
				-- graph[secNodeId] = createNode(secPoint, totalDistance, line, targetNode)
				-- targetNode.next = firstNode
				-- addAllNodesFromLineRight(graph, line, firstPointIdx, firstNode)
				-- addAllNodesFromLineLeft(graph, line, secPointIdx, graph[secNodeId])
			-- end
		-- end
	-- end
-- end

local function addFirstNodes(graph, node)
	--forEachElement(node.line, function(id, line)
		--local idx, point, distance = findClosestPoint(node)
		local firstNode = createFirstNode(node)
		--_Gtme.print("pos", firstNode.pos, node.line.id)
		graph[firstNode.id] = firstNode

		--local secNode = createSecondNode(node, firstNode)

		--targetNode.next =
		--targetNode.previous =
		--addFirstAndSecondNodes(graph, node)

		addAllNodesOfTargetLines(graph, graph[firstNode.id], node)

		--addAllNodesFromLine(graph, line, idx, graph[firstNodeId])(graph, firstPointIdx, firstNode, line, targetNode)
		--addAllNodesFromLine(graph, idx, graph[firstNodeId], node.line, node)
	--end)
end

local function copyGraph(self, graph)
	forEachElement(graph, function(id, node)
		self.netpoints[id] = node
	end)
end

local function addNodesFromTargetLines(self)
	local graph = {}

	forEachElement(self.netpoints, function(id, node)
		graph[id] = node --< I don't want change self.netpoints in this loop
		addFirstNodes(graph, node) -- REVIEW graph[id] ou node
	end)

	copyGraph(self, graph)
end


-- local function findTargetNodePosition(node)
	-- local x = node.point:getX()
	-- local npoints = node.line.geom:getNPoints()

	-- for i = 0, npoints - 1 do
		-- local p = node.line.geom:getPointN(i)
		-- _Gtme.print(p:getX(), x)
		-- if p:getX() > x then
			-- return i
		-- end
	-- end
-- end

-- local function addTargetClosestPointInLine(line, closestPoint, shortestPath)
	-- local pos = findNewPointPosition(line, closestLine)
	-- addPointInLine(line, pos, closestPoint)
	-- --line.points[pos] = closestPoint
-- end

-- local function setTargetNodesPosition(self)
	-- forEachElement(self.netpoints, function(_, targetNode)
		-- targetNode.pos = findTargetNodePosition(targetNode)
		-- _Gtme.print(targetNode.pos)
	-- end)
-- end

local function isAdjacentByPoints(p1, p2)
	return p1:distance(p2) == 0
end

local function isNodeBelongingToTargetLine(node, targetLine)
	return node.line.id == targetLine.id
end

local function addFirstNodeInfo(node)
	if not node.first then
		node.first = true
		local previousNode = node.previous
		node.previous = {}
		table.insert(node.previous, previousNode)
	end
end

local function addLastNodeInfo(node)
	if not node.last then
		node.last = true
		local nextNode = node.next
		node.next = {}
		table.insert(node.next, nextNode)
	end
end

local function isTargetLine(line)
	return targetLines[line.id] ~= nil
end

local computedLines = {}

local function addNodesForward(self, targetLine, point, line)
	local nid = point:asText()
	local node = self.netpoints[nid]

	if isNodeBelongingToTargetLine(node, targetLine) then
		--if node.targetId == 8 then
		_Gtme.print("addNodesForwardd", node.targetId, targetLine.id, line.id, line.npoints, line.geom:getLength(), node.distance) --, node.line.geom:getLength())
		--end
		addAllNodesOfLineForward(self.netpoints, line, node, 0)
		computedLines[line.id] = line
	end
end

local function addNodesBackward(self, targetLine, point, line)
	local nid = point:asText()
	local node = self.netpoints[nid]

	if isNodeBelongingToTargetLine(node, targetLine) then
		--if node.targetId == 8 then
		_Gtme.print("addNodesBackward", node.targetId, node.line.id, targetLine.id, line.id, line.npoints, line.geom:getLength(), node.distance)
		--end
		addAllNodesOfLineBackward(self.netpoints, line, node, line.npoints - 1)
		computedLines[line.id] = line
	end
end

local function addNodesFromAdjacentsToTargetLines(self)
	forEachElement(targetLines, function(_, targetLine)
		local endpointsTarget = {first = targetLine.geom:getStartPoint(), last = targetLine.geom:getEndPoint()}

		forEachElement(self.lines, function(_, line)
			if not (isTargetLine(line) or computedLines[line.id]) then
				local endpointsLine = {first = line.geom:getStartPoint(), last = line.geom:getEndPoint()}

				if isAdjacentByPoints(endpointsTarget.first, endpointsLine.first) then
					addNodesForward(self, targetLine, endpointsTarget.first, line)
				elseif isAdjacentByPoints(endpointsTarget.first, endpointsLine.last) then --and (targetLine.id == 28) then
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

local function isUncomputedLine(line)
	return not (isTargetLine(line) or computedLines[line.id])
end

local function hasUncomputedLinesYet(self)
	return getn(computedLines) + getn(targetLines) ~= getn(self.lines)
end

local function addNodesFromNonAdjacentsToTargetLines(self)
	_Gtme.print("")
	_Gtme.print("")
	_Gtme.print("")
	_Gtme.print("addNodesFromNonAdjacentToTargetLines")
	forEachElement(self.lines, function(_, line)
		if computedLines[line.id] then
			local endpointsLine = {first = line.geom:getStartPoint(), last = line.geom:getEndPoint()}

			forEachElement(self.lines, function(_, uline)
				if isUncomputedLine(uline) then
					--_Gtme.print("unconnected", uline.id, computedLines[uline.id])
				--	if not computedLines[line.id] then
						local endpointsULine = {first = uline.geom:getStartPoint(), last = uline.geom:getEndPoint()}

						if isAdjacentByPoints(endpointsLine.first, endpointsULine.first) then
							addNodesForward(self, line, endpointsLine.first, uline)
						elseif isAdjacentByPoints(endpointsLine.first, endpointsULine.last)
								-- and ((uline.id == 34)
								-- or (uline.id == 33)
								-- or (uline.id == 15)
								-- or (uline.id == 17)
								-- or (uline.id == 16)
								-- or (uline.id == 32)
								-- )
								then
							addNodesBackward(self, line, endpointsLine.first, uline)
						elseif isAdjacentByPoints(endpointsLine.last, endpointsULine.first)
								-- and ((uline.id == 15)
									-- or (uline.id == 30)
									-- or (uline.id == 25)
									-- or (uline.id == 21)
									-- or (uline.id == 31)
									-- or (uline.id == 3)
								-- )
								then
							addNodesForward(self, line, endpointsLine.last, uline)
						elseif isAdjacentByPoints(endpointsLine.last, endpointsULine.last)
									-- and ((uline.id == 9)
									-- or (uline.id == 14)
								-- )
								then
							-- addNodesWhenPointsAreBothLast(self, line, endpointsLine.last, uline)
							addNodesBackward(self, line, endpointsLine.last, uline)
						end
					--end
				end
			end)
		end
	end)
	_Gtme.print("computedLines-------------->", getn(computedLines) + getn(targetLines))
	_Gtme.print("uncomputedLines-------------->", getn(self.lines) - (getn(computedLines) + getn(targetLines)))
	if hasUncomputedLinesYet(self) then
		addNodesFromNonAdjacentsToTargetLines(self)
	end
end

local function createConnectivityInfoGraph(self)
	addNodesFromTargetLines(self)
	addNodesFromAdjacentsToTargetLines(self)
	addNodesFromNonAdjacentsToTargetLines(self)
	--local graph = createInitialNodes(self, graph)

	-- createInteriorRelationOfLines(self, graph)
	-- checkIfLineCrossesError(self.lines)
	-- connectNodesToAdjacentLinesConsideringError(self, graph)
	-- checkIfAllLinesAreConnected(self.lines) -- TODO: review this checking

	--return graph
end

-- local function connectEachNodeToTargetClosestLines(self, graph, closestLinesToTargets)
	-- local progress = 0
	-- local graphSize = getn(graph)

	-- forEachElement(graph, function(_, node)
		-- if self.progress then
			-- progress = progress + 1 -- SKIP
			-- print(table.concat{"Computing distance outside ", progress, "/", graphSize}) -- SKIP
		-- end

		-- for i = 1, #closestLinesToTargets do
			-- local closestLine = closestLinesToTargets[i]
			-- local distance = node.point:distance(closestLine.closestPoint)
			-- local outDist = self.outside(distance, closestLine)

			-- if node.distanceOutside > outDist then
				-- node.distanceOutside = outDist
				-- node.targetIDOutside = i
			-- end
		-- end
	-- end)
-- end

-- local function isWeightChanged(node, weight)
	-- return node.distance > weight
-- end

-- local function insertNodeWeightInfo(node, weight, targetId)
	-- node.distance = weight
	-- node.targetID = targetId
-- end

-- local function calcWeightedDistance(p1, p2, weight, line)
	-- local distance = p1:distance(p2)
	-- return weight(distance, line)
-- end

-- local function includeWeightToNodesThatBelongClosestLines(self, graph, closestLinesToTargets)
	-- for i = 1, #closestLinesToTargets do
		-- local closestLine = closestLinesToTargets[i]

		-- if self.progress then
			-- print(table.concat{"Reducing distances ", i, "/", #closestLinesToTargets}) -- SKIP
		-- end

		-- local nPoints = closestLine.lineObj:getNPoints()

		-- for j = 0, nPoints - 1 do
			-- local point = closestLine.lineObj:getPointN(j)
			-- local pointId = point:asText()
			-- local distWeighted = calcWeightedDistance(point, closestLine.closestPoint,
													-- self.weight, closestLine)
			-- local node = graph[pointId]

			-- if isWeightChanged(node, distWeighted) then
				-- insertNodeWeightInfo(node, distWeighted, i)
			-- end
		-- end
	-- end
-- end

-- local function isNodeWeighted(node)
	-- return node.distance ~= math.huge
-- end

-- local function checkIfNodeWeightWasSetOrUpdated(node, adjacentNode, weight, line)
	-- if isNodeWeighted(adjacentNode) then
		-- local distWeighted = calcWeightedDistance(node.point, adjacentNode.point, weight, line)
		-- distWeighted = distWeighted + adjacentNode.distance
		-- -- _Gtme.print(line)
		-- -- os.exit(0)

		-- if isWeightChanged(node, distWeighted) then
			-- insertNodeWeightInfo(node, distWeighted, adjacentNode.targetID) --< insert means create or update
			-- return true
		-- end
	-- end

	-- return false
-- end

-- local function checkInNodeArcs(node, adjacentNode, weight)
	-- local changed = false
	-- for _, line in pairs(node.arcs) do
		-- changed = checkIfNodeWeightWasSetOrUpdated(node, adjacentNode, weight, line)
	-- end
	-- return changed
-- end

-- local function checkInAdjancentNodeArcs(node, adjacentNode, weight)
	-- local changed = false

	-- for id, line in pairs(adjacentNode.arcs) do
		-- if not node.arcs[id] then --< don't need to check again, it was already checked above
			-- changed = checkIfNodeWeightWasSetOrUpdated(node, adjacentNode, weight, line)
		-- end
	-- end

	-- return changed
-- end

-- local function checkIfNodeWeightWasChangedByAdjacentNode(node, adjacentNode, weight)
	-- return checkInNodeArcs(node, adjacentNode, weight) or
			-- checkInAdjancentNodeArcs(node, adjacentNode, weight)
-- end

-- local function checkIfNodeWeightWasChanged(self, graph, node)
	-- local changed = false

	-- for i = 1, #node.adjacents do
		-- local adjacentId = node.adjacents[i].id
		-- local adjacentNode = graph[adjacentId]
		-- changed = checkIfNodeWeightWasChangedByAdjacentNode(node, adjacentNode, self.weight)
	-- end

	-- return changed
-- end

-- local function hasWeightToInclude(self, graph)
	-- local changed = false

	-- forEachElement(graph, function(_, node)
		-- if checkIfNodeWeightWasChanged(self, graph, node) then
			-- changed = true
		-- end
	-- end)

	-- return changed
-- end

-- local function includeWeightToAllNodes(self, graph)
	-- while hasWeightToInclude(self, graph) do end
-- end

local function createOpenNetwork(self)
	self.lines = createLinesInfo(self.lines)

--	checkIfPointsCoordinatesAreAcending(self.lines)

	self.netpoints = {}
	findAndAddTargetNodes(self)
--	setTargetNodesPosition(self)
	--local closestLinesToTargets = createClosestLinesToTargets(self)
	--self.target = createTargeInfo(self.target)
	createConnectivityInfoGraph(self)
-- for i = 1, #closestLinesToTargets do
	-- _Gtme.print(closestLinesToTargets[i])
	-- _Gtme.print(closestLinesToTargets[i].lineObj:getNPoints())

-- end
-- os.exit(0)
	-- connectEachNodeToTargetClosestLines(self, graph, closestLinesToTargets)
	-- includeWeightToNodesThatBelongClosestLines(self, graph, closestLinesToTargets)
	-- includeWeightToAllNodes(self, graph)
-- for k, v in pairs(graph) do
	-- _Gtme.print(k, v)
	-- for kk, vv in pairs(v) do
		-- _Gtme.print(kk, vv)
	-- end

	-- local out = ""
	-- for id, l in pairs(v.arcs) do
		-- out = out..id.."; "
	-- end
	-- _Gtme.print(out)
-- end
-- os.exit(0)
	-- return {
		-- netpoint = graph,
		-- target = closestLinesToTargets,
		-- lines = self.lines
	-- }
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
