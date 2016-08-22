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

local function lineCheck(cs)
	local csPoint = CellularSpace{xdim = 1}
	local counter = 1

	forEachCell(cs, function(cell)
		local geometry = tl:castGeomToSubtype(cell.geom:getGeometryN(0))
		local nPoint = geometry:getNPoints()

		for i = 0, nPoint do
			local point = binding.te.gm.Point(geometry:getX(i), geometry:getY(i), geometry:getSRID())
			local cellPoint = Cell{point = point, x = i + 1, y = counter}

			csPoint:add(cellPoint)
		end
		counter = counter + 1
	end)

	return csPoint
end

local function getBELine(cs)
	local csPoint = CellularSpace{xdim = 1}
	local counter = 1

	forEachCell(cs, function(cell)
		local geometry = tl:castGeomToSubtype(cell.geom:getGeometryN(0))
		local nPoint = geometry:getNPoints()
		local beginPoint = binding.te.gm.Point(geometry:getX(0), geometry:getY(0), geometry:getSRID())
		local cellPoint = Cell{beginPoint = beginPoint, counter = counter, x = 1, y = counter }

		csPoint:add(cellPoint)
		for i = 1, nPoint do
			local endPoint = binding.te.gm.Point(geometry:getX(i), geometry:getY(i), geometry:getSRID())

		end

		local cellPoint = Cell{endPoint = endPoint, counter = counter, x = counter + 1, y = counter + 1}

		csPoint:add(cellPoint)
		counter = counter + 1
	end)

	return csPoint
end

local function targetCheck(csLine, csTarget)
	forEachCell(csTarget, function(cellRed)
		local lineValidates = false
		local differance = math.huge
		local geometry1 = tl:castGeomToSubtype(cellRed.geom:getGeometryN(0))

		forEachCell(csLine, function(cellBlue)
			local geometry2 = tl:castGeomToSubtype(cellBlue.geom:getGeometryN(0))
			local nPoint = geometry2:getNPoints()

			for i = 0, nPoint do
				local distance = geometry1:distance(cellBlue.geom)
				if differance > distance then
					differance = distance
				end

				if distance < 2 then
					lineValidates = true
				end
			end

			if lineValidates == true then
				return false
			end
		end)

		if not lineValidates then
			customError("line do not touch, They have a differance of: "..differance)
		end
	end)
end

local function checksInterconnectedNetwork(csLine, csTarget)
    local csPoint = getBELine(csLine)

	forEachCell(csPoint, function(cellRed)
		local lineValidates = false
		local differance = math.huge

		forEachCell(csPoint, function(cellBlue)
			if not (cellRed.counter == cellBlue.counter) and 
			cellRed.counter ~= nil and cellBlue.counter ~= nil then
				local distance = cellRed:distance(cellBlue)
    
				if differance > distance then
					differance = distance
				end

				if distance < 2 then
					lineValidates = true
				end
			end

			if lineValidates == true then
				return false
			end
		end)

		if not lineValidates and cellRed.x ~= 0 then
			customError("line do not touch, They have a differance of: "..differance)
		end
	end)
end

Network_ = {
	type_ = "Network"
}

metaTableNetwork_ = {
	__index = Network_,
	__tostring = _Gtme.tostring
}

--- Type for network creation. Given geometry of the line type,
-- constructs a geometry network. This type is used to calculate the best path.
-- @arg data.target CellularSpace that receives end points of the networks.
-- @arg data.lines CellularSpace that receives a network.
-- this CellularSpace receives a projet with geometry, a layer,
-- and geometry boolean argument, indicating whether the project has a geometry.
-- @arg data.strategy Strategy to be used in the network (optional).
-- @arg data.weight User defined function to change the network distance (optional).
-- @arg data.outside User-defined function that computes the distance based on an
-- Euclidean to enter and to leave the Network (optional).
-- @output a network based on the geometry.
-- @usage local roads = CellularSpace{
-- 	file = filePath("roads.shp", "gpm"),
-- 	geometry = true
-- }
-- local communities = CellularSpace{
-- 	file = filePath("communities.shp", "gpm"),
-- 	geometry = true
-- }
-- local nt = Network{
--	target = communities,
--	lines = roads
-- }
function Network(data)
	verifyNamedTable(data)
	if type(data.lines) ~= "CellularSpace" then
		incompatibleTypeError("lines", "CellularSpace", data.lines)
	else
		if data.lines.geometry then
			local cell = data.lines:sample()

			if not string.find(cell.geom:getGeometryType(), "Line") then
            	customError("Argument 'lines' should be composed by lines, got '"..cell.geom:getGeometryType().."'.")
			end
		end
	end

	if type(data.target) ~= "CellularSpace" then
		incompatibleTypeError("target", "CellularSpace", data.target)
	else
		if data.target.geometry then
			local cell = data.target:sample()

			if not string.find(cell.geom:getGeometryType(), "Point") then
            	customError("Argument 'target' should be composed by points, got '"..cell.geom:getGeometryType().."'.")
			end
		end
	end
    
	if data.strategy ~= nil and string.find(data.strategy, "open") then
		defaultValueWarning("strategy", data.strategy)
	end
    
	if data.weight ~= nil and type(data.weight) ~= "function" then
		incompatibleTypeError("weight", "function", data.weight)
	end
    
	if data.outside ~= nil and type(data.outside) ~= "function" then
		incompatibleTypeError("outside", "function", data.outside)
	end

	setmetatable(data, metaTableNetwork_)
	return data
end