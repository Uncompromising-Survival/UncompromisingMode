require "map/room_functions"

local Layouts = require ("map/layouts").Layouts
local StaticLayout = require ("map/static_layout")

---------------------------------------------
-- Lunar Grotto
---------------------------------------------

-- This room is Depricated, could include in non-flooded worlds.
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
            cavelight = 3,
        },
        distributepercent = 0.15,
        distributeprefabs =
        {
            mushtree_moon = 0.025,
			
			zaspberry_plant = 0.025,
			shockworm = 0.01,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})

Layouts["cave_exit_moon"] = StaticLayout.Get("map/static_layouts/cave_exit_moon")
AddRoom("GrottoStairs",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
    value = WORLD_TILES.PEBBLEBEACH,
	contents = {
		countstaticlayouts = {
			["cave_exit_moon"] = 1,
		},
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
			um_reeds_lunar = 1,
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
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
    value = WORLD_TILES.UM_GROTTO_PATCHY,
	contents = {
		countprefabs =
		{
			cavelight = 4,
			moonspiderden = math.random(3,4),
		},
		distributepercent = 0.18,
		distributeprefabs =
		{
			lightflier_flower = 0.1,
			lunar_island_rocks = 0.5,
			flint = 0.5,
			lunar_island_rock1 = 0.5,
			um_reeds_lunar = 1,
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
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
    value = WORLD_TILES.UM_GROTTO_PATCHY,
	--random_node_entrance_weight = 0,
	random_node_exit_weight = 0,
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
			um_reeds_lunar = 1,
			twigs = 0.25,
			sapling_moon = 0.4,
		},
	},
})

AddRoom("BGGrottoReeds",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_GROTTO_PATCHY,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
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
			um_reeds_lunar = 0.75,
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
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
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
        distributepercent = 0.25,
        distributeprefabs =
        {
            mushtree_moon = 0.075,

            lightflier_flower = 0.02,

			
            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
			um_reeds_lunar = 0.005,
			--zaspberry_plant = 0.0015,
			molebathill = 0.005,
			molebat = 0.01,
            um_tentacle_moon = 0.0025,
            twigs = 0.005,
            sapling_moon = 0.0025,
            flint = 0.0025,
            um_mushroom_moon = 0.02,
			--shockworm = 0.005,
        },
    }
})

AddRoom("GrottoLightFlood", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_LIGHTFLOODED,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
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
        distributepercent = 0.25,
        distributeprefabs =
        {
            mushtree_moon = 0.075,
            um_mushroom_moon = 0.02,
            lightflier_flower = 0.02,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
			um_reeds_lunar = 0.005,
			--zaspberry_plant = 0.002,
			molebathill = 0.005,
			molebat = 0.01,
            um_tentacle_moon = 0.0025,
            twigs = 0.005,
            sapling_moon = 0.0025,
            flint = 0.005,
			--shockworm = 0.005,
        },
    }
})

AddRoom("GrottoHeavyFloodWorms", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
	--random_node_entrance_weight = 0,
	--random_node_exit_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolBig"] = 2,
            ["GrottoPoolSmall"] = 2,
        },
        countprefabs =
        {
			um_moonglass_ceiling = function() return math.random(0,1) end,
            cavelight = 4,
        },
        distributepercent = 0.2,
        distributeprefabs =
        {
            mushtree_moon = 0.4,

            lightflier_flower = 0.02,


            moonglass_stalactite1 = 0.001,
            moonglass_stalactite2 = 0.0007,
            moonglass_stalactite3 = 0.001,
			zaspberry_plant = 0.001,
			shockworm = 0.0005,
        },
    }
})

-- AXE This room is special, it signals the direction of the grotto, but provides a challenge, progress through the darkness and make it to the archives!
AddRoom("GrottoDarknessWorms", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_FLOODWATER_GROTTO,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
	--random_node_entrance_weight = 0,
	random_node_exit_weight = 0,
    contents =  {
        countprefabs =
        {
			um_moonglass_ceiling = function() return math.random(2,3) end,
            zaspberry_plant = 1,
            shockworm = function() return math.random(0,2) end,
            skeleton = function() return math.random(0,1) end,
        },
    }
})

AddRoom("GrottoDarknessTentacles", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED_SANDY,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
	random_node_entrance_weight = 0,
	--random_node_exit_weight = 0,
    contents =  {
        countprefabs =
        {
			um_moonglass_ceiling = function() return math.random(2,3) end,
            twigs = function() return math.random(3,6) end,
            um_tentacle_moon = function() return math.random(0,2) end,
            skeleton = function() return math.random(0,1) end,
        },
    }
})

AddRoom("GrottoHeavyFloodTentacles", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED_SANDY,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
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
			um_moonglass_ceiling = 1,
            cavelight = 4,
        },
        distributepercent = 0.2,
        distributeprefabs =
        {
            lightflier_flower = 0.02,


            moonglass_stalactite1 = 0.001,
            moonglass_stalactite2 = 0.001,
            moonglass_stalactite3 = 0.001,
			um_reeds_lunar = 0.01,
			um_tentacle_moon = 0.003,
            twigs = 0.005,
            sapling_moon = 0.0025,
            flint = 0.0025,
        },
    }
})

AddRoom("GrottoHeavyFloodBoth", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
	tags = {"not_mainland"},
	SafeFromDisconnect = true,
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
			um_moonglass_ceiling = function() return math.random(1,2) end,
            cavelight = 4,
        },
        distributepercent = 0.15,
        distributeprefabs =
        {
            mushtree_moon = 0.1,

            lightflier_flower = 0.02,


            moonglass_stalactite1 = 0.0007,
            moonglass_stalactite2 = 0.0007,
            moonglass_stalactite3 = 0.001,
			shockworm = 0.001,
			um_tentacle_moon = 0.001,
        },
    }
})

AddRoom("ArchiveMazeEntrance_Flooded", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.UM_GROTTO_LIGHTFLOODED,
	tags = {"not_mainland","lunacyarea","RoadPoison","MazeEntrance","UMMazeEntranceGrotto"},
	SafeFromDisconnect = true,
    contents =  {
        countstaticlayouts =
        {
			["GrottoPoolBig"] = 5,
        },
        countprefabs =
        {
			um_tentacle_moon = 4,
            cavelight = 4,
        },
        distributepercent = 0.3,
        distributeprefabs =
        {
            mushtree_moon = 0.25,

            lightflier_flower = 0.2,


            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
			zaspberry_plant = 0.05,
			um_reeds_lunar = 0.3,
            twigs = 0.07,
            sapling_moon = 0.03,
            flint = 0.05,
        },
    }
})