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
local closestLinesToTargets = {}
local targetLines = {}

local function createLineInfo(line)
	return {
		id = line.FID,
		geom = line.geom:getGeometryN(0),
		npoints = line.geom:getNPoints()
		--points = {}
	}
end

-- local function setPoints(line)
	-- for i = 0, line.geom:getNPoints() - 1 do
		-- points[i] = line.geom:getPointN(i)
	-- end
-- end

local function createLinesInfo(lines)
	local linesInfo = {}
	forEachCell(lines, function(line)
		linesInfo[line.FID] = createLineInfo(line)
	end)

	return linesInfo
end

-- local function checkIfPointsCoordinatesAreAcending(lines)
	-- forEachElement(lines, function(_, line)
		-- local npoints = line.geom:getNPoints()

		-- for i = 0, npoints - 1 do

		-- end
	-- end)
-- end

local function addTargetInfoInLine(line, point, distance)
	local closestPoint = point:closestPoint(line.geom)
	line.closestPoint = {id = closestPoint:asText(), point = closestPoint}
	line.shortestPath = distance
	--line.targetPoint = point
	targetLines[line.id] = line
end

local function createTargetNode(point, distance, line)
	return {
		target = true,
		id = point:asText(),
		point = point,
		--adjacents = {},
		distance = distance,
		--distanceOutside = math.huge,
		line = line -- lines which the point belongs
	}
end

local function createNode(point, distance, line, position)
	return {
		id = point:asText(),
		point = point,
		--adjacents = {},
		distance = distance,
		--distanceOutside = math.huge,
		line = line, -- lines which the point belongs
		pos = position,
		--next = nextNode
	}
end

-- local function findClosestPointFromLineToNode(line, node)
	-- local closestPoint
	-- local closestPointIdx
	-- local targetLine
	-- local minDistance = math.huge
	-- local npoints = line.geom:getNPoints()

	-- for i = 0, npoints - 1 do
		-- local point = line.geom:getPointN(i)
		-- local distance = node.point:distance(point)

		-- if minDistance > distance then
			-- closestPoint = point
			-- minDistance = distance
			-- closestPointIdx = i
		-- end

	-- end

	-- return closestPointIdx, closestPoint, minDistance
-- end
-- local function findNewPointPosition(line, closestPoint)
	-- local xcp = closestPoint:getX()

	-- for i = 0, getn(line) - 2 do
		-- if not line.points[0]:getX() < xcp then
			-- return i
		-- end
	-- end
-- end

-- local function addTargetClosestPointInLine(line, closestPoint, shortestPath)
	-- local pos = findNewPointPosition(line, closestLine)
	-- addPointInLine(line, pos, closestPoint)
	-- --line.points[pos] = closestPoint
-- end

-- TODO(avancinirodrigo): this method can be improved by some tree
--local function createClosestLinesToTargets(self)
local function addTargetNodes(self) -- TODO: this function is doing two things, review name
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
												targetLine.shortestPath, targetLine) --< if is arc ramificated?

		--addTargetClosestPointInLine(targetLine, targetPoint, minDistance)
	end)
end

-- local function createNode(lineId, point, distance)
	-- return {
		-- point = point,
		-- --adjacents = {},
		-- distance = distance,
		-- --distanceOutside = math.huge,
		-- arcs = {lineId} -- lines which the point belongs
	-- }
-- end

-- local function createAdjacentPointInfo(pointId, distance)
	-- return {
		-- id = pointId,
		-- distance = distance
	-- }
-- end

-- local function connectNodeToAdjacentPointById(node, pointId, distance)
	-- table.insert(node.adjacents, createAdjacentPointInfo(pointId, distance))
-- end

-- local function connectNodeToAdjacentPoint(node, point, distance)
	-- -- local adjInfo = createAdjacentPointInfo(point:asText(), distance)
	-- -- table.insert(node.adjacents, adjInfo)
	-- connectNodeToAdjacentPointById(node, point:asText(), distance)
-- end

