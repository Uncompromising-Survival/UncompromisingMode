require "map/room_functions"

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

Layouts["cave_entrance_lush"] = StaticLayout.Get("map/static_layouts/cave_entrance_lush")

Layouts["widow_arena"] = StaticLayout.Get("map/static_layouts/widow_arena")
Layouts["widow_arena"].ground_types = HOODED_ARENA_GROUND_TYPES

Layouts["giant_tree_generic"] = StaticLayout.Get("map/static_layouts/giant_tree_generic")
Layouts["giant_tree_generic"].ground_types = HOODED_GROUND_TYPES

Layouts["giant_tree_pond"] = StaticLayout.Get("map/static_layouts/giant_tree_pond")
Layouts["giant_tree_pond"].ground_types = HOODED_GROUND_TYPES

Layouts["hf_holidays"] = StaticLayout.Get("map/static_layouts/hf_holidays")
Layouts["hf_holidays"].ground_types = HOODED_GROUND_TYPES

AddRoom("GiantTrees",
	{
		colour = { r = .6, g = .2, b = .8, a = .50 },
		value = WORLD_TILES.UM_HOODED_FOREST,
		tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
		contents =
		{
			distributepercent = 0.6,
			distributeprefabs = {
				evergreen_sparse = 0.5,
				thicket_builder = 1,
				ghost_walrus = 0.005,
				blueberryplantbuncher = 0.1,
				red_mushroom = 0.05,
				hoodedtrapdoor = 0.05,
				lightrays_canopy = 0.05,
				um_bear_trap_old = 0.1,
				um_fern_fox_den = 0.015,
			},
            countprefabs =
            {
                extracanopyspawner = 4,
                pitcherplant = function() return math.random(1, 2) end,
            },
			countstaticlayouts = {
				["giant_tree_generic"] = function() return math.random(1,3) end,
				["giant_tree_pond"] = function() return math.random(0,2) end,
			}
        }
    })
local PrefabSwaps = require("prefabswaps")	
PrefabSwaps.AddPrefabProxy("perma_berrybush_juicy", "berrybush_juicy") -- To spawn juicy berries all the time here, need to add this proxy.

AddRoom("RockyGiantTrees",
{
	colour = { r = .6, g = .2, b = .8, a = .50 },
	value = WORLD_TILES.UM_HOODED_ROCKY,
	tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
	contents =
	{
		distributepercent = 0.4,
		distributeprefabs = {
			perma_grass = 0.2,
			perma_berrybush_juicy = 0.1,
			thicket_builder = 1,
			ghost_walrus = 0.005,
			--blueberryplantbuncher = 0.1,
			lightrays_canopy = 0.05,
			um_bear_trap_old = 0.1,
			rock1 = 0.25,
			rock2 = 0.2,
			red_mushrom = 0.03,
			green_mushroom = 0.03,
			blue_mushroom = 0.03,
		},
		countprefabs =
		{
			extracanopyspawner = 4,
			tallbirdnest = function() return math.random(0,1) end,
		},
		countstaticlayouts = {
			["giant_tree_generic"] = function() return math.random(1,3) end,
		}
	}
})

AddRoom("RockyWalrusGiantTrees",
	{
		colour = { r = .6, g = .2, b = .8, a = .50 },
		value = WORLD_TILES.UM_HOODED_ROCKY,
		tags = {"hoodedcanopy" },
		contents =
		{
			distributepercent = 0.6,
			distributeprefabs = {
				um_bear_trap_old = 0.1,
				perma_grass = 0.2,
				perma_berrybush_juicy = 0.1,
				thicket_builder = 1,
				ghost_walrus = 0.5,
				--blueberryplantbuncher = 0.1,
				red_mushrom = 0.07,
				green_mushroom = 0.07,
				blue_mushroom = 0.07,
				lightrays_canopy = 0.25,
				rock1 = 0.25,
				rock2 = 0.2,
			},
            countprefabs =
            {
                extracanopyspawner = 4,
                walrus_camp = 1,
				tallbirdnest = function() return math.random(0,2) end,

            },
			countstaticlayouts = {
				["giant_tree_generic"] = function() return math.random(3,5) end,
			}
        }
    })
	
