-- @example Implementation of a simple Generalized Transport Cost model.
-- It calculates the GTC for Brazil considering the most important ports
-- of the country as destinations, using the main roads network for displacement.
-- GPM configuration is set with the entrance option as closest line by lines (default).

import("gpm")

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
	inside = function(distance, line)
		return distance * 1e-3 * line.custo_ajus
	end,
	outside = function(distance)
		return distance * 1e-3 * 2
	end
}

local cs = CellularSpace{
	file = filePath("br_cs_5880_25x25km.shp", "gpm")
}

local gpm = GPM{
	destination = network,
	origin = cs,
	progress = false
}

gpm:fill{
	strategy = "minimum",
	attribute = "cost",
	copy = "NOME_MICRO"
}

Map{
	target = cs,
	select = "cost",
	min = 5,
	max = 2860,
	slices = 20,
	color = "YlOrRd"
}

Map{
	target = cs,
	select = "NOME_MICRO",
	value = {"BELEM", "CARAGUATATUBA", "FORTALEZA", "ITAJAI",
			"JOINVILLE", "MACAE", "MOSSORO", "PARANAGUA",
			"RECIFE", "RIO DE JANEIRO", "SALVADOR", "SANTOS",
			"SAO LUIS", "VITORIA"},
	color = {"darkGreen", "blue", "red", "orange",
			"darkGray", "lightBlue", "magenta", "cyan",
			"brown", "gray", "lightRed", "darkPurple",
			"yellow", "green"}
}
