data{
	file = "farms.shp",
	attributes = {"id"},
	description = {"Character identifier"},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "rfarms_cells2.shp",
	attributes = {
		"id",
		"col",
		"row"
	},
	description = {
		"Character identifier",
		"number of columns",
		"number of line"
	},
	summary = "A shapefile describing the farms.",
	source = "TerraME team"
}

data{
	file = "censopop2000_bd.shp",
	attributes = {
		"MSLINK", 
		"AREA_1",
		"PERIMETRO_",
		"CODIGO",
		"NOMEMUNI",
		"RENDIMENTO",
		"NUMERO_PES",
		"RENDAPCAPI",
		"DENS_POP"
	},
	description = {
		"?",
		"Area of region",
		"Perimeter of city",
		"Character code",
		"Name of city",
		"Yield of the city",
		"Number of people",
		"Income per person",
		"Population density"
	},
	summary = "A shapefile describing the population control.",
	source = "TerraME team"
}

data{
	file = "communities.shp",
	attributes = {
		"LAYER", 
		"LOCALIDADE",
		"MUNICIPIO",
		"ATENDIMENT",
		"POPULA__O",
		"UCS_FATURA",
		"ALIMENTADO",
		"CONSUMO_FA",
		"CONSUMO_ME"
	},
	description = {
		"Type of layer",
		"Location of region",
		"City of the region",
		"Atendiment in the region",
		"Number of population",
		"?",
		"Fed communities",
		"?",
		"?"
	},
	summary = "A shapefile describing the communities states.",
	source = "TerraME team"
}

data{
	file = "comunidades_UTM.shp",
	attributes = {
		"LAYER", 
		"LOCALIDADE",
		"MUNICIPIO",
		"ATENDIMENT",
		"POPULA__O",
		"UCS_FATURA",
		"ALIMENTADO",
		"CONSUMO_FA",
		"CONSUMO_ME"
	},
	description = {
		"Type of layer",
		"Location of region",
		"City of the region",
		"Atendiment in the region",
		"Number of population",
		"?",
		"Fed communities",
		"?",
		"?"
	},
	summary = "A shapefile describing the population control.",
	source = "TerraME team"
}

data{
	file = "lotes_UTM.shp",
	attributes = {"id"},
	description = {"Character identifier"},
	summary = "A shapefile describing the lots.",
	source = "TerraME team"
}

data{
	file = "roads.shp",
	attributes = {
		"GM_LAYER", 
		"GM_TYPE",
		"LAYER",
		"FEATURE_ID",
		"CD_NUMERO_",
		"CD_ALINHAM",
		"CD_CLASSE",
		"CD_PAVIMEN",
		"CD_TRAFEGO",
		"CD_SITUACA",
		"CD_ADMINIS",
		"NM_RODOVIA",
		"NM_SIGLA",
		"PROJECT_ID",
		"SHAPE_LENG",
		"SHAPE_LEN",
		"OBJET_ID_8"
	},
	description = {
		"Geometry of layer",
		"Type of geometry",
		"Type of layer",
		"Identifier feature",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"Number of highway",
		"Number of acronyms",
		"Identifier project",
		"?",
		"?",
		"Objects identifier 8"
	},
	summary = "A shapefile describing the lots.",
	source = "TerraME team"
}

data{
	file = "rondonia_roads_lin.shp",
	attributes = { 
		"SPRPERIMET", 
		"SPRCLASSE",
		"objet_id_5"
	},
	description = {
		"?",
		"?",
		"Objects identifier 55"
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
		"SPRROTULO", 
		"SPRNOME",
		"MSLINK",
		"MAPID",
		"CODIGO",
		"AREA_1",
		"PERIMETRO_",
		"GEOCODIGO",
		"NOME",
		"SEDE",
		"LATITUDESE",
		"LONGITUDES",
		"AREA_TOT_G",
		"objet_id_2"
	},
	description = {
		"?",
		"?",
		"?",
		"Identifier of map",
		"Character code",
		"Area of region",
		"Perimeter of city",
		"Geografico code",
		"Name of city",
		"?",
		"Latitude of city",
		"Longitude of city",
		"?",
		"Objects identifier 2"
	},
	summary = "A shapefile describing urban centers of Rondonia.",
	source = "TerraME team"
}

data{
	file = "rodovias_UTM.shp",
	attributes = {
		"GM_LAYER", 
		"GM_TYPE",
		"LAYER",
		"FEATURE_ID",
		"CD_NUMERO_",
		"CD_ALINHAM",
		"CD_CLASSE",
		"CD_PAVIMEN",
		"CD_TRAFEGO",
		"CD_SITUACA",
		"CD_ADMINIS",
		"NM_RODOVIA",
		"NM_SIGLA",
		"PROJECT_ID",
		"SHAPE_LENG",
		"SHAPE_LEN",
		"OBJET_ID_8"
	},
	description = {
		"Geometry of layer",
		"Type of geometry",
		"Type of layer",
		"Identifier feature",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"?",
		"Number of highway",
		"Number of acronyms",
		"Identifier project",
		"?",
		"?",
		"Objects identifier 8"
	},
	summary = "A shapefile describing urban centers of Rondonia.",
	source = "TerraME team"
}