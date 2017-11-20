local function sumPreviousDistances(node)
	local previousNode = node.previous
	local currNode = node
	local sum = 0

	while previousNode do
		if currNode.router then
			for i = 1, #currNode.previous do
				local dt = currNode.previous[i].distance - currNode.distance
				sum = sum + sumPreviousDistances(currNode.previous[i]) + dt
			end
			return sum
		end
		local delta = previousNode.distance - currNode.distance
		sum = sum + delta

		if previousNode.router then
			for i = 1, #previousNode.previous do
				local dt = previousNode.previous[i].distance - previousNode.distance
				sum = sum + sumPreviousDistances(previousNode.previous[i]) + dt
			end
			return sum
		end
		currNode = previousNode
		previousNode = previousNode.previous
	end

	return sum
end

local function sumDistances(targetNode)
	return sumPreviousDistances(targetNode.first) + sumPreviousDistances(targetNode.second)
			+ targetNode.first.distance + targetNode.second.distance - 2*targetNode.distance
end

local function testNetpointsDistances(unitTest, netpoints, targetNode, targetLine, lines)
	local lastPoint = targetLine.geom:getEndPoint()
	local npoints = targetLine.geom:getNPoints()
	local lineLength

	if targetLine.id == 10 then
		local startPoint = targetLine.geom:getPointN(6)
		lineLength = netpoints[startPoint:asText()].distance + netpoints[lastPoint:asText()].distance - 2 * targetNode.distance
		unitTest:assertEquals(lineLength, targetLine.geom:getLength() - 879.62852450418, 1.0e-10)
	else
		local startPoint = targetLine.geom:getStartPoint()
		lineLength = netpoints[startPoint:asText()].distance + netpoints[lastPoint:asText()].distance - 2 * targetNode.distance
		unitTest:assertEquals(lineLength, targetLine.geom:getLength(), 1.0e-10)
	end

	local acumDistance = 0

	if targetLine.id == 10 then
		for i = 6, npoints - 2 do
			local currPoint = targetLine.geom:getPointN(i)
			local nextPoint = targetLine.geom:getPointN(i + 1)
			acumDistance = acumDistance + currPoint:distance(nextPoint)
		end
	else
		for i = 0, npoints - 2 do
			local currPoint = targetLine.geom:getPointN(i)
			local nextPoint = targetLine.geom:getPointN(i + 1)
			acumDistance = acumDistance + currPoint:distance(nextPoint)
		end
	end

	unitTest:assertEquals(acumDistance, lineLength, 1.0e-10)

	local totalDistance = sumDistances(targetNode)

	unitTest:assertEquals(getn(netpoints), 340)

	if targetLine.id == 28 then
		acumDistance = acumDistance
									-- adjancent lines
									-- isAdjacentByPoints(endpointsTarget.start, endpointsLine.start)
									+ lines[26].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.start, endpointsLine.end)
									+ lines[27].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.start)
									+ lines[24].geom:getLength()

									-- non-adjancent lines
									--isAdjacentByPoints(endpointsLine.first, endpointsULine.last)
									+ lines[15].geom:getLength() - 525.19123580594 --< distance entering in line 15 by line 10
									+ lines[17].geom:getLength()
									-- isAdjacentByPoints(endpointsLine.last, endpointsULine.first)
									+ lines[25].geom:getLength()
									-- isAdjacentByPoints(endpointsLine.last, endpointsULine.last)
									+ lines[9].geom:getLength()
	elseif targetLine.id == 18 then
		acumDistance = acumDistance
									-- adjancent lines
									-- isAdjacentByPoints(endpointsTarget.start, endpointsLine.start)
									+ lines[0].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.start, endpointsLine.end)
									+ lines[37].geom:getLength()

									-- non-adjancent lines
									-- isAdjacentByPoints(endpointsLine.first, endpointsULine.first)
									+ lines[13].geom:getLength()
									--+ lines[3].geom:getLength()
									+ lines[36].geom:getLength() - 449.43410125262 --< distance entering in line 36 by line 8

									-- isAdjacentByPoints(endpointsLine.first, endpointsULine.last)
									+ lines[32].geom:getLength()
									+ lines[16].geom:getLength()
									--+ lines[33].geom:getLength() --< removed by line 8
									-- isAdjacentByPoints(endpointsLine.last, endpointsULine.first)
									+ lines[3].geom:getLength()

									-- adjancent to non-adjancent and so on
									+ lines[4].geom:getLength()
									+ lines[5].geom:getLength()
									+ lines[2].geom:getLength()
									+ lines[22].geom:getLength()
	elseif targetLine.id == 8 then
		acumDistance = acumDistance + lines[10].geom:getLength() - 5033.3341288441 --< distance entering in line 10 by line 8

									-- adjancent lines
									-- isAdjacentByPoints(endpointsTarget.start, endpointsLine.end)
									+ lines[1].geom:getLength() + lines[35].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.start)
									+ lines[20].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.last)
									+ lines[19].geom:getLength()

									-- non-adjancent lines
									-- isAdjacentByPoints(endpointsLine.first, endpointsULine.first)
									+ lines[36].geom:getLength() - 670.48413413882 --< distance entering in line 36 by line 18
									-- isAdjacentByPoints(endpointsLine.first, endpointsULine.last)
									+ lines[34].geom:getLength()
									--+ lines[33].geom:getLength() --< removed by line 18
									--+ lines[16].geom:getLength() --< removed by line 18
									--+ lines[32].geom:getLength() --< removed by line 18
									-- isAdjacentByPoints(endpointsLine.last, endpointsULine.first)
									+ lines[30].geom:getLength() + lines[21].geom:getLength()
									+ lines[31].geom:getLength()

									-- adjancent to non-adjancent and so on
									+ lines[12].geom:getLength()
									+ lines[6].geom:getLength()
									+ lines[14].geom:getLength() - 4396.0403189702
									+ lines[11].geom:getLength()
									+ lines[23].geom:getLength()
	elseif targetLine.id == 10 then
		acumDistance = acumDistance
									-- adjancent lines
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.start)
									+ lines[7].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.last)
									+ lines[29].geom:getLength()

									-- non-adjancent lines
									-- isAdjacentByPoints(endpointsLine.last, endpointsULine.last)
									+ lines[14].geom:getLength() - 2489.1822631646

									-- adjancent to non-adjancent and so on
									--+ lines[6].geom:getLength() --< removed by 8
									--+ lines[12].geom:getLength() --< removed by 8
	end

	unitTest:assertEquals(totalDistance, acumDistance, 1.0e-10)