-- local function addNodeInGraphIfNodeNotExists(graph, id, point)
	-- graph[id] = createNode(point)
-- end

-- local function addNodeInGraph(graph, id, point)
	-- graph[id] = createNode(point)
-- end

-- local function insertNodeArcRelation(node, arcId, line)
	-- node.arcs[arcId] = line
-- end

-- local function insertNodeInGraph(graph, id, point, line)
	-- if not graph[id] then
		-- addNodeInGraphIfNodeNotExists(graph, id, point)
	-- end

	-- insertNodeArcRelation(graph[id], line.FID, line)
-- end

-- local function connectEndpointsOfLine(graph, line)
	-- local lineObj = line.geom:getGeometryN(0)
	-- local firstPoint = lineObj:getStartPoint()
	-- local lastPoint = lineObj:getEndPoint()
	-- local fpid = firstPoint:asText()
	-- local lpid = lastPoint:asText()
	-- local lineLength = lineObj:getLength()

	-- insertNodeInGraph(graph, fpid, firstPoint, line)
	-- connectNodeToAdjacentPoint(graph[fpid], lastPoint, lineLength)

	-- insertNodeInGraph(graph, lpid, lastPoint, line)
	-- connectNodeToAdjacentPoint(graph[lpid], firstPoint, lineLength)


	-- line.firstPoint = {point = firstPoint, id = fpid}
	-- line.lastPoint = {point = lastPoint, id = lpid}
	-- line.lineObj = lineObj
-- end

-- local function connectInteriorPointsOfLine(graph, line)
	-- local nPoints = line.lineObj:getNPoints()

	-- if nPoints > 2 then
		-- for i = 0, nPoints - 1 do
			-- local currPoint = line.lineObj:getPointN(i)
			-- local id = currPoint:asText()

			-- insertNodeInGraph(graph, id, currPoint, line)

			-- local afterPoint
			-- local beforePoint

			-- if i == 0 then
				-- afterPoint = line.lineObj:getPointN(i + 1)
				-- local distance = currPoint:distance(afterPoint)
				-- connectNodeToAdjacentPoint(graph[id], afterPoint, distance)
			-- elseif i == nPoints - 1 then
				-- beforePoint = line.lineObj:getPointN(i - 1)
				-- local distance = currPoint:distance(beforePoint)
				-- connectNodeToAdjacentPoint(graph[id], beforePoint, distance)
			-- else
				-- beforePoint = line.lineObj:getPointN(i - 1)
				-- local distance = currPoint:distance(beforePoint)
				-- connectNodeToAdjacentPoint(graph[id], beforePoint, distance)

				-- afterPoint = line.lineObj:getPointN(i + 1)
				-- distance = currPoint:distance(afterPoint)
				-- connectNodeToAdjacentPoint(graph[id], afterPoint, distance)
			-- end
		-- end
	-- end
-- end

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

-- local function connectNodesToAdjacentLinesConsideringError(self, graph)
	-- forEachCell(self.lines, function(lineA)
		-- local endpointsA = {lineA.firstPoint, lineA.lastPoint}
		-- local hasAdjacent = false
		-- local minDistance = math.huge

		-- for i = 1, #endpointsA do
			-- local endpointA = endpointsA[i]

			-- forEachCell(self.lines, function(lineB)
				-- if lineB.FID ~= lineA.FID then
					-- local endpointsB = {lineB.firstPoint, lineB.lastPoint}

					-- for j = 1, #endpointsB do
						-- local endpointB = endpointsB[j]
						-- local distance = endpointA.point:distance(endpointB.point)

						-- if distance <= self.error then
							-- if j == 1 then
								-- connectNodeToAdjacentPointById(graph[endpointA.id], endpointsB[2].id, lineB.lineObj:getLength())
							-- else
								-- connectNodeToAdjacentPointById(graph[endpointA.id], endpointsB[1].id, lineB.lineObj:getLength())
							-- end

							-- hasAdjacent = true
						-- end

						-- if minDistance > distance then
							-- minDistance = distance
						-- end
					-- end
				-- end
			-- end)
		-- end

		-- if not hasAdjacent then
			-- customError("Line: '"..lineA.FID.."' does not touch any other line. The minimum distance found was: "..minDistance..".")
		-- end
	-- end)
