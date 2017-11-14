-- local function sumDistanceByNext(node)
	-- local next = node.next
	-- local sum = 0 --node.distance
	-- local currNode = node
	-- while next do
		-- if next.last then
			-- sum = sum + next.distance - currNode.distance
			-- for i = 1, #next.next do
				-- sum = sum + sumDistanceByNext(next.next[i]) + next.next[i].distance - next.distance
			-- end
			-- return sum
		-- else
			-- sum = sum + next.distance - currNode.distance
		-- -- if node.line.id == 28 then
			-- -- _Gtme.print(sum, next.distance - currNode.distance, next.pos)
		-- -- end
		-- end
		-- currNode = next
		-- next = next.next
	-- end

	-- return sum
-- end

-- local function sumDistanceByPrevious(node)
	-- local previous = node.previous
	-- local sum = 0
	-- local currNode = node

	-- while previous do
		-- if previous.first then
			-- --_Gtme.print("first", #previous.previous)
			-- sum = sum + previous.distance - currNode.distance
			-- for i = 1, #previous.previous do
				-- --_Gtme.print(previous.pos, previous.previous[i].pos)
				-- --_Gtme.print(previous.distance,  previous.previous[i].distance, previous.previous[i].distance - previous.distance)
				-- sum = sum + sumDistanceByPrevious(previous.previous[i]) + previous.previous[i].distance - previous.distance

			-- end
			-- return sum
		-- else
			-- sum = sum + previous.distance - currNode.distance
			-- -- if (node.line.id == 28) or (node.line.id == 26) then
				-- -- _Gtme.print(previous.distance - currNode.distance, currNode.pos, previous.pos)
			-- -- end
		-- end
		-- currNode = previous
		-- previous = previous.previous
	-- end

	-- return sum
-- end

local function sumPreviousDistances(node)
	-- if not previousNode then
		-- return 0
	-- end
	local previousNode = node.previous
	local currNode = node
	local sum = 0

	while previousNode do
		if currNode.router then
			--_Gtme.print("currNode router", currNode.line.id)
			for i = 1, #currNode.previous do
				local dt = currNode.previous[i].distance - currNode.distance
				sum = sum + sumPreviousDistances(currNode.previous[i]) + dt
			end
			return sum			
		end
		--_Gtme.print(previousNode.line.id, previousNode.pos)
		local delta = previousNode.distance - currNode.distance
		sum = sum + delta

		if previousNode.router then
			--_Gtme.print("-----------------------------")
			--_Gtme.print("previous router", previousNode.line.id)
			--_Gtme.print("router", #previousNode.previous)
			for i = 1, #previousNode.previous do
				local dt = previousNode.previous[i].distance - previousNode.distance
				--_Gtme.print("previous line", previousNode.previous[i].line.id)
				sum = sum + sumPreviousDistances(previousNode.previous[i]) + dt
			end
			return sum
		end
		--_Gtme.print(previousNode.line.id, currNode.line.id)
		currNode = previousNode
		previousNode = previousNode.previous
	end

	-- if previousNode.router then
		-- for i = 1, #previousNode.previous do
			-- return node.distance - previousNode.distance + sumPreviousDistances(previousNode, previousNode.previous[i])
		-- end
	-- --elseif not node.router then
		-- return 0
	-- end
	
	-- return previousNode.distance - node.distance + sumPreviousDistances(previousNode, previousNode.previous)	

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
			-- if targetLine.id == 10 then
				-- -- _Gtme.print(currPoint:distance(nextPoint), i)
				-- _Gtme.print(acumDistance, currPoint:distance(nextPoint), i)
			-- end
		end

		-- if targetLine.id == 8 then
			-- acumDistance = acumDistance + 743.63102767576
			-- lineLength = lineLength + 743.63102767576
		-- end
	end
	--_Gtme.print("--------------------------")

	unitTest:assertEquals(acumDistance, lineLength, 1.0e-10)
	_Gtme.print(targetLine.id)
	local totalDistance = sumDistances(targetNode) --sumDistanceByNext(targetNode) + sumDistanceByPrevious(targetNode)

		-- _Gtme.print("-----++++++++++++++++++++++++++++")
		-- local nline = 13
		-- if lines[nline] then
			-- local sum = 0
			-- for i = 0, lines[nline].npoints - 2 do
				-- local pi = lines[nline].geom:getPointN(i)
				-- local pi1 = lines[nline].geom:getPointN(i + 1)
				-- local dif = pi1:distance(pi)
				-- _Gtme.print(dif)
				-- _Gtme.print(netpoints[pi:asText()].targetId, netpoints[pi:asText()].previous) --, netpoints[pi:asText()].previous.line.id)
				-- -- for k, v in pairs (netpoints[pi:asText()].previous) do
					-- -- _Gtme.print("**", k, v, v.line.id)
				-- -- end
				-- --_Gtme.print(netpoints[pi1:asText()].targetId, netpoints[pi1:asText()].previous, netpoints[pi1:asText()].previous.line.id)
				-- sum = sum + dif
			-- end
			-- _Gtme.print("length", lines[nline].geom:getLength(), sum)
		-- end	
		
	unitTest:assertEquals(getn(netpoints), 245)	
	
	if targetLine.id == 28 then
		--_Gtme.print(lines[15].geom:getLength() - 525.19123580594)
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
	elseif targetLine.id == 18 then
		--_Gtme.print(lines[3].geom:getLength())
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
									+ lines[32].geom:getLength() + lines[16].geom:getLength()
									--+ lines[33].geom:getLength() --< removed by line 8
									-- isAdjacentByPoints(endpointsLine.last, endpointsULine.first)
									+ lines[3].geom:getLength()
	elseif targetLine.id == 8 then
		--_Gtme.print(lines[36].geom:getLength() - 407.49787123649)
		--_Gtme.print(lines[36].geom:getLength() - 186.44783835029)
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
	elseif targetLine.id == 10 then
		acumDistance = acumDistance
									-- adjancent lines
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.start)
									+ lines[7].geom:getLength()
									-- isAdjacentByPoints(endpointsTarget.last, endpointsLine.last)
									+ lines[29].geom:getLength()

									-- non-adjancent lines
									--+ lines[15].geom:getLength()
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
		--unitTest:assertEquals(targetNode.first.point:asText(), firstNode.point:asText()) -- SKIP
		secPointIdx = firstPointIdx + 1
	else
		--unitTest:assertEquals(targetNode.first.point:asText(), firstNode.point:asText()) -- SKIP
		secPointIdx = firstPointIdx - 1
	end

	local secPoint = targetLine.geom:getPointN(secPointIdx)
	local secNode = netpoints[secPoint:asText()]

	unitTest:assertEquals(targetNode.second.id, secNode.id)
	unitTest:assertEquals(secNode.next.id, targetNode.id)

	testDataConnections(unitTest, targetNode)
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
			weight = function(distance, cell) -- weights is only the distance
				return distance
			end,
			outside = function(distance)
				return distance
			end
		}

		unitTest:assertType(network1, "Network")
		-- unitTest:assertEquals(#network1.distance.lines, #roads.cells) -- SKIP
		-- unitTest:assertEquals(#network1.distance.target, #communities.cells) -- SKIP

		-- forEachElement(network1.distance.netpoint, function(_, netpoint)
			-- unitTest:assert(netpoint.distance >= 0) -- SKIP
			-- unitTest:assert(netpoint.distanceOutside >= 0) -- SKIP
			-- unitTest:assertType(netpoint.targetIDOutside, "number") -- SKIP
			-- unitTest:assertType(netpoint.targetID, "number") -- SKIP
			-- unitTest:assertType(netpoint.point, "userdata") -- SKIP
		-- end)

		unitTest:assert(network1.lines ~= roads)
		unitTest:assertEquals(getn(network1.lines), #roads)
		unitTest:assertNotNil(network1.lines[0])
		unitTest:assertNotNil(network1.lines[37])
		unitTest:assertNil(network1.lines[38])

		unitTest:assertEquals(network1.lines[10].shortestPath, 599.05719061263, 1.0e-10)
		unitTest:assertEquals(network1.lines[8].shortestPath, 59.688264448298, 1.0e-10)
		unitTest:assertEquals(network1.lines[18].shortestPath, 83.520707733564, 1.0e-10)
		unitTest:assertEquals(network1.lines[28].shortestPath, 1041.9740663377, 1.0e-10)

		forEachElement(network1.lines, function(id, line)
			if not ((id == 8) or (id == 10) or (id == 18) or (id == 28)) then
				unitTest:assertNil(network1.lines[id].shortestPath)
			end
		end)

		--unitTest:assertEquals(getn(network1.netpoints), #communities) --SKIP
		unitTest:assertEquals(network1.netpoints[network1.lines[10].closestPoint.id].distance, network1.lines[10].shortestPath)
		unitTest:assertEquals(network1.netpoints[network1.lines[8].closestPoint.id].distance, network1.lines[8].shortestPath)
		unitTest:assertEquals(network1.netpoints[network1.lines[18].closestPoint.id].distance, network1.lines[18].shortestPath)
		unitTest:assertEquals(network1.netpoints[network1.lines[28].closestPoint.id].distance, network1.lines[28].shortestPath)

		local targetNodes = {}

		forEachElement(network1.netpoints, function(_, netpoint)
			--unitTest:assert((#netpoint.arcs == 1) or (#netpoint.arcs == 2)) -- SKIP

			if netpoint.line.id == 8 then
				unitTest:assert(netpoint.distance >= network1.lines[8].shortestPath)
				if netpoint.target then
					targetNodes[8] = netpoint
				end
			elseif netpoint.line.id == 10 then
				unitTest:assert(netpoint.distance >= network1.lines[10].shortestPath)
				if netpoint.target then
					targetNodes[10] = netpoint
				end
			elseif netpoint.line.id == 18 then
				unitTest:assert(netpoint.distance >= network1.lines[18].shortestPath)
				if netpoint.target then
					targetNodes[18] = netpoint
				end
			elseif netpoint.line.id == 28 then
				unitTest:assert(netpoint.distance >= network1.lines[28].shortestPath)
				if netpoint.target then
					targetNodes[28] = netpoint
				end
			--else
			--	unitTest:assertEquals(netpoint.line[1].id, -1) -- SKIP --<< this assert is only to check the elseifs and it mustn't be executed
			end
		end)

		forEachElement(targetNodes, function(i)
			testNetpointsDistances(unitTest, network1.netpoints, targetNodes[i], network1.lines[i], network1.lines)
			testNetpointsConnections(unitTest, network1.netpoints, targetNodes[i], network1.lines[i])
		end)

		-- forEachElement(network1.netpoints, function(_, node)
			-- _Gtme.print(node.line.id)
			-- if node.next then
				-- _Gtme.print(node.next.id)
			-- end
			-- if node.previous then
				-- _Gtme.print(node.previous.id)
			-- end
		-- end)
		--testNetpointsDistances(unitTest, network1.netpoints, targetNodes[8], network1.lines[8])
		--testNetpointsConnections(unitTest, network1.netpoints, targetNodes[8], network1.lines[8])

		-- LINES VAI TER QUE SUMIR, CRIAR MYLYNES
		--testNetpointsDistances(unitTest, network1.netpoints, targetNodes[10], network1.lines[10])
		--testNetpointsConnections(unitTest, network1.netpoints, targetNodes[10], network1.lines[10])

		-- forEachElement(network1.netpoints, function(id, line)
			-- if not ((id == 8) or (id == 10) or (id == 18) or (id == 28)) then
				-- unitTest:assertNil(network1.lines[id].shortestPath) -- SKIP
			-- end
		-- end)

		-- for k, v in pairs(roads) do
			-- _Gtme.print(k, v)
			-- break
		-- end

		-- for k, v in pairs(network1.lines) do
			-- _Gtme.print(k, v)
			-- break
		-- end
		--_Gtme.print(roads[1])
		--_Gtme.print(network1.lines[1])

		-- local netpoint = network1.distance.netpoint
		-- local target = network1.distance.target

		-- for i = 1, #target do
			-- unitTest:assert((target[i].FID == 18) or (target[i].FID == 10) or -- SKIP
							-- (target[i].FID == 8) or (target[i].FID == 28))
		-- end

		-- forEachElement(netpoint, function(_, np)
			-- for fid, line in pairs(np.arcs) do
				-- if (fid == 8) or (fid == 35) or (fid == 1) or (fid == 30) or
					-- (fid == 11) or (fid == 23) or (fid == 31) or (fid == 12) or
					-- (fid == 34) or (fid == 21) then
					-- unitTest:assertEquals(target[np.targetID].FID, 8) -- SKIP
				-- elseif fid == 29 then
					-- unitTest:assertEquals(target[np.targetID].FID, 10) -- SKIP
				-- elseif (fid == 18) or (fid == 3) or (fid == 4) or (fid == 37) or
						-- (fid == 22) or (fid == 2) or (fid == 5) or (fid == 0) or
						-- (fid == 13) or (fid == 32) then
					-- unitTest:assertEquals(target[np.targetID].FID, 18) -- SKIP
				-- elseif (fid == 28) or (fid == 25) or (fid == 24) or (fid == 26) or
						-- (fid == 27) or (fid == 9) then
					-- unitTest:assertEquals(target[np.targetID].FID, 28) -- SKIP
				-- elseif (fid == 10) or (fid == 19) or (fid == 20) or (fid == 6) then
					-- unitTest:assert((target[np.targetID].FID == 8) or (target[np.targetID].FID == 10)) -- SKIP
				-- elseif (fid == 7) or (fid == 17) or (fid == 15) then
					-- unitTest:assert((target[np.targetID].FID == 10) or (target[np.targetID].FID == 28)) -- SKIP
				-- elseif (fid == 33) or (fid == 36) then
					-- unitTest:assert((target[np.targetID].FID == 8) or (target[np.targetID].FID == 18)) -- SKIP
				-- elseif fid == 16 then
					-- unitTest:assert((target[np.targetID].FID == 10) or (target[np.targetID].FID == 8) or -- SKIP
									-- (target[np.targetID].FID == 18))
				-- elseif fid == 14 then
					-- unitTest:assert((target[np.targetID].FID == 10) or (target[np.targetID].FID == 8) or -- SKIP
									-- (target[np.targetID].FID == 28))
				-- else
					-- unitTest:assertEquals(fid, -1) -- SKIP --<< this assert is only to check the elseifs and it mustn't be executed
				-- end
			-- end
		-- end)

		-- roads = CellularSpace{
			-- file = filePath("roads.shp", "gpm")
		-- }

		-- communities = CellularSpace{
			-- file = filePath("communities.shp", "gpm")
		-- }

		-- local network2 = Network{
			-- lines = roads,
			-- target = communities,
			-- progress = false,
			-- weight = function(distance, cell)
				-- if cell.STATUS == "paved" then
					-- return distance * 0.2
				-- else
					-- return distance * 0.5
				-- end
			-- end,
			-- outside = function(distance)
				-- return distance * 2
			-- end
		-- }

		-- local netpoint = network2.distance.netpoint
		-- local target = network2.distance.target

		-- for i = 1, #target do
			-- unitTest:assert((target[i].FID == 18) or (target[i].FID == 10) or -- SKIP
							-- (target[i].FID == 8) or (target[i].FID == 28))
		-- end

		-- forEachElement(netpoint, function(_, np)
			-- for fid, line in pairs(np.arcs) do
				-- if (fid == 8) or (fid == 35) or (fid == 1) or (fid == 30) or
					-- (fid == 11) or (fid == 23) or (fid == 31) or (fid == 12) or
					-- (fid == 34) or (fid == 21) then
					-- unitTest:assertEquals(target[np.targetID].FID, 8) -- SKIP
				-- elseif fid == 29 then
					-- unitTest:assertEquals(target[np.targetID].FID, 10) -- SKIP
				-- elseif (fid == 18) or (fid == 3) or (fid == 4) or (fid == 37) or
						-- (fid == 22) or (fid == 2) or (fid == 5) or (fid == 0) or
						-- (fid == 13) or (fid == 32) then
					-- unitTest:assertEquals(target[np.targetID].FID, 18) -- SKIP
				-- elseif (fid == 28) or (fid == 25) or (fid == 24) or (fid == 26) or
						-- (fid == 27) or (fid == 9) then
					-- unitTest:assertEquals(target[np.targetID].FID, 28) -- SKIP
				-- elseif (fid == 10) or (fid == 19) or (fid == 20) or (fid == 6) then
					-- unitTest:assert((target[np.targetID].FID == 8) or (target[np.targetID].FID == 10)) -- SKIP
				-- elseif (fid == 7) or (fid == 17) or (fid == 15) then
					-- unitTest:assert((target[np.targetID].FID == 10) or (target[np.targetID].FID == 28)) -- SKIP
					-- _Gtme.print(fid, target[np.targetID].FID)
					-- if fid == 7 then
						-- for k, v in pairs(np) do
							-- _Gtme.print(k, v)
						-- end
						-- for k, v in pairs(np.arcs) do
							-- _Gtme.print(k)
						-- end
						-- os.exit(0)
					-- end
				-- elseif (fid == 33) or (fid == 36) then
					-- unitTest:assert((target[np.targetID].FID == 8) or (target[np.targetID].FID == 18)) -- SKIP
				-- elseif fid == 16 then
					-- unitTest:assert((target[np.targetID].FID == 10) or (target[np.targetID].FID == 8) or -- SKIP
									-- (target[np.targetID].FID == 18))
				-- elseif fid == 14 then
					-- unitTest:assert((target[np.targetID].FID == 10) or (target[np.targetID].FID == 8) or -- SKIP
									-- (target[np.targetID].FID == 28))
				-- else
					-- unitTest:assertEquals(fid, -1) -- SKIP --<< this assert is only to check the elseifs and it mustn't  be executed
				-- end
			-- end
		-- end)

	end
}

