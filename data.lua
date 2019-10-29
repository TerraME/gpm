data{
	file = "partofbrazil.shp",
	attributes = {
		name = "Name of the state."
	},
	summary = "A shapefile describing the some Brazilian states.",
	source = "TerraME team"
}

data{
	file = "farms.shp",
	attributes = {id = "Unique identifier."},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "communities.shp",
	attributes = {
		LOCALIDADE = "Name of the community.",
		MUNICIPIO = "Municipality the community belongs.",
	},
	summary = "A shapefile describing some communities in Santarem, Para, Brazil.",
	source = "TerraME team"
}

data{
	file = "roads.shp",
	attributes = {
		STATUS = "Status of the road: 'paved' or 'nonpaved'.",
	},
	summary = "Some roads of Santarem, Para state, Brazil.",
	source = "TerraME team"
}

directory{
	name = "error",
	summary = "Some corrupted files for internal tests.",
	source = "TerraME team"
}

directory{
	name = "test",
	summary = "Some files for internal tests.",
	source = "TerraME team"
}

data{
	file = "area.gpm",
	summary = "GPM file created by example area.lua.",
	source = "TerraME team"
}

data{
	file = "border.gal",
	summary = "GAL file created by example border.lua.",
	source = "TerraME team"
}

data{
	file = "border.gwt",
	summary = "GWT file created by example border.lua.",
	source = "TerraME team"
}

data{
	file = "border.gpm",
	summary = "GPM file created by example border.lua.",
	source = "TerraME team"
}

data{
	file = "br_cs_5880_25x25km.shp",
	summary = "A cellular space created from Brazil territory.",
	source = "TerraME team"
}

data{
	file = "br_ports_5880.shp",
	attributes = {
		COD_IBGE = "IBGE code identifier.",
		NOME_UF = "Federative unit name.",
		COD_UF = "Federative unit code identifier.",
		NOME_MUNI = "Port municipality.",
		COD_MESO = "Region code identifier.",
		NOMEMESO = "Region name.",
		COD_MICRO = "Port city.",
		UF = "Federative unit abbreviation.",
		NOME_MICRO = "Port city name.",
		SITUACAOP = "Port status.",
		ADM = "Port administration.",
		TIPOCARGA = "Type of cargo.",
		EMPRESA = "Port administration company.",
		OBS = "Status note.",
		CODCENTRAN = "Unknow identifier.",
		objet_id_5 = "Unknow identifier.",
	},	
	summary = "A shapefile with some main sea ports of Brazil.",
	source = "TerraME team"
}

data{
	file = "br_roads_5880.shp",
	attributes = {
		OBJECTID_1 = "Unknow identifier.",
		OBJECTID = "Unknow identifier.",
		RODOVIA = "Road name.",
		EXTENSAO = "Road extension.",
		REVESTIMEN = "Road status.",
		JURISDICAO = "Road jurisdiction.",
		PISTA = "Road lane status.",
		custo_ajus = "Road cost.",
	},	
	summary = "A shapefile with Brazil main roads describing the transportation cost peer road stretch.",
	source = "TerraME team"
}
