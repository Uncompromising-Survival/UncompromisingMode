require "map/room_functions"

local Layouts = require ("map/layouts").Layouts
local StaticLayout = require ("map/static_layout")

---------------------------------------------
-- Lunar Grotto
---------------------------------------------

AddRoom("WormyMoonMushForest", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.FUNGUSMOON,
    tags = {},
    random_node_entrance_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolSmall"] = 2,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.2,
        distributeprefabs =
        {
            mushtree_moon = 0.025,
			
			zaspberry_plant = 0.025,
			shockworm = 0.01,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})

Layouts["cave_exit_moon"] = StaticLayout.Get("map/static_layouts/cave_exit_moon")
AddRoom("GrottoStairs",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.PEBBLEBEACH,
	contents = {
		countstaticlayouts = {
			["cave_exit_moon"] = 1,
		},
		countprefabs =
		{

			cavelight = 3,
		},
		distributepercent = 0.18,
		distributeprefabs =
		{
			grass = 0.2,
			lunar_island_rocks = 0.5,
			flint = 0.5,
			lunar_island_rock1 = 0.5,
			reeds = 0.75,
			twigs = 0.25,
			sapling_moon = 0.4,
			lightflier_flower = 0.2,
			driftwood_tall = 0.1,
			driftwood_small2 = 0.2,
			driftwood_small2 = 0.2,
		},
	},
})

AddRoom("GrottoGrass",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.PEBBLEBEACH,
	contents = {
		countprefabs =
		{
			cavelight = 3,
			moonspiderden = math.random(3,4),
		},
		distributepercent = 0.18,
		distributeprefabs =
		{
			lightflier_flower = 0.1,
			lunar_island_rocks = 0.5,
			flint = 0.5,
			lunar_island_rock1 = 0.5,
			reeds = 0.25,
			grass = 0.75,
			twigs = 0.25,
			sapling_moon = 0.4,
			driftwood_tall = 0.1,
			driftwood_small2 = 0.2,
			driftwood_small2 = 0.2,
		},
	},
})

AddRoom("GrottoGrassNoise",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.PEBBLEBEACH,
	type = NODE_TYPE.Room,
	--random_node_entrance_weight = 0,
	random_node_exit_weight = 0,
	contents = {
		countprefabs =
		{
			cavelight = 3,
		},
		distributepercent = 0.18,
		distributeprefabs =
		{

			lunar_island_rocks = 0.5,
			flint = 0.5,
			lunar_island_rock1 = 0.5,
			reeds = 0.25,
			grass = 0.75,
			twigs = 0.25,
			sapling_moon = 0.4,
		},
	},
})

AddRoom("BGGrottoReeds",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.PEBBLEBEACH,
	contents = {
		countprefabs =
		{
			cavelight = 4,
		},
		distributepercent = 0.18,
		distributeprefabs =
		{
			lunar_island_rocks = 0.5,
			flint = 0.5,
			lunar_island_rock1 = 0.5,
			reeds = 0.75,
			grassgekko = 0.25,
			twigs = 0.25,
			sapling_moon = 0.4,
			driftwood_tall = 0.07,
			driftwood_small2 = 0.05,
			driftwood_small2 = 0.05,
			
		},
	},
})

AddRoom("GrottoLightFloodNoise", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_LIGHTFLOODED,
    tags = {},
	type = NODE_TYPE.Room,
	random_node_entrance_weight = 0,
	--random_node_exit_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolBig"] = 1,
            ["GrottoPoolSmall"] = 4,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
			cavelight = 4,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.075,

            lightflier_flower = 0.02,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,
			
            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
			reeds = 0.005,
			zaspberry_plant = 0.005,
			molebathill = 0.005,
			molebat = 0.01,
			--shockworm = 0.005,
        },
    }
})

AddRoom("GrottoLightFlood", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_LIGHTFLOODED,
    tags = {},
	random_node_entrance_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolBig"] = 1,
            ["GrottoPoolSmall"] = 4,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
			cavelight = 4,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.075,

            lightflier_flower = 0.02,
            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
			reeds = 0.005,
			zaspberry_plant = 0.005,
			molebathill = 0.005,
			molebat = 0.01,
			--shockworm = 0.005,
        },
    }
})

AddRoom("GrottoHeavyFloodNoise", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
    tags = {},
	type = NODE_TYPE.Room,
	random_node_entrance_weight = 0,
	--random_node_exit_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolBig"] = 2,
            ["GrottoPoolSmall"] = 2,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.02,

            lightflier_flower = 0.02,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.01,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.01,
			zaspberry_plant = 0.004,
			shockworm = 0.002,
			um_moonglass_ceiling = 0.001,
        },
    }
})

AddRoom("GrottoHeavyFlood", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
    tags = {},
	--random_node_entrance_weight = 0,
	random_node_exit_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolBig"] = 2,
            ["GrottoPoolSmall"] = 2,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.35,
        distributeprefabs =
        {
            mushtree_moon = 0.02,

            lightflier_flower = 0.02,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.01,
			zaspberry_plant = 0.004,
			shockworm = 0.002,
			um_moonglass_ceiling = 0.001,
        },
    }
})

AddRoom("ArchiveMazeEntrance_Flooded", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
    tags = {"MazeEntrance", "RoadPoison", "lunacyarea"},
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolSmall"] = 1,
			["GrottoPoolBig"] = 1,
        },
        distributepercent = 0.6,
        distributeprefabs =
        {
            mushtree_moon = 0.05,

            lightflier_flower = 0.005,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
			zaspberry_plant = 0.002,
			shockworm = 0.002,
        },
    }
})