end

local function testPreviousDataConnections(unitTest, node, previousNode)
	if not previousNode then
		return
	end

	if previousNode.router then
		unitTest:assert(#previousNode.previous > 1)
		for i = 1, #previousNode.previous do
			testPreviousDataConnections(unitTest, previousNode, previousNode.previous[i])
		end
	elseif not node.router then
		unitTest:assertEquals(node.targetId, previousNode.targetId)
		unitTest:assertEquals(previousNode.next.id, node.id)
		unitTest:assert(previousNode.distance > node.distance)
	end

	unitTest:assertNotNil(node.line)

	testPreviousDataConnections(unitTest, previousNode, previousNode.previous)
end

local function testDataConnections(unitTest, targetNode)
	testPreviousDataConnections(unitTest, targetNode, targetNode.first)
	testPreviousDataConnections(unitTest, targetNode, targetNode.second)
end

local function testNetpointsConnections(unitTest, netpoints, targetNode, targetLine)
	local firstNode
	local firstPointIdx
	local minDistance = math.huge
	local npoints = targetLine.geom:getNPoints()

	if targetLine.id == 10 then
		for i = 1, npoints - 1 do
			local point = targetLine.geom:getPointN(i)
			local nodeId = point:asText()
			if minDistance > netpoints[nodeId].distance then
				firstNode = netpoints[nodeId]
				firstPointIdx = i
				minDistance = netpoints[nodeId].distance
			end
		end
	else
		for i = 0, npoints - 1 do
			local point = targetLine.geom:getPointN(i)
			local nodeId = point:asText()
			if minDistance > netpoints[nodeId].distance then
				firstNode = netpoints[nodeId]
				firstPointIdx = i
				minDistance = netpoints[nodeId].distance
			end
		end
	end

	local secPointIdx

	unitTest:assertEquals(targetNode.first.id, firstNode.id)
	unitTest:assertEquals(firstNode.next.id, targetNode.id)

	if targetLine.id == 10 then
		secPointIdx = firstPointIdx + 1
	else
		secPointIdx = firstPointIdx - 1
	end

	local secPoint = targetLine.geom:getPointN(secPointIdx)
	local secNode = netpoints[secPoint:asText()]

	unitTest:assertEquals(targetNode.second.id, secNode.id)
	unitTest:assertEquals(secNode.next.id, targetNode.id)

	testDataConnections(unitTest, targetNode)
end

local function getTagetNodes(network)
	local targetNodes = {}

	forEachElement(network.netpoints, function(_, netpoint)
		if netpoint.line.id == 8 then
			if netpoint.target then
				targetNodes[8] = netpoint
			end
		elseif netpoint.line.id == 10 then
			if netpoint.target then
				targetNodes[10] = netpoint
			end
		elseif netpoint.line.id == 18 then
			if netpoint.target then
				targetNodes[18] = netpoint
			end
		elseif netpoint.line.id == 28 then
			if netpoint.target then
				targetNodes[28] = netpoint
			end
		end
	end)

	return targetNodes
end

return {
	Network = function(unitTest)
		local roads = CellularSpace{
			file = filePath("roads.shp", "gpm")
		}

		local communities = CellularSpace{
			file = filePath("communities.shp", "gpm")
		}

		local network1 = Network{
			lines = roads,
			target = communities,
			progress = false,
			weight = function(distance) -- weights is only the distance
				return distance
			end,
			outside = function(distance)
				return distance
			end
		}

		unitTest:assertType(network1, "Network")

		unitTest:assert(network1.lines ~= roads)
		unitTest:assertEquals(getn(network1.lines), #roads)
		unitTest:assertNotNil(network1.lines[0])
		unitTest:assertNotNil(network1.lines[37])
		unitTest:assertNil(network1.lines[38])

		unitTest:assertEquals(network1.lines[10].shortestPath, 599.05719061263, 1.0e-10)
		unitTest:assertEquals(network1.lines[8].shortestPath, 59.688264448298, 1.0e-10)
		unitTest:assertEquals(network1.lines[18].shortestPath, 83.520707733564, 1.0e-10)
		unitTest:assertEquals(network1.lines[28].shortestPath, 1041.9740663377, 1.0e-10)

		forEachElement(network1.lines, function(id)
			if not ((id == 8) or (id == 10) or (id == 18) or (id == 28)) then
				unitTest:assertNil(network1.lines[id].shortestPath)
			end
		end)

		unitTest:assertEquals(network1.netpoints[network1.lines[10].closestPoint.id].distance, network1.lines[10].shortestPath)
		unitTest:assertEquals(network1.netpoints[network1.lines[8].closestPoint.id].distance, network1.lines[8].shortestPath)
		unitTest:assertEquals(network1.netpoints[network1.lines[18].closestPoint.id].distance, network1.lines[18].shortestPath)
		unitTest:assertEquals(network1.netpoints[network1.lines[28].closestPoint.id].distance, network1.lines[28].shortestPath)

		local targetNodes = getTagetNodes(network1)

		forEachElement(network1.netpoints, function(_, netpoint)
			if netpoint.line.id == 8 then
				unitTest:assert(netpoint.distance >= network1.lines[8].shortestPath)
			elseif netpoint.line.id == 10 then
				unitTest:assert(netpoint.distance >= network1.lines[10].shortestPath)
			elseif netpoint.line.id == 18 then
				unitTest:assert(netpoint.distance >= network1.lines[18].shortestPath)
			elseif netpoint.line.id == 28 then
				unitTest:assert(netpoint.distance >= network1.lines[28].shortestPath)
			end
		end)

		forEachElement(targetNodes, function(i)
			testNetpointsDistances(unitTest, network1.netpoints, targetNodes[i], network1.lines[i], network1.lines)
			testNetpointsConnections(unitTest, network1.netpoints, targetNodes[i], network1.lines[i])
		end)

		unitTest:assertEquals(sumDistances(targetNodes[8]), 47958.718817508, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[10]), 10181.40682336, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[18]), 19061.171190073, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[28]), 24344.126540223, 1.0e-9)

		local network2 = Network{
			lines = roads,
			target = communities,
			progress = false,
			weight = function(distance)
				return distance * 2
			end,
			outside = function(distance)
				return distance * 2
			end
		}

		targetNodes = getTagetNodes(network2)

		unitTest:assertEquals(sumDistances(targetNodes[8]), 2 * 47958.718817508, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[10]), 2 * 10181.40682336, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[18]), 2 * 19061.171190073, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[28]), 2 * 24344.126540223, 1.0e-9)

		local network3 = Network{
			lines = roads,
			target = communities,
			progress = false,
			weight = function(distance)
				return distance / 2
			end,
			outside = function(distance)
				return distance / 2
			end
		}

		targetNodes = getTagetNodes(network3)

		unitTest:assertEquals(sumDistances(targetNodes[8]), 47958.718817508 / 2, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[10]), 10181.40682336 / 2, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[18]), 19061.171190073 / 2, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[28]), 24344.126540223 / 2, 1.0e-9)
		
		local network4 = Network{
			lines = roads,
			target = communities,
			progress = false,
			weight = function(distance, cell)
				if cell.STATUS == "paved" then
					return distance / 2
				else
					return distance
				end
			end
		}

		targetNodes = getTagetNodes(network4)

		unitTest:assertEquals(sumDistances(targetNodes[8]), 47958.718817508 / 2, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[10]), 10181.40682336 / 2, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[18]), 19061.171190073 / 2, 1.0e-9)
		unitTest:assertEquals(sumDistances(targetNodes[28]), 24344.126540223 / 2, 1.0e-9)		
	end
}

