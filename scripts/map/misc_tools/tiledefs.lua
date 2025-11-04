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
    }, {
        name = "ancienthoodedturf.tex",
        atlas = "ancienthoodedturf.xml",
        noise_texture = "mini_noise_jungle.tex"
    }, {
        name = "ancienthoodedturf",
        anim = "ancienthoodedturf",
        bank_build = "hfturf"
    })

AddTile("HOODEDFOREST_FOLIAGE", -- tile_name 1
    "LAND",                     -- tile_range 2
    {
        -- tile_data 3
        ground_name = "hoodedfoliage",
    }, {
        -- ground_tile_def 4 -- Looking for the atlas here, which is hoodedmoss.xml
        name = "grass", -- From Grass
        noise_texture = "ground_noise_hoodedfoliage",
        runsound = "dontstarve/movement/walk_grass",
        walksound = "dontstarve/movement/walk_grass",
        snowsound = "dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR,
        cannotbedug = true
    }, {
        -- minimap_tile_def 5
        name = "map_edge",
        noise_texture = "mini_grass_noise",
    }, {
        -- turf_def 6
        name = "hoodedmoss",
        anim = "hoodedmoss",
        bank_build = "hfturf"
    })

AddTile("HOODEDFOREST_FOLIAGE_DARK", -- tile_name 1
    "LAND",                          -- tile_range 2
    {
        -- tile_data 3
        ground_name = "hoodedfoliage",
    }, {
        -- ground_tile_def 4 -- Looking for the atlas here, which is hoodedmoss.xml
        name = "forest", -- From Forest
        noise_texture = "ground_noise_hoodedfoliage",
        runsound = "dontstarve/movement/walk_grass",
        walksound = "dontstarve/movement/walk_grass",
        snowsound = "dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "map_edge",
        noise_texture = "mini_forest_noise",
    }, {
        -- turf_def 6
        name = "hoodedmoss",
        anim = "hoodedmoss",
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

AddTile("UM_FLOODWATER_GROTTO",
    "LAND",
    {
        ground_name = "um_floodwater",
    }, {
        name = "um_floodwater",
        noise_texture = "Ground_noise_moon_fungus_flooded",
        runsound = "dontstarve/movement/run_marsh",
        walksound = "dontstarve/movement/walk_marsh",
        snowsound = "dontstarve/movement/run_marsh",
        mudsound = "dontstarve/movement/run_marsh",
        colors = GROUND_OCEAN_COLOR,
        cannotbedug = true
    }, {
        name = "map_edge",
        noise_texture = "Ground_noise_moon_fungus_flooded_mini"
    }, {
        name = "ancienthoodedturf",
        anim = "ancienthoodedturf",
        bank_build = "hfturf"
    })

AddTile("UM_FLOODWATER_BROILING",
    "LAND",
    {
        ground_name = "um_floodwater",
    }, {
        name = "um_floodwater",
        noise_texture = "Ground_noise_broiling_flooded",
        runsound = "dontstarve/movement/run_marsh",
        walksound = "dontstarve/movement/walk_marsh",
        snowsound = "dontstarve/movement/run_marsh",
        mudsound = "dontstarve/movement/run_marsh",
        colors = GROUND_OCEAN_COLOR,
        cannotbedug = true
    }, {
        name = "map_edge",
        noise_texture = "Ground_noise_moon_fungus_flooded_mini"
    }, {
        name = "ancienthoodedturf",
        anim = "ancienthoodedturf",
        bank_build = "hfturf"
    })




-- Boiling Fields tiles
AddTile("UM_HOTSPRING_GRASS", -- tile_name 1
    "LAND",                   -- tile_range 2
    {
        -- tile_data 3
        ground_name = "UM_HOTSPRING_GRASS", -- <-- xenomeadow
    }, {
        -- ground_tile_def 4
        name = "yellowgrass", -- <-- xenomeadow
        noise_texture = "um_hotspring_grass.tex",
        runsound = "dontstarve/movement/run_mud",
        walksound = "dontstarve/movement/run_mud",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "yellowgrass",
        noise_texture = "mini_um_hotspring_grass.tex"
    }, {
        -- turf_def 6
        name = "um_hotspring_grass",
        anim = "um_hotspring_grass",
        bank_build = "hfturf"
    })

AddTile("UM_HOTSPRING_WHITEROCK", -- tile_name 1
    "LAND",                       -- tile_range 2
    {
        -- tile_data 3
        ground_name = "UM_HOTSPRING_WHITEROCK",
    }, {
        -- ground_tile_def 4
        name = "rocky_yellow",
        noise_texture = "um_hotspring_whiterock.tex",
        runsound = "dontstarve/movement/run_dirt",
        walksound = "dontstarve/movement/walk_dirt",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "rocky_yellow",
        noise_texture = "mini_um_hotspring_whiterock.tex"
    }, {
        -- turf_def 6
        name = "um_hotspring_whiterock",
        anim = "um_hotspring_whiterock",
        bank_build = "hfturf"
    })

AddTile("UM_HOTSPRING_YELLOWROCK", -- tile_name 1
    "LAND",                        -- tile_range 2
    {
        -- tile_data 3
        ground_name = "UM_HOTSPRING_YELLOWROCK",
    }, {
        -- ground_tile_def 4
        name = "rocky_yellow",
        noise_texture = "um_hotspring_yellowrock.tex",
        runsound = "dontstarve/movement/run_dirt",
        walksound = "dontstarve/movement/walk_dirt",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        colors = GROUND_OCEAN_COLOR
    }, {
        -- minimap_tile_def 5
        name = "rocky_yellow",
        noise_texture = "mini_um_hotspring_yellowrock.tex"
    }, {
        -- turf_def 6
        name = "um_hotspring_yellowrock",
        anim = "um_hotspring_yellowrock",
        bank_build = "hfturf"
    })

-- Lava Caves Turf
AddTile(
    "UM_GRASSMAGMA", --tile_name 1
    "LAND",          --tile_range 2
    {                --tile_data 3
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
    "LAND",     --tile_range 2
    {           --tile_data 3
        ground_name = "magma_rock",
    },
    {
        name = "rocky_clear",
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
        name = "um_magma",
        anim = "um_magma",
        bank_build = "hfturf"
    }
)


AddTile(
    "UM_MAGMA_LAVAMOLTEN", --tile_name 1
    "IMPASSABLE",          --tile_range 2 --can't be immpassible so we can do actions on it.
    {                      --tile_data 3
        ground_name = "floortox",
    },
    {
        name = "rocky",
        noise_texture = "ground_floortox.tex",
        runsound = "dontstarve/movement/run_marsh",
        walksound = "dontstarve/movement/walk_marsh",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
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

AddTile(
    "UM_MAGMA_LAVATEMP", --tile_name 1
    "LAND",              --tile_range 2
    {                    --tile_data 3
        ground_name = "magma_rock",
    },
    {
        name = "rocky_clear",
        noise_texture = "ground_magma_rock_lavaborder.tex", --Gearless's art
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
    "UM_MAGMA_LAVABORDER", --tile_name 1
    "LAND",                --tile_range 2
    {                      --tile_data 3
        ground_name = "magma_rock",
    },
    {
        name = "rocky_clear",
        noise_texture = "ground_magma_rock_lavaborder.tex", --Gearless's art
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
    "IMPASSABLE",  --tile_range 2
    {              --tile_data 3
        ground_name = "floortox",
    },
    {
        name = "rocky",
        noise_texture = "ground_floortox.tex",
        runsound = "dontstarve/movement/run_marsh",
        walksound = "dontstarve/movement/walk_marsh",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
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
ChangeTileRenderOrder(WORLD_TILES.UM_HOTSPRING_YELLOWROCK, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.UM_HOTSPRING_GRASS, WORLD_TILES.DIRT)
ChangeTileRenderOrder(WORLD_TILES.UM_FLOORTOX, WORLD_TILES.DIRT)


ChangeMiniMapTileRenderOrder(WORLD_TILES.HOODEDFOREST, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.ANCIENTHOODEDFOREST, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.UM_HOTSPRING_YELLOWROCK, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.DIRT)
ChangeMiniMapTileRenderOrder(WORLD_TILES.UM_HOTSPRING_GRASS, WORLD_TILES.DIRT)

local function GetTileForHotspringFlooded(noise) -- Keep flooded hotspring area in the files for future replacement
    if noise < 0.2 then
        return WORLD_TILES.UM_HOTSPRING_GRASS
    elseif noise < 0.4 then
        return WORLD_TILES.UM_HOTSPRING_WHITEROCK
    elseif noise < 0.6 then
        return WORLD_TILES.UM_HOTSPRING_YELLOWROCK
    else
        return WORLD_TILES.UM_FLOODWATER_BROILING
    end
end

local function GetTileForHotspring(noise)
    if noise < 0.3 then
        return WORLD_TILES.UM_HOTSPRING_GRASS
    elseif noise < 0.5 then
        return WORLD_TILES.UM_HOTSPRING_WHITEROCK
    else
        return WORLD_TILES.UM_HOTSPRING_YELLOWROCK
    end
end

local function GetTileForHoodedForest(noise)
    if noise < 0.4 then
        return WORLD_TILES.HOODEDFOREST_FOLIAGE
    end
    return WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK
end

local function GetTileForHoodedForestSparse(noise)
    if noise < 0.6 then
        return WORLD_TILES.HOODEDFOREST_FOLIAGE
    end
    return WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK
end

local function GetTileForRockyHoodedForest(noise)
    if noise < 0.4 then
        return WORLD_TILES.ROCKY
    end
    if noise < 0.5 then
        return WORLD_TILES.HOODEDFOREST_FOLIAGE
    end
    return WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK
end

local function GetTileForHotspringIA(noise)
    if noise < 0.3 then
        return WORLD_TILES.MAGMAFIELD
    elseif noise < 0.5 then
        return WORLD_TILES.UM_HOTSPRING_WHITEROCK
    end
    return WORLD_TILES.UM_HOTSPRING_YELLOWROCK
end

local function GetTileForHotspring_Foresty(noise)
    if noise < 0.3 then
        return WORLD_TILES.UM_HOTSPRING_WHITEROCK
    elseif noise < 0.5 then
        return WORLD_TILES.UM_HOTSPRING_GRASS
    end
    return WORLD_TILES.UM_HOTSPRING_YELLOWROCK
end

local function GetTileForLushMagma(noise)
    if noise < 0.5 then
        return WORLD_TILES.UM_GRASSMAGMA
    end

    return WORLD_TILES.UM_MAGMA
end

local function GetTileForMagmaRole(noise)
    if noise < 0.5 then
        return WORLD_TILES.VENT
    end

    return WORLD_TILES.UM_MAGMA
end

local function GetTileForGrottoFloodLight(noise)
    if noise < 0.4 then
        return WORLD_TILES.UM_FLOODWATER_GROTTO
    elseif noise < 0.5 then
        return WORLD_TILES.PEBBLEBEACH
    end

    return WORLD_TILES.FUNGUSMOON
end

local function GetTileForGrottoFloodHeavy(noise)
    if noise < 0.65 then
        return WORLD_TILES.UM_FLOODWATER_GROTTO
    end

    return WORLD_TILES.FUNGUSMOON
end

local function GetTileForMoltenMagma(noise)
    if noise > 0.1 and noise < 0.6 then
        return WORLD_TILES.UM_MAGMA_LAVATEMP
    end
    return WORLD_TILES.UM_MAGMA_LAVABORDER
end

AddTile("UM_HOTSPRING", "NOISE")
AddTile("UM_HOTSPRING_IA", "NOISE")
AddTile("UM_HOTSPRING_FORESTY", "NOISE")
AddTile("UM_HOODED_FOREST", "NOISE")
AddTile("UM_HOODED_FOREST_SPARSE", "NOISE")
AddTile("UM_HOODED_ROCKY", "NOISE")
AddTile("UM_MAGMA_JUNGLY", "NOISE")
AddTile("UM_MAGMA_FUMAROLE", "NOISE")

AddTile("UM_GROTTO_LIGHTFLOODED", "NOISE")
AddTile("UM_GROTTO_HEAVYFLOODED", "NOISE")
AddTile("UM_MAGMA_LAVAMOLTEN_NOISE", "NOISE")

local NoiseTileFunctions = require("noisetilefunctions")

NoiseTileFunctions[WORLD_TILES.UM_HOTSPRING] = GetTileForHotspring
NoiseTileFunctions[WORLD_TILES.UM_HOTSPRING_IA] = GetTileForHotspringIA
NoiseTileFunctions[WORLD_TILES.UM_HOTSPRING_FORESTY] = GetTileForHotspring_Foresty

NoiseTileFunctions[WORLD_TILES.UM_HOODED_FOREST] = GetTileForHoodedForest

NoiseTileFunctions[WORLD_TILES.UM_HOODED_FOREST_SPARSE] = GetTileForHoodedForestSparse

NoiseTileFunctions[WORLD_TILES.UM_HOODED_ROCKY] = GetTileForRockyHoodedForest

NoiseTileFunctions[WORLD_TILES.UM_MAGMA_JUNGLY] = GetTileForLushMagma
NoiseTileFunctions[WORLD_TILES.UM_MAGMA_FUMAROLE] = GetTileForMagmaRole

--NoiseTileFunctions[WORLD_TILES.UM_MAGMA_LAVAMOLTEN] = GetTileForMoltenMagma
NoiseTileFunctions[WORLD_TILES.UM_MAGMA_LAVAMOLTEN_NOISE] = GetTileForMoltenMagma

NoiseTileFunctions[WORLD_TILES.UM_GROTTO_LIGHTFLOODED] = GetTileForGrottoFloodLight
NoiseTileFunctions[WORLD_TILES.UM_GROTTO_HEAVYFLOODED] = GetTileForGrottoFloodHeavy

require("map/terrain")
--require("map/torreniv_terrain")

local filters = {

    ["evergreen_sparse"] = { WORLD_TILES.ROAD, WORLD_TILES.WOODFLOOR, WORLD_TILES.SCALE, WORLD_TILES.CARPET, WORLD_TILES.CHECKER, WORLD_TILES.ROCKY, WORLD_TILES.DIRT, WORLD_TILES.DESERT_DIRT, WORLD_TILES.MONKEY_DOCK, WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_YELLOWROCK, WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK },
    ["evergreen_sparse_normal"] = { WORLD_TILES.ROAD, WORLD_TILES.WOODFLOOR, WORLD_TILES.SCALE, WORLD_TILES.CARPET, WORLD_TILES.CHECKER, WORLD_TILES.ROCKY, WORLD_TILES.DIRT, WORLD_TILES.DESERT_DIRT, WORLD_TILES.MONKEY_DOCK, WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_YELLOWROCK, WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK },
    ["evergreen_sparse_short"] = { WORLD_TILES.ROAD, WORLD_TILES.WOODFLOOR, WORLD_TILES.SCALE, WORLD_TILES.CARPET, WORLD_TILES.CHECKER, WORLD_TILES.ROCKY, WORLD_TILES.DIRT, WORLD_TILES.DESERT_DIRT, WORLD_TILES.MONKEY_DOCK, WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_YELLOWROCK, WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK },
    ["evergreen_sparse_tall"] = { WORLD_TILES.ROAD, WORLD_TILES.WOODFLOOR, WORLD_TILES.SCALE, WORLD_TILES.CARPET, WORLD_TILES.CHECKER, WORLD_TILES.ROCKY, WORLD_TILES.DIRT, WORLD_TILES.DESERT_DIRT, WORLD_TILES.MONKEY_DOCK, WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_YELLOWROCK, WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK },

    ["thicket_builder"] = { WORLD_TILES.HOODEDFOREST_FOLIAGE },
    ["hoodedtrapdoor"] = { WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK },

    ["um_hotspring"] = { WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_GRASS },
    ["magmarock"] = { WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_GRASS, WORLD_TILES.UM_HOTSPRING_YELLOWROCK },
    ["magmarock1"] = { WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_GRASS, WORLD_TILES.UM_HOTSPRING_YELLOWROCK },
    ["um_magmarock1"] = { WORLD_TILES.UM_GRASSMAGMA },

    ["magmarock_gold"] = { WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_GRASS, WORLD_TILES.UM_HOTSPRING_YELLOWROCK },
    ["jungletree_burnt"] = { WORLD_TILES.UM_HOTSPRING_WHITEROCK, WORLD_TILES.UM_HOTSPRING_GRASS, WORLD_TILES.UM_HOTSPRING_YELLOWROCK },

    ["lava_pond_cave"] = { WORLD_TILES.UM_GRASSMAGMA },
    ["fyriterock"] = { WORLD_TILES.UM_GRASSMAGMA },
    ["um_pepperdragon_nest"] = { WORLD_TILES.UM_MAGMA },


    -- Moon Grotto Stuff
    ["molebat"] = { WORLD_TILES.FUNGUSMOON, WORLD_TILES.UM_FLOODWATER_GROTTO },
    ["molebathill"] = { WORLD_TILES.FUNGUSMOON, WORLD_TILES.UM_FLOODWATER_GROTTO },
    ["mushtree_moon"] = { WORLD_TILES.PEBBLEBEACH, WORLD_TILES.UM_FLOODWATER_GROTTO },
    ["lightflier_flower"] = { WORLD_TILES.UM_FLOODWATER_GROTTO },

    ["shockworm"] = { WORLD_TILES.PEBBLEBEACH, WORLD_TILES.FUNGUSMOON },
    ["zaspberry_plant"] = { WORLD_TILES.PEBBLEBEACH, WORLD_TILES.FUNGUSMOON },
}

for k, v in pairs(filters) do
    GLOBAL.terrain.filter[k] = v
end

table.insert(GLOBAL.terrain.filter["rock1"], WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK)
table.insert(GLOBAL.terrain.filter["rock1"], WORLD_TILES.HOODEDFOREST_FOLIAGE)
table.insert(GLOBAL.terrain.filter["rock2"], WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK)
table.insert(GLOBAL.terrain.filter["rock2"], WORLD_TILES.HOODEDFOREST_FOLIAGE)

GLOBAL.HOODED_GROUND_TYPES = {
    WORLD_TILES.HOODEDFOREST, WORLD_TILES.ANCIENTHOODEDFOREST, WORLD_TILES.HOODEDFOREST_FOLIAGE, -- 1,2,3
}
GLOBAL.PYRE_THICKET_GROUND_TYPES = {
    WORLD_TILES.UM_GRASSMAGMA, -- 1,2
}
GLOBAL.HOODED_ARENA_GROUND_TYPES = {
    WORLD_TILES.HOODEDFOREST, WORLD_TILES.ROCKY, -- 1,2
}
