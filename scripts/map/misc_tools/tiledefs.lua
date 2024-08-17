AddTile("HOODEDFOREST", -- tile_name 1
    "LAND",             -- tile_range 2
    {
        -- tile_data 3
        ground_name = "hoodedmoss",
    }, {
        -- ground_tile_def 4 -- Looking for the atlas here, which is hoodedmoss.xml
        name = "hoodedmoss",
        noise_texture = "noise_hoodedmoss",
        runsound = "dontstarve/movement/walk_grass",
        walksound = "dontstarve/movement/walk_grass",
        snowsound = "dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "hoodedmoss",
        noise_texture = "mini_noise_hoodedmoss.tex"
    }, {
        -- turf_def 6
        name = "hoodedmoss",
        anim = "hoodedmoss",
        bank_build = "hfturf"
    })

AddTile("ANCIENTHOODEDFOREST", 
	"LAND", 
	{ 
		ground_name = "ancienthoodedturf"
	}, { 
		name = "ancienthoodedturf", 
		noise_texture = "noise_jungle", 
		runsound = "dontstarve/movement/walk_grass", 
		walksound = "dontstarve/movement/walk_grass", 
		snowsound = "dontstarve/movement/run_snow", 
		mudsound = "dontstarve/movement/run_mud", 
		colors = GROUND_OCEAN_COLOR 
	},{ 
		name = "ancienthoodedturf.tex", 
		atlas = "ancienthoodedturf.xml", 
		noise_texture = "mini_noise_jungle.tex" 
	}, { 
		name = "ancienthoodedturf", 
		anim = "ancienthoodedturf", 
		bank_build = "hfturf" 
	})

AddTile("UM_FLOODWATER", 
	"LAND", 
	{ 
		ground_name = "um_floodwater",	
	}, { 
		name = "um_floodwater", 
		noise_texture = "noise_um_floodwater", 
		runsound = "dontstarve/movement/run_marsh", 
		walksound = "dontstarve/movement/walk_marsh", 
		snowsound = "dontstarve/movement/run_marsh", 
		mudsound = "dontstarve/movement/run_marsh", 
		colors = GROUND_OCEAN_COLOR, 
		cannotbedug = true 
	}, { 
		name = "map_edge", 
		noise_texture = "mini_noise_um_floodwater" 
	}, { 
		name = "ancienthoodedturf", 
		anim = "ancienthoodedturf", 
		bank_build = "hfturf" 
	})


	
AddTile("BOILINGFIELDS", -- tile_name 1
    "LAND",             -- tile_range 2
    {
        -- tile_data 3
        ground_name = "Savanna", -- <-- xenomeadow
    }, {
        -- ground_tile_def 4
        name = "yellowgrass", -- <-- xenomeadow
        noise_texture = "ground_xenomeadow.tex",
        runsound = "dontstarve/movement/walk_grass",
        walksound = "dontstarve/movement/walk_grass",
        snowsound = "dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "yellowgrass",
        noise_texture = "mini_ground_xenomeadow.tex"
    }, {
        -- turf_def 6
        name = "xenomeadow",
        anim = "xenomeadow",
        bank_build = "hfturf"
    })
	
AddTile("CRACKEDBASALT", -- tile_name 1
    "LAND",             -- tile_range 2
    {
        -- tile_data 3
        ground_name = "Rocky",
    }, {
        -- ground_tile_def 4
        name = "rocky",
        noise_texture = "ground_xenobasalt.tex",
        runsound = "dontstarve/movement/run_rock",
        walksound = "dontstarve/movement/walk_rock",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "hoodedmoss",
        noise_texture = "mini_ground_xenobasalt.tex"
    }, {
        -- turf_def 6
        name = "xenobasalt",
        anim = "xenobasalt",
        bank_build = "hfturf"
    })

AddTile(
    "UM_GRASSMAGMA", --tile_name 1
    "LAND", --tile_range 2
    { --tile_data 3
        ground_name = "magma_grass",
    },
    { --ground_tile_def 4
        name = "cleargrass",
        noise_texture = "levels/textures/ground_magma_grass.tex",
        runsound = "dontstarve/movement/walk_grass",
        walksound = "dontstarve/movement/walk_grass",
        snowsound = "dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    },
    { --minimap_tile_def 5
        name = "hoodedmoss.tex",
        atlas = "ancienthoodedturf.xml",
        noise_texture = "mini_um_grassmagma.tex"
    },
    { --turf_def 6
        name = "magma_rock",
        anim = "magma_rock",
        bank_build = "turf_archives"
    }
)

AddTile(
    "UM_MAGMA", --tile_name 1
    "LAND", --tile_range 2
    { --tile_data 3
        ground_name = "magma_rock",
    },
    {
        name = "blocky",
        noise_texture = "ground_magma_rock.tex", --Gearless's art
        runsound = "dontstarve/movement/run_rock",
        walksound = "dontstarve/movement/walk_rock",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    },
    { --Placeholder minimap
        name = "hoodedmoss.tex",
        atlas = "ancienthoodedturf.xml",
        noise_texture = "mini_um_magma.tex"
    },
    { --Placeholder turf
        name = "magma_rock",
        anim = "magma_rock",
        bank_build = "turf_archives"
    }
)

AddTile(
    "UM_FLOORTOX", --tile_name 1
    "IMPASSABLE", --tile_range 2
    { --tile_data 3
        ground_name = "floortox",
    },
    { 
        name = "rocky",
        noise_texture = "ground_floortox.tex",
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    },
    { --minimap_tile_def 5
        name = "hoodedmoss.tex",
        atlas = "ancienthoodedturf.xml",
        noise_texture = "mini_ground_xenobasalt.tex"
    },
    { --turf_def 6
        name = "magma_rock",
        anim = "magma_rock",
        bank_build = "turf_archives"
    }
)
	
ChangeTileRenderOrder(WORLD_TILES.UM_MAGMA, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.HOODEDFOREST, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.ANCIENTHOODEDFOREST, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.CRACKEDBASALT, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.BOILINGFIELDS, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.UM_FLOORTOX, WORLD_TILES.DIRT)


ChangeMiniMapTileRenderOrder(WORLD_TILES.HOODEDFOREST, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.ANCIENTHOODEDFOREST, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.CRACKEDBASALT, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.BOILINGFIELDS, WORLD_TILES.DIRT)