-- @example Compute the neighbors of some Brazilian states. The weight
-- is based on the proportion beteween the intersection area and
-- the perimeter of the state.

-- import gpm
import("gpm")

-- create the CellularSpace
local states = CellularSpace{
	file = filePath("partofbrazil.shp", "gpm"),
	-- if we use brazilstates, from base package
	-- file = filePath("brazilstates.shp"),
	-- we got the following error:
	-- Error:TopologyException: side location conflict at 206365.69730904375 -131152.72123499925
	geometry = true
}

-- creating a GPM
local gpm = GPM{
	origin = states,
	strategy = "border",
	progress = false
}

forEachOrderedElement(gpm.neighbor, function(idx, neigh)
	print(states:get(idx).name)

	forEachOrderedElement(neigh, function(midx, weight)
		print("\t"..states:get(midx).name.." ("..string.format("%.2f", weight)..")")
	end)
end)

