local function sumPreviousDistances(node)
	local previousNode = node.previous
	local currNode = node
	local sum = 0

	while previousNode and (previousNode.next.id == currNode.id) do
		if currNode.router then
			for i = 1, #currNode.previous do
				if currNode.previous[i].next.id == currNode.id then
					local dt = currNode.previous[i].distance - currNode.distance
					sum = sum + sumPreviousDistances(currNode.previous[i]) + dt
				end
			end
			return sum
		end
		local delta = previousNode.distance - currNode.distance
		sum = sum + delta

		if previousNode.router then
			for i = 1, #previousNode.previous do
				if previousNode.previous[i].next.id == previousNode.id then
					local dt = previousNode.previous[i].distance - previousNode.distance
					sum = sum + sumPreviousDistances(previousNode.previous[i]) + dt
				end
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

	unitTest:assertEquals(getn(netpoints), 344)

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
									+ lines[14].geom:getLength() - 4126.3673717398
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
	if (not previousNode) or (not previousNode.next) then
		return
	end

	if node.id ~= previousNode.next.id then
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
		unitTest:assert((node.pos == previousNode.pos + 1)
						or (node.pos == previousNode.pos - 1)
						or ((previousNode.pos == 1) and (node.pos == node.line.npoints - 1))
						or ((node.pos == 0.1) or (previousNode.pos == 0.1))
						or ((node.pos == 0.5) or (previousNode.pos == 0.5)))
	end

	if node.target then
		unitTest:assertEquals(node.pos, 0.1)
	end

	if node.line.npoints == 2 then
		unitTest:assert((node.pos == 0.5)
						or (previousNode.pos == 0.5)
						or (node.next.pos == 0.5))
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
		if netpoint.targetId == 2 then
			if netpoint.target then
				targetNodes[2] = netpoint
			end
		elseif netpoint.targetId == 1 then
			if netpoint.target then
				targetNodes[1] = netpoint
			end
		elseif netpoint.targetId == 3 then
			if netpoint.target then
				targetNodes[3] = netpoint
			end
		elseif netpoint.targetId == 0 then
			if netpoint.target then
				targetNodes[0] = netpoint
			end
		elseif netpoint.targetId == 39 then
			if netpoint.target then
				targetNodes[39] = netpoint
			end
		end
	end)

	return targetNodes
end

local function getDifference(targetId, from, to)
	local dif = {}
	for k, _ in pairs(from[targetId]) do
		if not to[targetId][k] then
			table.insert(dif, k)
		end
	end
	return dif
end

local function getAnyNodeFromLine(netpoints, lineId)
	for _, n in pairs(netpoints) do
		if n.line.id == lineId then
			return n
		end
	end
end