AddRoom("HoodedEntrance",
	{
		colour = { r = .6, g = .2, b = .8, a = .50 },
		value = WORLD_TILES.UM_HOODED_FOREST,
		tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
		contents =
		{
			distributepercent = 0.5,
			distributeprefabs = {
				thicket_builder = 1,
				ghost_walrus = 0.005,
				blueberryplantbuncher = 0.1,
				red_mushroom = 0.05,
				hoodedtrapdoor = 0.05,
				lightrays_canopy = 0.01,
				um_bear_trap_old = 0.1,
				hoodedtrapdoor = 0.05,
				um_fern_fox_den = 0.015,
			},
            countprefabs =
            {
				pitcherplant = 1,
            },
			countstaticlayouts = {
				["giant_tree_generic"] = function() return math.random(3,4) end,
			}
        }
    })
AddRoom("SpideryGiantTrees",
    {
        colour = { r = 1, g = 1, b = 1, a = .50 },
        value = WORLD_TILES.UM_HOODED_FOREST,
        tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
        contents =
        {
            countstaticlayouts = {
                ["widow_arena"] = 1,
            },
            distributepercent = 0.4,
            distributeprefabs =
            {
                um_bear_trap_old = 0.1,
                thicket_builder = 1,
                lightrays_canopy = 0.1,
				ghost_walrus = 0.005,
				hoodedtrapdoor = 0.05,
            },
            countprefabs =
            {
                extracanopyspawner = 4,
            },
        }
    })
AddRoom("WalrusGiantTrees",
	{
		colour = { r = .6, g = .2, b = .8, a = .50 },
		value = WORLD_TILES.UM_HOODED_FOREST,
		tags = { "hoodedcanopy" }, --"ForceDisconnected"
		contents =
		{
			distributepercent = 0.6,
			distributeprefabs = {
				um_bear_trap_old = 0.1,
				evergreen_sparse = 0.5,
				thicket_builder = 1,
				ghost_walrus = 0.5,
				blueberryplantbuncher = 0.1,
				green_mushroom = 0.05,
				hoodedtrapdoor = 0.2,
				lightrays_canopy = 0.25,
				um_fern_fox_den = 0.015,
			},
            countprefabs =
            {
                extracanopyspawner = 4,
                pitcherplant = 1,
                walrus_camp = 1,

            },
			countstaticlayouts = {
				["giant_tree_generic"] = function() return math.random(7,10) end,
				["giant_tree_pond"] = function() return math.random(0,2) end,
			}
        }
    })

AddRoom("BGGiantTrees",
	{
		colour = { r = 1, g = 1, b = 1, a = .50 },
		value = WORLD_TILES.UM_HOODED_FOREST,
		tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
		contents =
		{
			distributepercent = 0.6,
			distributeprefabs = {
				evergreen_sparse = 0.5,
				thicket_builder = 1,
				ghost_walrus = 0.03,
				blueberryplantbuncher = 0.1,
				blue_mushroom = 0.05,
				lightrays_canopy = 0.25,
				um_bear_trap_old = 0.1,
				hoodedtrapdoor = 0.05,
				um_fern_fox_den = 0.015,
			},
			countprefabs =
			{
                extracanopyspawner = function() return 10 + math.random(0, 1) end,
                --pitcherplant = function() return math.random(0, 1) end,

            },
			countstaticlayouts = {
				["giant_tree_generic"] = function() return math.random(7,10) end,
			}
        }

    })
AddRoom("FoxGathering",
    {
        colour = { r = 1, g = 1, b = 1, a = .50 },
        value = WORLD_TILES.UM_HOODED_FOREST,
        tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
        contents =
        {
		
            countprefabs =
            {
				thicket_builder = function() return math.random(2,3) end,
                um_fern_fox_den = function() return 1 + math.random(2, 3) end,
                extracanopyspawner = 4,
				hoodedtrapdoor = function() return math.random (3,4) end,
            },
			countstaticlayouts = {
				["giant_tree_generic"] = function() return math.random(7,10) end,
			}
        }

    })