-- end

-- local function createInteriorRelationOfLines(self, graph)
	-- forEachCell(self.lines, function(line)
		-- connectEndpointsOfLine(graph, line)
		-- connectInteriorPointsOfLine(graph, line)
	-- end)
-- end

-- local function createInitialNodes(self, graph)
	-- local graph = {}
	-- for i = 1, #closestLinesToTargets do
		-- local line = closestLinesToTargets[i]
		-- graph[line.closestPoint.id] = createNode(line.id, line.closestPoint.point, line.shortestPath)
	-- end

	-- return graph
-- end

local function findClosestPoint(node)
	local line = node.line
	local pointInfo = {}
	pointInfo.distance = math.huge

	--local npoints = line.geom:getNPoints()

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

local function addArcRelation(node, line)
	table.insert(node.arcs, line)
end

local function createNodeByNextPoint(graph, point, position, currNode, line) -- TODO ESTÁ INSERINDO NO GRAPH TAMBÉM
	local distance = currNode.point:distance(point)
	local totalDistance = currNode.distance + distance
	local newNodeId = point:asText()

	graph[newNodeId] = createNode(point, totalDistance, line, position)

	return graph[newNodeId]
end

local function reviewNextDistances(node, nextNode)
	while nextNode do
		local distance = node.distance + node.point:distance(nextNode.point) -- TODO: this can be improved using delta distance
		--_Gtme.print(distance, nextNode.distance)		
		if nextNode.distance > distance then
			--_Gtme.print("change")
			nextNode.distance = distance
			nextNode.previous = node
			node.next = nextNode

			if nextNode.target then -- TODO: can target point belongs to another target?
				return
			end
			
			node = nextNode
			nextNode = nextNode.next
			nextNode.previous = nil
			node.next = nil
			_Gtme.print(node.pos, nextNode.pos)
		else
			return
		end
	end
end

local function reviewPreviousDistances(node, previousNode)
	while previousNode do
		local distance = node.distance + node.point:distance(previousNode.point) -- TODO: this can be improved using delta distance
		--_Gtme.print(distance, previousNode.distance)
		if previousNode.distance > distance then
			--_Gtme.print("change")
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

local function getLastPosition(node)
	return node.line.npoints - 1
end

local function isLastPosition(node, position)
	return position == getLastPosition(node)
end

local function isFirstPosition(position)
	return position == 0
end

local function isStartNode(node)
	return node.pos == 0
end

local function isEndNode(node)
	return node.pos == getLastPosition(node)
end

local function setExistingNode(graph, node, currNode, position)
	local distance = currNode.point:distance(node.point)
	local nextDistance = currNode.distance + distance

	if node.distance > nextDistance then
		if isStartNode(node) then --node.pos == 0 then
			local nextNode = node.next
			nextNode.previous = nil
			node.previous = nil
			node.next = nil
			node.line = currNode.line
			node.pos = position
			node.distance = nextDistance
			if isLastPosition(node, position) then --position == getLastPosition(node) then
				currNode.next = node
				node.previous = currNode
				reviewNextDistances(node, nextNode) -- TODO: create delta distance
			elseif isFirstPosition(position) then
				currNode.previous = node
				node.next = currNode
				--reviewPreviousDistances()
				customError("not implemented yet")
			end
		end
	else
		local previousDistance = node.distance + distance
		--_Gtme.print("distance1", previousDistance, currNode.distance, distance, currNode.line.id, position)
		if currNode.distance > previousDistance then
		
			if isEndNode(node) then --.pos == node.line.npoints - 1 then
				--_Gtme.print("distance1", previousDistance, currNode.distance, distance, currNode.line.id, position)
				currNode.distance = previousDistance
				currNode.previous = node
				node.next = currNode
				
				if isFirstPosition(position) then
					reviewNextDistances(currNode, currNode.next)
				elseif isLastPosition(node, position) then
					customError("not implemented yet")
				end
			end
		end
			
	end
