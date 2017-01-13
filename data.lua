data{
	file = "partofbrasil.shp",
	attributes = {
		SPRAREA = "Polygon area", 
		SPRPERIMET = "Polygon perimeter", 
		SPRROTULO = "A name for the state", 
		SPRNOME = "A name for the state", 
		NOME_UF = "Name of the state",
		SIGLA = "A name for the state", 
		CAPITAL = "Name of the state's capital", 
		CODIGO = "A code for the state", 
		REGIAO = "Name of the region the state belongs", 
		POPUL = "Population of the state"
	},
	summary = "A shapefile describing the some Brazilian states.",
	source = "TerraME team"
}

data{
	file = "farms.shp",
	attributes = {id = "Character identifier"},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "farms_cells2.shp",
	attributes = {
		id = "Character identifier",
		col = "Number of columns",
		row = "Number of line"
	},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "farms_cells3.shp",
	attributes = {
		id = "Character identifier",
		col = "Number of columns",
		row = "Number of line"
	},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "farms_cells.shp",
	attributes = {
		id = "Character identifier",
		col = "Number of columns",
		row = "Number of line"
	},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "censopop2000_bd.shp",
	attributes = {
		MSLINK = "?", 
		AREA_1 = "Area of region",
		PERIMETRO_ = "Perimeter of city",
		CODIGO = "Character code",
		NOMEMUNI = "Name of city",
		RENDIMENTO = "Yield of the city",
		NUMERO_PES = "Number of people",
		RENDAPCAPI = "Income per person",
		DENS_POP = "Population density"
	},
	summary = "A shapefile describing the population control.",
	source = "TerraME team"
}

data{
	file = "communities.shp",
	attributes = {
		LAYER = "Type of layer", 
		LOCALIDADE = "Location of region",
		MUNICIPIO = "City of the region",
		ATENDIMENT = "Atendiment in the region",
		POPULA__O = "Number of population",
		UCS_FATURA = "?",
		ALIMENTADO = "Fed communities",
		CONSUMO_FA = "?",
		CONSUMO_ME = "?"
	},
	summary = "A shapefile describing the communities states.",
	source = "TerraME team"
}

data{
	file = "comunidades_UTM.shp",
	attributes = {
		LAYER = "Type of layer", 
		LOCALIDADE = "Location of region",
		MUNICIPIO = "City of the region",
		ATENDIMENT = "Atendiment in the region",
		POPULA__O = "Number of population",
		UCS_FATURA = "?",
		ALIMENTADO = "Fed communities",
		CONSUMO_FA = "?",
		CONSUMO_ME = "?"
	},
	summary = "A shapefile describing the population control.",
	source = "TerraME team"
}

data{
	file = "lotes_UTM.shp",
	attributes = {id = "Character identifier"},
	summary = "A shapefile describing the lots.",
	source = "TerraME team"
}

data{
	file = "roads.shp",
	attributes = {
		GM_LAYER = "Geometry of layer", 
		GM_TYPE = "Type of geometry",
		LAYER = "Type of layer",
		FEATURE_ID = "Identifier feature",
		CD_NUMERO_ = "?",
		CD_ALINHAM = "?",
		CD_CLASSE = "?",
		STATUS = "?",
		CD_TRAFEGO = "?",
		CD_SITUACA = "?",
		CD_ADMINIS = "?",
		NM_RODOVIA = "Number of highway",
		NM_SIGLA = "Number of acronyms",
		PROJECT_ID = "Identifier project",
		SHAPE_LENG = "?",
		SHAPE_LEN = "?",
		OBJET_ID_8 = "Objects identifier 8"
	},
	summary = "A shapefile describing the lots.",
	source = "TerraME team"
}

data{
	file = "rondonia_roads_lin.shp",
	attributes = { 
		SPRPERIMET = "?", 
		SPRCLASSE = "?",
		objet_id_5 = "Objects identifier 55"
	},
	summary = "A shapefile describing the roads of  rondonia.",
	source = "TerraME team"
}

data{
	file = {
		"rondonia_urban_centers_pt.shp",
		"rondonia_roads_props.txt",
		"rondonia_urban_centers_props.txt"
        },
	attributes = {
		SPRROTULO = "?", 
		SPRNOME = "?",
		MSLINK = "?",
		MAPID = "Identifier of map",
		CODIGO = "Character code",
		AREA_1 = "Area of region",
		PERIMETRO_ = "Perimeter of city",
		GEOCODIGO = "Geografico code",
		NOME = "Name of city",
		SEDE = "?",
		LATITUDESE = "Latitude of city",
		LONGITUDES = "Longitude of city",
		AREA_TOT_G = "?",
		objet_id_2 = "Objects identifier 2"
	},
	summary = "A shapefile describing urban centers of Rondonia.",
	source = "TerraME team"
}

data{
	file = "rodovias_UTM.shp",
	attributes = {
		GM_LAYER = "Geometry of layer", 
		GM_TYPE = "Type of geometry",
		LAYER = "Type of layer",
		FEATURE_ID = "Identifier feature",
		CD_NUMERO_ = "?",
		CD_ALINHAM = "?",
		CD_CLASSE = "?",
		STATUS = "?",
		CD_TRAFEGO = "?",
		CD_SITUACA = "?",
		CD_ADMINIS = "?",
		NM_RODOVIA = "Number of highway",
		NM_SIGLA = "Number of acronyms",
		PROJECT_ID = "Identifier project",
		SHAPE_LENG = "?",
		SHAPE_LEN = "?",
		OBJET_ID_8 = "Objects identifier 8"
	},
	summary = "A shapefile describing urban centers of Rondonia.",
	source = "TerraME team"
}