AddRoom("MoonBaseGiantTrees", {
    colour = { r = .8, g = 0.5, b = .6, a = .50 },
    value = WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK,
    tags = { "RoadPoison", "hoodedcanopy" },
    contents = {
		countstaticlayouts = {
			["MoonbaseOne"] = 1
		},
        distributepercent = 0.3,
        distributeprefabs =
        {
            evergreen_sparse = 0.5,
            thicket_builder = 1,
            blueberryplantbuncher = 0.1,
            pitcherplant = 0.001,
			um_bear_trap_old = 0.05,
			hoodedtrapdoor = 0.05,
			
        },
		countprefabs =
		{
			extracanopyspawner = 4,
		},
    }

})
AddRoom("QuestionableDecisions",
    {
        colour = { r = 1, g = 1, b = 1, a = .50 },
        value = WORLD_TILES.UM_HOODED_FOREST,
        tags = { "RoadPoison", "hoodedcanopy" }, --"ForceDisconnected"
        contents =
        {
            distributepercent = 0.3,
            distributeprefabs =
            {
                thicket_builder = 1,
                lightrays_canopy = 0.25,
            },
            countstaticlayouts = { ["cave_entrance_lush"] = 1 },
        }
    })
AddRoom("HoodedTown", {
    colour = { r = .8, g = 0.5, b = .6, a = .50 },
    value = WORLD_TILES.UM_HOODED_FOREST,
    tags = { "RoadPoison", "hoodedcanopy" },
    contents = {
        countprefabs = {
            extracanopyspawner = function() return 10 + math.random(0, 1) end,
			
        },

        distributepercent = 0.3,
        distributeprefabs =
        {
            evergreen_sparse = 0.4,
            thicket_builder = 1,
            ghost_walrus = 0.02,
            blueberryplantbuncher = 0.1,
            pitcherplant = 0.001,
            lightrays_canopy = 0.25,
			um_bear_trap_old = 0.1,
			hoodedtrapdoor = 0.05,
        },
		countstaticlayouts = {
			["giant_tree_generic"] = function() return math.random(1,2) end,
		}
    }
})
AddRoom("RoseGarden", {
    colour = { r = .8, g = 0.5, b = .6, a = .50 },
    value = WORLD_TILES.UM_HOODED_FOREST,
    tags = { "RoadPoison", "hoodedcanopy" },
    contents = {
        countprefabs = {
            extracanopyspawner = function() return 10 + math.random(0, 1) end,
        },

        distributepercent = 0.3,
        distributeprefabs =
        {
            evergreen_sparse = 0.4,
            thicket_builder = 1,
            ghost_walrus = 0.005,
            blueberryplantbuncher = 0.01,
            lightrays_canopy = 0.25,
			um_bear_trap_old = 0.1,
			hoodedtrapdoor = 0.05,
        },
		countstaticlayouts = {
			["hf_holidays"] = 1,
			["giant_tree_generic"] = function() return math.random(1,2) end,
		},
    }
})
AddRoom("HFHolidays", {
    colour = { r = .8, g = 0.5, b = .6, a = .50 },
    value = WORLD_TILES.UM_HOODED_FOREST,
    tags = { "RoadPoison", "hoodedcanopy" },
    contents = {
        countprefabs = {
            extracanopyspawner = function() return 10 + math.random(0, 1) end,
        },

        distributepercent = 0.6,
        distributeprefabs =
        {
            um_bear_trap_old = 0.1,
            ghost_walrus = 0.01,
            evergreen_sparse = 0.4,
            thicket_builder = 1,
            blueberryplantbuncher = 0.01,
            lightrays_canopy = 0.25,
			um_bear_trap_old = 0.1,
			hoodedtrapdoor = 0.05,
        },
    }
})