end

-- Template Method
-- Warning: this method is overwrited in some places
local function linkNodeToNext(node, nextNode)
	node.next = nextNode
	nextNode.previous = node
end

-- Template Method
-- Warning: this method is overwrited in some places
local function linkNodeToPrevious(node, previousNode)
	node.previous = previousNode
	previousNode.next = node
end

local function addAllNodesOfTargetLinesLeft(graph, targetLine, node)
	if node.pos == 0 then
		return
	else
		local i = node.pos - 1
		local currNode = node
		while i >= 0 do
			local point = targetLine.geom:getPointN(i)
			local nodeId = point:asText()
			--_Gtme.print(targetLine.id, i)

			if graph[nodeId] then
				setExistingNode(graph, graph[nodeId], currNode, i)
			else
				local previousNode = createNodeByNextPoint(graph, point, i, currNode, targetLine)
				--currNode.previous = previousNode
				--previousNode.next = currNode
				linkNodeToPrevious(currNode, previousNode)
				currNode = previousNode
			end
			i = i - 1
		end
	end
end

local function addAllNodesOfTargetLinesRight(graph, targetLine, node)
	local npoints = targetLine.npoints --.geom:getNPoints()
	_Gtme.print(targetLine.id, npoints)
	if node.pos == npoints - 1 then
		return
	else
		local currNode = node
		for i = node.pos + 1, npoints - 1 do
			local point = targetLine.geom:getPointN(i)
			local nodeId = point:asText()

			if graph[nodeId] then
				setExistingNode(graph, graph[nodeId], currNode, i)
			else
				local nextNode = createNodeByNextPoint(graph, point, i, currNode, targetLine)
				--currNode.next = nextNode
				--nextNode.previous = currNode
				linkNodeToNext(currNode, nextNode)
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

local function linkNodesWhenFirstNodeIsLeft(graph, targetNode, firstNode, secNode)
	targetNode.next = secNode
	targetNode.previous = firstNode
	firstNode.next = targetNode
	secNode.previous = targetNode
end

local function linkNodesWhenFirstNodeIsRight(graph, targetNode, firstNode, secNode)
	targetNode.next = firstNode
	targetNode.previous = secNode
	firstNode.previous = targetNode
	secNode.next = targetNode
end

local function addAllNodesOfTargetLines(graph, firstNode, targetNode)
	local line = targetNode.line
	local secPoint = findSecondPoint(firstNode, targetNode)
	local secNode = createNode(secPoint.point, secPoint.distance, line, secPoint.pos)
	graph[secNode.id] = secNode
	_Gtme.print(secPoint.pos, secPoint.distance - targetNode.distance, firstNode.pos, targetNode.line.npoints, targetNode.line.id)

	if firstNode.pos == 0 then
		linkNodesWhenFirstNodeIsLeft(graph, targetNode, firstNode, graph[secNode.id])
		addAllNodesOfTargetLinesRight(graph, targetNode.line, graph[secNode.id])
	else
		--local npoints = line.geom:getNPoints()

		if firstNode.pos == line.npoints - 1 then
			linkNodesWhenFirstNodeIsRight(graph, targetNode, firstNode, graph[secNode.id])
			addAllNodesWhenFirstNodeIsStartIsEnd(graph, targetNode, firstNode, graph[secNode.id])
		else
			if secPoint.pos > firstNode.pos then
				linkNodesWhenFirstNodeIsLeft(graph, targetNode, firstNode, graph[secNode.id])
				addAllNodesOfTargetLinesRight(graph, line, graph[secNode.id])
				addAllNodesOfTargetLinesLeft(graph, line, firstNode)
			else
				linkNodesWhenFirstNodeIsRight(graph, targetNode, firstNode, graph[secNode.id])
				addAllNodesOfTargetLinesRight(graph, line, firstNode)
				addAllNodesOfTargetLinesLeft(graph, line, graph[secNode.id])
			end
		end
	end