return {
	Network = function(unitTest)
		local checkRouterNodeProperties = function(router)
			unitTest:assert(#router.previous > 1)
			unitTest:assertEquals(router.line.id, router.next.line.id)
			for i = 1, #router.previous do
				unitTest:assert(router.id ~= router.previous[i].id)
				if router.previous[i].target then
					unitTest:assert((router.id == router.previous[i].first.id)
									or (router.id == router.previous[i].second.id))
					unitTest:assert(router.targetId ~= router.previous[i].targetId)
				else
					if router.id == router.previous[i].next.id then
						unitTest:assert(router.distance < router.previous[i].distance)
						unitTest:assertEquals(router.targetId, router.previous[i].targetId)
					end
					unitTest:assert(router.distance > router.next.distance)
					unitTest:assert(router.line.id ~= router.previous[i].line.id)
				end
			end
		end

		local isPreviousCircular = function(node, previousNode)
			if previousNode.target then
				return node.next.id ~= previousNode.id
			end
			return previousNode.next.id ~= node.id
		end

		local checkPreviousCircularProperties = function(node)
			if node.previous then
				if node.router then
					for i = 1, #node.previous do
						if isPreviousCircular(node, node.previous[i]) then
							if node.previous[i].target then
								unitTest:assert((node.id == node.previous[i].first.id)
												or (node.id == node.previous[i].second.id))
							else
								unitTest:assert(node.previous[i].previous.id == node.id)
							end
						end
					end
				elseif not node.previous.router then
					if isPreviousCircular(node, node.previous) then
						if node.previous.target then
							unitTest:assert((node.id == node.previous.first.id)
											or (node.id == node.previous.second.id))
						else
							unitTest:assert(node.previous.previous.id == node.id)
						end
					end
				end
			end
		end

		local checkTargetIdProperties = function(node, firstNode, lastNode, line, numOfTargets)
			unitTest:assert((node.targetId >= 0) and (node.targetId <= numOfTargets - 1))
			if not ((node.targetId == firstNode.targetId)
					or (node.targetId == lastNode.targetId)) then
				unitTest:assert((firstNode.line.targetNode ~= nil) or (node.line.targetNode ~= nil))
			end
			if firstNode.targetId == lastNode.targetId then
				if node.targetId ~= firstNode.targetId then
					unitTest:assertNotNil(line.targetNode)
				end
			end
			if node.target then
				unitTest:assertEquals(node.targetId, node.first.targetId) -- SKIP
				unitTest:assertEquals(node.targetId, node.second.targetId) -- SKIP
				unitTest:assertNil(node.next) -- SKIP
			else
				unitTest:assertEquals(node.targetId, node.next.targetId) -- SKIP
			end
		end

		local checkNetworkProperties = function(network, numOfTargets)
			local checkTargetMiddlePoint = function(targetNode)
				if targetNode.line.npoints == 2 then
					return (targetNode.first.pos == 0.5)
							or (targetNode.second.pos == 0.5)
				end
				return true
			end
			local checkRouterMiddlePoint = function(router)
				if router.next.pos == 0.5 then return true end
				if router.next.pos == 0.1 then
					local targetNode = router.next
					if targetNode.line.npoints == 2 then
						return (targetNode.first.pos == 0.5)
								or (targetNode.second.pos == 0.5)
					end
				end
				for i = 1, #router.previous do
					if router.previous[i].pos == 0.5 then
						return true
					elseif router.previous[i].pos == 0.1 then
						local targetNode = router.previous[i]
						if targetNode.line.npoints == 2 then
							return (targetNode.first.pos == 0.5)
									or (targetNode.second.pos == 0.5)
						end
					end
				end
				return false
			end
			for _, line in pairs(network.lines) do
				if line.npoints == 2 then
					local firstNode = network.netpoints[line.first.id]
					local lastNode = network.netpoints[line.last.id]

					if firstNode.router then
						unitTest:assert(checkRouterMiddlePoint(firstNode))
						if lastNode.router then
							unitTest:assert(checkRouterMiddlePoint(lastNode))
						elseif lastNode.previous then
							unitTest:assert((lastNode.next.pos == 0.5) or (lastNode.previous.pos == 0.5)
											or (lastNode.next.pos == 0.1) or (lastNode.previous.pos == 0.1))
							if lastNode.next.pos == 0.1 then
								unitTest:assert(checkTargetMiddlePoint(lastNode.next))
							elseif lastNode.previous.pos == 0.1 then
								unitTest:assert(checkTargetMiddlePoint(lastNode.previous)) -- SKIP
							else
								unitTest:assert((lastNode.next.pos == 0.5) or (lastNode.previous.pos == 0.5))
							end
						end
					elseif lastNode.router then
						unitTest:assert(checkRouterMiddlePoint(lastNode))
						if firstNode.previous then
							unitTest:assert((firstNode.next.pos == 0.5) or (firstNode.previous.pos == 0.5)
											or (firstNode.next.pos == 0.1) or (firstNode.previous.pos == 0.1))
							if firstNode.next.pos == 0.1 then
								unitTest:assert(checkTargetMiddlePoint(firstNode.next))
							elseif firstNode.previous.pos == 0.1 then
								unitTest:assert(checkTargetMiddlePoint(firstNode.previous)) -- SKIP
							else
								unitTest:assert((firstNode.next.pos == 0.5) or (firstNode.previous.pos == 0.5))
							end
						end
					elseif firstNode.previous then
						unitTest:assert((firstNode.next.pos == 0.5) or (firstNode.previous.pos == 0.5))
						if lastNode.previous then
							unitTest:assert((lastNode.next.pos == 0.5) or (lastNode.previous.pos == 0.5))
						end
					elseif lastNode.previous then
						unitTest:assert((lastNode.next.pos == 0.5) or (lastNode.previous.pos == 0.5))
					end
				end

				local firstNode = network.netpoints[line.first.id]
				local lastNode = network.netpoints[line.last.id]
				unitTest:assertEquals(firstNode.targetId, firstNode.next.targetId)
				unitTest:assertEquals(lastNode.targetId, lastNode.next.targetId)

				for i = 0, line.npoints - 1 do
					local nodeId = line.geom:getPointAsTextAt(i)
					local node = network.netpoints[nodeId]
					unitTest:assert(node.distance > 0)
					if node.router then
						checkRouterNodeProperties(node)
					elseif node.target then
						unitTest:assertNil(node.next) -- SKIP
						unitTest:assertEquals(node.pos, 0.1) -- SKIP
					elseif (i ~= 0) and (i ~= line.npoints - 1) then
						unitTest:assertEquals(node.pos, i) -- SKIP
					end
					checkPreviousCircularProperties(node)
					checkTargetIdProperties(node, firstNode, lastNode, line, numOfTargets)
				end
			end
		end

		local networkSetWeightAndOutsideEqualDistance = function()
			local roads = CellularSpace{
				file = filePath("roads.shp", "gpm")
			}

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local network = Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance) -- weights is only the distance
					return distance
				end,
				outside = function(distance)
					return distance
				end
			}

			checkNetworkProperties(network, #communities)

			unitTest:assertType(network, "Network")

			unitTest:assert(network.lines ~= roads)
			unitTest:assertEquals(getn(network.lines), #roads)
			unitTest:assertNotNil(network.lines[0])
			unitTest:assertNotNil(network.lines[37])
			unitTest:assertNil(network.lines[38])

			unitTest:assertEquals(network.lines[10].shortestPath, 599.05719061263, 1.0e-10)
			unitTest:assertEquals(network.lines[8].shortestPath, 59.688264448298, 1.0e-10)
			unitTest:assertEquals(network.lines[18].shortestPath, 83.520707733564, 1.0e-10)
			unitTest:assertEquals(network.lines[28].shortestPath, 1041.9740663377, 1.0e-10)

			forEachElement(network.lines, function(id)
				if not ((id == 8) or (id == 10) or (id == 18) or (id == 28)) then
					unitTest:assertNil(network.lines[id].shortestPath)
				end
			end)

			unitTest:assertEquals(network.netpoints[network.lines[10].closestPoint.id].distance, network.lines[10].shortestPath)
			unitTest:assertEquals(network.netpoints[network.lines[8].closestPoint.id].distance, network.lines[8].shortestPath)
			unitTest:assertEquals(network.netpoints[network.lines[18].closestPoint.id].distance, network.lines[18].shortestPath)
			unitTest:assertEquals(network.netpoints[network.lines[28].closestPoint.id].distance, network.lines[28].shortestPath)

			forEachElement(network.netpoints, function(_, netpoint)
				if netpoint.line.id == 8 then
					unitTest:assert(netpoint.distance >= network.lines[8].shortestPath)
				elseif netpoint.line.id == 10 then
					unitTest:assert(netpoint.distance >= network.lines[10].shortestPath)
				elseif netpoint.line.id == 18 then
					unitTest:assert(netpoint.distance >= network.lines[18].shortestPath)
				elseif netpoint.line.id == 28 then
					unitTest:assert(netpoint.distance >= network.lines[28].shortestPath)
				end
			end)

			local targetNodes = getTagetNodes(network)

			forEachElement(targetNodes, function(i, targetNode)
				testNetpointsDistances(unitTest, network.netpoints, targetNodes[i],
									network.lines[targetNode.line.id], network.lines)
				testNetpointsConnections(unitTest, network.netpoints, targetNodes[i], network.lines[targetNode.line.id])
			end)

			unitTest:assertEquals(sumDistances(targetNodes[2]), 48228.391764738, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[1]), 10181.40682336, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[3]), 19061.171190073, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[0]), 24344.126540223, 1.0e-9)
		end

		local networkSetWeightAndOutsideMultipliedBy2 = function()
			local roads = CellularSpace{
				file = filePath("roads.shp", "gpm")
			}

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local network = Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance)
					return distance * 2
				end,
				outside = function(distance)
					return distance * 2
				end
			}

			checkNetworkProperties(network, #communities)

			unitTest:assertEquals(network.lines[10].shortestPath, 599.05719061263 * 2, 1.0e-10)
			unitTest:assertEquals(network.lines[8].shortestPath, 59.688264448298 * 2, 1.0e-10)
			unitTest:assertEquals(network.lines[18].shortestPath, 83.520707733564 * 2, 1.0e-10)
			unitTest:assertEquals(network.lines[28].shortestPath, 1041.9740663377 * 2, 1.0e-10)

			local targetNodes = getTagetNodes(network)
			unitTest:assertEquals(sumDistances(targetNodes[2]), 2 * 48228.391764738, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[1]), 2 * 10181.40682336, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[3]), 2 * 19061.171190073, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[0]), 2 * 24344.126540223, 1.0e-9)
		end

		local networkSetWeightAndOutsideDividedBy2 = function()
			local roads = CellularSpace{
				file = filePath("roads.shp", "gpm")
			}

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local network = Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance)
					return distance / 2
				end,
				outside = function(distance)
					return distance / 2
				end
			}

			checkNetworkProperties(network, #communities)

			unitTest:assertEquals(network.lines[10].shortestPath, 599.05719061263 / 2, 1.0e-10)
			unitTest:assertEquals(network.lines[8].shortestPath, 59.688264448298 / 2, 1.0e-10)
			unitTest:assertEquals(network.lines[18].shortestPath, 83.520707733564 / 2, 1.0e-10)
			unitTest:assertEquals(network.lines[28].shortestPath, 1041.9740663377 / 2, 1.0e-10)

			local targetNodes = getTagetNodes(network)
			unitTest:assertEquals(sumDistances(targetNodes[2]), 48228.391764738 / 2, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[1]), 10181.40682336 / 2, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[3]), 19061.171190073 / 2, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[0]), 24344.126540223 / 2, 1.0e-9)
		end

		local networkSetWeightDividedBy10 = function()
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
				inside = function(distance) -- weights is only the distance
					return distance
				end,
				outside = function(distance)
					return distance
				end
			}

			local linesTargets1 = {}
			linesTargets1[0] = {}
			linesTargets1[1] = {}
			linesTargets1[2] = {}
			linesTargets1[3] = {}

			forEachElement(network1.netpoints, function(_, netpoint)
				linesTargets1[netpoint.targetId][netpoint.line.id] = netpoint.targetId
			end)

			local network = Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance, cell)
					if cell.STATUS == "paved" then
						return distance / 10
					else
						return distance
					end
				end,
				outside = function(distance)
					return distance
				end
			}

			checkNetworkProperties(network, #communities)

			forEachElement(network.lines, function(_, line)
				if (line.cell.STATUS == "paved") and line.npoints then
					local sum = 0
					for i = 0, line.npoints - 2 do
						local p1 = line.geom:getPointN(i)
						local p2 = line.geom:getPointN(i + 1)
						local pdist = p1:distance(p2)
						local n1 = network.netpoints[p1:asText()]
						local n2 = network.netpoints[p2:asText()]
						local dif = math.abs(n2.distance - n1.distance)
						unitTest:assertEquals(dif, pdist / 10, 1.0e-9)
						unitTest:assertEquals(n1.targetId, n2.targetId)
						sum = sum + dif
					end
					unitTest:assertEquals(line.geom:getLength() / 10, sum, 1.0e-9)
				end
			end)

			local linesTargets4 = {}
			linesTargets4[0] = {}
			linesTargets4[1] = {}
			linesTargets4[2] = {}
			linesTargets4[3] = {}

			forEachElement(network.netpoints, function(_, netpoint)
				linesTargets4[netpoint.targetId][netpoint.line.id] = netpoint.targetId
				if netpoint.line.cell.STATUS == "paved" then
					unitTest:assert(belong(netpoint.line.id, {0, 3, 5, 19, 20, 21, 23, 34, 36, 37}))
				end
			end)

			local difFrom4To1 = getDifference(2, linesTargets4, linesTargets1)
			unitTest:assert(belong(16, difFrom4To1))
			unitTest:assert(belong(32, difFrom4To1))
			-- unitTest:assert(belong(33, difFrom4To1)) -- SKIP -- TODO: REVIEW

			local difFrom1To4 = getDifference(2, linesTargets1, linesTargets4)
			unitTest:assert(belong(34, difFrom1To4))
			unitTest:assert(belong(36, difFrom1To4))

			difFrom4To1 = getDifference(3, linesTargets4, linesTargets1)
			unitTest:assert(belong(1, difFrom4To1))
			unitTest:assert(belong(34, difFrom4To1))

			difFrom1To4 = getDifference(3, linesTargets1, linesTargets4)
			unitTest:assert(belong(16, difFrom1To4))

			local targetNodes = getTagetNodes(network)

			unitTest:assert(sumDistances(targetNodes[2]) < 47958.718817508)
			unitTest:assert(sumDistances(targetNodes[1]) < 10181.40682336)
			unitTest:assert(sumDistances(targetNodes[3]) < 19061.171190073)
			unitTest:assert(sumDistances(targetNodes[0]) < 24344.126540223)
		end

		local findWarning = function(warns, warn)
			for i = 1, #warns do
				if warns[i] == warn then
					return warn
				end
			end
			return ""
		end

		local networkWithInvertedLine = function()
			local roads = CellularSpace{
				file = filePath("test/netinverted1.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/ports_antaq_sirgas2000_south1.shp", "gpm"),
				missing = 0
			}


			local customWarningBkp = customWarning
			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local warns = {
				[1] = "Line '53' has more than one target. Target '2' was removed by '1', distances (169265.43142207, 136195.263543).",
				[2] = "Line '25' has more than one target. Target '4' was removed by '5', distances (417176.92037951, 386500.65663679).",
				[3] = "Line '6' has more than one target. Target '1' was removed by '0', distances (15825.518077182, 1243.8066195354).",
				[4] = "Target '1' of line '53' was removed by target '0'.",
				[5] = "Target '5' of line '25' was removed by target '3'."
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				inside = function(distance) -- weights is only the distance
					return distance
				end,
				outside = function(distance)
					return distance
				end
			}

			for i = 1, #warnMsgs do
				unitTest:assertEquals(findWarning(warns, warnMsgs[i]), warnMsgs[i])
			end

			unitTest:assertEquals(getn(network.netpoints), 45318)
			unitTest:assertEquals(network.lines[43].shortestPath, 1531.231486377, 1.0e-9) --< inverted line

			customWarning = customWarningBkp
		end

		local networkWithTwoTargetsInSameLine = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_ne1.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/ports_sirgas2000_ne1.shp", "gpm"),
				missing = 0
			}

			local network

			local moreThanOneTargetInSameLine = function()
				network = Network{
					lines = roads,
					target = ports,
					progress = false,
					inside = function(distance)
						return distance
					end,
					outside = function(distance)
						return distance * 4
					end
				}
			end

			unitTest:assertWarning(moreThanOneTargetInSameLine,
							"Line '6' has more than one target. Target '1' was removed by '0', distances (63302.072308726, 4975.2264781415).")
			unitTest:assertEquals(getn(network.netpoints), 6571)

			local targetNodes = getTagetNodes(network)
			unitTest:assertEquals(getn(targetNodes), 1)

			local network1
			moreThanOneTargetInSameLine = function()
				network1 = Network{
					lines = roads,
					target = ports,
					progress = false,
					inside = function(distance)
						return distance * 10
					end,
					outside = function(distance)
						return distance
					end
				}
			end

			unitTest:assertWarning(moreThanOneTargetInSameLine,
							"Line '6' has more than one target. Target '1' was removed by '0', distances (15825.518077182, 1243.8066195354).")
			unitTest:assertEquals(getn(network.netpoints), 6571)

			local targetNodes1 = getTagetNodes(network1)
			unitTest:assertEquals(getn(targetNodes1), 1)
		end

		local networkValidateFalse = function()
			local roads = CellularSpace{
				file = filePath("roads.shp", "gpm")
			}

			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local network = Network{
				lines = roads,
				target = communities,
				progress = false,
				inside = function(distance)
					return distance * 2
				end,
				outside = function(distance)
					return distance * 2
				end,
				validate = false
			}

			unitTest:assertEquals(getn(network.netpoints), 344)

			unitTest:assertEquals(network.lines[10].shortestPath, 599.05719061263 * 2, 1.0e-10)
			unitTest:assertEquals(network.lines[8].shortestPath, 59.688264448298 * 2, 1.0e-10)
			unitTest:assertEquals(network.lines[18].shortestPath, 83.520707733564 * 2, 1.0e-10)
			unitTest:assertEquals(network.lines[28].shortestPath, 1041.9740663377 * 2, 1.0e-10)

			local targetNodes = getTagetNodes(network)
			unitTest:assertEquals(sumDistances(targetNodes[2]), 2 * 48228.391764738, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[1]), 2 * 10181.40682336, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[3]), 2 * 19061.171190073, 1.0e-9)
			unitTest:assertEquals(sumDistances(targetNodes[0]), 2 * 24344.126540223, 1.0e-9)
		end

		local networkReviewMoreThanOneRouterNode = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_ne2.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/ports_sirgas2000_ne2.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				validate = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			unitTest:assertEquals(getn(network.netpoints), 130066)

			local netpoint44 = getAnyNodeFromLine(network.netpoints, 44)
			local netpoint153 = getAnyNodeFromLine(network.netpoints, 153)

			unitTest:assertEquals(netpoint44.targetId, netpoint153.targetId) --< more than one router
			unitTest:assertEquals(netpoint44.targetId, 1)
		end

		local networkReviewLineWith2Points = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_south2.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/porto_alegre_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			unitTest:assertEquals(getn(network.netpoints), 6964)
			unitTest:assertEquals(network.lines[25].npoints, 2)
		end

		local problemWhenErrorArgumentIsTooBig = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_south3.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/porto_alegre_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			local netWithAcceptableError = Network{
				lines = roads,
				target = ports,
				progress = false,
				error = 5,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			forEachElement(network.netpoints, function(id)
				local d1 = network.netpoints[id].distance
				local d2 = netWithAcceptableError.netpoints[id].distance
				unitTest:assertEquals(d1, d2)
			end)
		end

		local joinConnectedLinesTest = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_south6.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/port_estrela_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			unitTest:assertEquals(getn(network.netpoints), 3979)
		end

		local targetNodeIsEqualsToLineEndpoints = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_ne3.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/port_belem_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance
				end
			}

			local targetNode = getTagetNodes(network)[0]
			unitTest:assertEquals(targetNode.line.id, 0)

			local totalDistance = sumPreviousDistances(targetNode.first)
									+ sumPreviousDistances(targetNode.second)
									+ targetNode.first.point:distance(targetNode.second.point)

			local sumLinesLength = network.lines[0].geom:getLength()
									+ network.lines[1].geom:getLength()
									+ network.lines[2].geom:getLength()

			unitTest:assertEquals(totalDistance, sumLinesLength, 1.0e-9)
		end

		local adjustRouterNodePositionTest = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_ne14.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/port_aratu_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				validate = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			unitTest:assertEquals(getn(network.netpoints), 23163)
			unitTest:assertEquals(network.lines[29].npoints, 54) --< line with adjust router node position
		end

		local reviewNextNodeWhenItIsTargetNode = function()
			local roads = CellularSpace{
				file = filePath("test/pa_roads_simpl_1m.shp", "gpm")
			}

			local sedes = CellularSpace{
				file = filePath("test/ParaSedes.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local warns = {
				[1] = "Target '90' of line '497' cannot enter in the network due to target '77'.",
				[2] = "Target '81' of line '654' was removed by target '31'.",
				[3] = "Target '14' of line '295' was removed by target '31'.",
				[4] = "Target '73' of line '832' was removed by target '112'.",
				[5] = "Target '86' of line '550' was removed by target '25'.",
				[6] = "Target '121' of line '350' was removed by target '130'.",
				[7] = "Target '93' of line '178' was removed by target '17'.",
				[8] = "Target '14' of line '295' was removed by target '81'.",
				[9] = "Target '93' of line '178' cannot enter in the network due to target '17'."
			}

			local network = Network{
				lines = roads,
				target = sedes,
				progress = false,
				validate = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			for i = 1, #warnMsgs do
				if not string.find(warnMsgs[i], "^Line") then
					unitTest:assertEquals(findWarning(warns, warnMsgs[i]), warnMsgs[i])
				end
			end

			customWarning = customWarningBkp

			local targetNode39 = getTagetNodes(network)[39]
			unitTest:assertEquals(targetNode39.line.id, 569)
			unitTest:assertNotNil(targetNode39.first)
			unitTest:assertNotNil(targetNode39.second)
		end

		local lineHasTwoTargets = function()
			local roads = CellularSpace{
				file = filePath("test/pa_roads_simpl_1m_2.shp", "gpm")
			}

			local sedes = CellularSpace{
				file = filePath("test/ParaSedes_2.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local network = Network{
				lines = roads,
				target = sedes,
				progress = false,
				validate = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			local warns = {
				[1] = "Line '0' has more than one target. Target '7' was removed by '3', distances (456195.66616617, 409928.01784464).",
				[2] = "Line '7' has more than one target. Target '9' was removed by '6', distances (192239.90945117, 15776.439180544).",
				[3] = "Line '0' has more than one target. Target '11' was removed by '3', distances (467638.11873217, 409928.01784464).",
				[4] = "Line '7' has more than one target. Target '12' was removed by '6', distances (107858.33146034, 15776.439180544).",
				[5] = "Line '7' has more than one target. Target '5' was removed by '6', distances (179416.72308451, 15776.439180544).",
				[6] = "Line '7' has more than one target. Target '6' was removed by '4', distances (15776.439180544, 4497.2884806748).",
				[7] = "Line '0' has more than one target. Target '3' was removed by '0', distances (409928.01784464, 268609.16431361).",
				[8] = "Line '6' has more than one target. Target '8' was removed by '1', distances (121706.03828736, 54041.863778962).",
				[9] = "Line '7' has more than one target. Target '5' was removed by '4', distances (179416.72308451, 4497.2884806748).",
				[10] = "Target '10' of line '2' was removed by target '1'.",
				[11] = "Target '10' of line '2' was removed by target '4'.",
				[12] = "Target '0' of line '0' was removed by target '4'.",
				[13] = "Target '0' of line '0' was removed by target '1'.",
				[14] = "Target '0' of line '0' was removed by target '10'."
			}

			for i = 1, #warnMsgs do
				unitTest:assertEquals(findWarning(warns, warnMsgs[i]), warnMsgs[i])
			end

			for _, node in pairs(network.netpoints) do
				unitTest:assert(node.targetId ~= 0)
				unitTest:assert(node.targetId ~= 10)
				if node.target then
					unitTest:assertNil(node.next)
				else
					unitTest:assertNotNil(node.next)
				end
			end

			customWarning = customWarningBkp
		end

		local lineHasTwoTargetsAnother = function()
			local roads = CellularSpace{
				file = filePath("test/pa_roads_simpl_1m_3.shp", "gpm")
			}

			local sedes = CellularSpace{
				file = filePath("test/ParaSedes_3.shp", "gpm"),
				missing = 0
			}

			local network
			local warnMsg = function()
				network = Network{
					lines = roads,
					target = sedes,
					progress = false,
					validate = false,
					inside = function(distance)
						return distance
					end,
					outside = function(distance)
						return distance * 4
					end
				}
			end

			unitTest:assertWarning(warnMsg,
						"Line '4' has more than one target. Target '0' was removed by '1', distances (6194.3145628177, 8.1013274221323).")

			local line4 = network.lines[4]
			unitTest:assertEquals(network.netpoints[line4.first.id].targetId, 1)
			unitTest:assertEquals(network.netpoints[line4.last.id].targetId, 1)
		end

		local checkBrazilPortsProperties = function()
			local roads = CellularSpace{
				file = filePath("br_roads_5880.shp", "gpm"),
				missing = 0
			}

			local ports = CellularSpace{
				file = filePath("br_ports_5880.shp", "gpm")
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				validate = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance
				end
			}

			checkNetworkProperties(network, #ports)
		end

		local hasTargetNodeAtReviewPreviousNodes = function()
			local roads = CellularSpace{
				file = filePath("test/roads_rm_target_node.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/plants_rm_target_node.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning

			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			local warns = {
				[1] = "Target '2' of line '23' cannot enter in the network due to target '1'.",
				[2] = "Target '0' of line '13' was removed by target '1'.",
				[3] = "Target '2' of line '23' was removed by target '1'."
			}

			for i = 1, #warnMsgs do
				unitTest:assertEquals(findWarning(warns, warnMsgs[i]), warnMsgs[i])
			end

			unitTest:assertEquals(getn(network.netpoints), 246)

			for _, node in pairs(network.netpoints) do
				unitTest:assert(node.targetId ~= 0)
				unitTest:assert(node.targetId ~= 2)
				if node.target then
					unitTest:assertNil(node.next)
				else
					unitTest:assertNotNil(node.next)
				end
			end

			customWarning = customWarningBkp
		end

		local hasTargetNodeAtSamePlace = function()
			local roads = CellularSpace{
				file = filePath("test/roads_rm_target_same_place.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/plants_rm_target_same_place.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			for _, node in pairs(network.netpoints) do
				unitTest:assert(node.targetId ~= 1)
				unitTest:assert(node.targetId ~= 0)
				unitTest:assert(node.targetId ~= 4)
				unitTest:assert(node.targetId ~= 3)
				unitTest:assert(node.targetId ~= 5)
				if node.target then
					unitTest:assertNil(node.next)
				else
					unitTest:assertNotNil(node.next)
				end
			end

			local warns = {
				[1] = "Line '4' has more than one target. Target '1' was removed by '0', distances (23.650280162811, 11.674443987434).",
				[2] = "Line '4' has more than one target. Target '0' was removed by '3', distances (11.674443987434, 6.7264736303321).",
				[3] = "Line '4' has more than one target. Target '4' was removed by '3', distances (7.6899493816548, 6.7264736303321).",
				[4] = "Target '3' of line '4' was removed by target '2'.",
				[5] = "Target '5' of line '2' was removed by target '2'."
			}

			for i = 1, #warnMsgs do
				unitTest:assertEquals(findWarning(warns, warnMsgs[i]), warnMsgs[i])
			end

			customWarning = customWarningBkp
		end

		local targetSecondNodeExists = function()
			local roads = CellularSpace{
				file = filePath("test/roads_second_node_exists.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/plants_second_node_exists.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning

			local warnMsg
			customWarning = function(msg)
				warnMsg = msg
			end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			for _, node in pairs(network.netpoints) do
				unitTest:assert(node.targetId ~= 0)
				if node.target then
					unitTest:assertNil(node.next)
				else
					unitTest:assertNotNil(node.next)
				end
			end

			unitTest:assert((warnMsg == "Target '0' of line '9' was removed by target '1'.")
							or (warnMsg == "Target '0' of line '9' cannot enter in the network due to target '1'."))

			customWarning = customWarningBkp
		end

		local reviewingFirstOfSecondNode = function()
			local roads = CellularSpace{
				file = filePath("test/roads_rev_fst_sec.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/plants_rev_fst_sec.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			for _, node in pairs(network.netpoints) do
				unitTest:assert(node.targetId ~= 2)
				if node.target then
					unitTest:assertNil(node.next)
				else
					unitTest:assertNotNil(node.next)
				end
			end

			unitTest:assertEquals(warnMsgs[1],
					"Line '4' has more than one target. Target '0' was removed by '1', distances (3.2425074901149, 0.52582088794423).")
			unitTest:assertEquals(warnMsgs[2], "Target '2' of line '8' was removed by target '1'.")

			customWarning = customWarningBkp
		end

		local removeTargetNodeCircular = function()
			local roads = CellularSpace{
				file = filePath("test/roads_target_node_2.shp", "gpm"),
				missing = 0
			}

			local ports = CellularSpace{
				file = filePath("test/plants_target_node_2.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			local warnMsgs = {}
			customWarning = function(msg)
				table.insert(warnMsgs, msg)
			end

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			customWarning = customWarningBkp

			local warns = {
				[1] = "Target '1' of line '39' was removed by target '2'.",
				[2] = "Target '3' of line '49' was removed by target '2'."
			}

			for i = 1, #warnMsgs do
				unitTest:assertEquals(findWarning(warns, warnMsgs[i]), warnMsgs[i])
			end

			for _, node in pairs(network.netpoints) do
				unitTest:assert(node.targetId ~= 1)
				unitTest:assert(node.targetId ~= 3)

				if node.target then
					unitTest:assertNil(node.next)
				else
					unitTest:assertNotNil(node.next)
				end
			end

			checkNetworkProperties(network, #ports)
		end

		local checkBrazilPlantsProperties = function()
			local roads = CellularSpace{
				file = filePath("br_roads_5880.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/br_plants_5880.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			customWarning = function() end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			customWarning = customWarningBkp

			checkNetworkProperties(network, #plants)
		end

		local problemWithRouterInAdjustTargetPreviousNode = function()
			local roads = CellularSpace{
				file = filePath("test/roads_node_next_problem.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/plants_node_next_problem.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			customWarning = function() end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			customWarning = customWarningBkp

			checkNetworkProperties(network, #plants)
		end

		local problemWithNextNodeOfRemovedTarget = function()
			local roads = CellularSpace{
				file = filePath("test/roads_node_next_problem2.shp", "gpm"),
				missing = 0
			}

			local plants = CellularSpace{
				file = filePath("test/plants_node_next_problem2.shp", "gpm"),
				missing = 0
			}

			local customWarningBkp = customWarning
			customWarning = function() end

			local network = Network{
				lines = roads,
				target = plants,
				progress = false,
				validate = false,
				inside = function(distance, line)
					return distance * line.custo_ajus * 1e-3
				end,
				outside = function(distance)
					return distance * 0.002388 --< (1e-3 * 2 * 1.194)
				end
			}

			customWarning = customWarningBkp

			checkNetworkProperties(network, #plants)
		end

		unitTest:assert(networkSetWeightAndOutsideEqualDistance)
		unitTest:assert(networkSetWeightAndOutsideMultipliedBy2)
		unitTest:assert(networkSetWeightAndOutsideDividedBy2)
		unitTest:assert(networkSetWeightDividedBy10)
		unitTest:assert(networkWithInvertedLine)
		unitTest:assert(networkWithTwoTargetsInSameLine)
		unitTest:assert(networkValidateFalse)
		unitTest:assert(networkReviewMoreThanOneRouterNode)
		unitTest:assert(networkReviewLineWith2Points)
		unitTest:assert(problemWhenErrorArgumentIsTooBig)
		unitTest:assert(joinConnectedLinesTest)
		unitTest:assert(targetNodeIsEqualsToLineEndpoints)
		unitTest:assert(adjustRouterNodePositionTest)
		unitTest:assert(reviewNextNodeWhenItIsTargetNode)
		unitTest:assert(lineHasTwoTargets)
		unitTest:assert(lineHasTwoTargetsAnother)
		unitTest:assert(checkBrazilPortsProperties)
		unitTest:assert(hasTargetNodeAtReviewPreviousNodes)
		unitTest:assert(hasTargetNodeAtSamePlace)
		unitTest:assert(targetSecondNodeExists)
		unitTest:assert(reviewingFirstOfSecondNode)
		unitTest:assert(removeTargetNodeCircular)
		unitTest:assert(checkBrazilPlantsProperties)
		unitTest:assert(problemWithRouterInAdjustTargetPreviousNode)
		unitTest:assert(problemWithNextNodeOfRemovedTarget)
	end,
	distances = function(unitTest)
		local weightOptions = function()
			local roads = CellularSpace{
				file = filePath("test/roads_sirgas2000_south3.shp", "gpm")
			}

			local ports = CellularSpace{
				file = filePath("test/porto_alegre_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local network = Network{
				lines = roads,
				target = ports,
				progress = false,
				inside = function(distance)
					return distance
				end,
				outside = function(distance)
					return distance * 4
				end
			}

			local port = ports:get("0")

			local portEstrelaCs = CellularSpace{
				file = filePath("test/port_estrela_sirgas2000.shp", "gpm"),
				missing = 0
			}

			local portEstrelaCell = portEstrelaCs:get("0")

			local lowestEntrance = function()
				local distances = network:distances(port, "lowest")
				unitTest:assertEquals(distances[0].weight, 8118.1838889808, 1.0e-10)


				local distances2 = network:distances(port, "lowest", "points")
				unitTest:assertEquals(distances2[0].weight, 0)

				local distances3 = network:distances(portEstrelaCell, "lowest")
				unitTest:assertEquals(distances3[0].weight, 196084.56388036, 1.0e-8)

				local distances4 = network:distances(portEstrelaCell, "lowest", "points")
				unitTest:assertEquals(distances4[0].weight, 196084.56388036, 1.0e-8)
			end

			local closestEntrance = function()
				local distances = network:distances(port, "closest")
				unitTest:assertEquals(distances[0].weight, 8118.1838889808, 1.0e-10)

				local distances2 = network:distances(port, "closest", "points")
				unitTest:assertEquals(distances2[0].weight, 0)

				local distances3 = network:distances(portEstrelaCell, "closest")
				unitTest:assertEquals(distances3[0].weight, 196084.56388036, 1.0e-8)

				local distances4 = network:distances(portEstrelaCell, "closest", "points")
				unitTest:assertEquals(distances4[0].weight, 196084.56388036, 1.0e-8)
			end

			unitTest:assert(lowestEntrance)
			unitTest:assert(closestEntrance)
		end

		local removeTargetButCellEnterInIt = function()
			local communities = CellularSpace{
				file = filePath("communities.shp", "gpm")
			}

			local roads = CellularSpace{
				file = filePath("roads.shp", "gpm")
			}

			local cells = CellularSpace{
				file = filePath("cells.shp", "gpm")
			}

			local network
			local warn = function()
				network = Network{
					target = communities,
					lines = roads,
					progress = false,
					inside = function(distance, cell)
						if cell.STATUS == "paved" then
							return distance / 5
						else
							return distance / 2
						end
					end,
					outside = function(distance) return distance * 4 end
				}
			end

			unitTest:assertWarning(warn, "Target '1' of line '10' was removed by target '2'.")

			local count1 = 0
			forEachCell(cells, function(cell)
				local weights = network:distances(cell, "closest", "points")
				for targetId, _ in pairs(weights) do
					if targetId == 1 then
						count1 = count1 + 1
					end
				end
			end)

			unitTest:assertEquals(count1, 55)

			local count2 = 0
			forEachCell(cells, function(cell)
				local weights = network:distances(cell, "lowest", "points")
				for targetId, _ in pairs(weights) do
					if targetId == 1 then
						count2 = count2 + 1
					end
				end
			end)

			unitTest:assertEquals(count2, 2254)
			unitTest:assertEquals(#cells, count2)

			local count3 = 0
			forEachCell(cells, function(cell)
				local weights = network:distances(cell, "closest", "lines")
				for targetId, _ in pairs(weights) do
					if targetId == 1 then
						count3 = count3 + 1
					end
				end
			end)

			unitTest:assertEquals(count3, 0)

			local count4 = 0
			forEachCell(cells, function(cell)
				local weights = network:distances(cell, "lowest", "lines")
				for targetId, _ in pairs(weights) do
					if targetId == 1 then
						count4 = count4 + 1
					end
				end
			end)

			unitTest:assertEquals(count4, #cells)
		end

		unitTest:assert(weightOptions)
		unitTest:assert(removeTargetButCellEnterInIt)
	end
}