end

local function createFirstNode(targetNode)
	local firstPoint = findClosestPoint(targetNode)
	local totalDistance = targetNode.distance + firstPoint.distance --< shortestPath + first point distance
	--local firstNodeId = firstPoint.point:asText()
	--graph[firstNodeId] = createNode(firstPoint.point, totalDistance, node.line, node)
	return createNode(firstPoint.point, totalDistance, targetNode.line, firstPoint.pos)
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

local function setInitialNodes(self)
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

local function isSamePoints(p1, p2)
	return p1:distance(p2) == 0
end

local function isNodeBelongingToTargetLine(node, targetLine)
	return node.line.id == targetLine.id
end

local function addAdjacentLineInFirstNode(node, line)
	if not node.first then
		--node.adjacents = {}
		node.first = true
		--local previous = {}
		--table.insert(node.previous, node.previous)
		--node.previous = {node.previous}
		_Gtme.print("addfirst", line.id, node.previous, node.pos)
		node.previous = {}
		--_Gtme.print("addfirst", line.id)
	end
	--table.insert(node.previous, {line = line, pos = node.pos})
end

local function setNodesInAdjacentLines(self)
	forEachElement(targetLines, function(_, targetLine)
		_Gtme.print("---------", targetLine.id)
		forEachElement(self.lines, function(_, line)
			if targetLine.id ~= line.id then
				local endpointsTarget = {first = targetLine.geom:getStartPoint(), last = targetLine.geom:getEndPoint()}
				local endpointsLine = {first = line.geom:getStartPoint(), last = line.geom:getEndPoint()}
				
				if isSamePoints(endpointsTarget.first, endpointsLine.first) then
					local firstId = endpointsTarget.first:asText()
					local firstNode = self.netpoints[firstId]
					--_Gtme.print(line.id, line.npoints, firstNode.pos, firstNode.line.id)
					
					linkNodeToNext = function(node, nextNode) --< template method overwrited
						if node.first then
							--customError("table")
							--os.exit()
							--_Gtme.print("node.first", node.line.id, nextNode.line.id, node.pos, node.distance, nextNode.pos, nextNode.distance)
							table.insert(node.previous, nextNode)
						else
							--_Gtme.print("nodes", node.line.id, nextNode.line.id, node.pos, node.distance, nextNode.pos, nextNode.distance)
							node.previous = nextNode
						end
						nextNode.next = node
					end
					
					if isNodeBelongingToTargetLine(firstNode, targetLine) then
						--_Gtme.print("entered")
						addAdjacentLineInFirstNode(firstNode, line)
						addAllNodesOfTargetLinesRight(self.netpoints, line, firstNode)
					end
					
				elseif isSamePoints(endpointsTarget.first, endpointsLine.last) then
					local firstId = endpointsTarget.first:asText()
					local firstNode = self.netpoints[firstId]					
					_Gtme.print(line.id, line.npoints, firstNode.pos, firstNode.line.id)
					
					linkNodeToPrevious = function(node, previousNode) --< template method overwrited 
						if node.first then
						-- if type(previous) == "table" then
							-- customError("table")
							-- os.exit()
						-- end
							table.insert(node.previous, previousNode) -- HERE HERE HERE
						else
							node.previous = previousNode
						end
						previousNode.next = node
					end				

					if isNodeBelongingToTargetLine(firstNode, targetLine) then
						_Gtme.print("entered")
						local pos = firstNode.pos
						firstNode.pos = line.npoints - 1
						--addAdjacentLine(firstNode, line)
						addAdjacentLineInFirstNode(firstNode, line)
						addAllNodesOfTargetLinesLeft(self.netpoints, line, firstNode)
						firstNode.pos = pos
					end
					
				end
			end
		end)
	end)
end

local function createConnectivityInfoGraph(self)
	setInitialNodes(self)
	setNodesInAdjacentLines(self)
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
	addTargetNodes(self)
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
