local env = env
GLOBAL.setfenv(1, GLOBAL)

local TREE_ROCK_DATA = require("prefabs/tree_rock_data")
local WEIGHTED_VINE_LOOT = TREE_ROCK_DATA.WEIGHTED_VINE_LOOT
local ROOMS_TO_LOOT_KEY = TREE_ROCK_DATA.ROOMS_TO_LOOT_KEY
local VINE_LOOT_DATA = TREE_ROCK_DATA.VINE_LOOT_DATA
local TASKS_TO_LOOT_KEY = TREE_ROCK_DATA.TASKS_TO_LOOT_KEY


--TODO CONFIGS

local ROOMS = {
    --challengespawner
    veteranshrine = "ROCKY_AREA",
    nearveteranshrine = "ROCKY_AREA",
    veteranshrine_ia = "MAGMAROCK_AREA",
    nearveteranshrine_ia = "MAGMAROCK_AREA",

    --wixie
    wixie_puzzlearea_ia = "JUNGLE_AREA",
    wixie_puzzlearea = "DECIDUOUS_AREA",
}

local WEIGHTED_LOOT = {
    ["UM_HOODED_FOREST_AREA"] = {
        ["rocks"]          = 15,
        ["goldnugget"]     = 10,
        ["flint"]          = 10,
        ["nitre"]          = 10,
        ["moonrocknugget"] = 3,
        ["snappy_jaw"]     = 3,
    },
    ["UM_REDMUSH_AREA"] = {
        ["rocks"]                 = 10,
        ["flint"]                 = 5,
        ["um_gemology_geode_red"] = 2,
    },
    ["UM_GREENMUSH_AREA"] = {
        ["rocks"]                   = 10,
        ["flint"]                   = 5,
        ["um_gemology_geode_green"] = 2,
    },
    ["UM_BLUEMUSH_AREA"] = {
        ["rocks"]                  = 10,
        ["flint"]                  = 5,
        ["um_gemology_geode_blue"] = 2,
    },
    ["UM_FUNGALNOISE_AREA"] = {
        ["rocks"]                   = 10,
        ["flint"]                   = 5,
        ["um_gemology_geode_red"]   = 2 / 3,
        ["um_gemology_geode_green"] = 2 / 3,
        ["um_gemology_geode_blue"]  = 2 / 3,
    },

    ["UM_MAGMA_AREA"] = {
        ["rocks"]        = 15,
        ["flint"]        = 6,
        ["um_fyrite"]    = 2,
        ["redgem"]       = 0.25,
        ["bluegem"]      = 0.25,
        ["purplegem"]    = 0.1,
        ["yellowgem"]    = 0.02,
        ["orangegem"]    = 0.02,
        ["greengem"]     = 0.02,
        ["fossil_piece"] = 0.25,

        --["um_gemology_geode_magma"]  = 0.25,
    },

    ["BOILING_SPRINGS_AREA"] = {
        ["nitre"]     = 15,
        ["rocks"]     = 10,
        ["boneshard"] = 10,
        ["um_fyrite"] = 2,
    },

    ["MOON_GROTTO_AREA"] = {
        ["rocks"]                   = 5,
        ["flint"]                   = 5,
        ["moonglass"]               = 5,
        ["um_gemology_geode_glass"] = 2.5,
    },
    --[[["RUINS_ENTRANCE_AREA"] = {
        ["rocks"]               = 8,
        ["fossil_piece"]        = 0.15,
        ["poop"]                = 5,
        ["flint"]               = 3,
        ["silk"]                = 2,
        ["cutlichen"]           = 10,
        ["thulecite_pieces"]    = 5,
        ["redgem"]              = 0.2,
        ["bluegem"]             = 0.2,
        ["purplegem"]           = 0.1,
        ["yellowgem"]           = 0.02,
        ["orangegem"]           = 0.02,
        ["greengem"]            = 0.02,
        ["wormlight"]           = 0.5,
        ["um_gemology_geode_slime"] = 0.5,
    },]]
    ["ROCKYLAND_AREA"] = {
        ["rocks"]                     = 10,
        ["flint"]                     = 10,
        ["goldnugget"]                = 5,
        ["guano"]                     = 30,
        ["slurtle_shellpieces"]       = 5,
        ["um_gemology_geode_lobster"] = 2.5,

    },
    ["GUANO_AREA"] = {
        ["rocks"]                   = 10,
        ["flint"]                   = 10,
        ["goldnugget"]              = 5,
        ["guano"]                   = 75,
        ["um_gemology_geode_guano"] = 5,
    },

    ["RUINS_AREA"] = {
        ["rocks"]                   = 5,
        ["flint"]                   = 3,
        ["thulecite_pieces"]        = 10,
        ["redgem"]                  = 0.75,
        ["bluegem"]                 = 0.75,
        ["purplegem"]               = 0.5,
        ["yellowgem"]               = 0.2,
        ["orangegem"]               = 0.2,
        ["greengem"]                = 0.2,
        ["um_gemology_geode_ruins"] = 0.2,
        ["wormlight"]               = 0.5,
    },

    ["VENT_AREA"] = { --Aka the default, kinda
        ["rocks"]                  = 15,
        ["flint"]                  = 6,
        ["goldnugget"]             = 2,
        ["redgem"]                 = 0.25,
        ["bluegem"]                = 0.25,
        ["purplegem"]              = 0.1,
        ["yellowgem"]              = 0.02,
        ["orangegem"]              = 0.02,
        ["greengem"]               = 0.02,
        ["um_gemology_geode_vent"] = 0.02,
    },

    ["VENT_AREA_SHADOW_RIFT"] = {
        ["rocks"]                  = 10,
        ["flint"]                  = 10,
        ["goldnugget"]             = 40,
        --["dreadstone"]        = 5, --bruh really klei
        ["redgem"]                 = 10,
        ["bluegem"]                = 10,
        ["purplegem"]              = 8,
        ["yellowgem"]              = 7,
        ["orangegem"]              = 7,
        ["greengem"]               = 7,
        ["um_gemology_geode_vent"] = 7,
    },

    ["SINKHOLE_AREA"] = {
        ["rocks"]                  = 12,
        ["flint"]                  = 5,
        ["goldnugget"]             = 3,
        ["nitre"]                  = 5,
        ["guano"]                  = 5,
        ["lightbulb"]              = 5,
        ["um_gemology_geode_sink"] = 2,
    },
}


local LOOT_DATA = {
    ["um_gemology_geode_red"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_red" } },
    ["um_gemology_geode_green"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_green" } },
    ["um_gemology_geode_blue"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_blue" } },
    ["um_gemology_geode_glass"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_glass" } },
    --["um_gemology_geode_slime"] = {build = "um_tree_rock_swaps", symbols = {"swap_geode_slime"}},
    ["um_gemology_geode_lobster"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_lobster" } },
    ["um_gemology_geode_guano"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_guano" } },
    ["um_gemology_geode_ruins"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_ruins" } },
    ["um_gemology_geode_vent"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_vent" } },
    ["um_gemology_geode_sink"] = { build = "um_tree_rock_swaps", symbols = { "swap_geode_sink" } },
    ["snappy_jaw"] = { build = "um_tree_rock_swaps", symbols = { "swap_snappy_jaw" } },
    ["um_fyrite"] = { build = "um_tree_rock_swaps", symbols = { "swap_pyrite" } },
}

local TASKS = {
    --HF
    ["Forest hunters"]              = "UM_HOODED_FOREST_AREA",

    --Mushroom forests
    ["RedForest"]                   = "UM_REDMUSH_AREA",
    ["GreenForest"]                 = "UM_GREENMUSH_AREA",
    ["BlueForest"]                  = "UM_BLUEMUSH_AREA",
    ["FungalNoiseForest"]           = "UM_FUNGALNOISE_AREA",
    ["FungalNoiseMeadow"]           = "UM_FUNGALNOISE_AREA",
    ["FungalNoiseForest_Petrified"] = "UM_FUNGALNOISE_AREA",
    ["FungalNoiseMeadow_Petrified"] = "UM_FUNGALNOISE_AREA",

    --Magma caves
    ["MagmaCaves"]                  = "UM_MAGMA_AREA",
    ["MagmaCavesEntrance"]          = "UM_MAGMA_AREA",
    ["MagmaSacred"]                 = "UM_MAGMA_AREA",

    --grotto
    ["GrottoEntrance"]              = "MOON_GROTTO_AREA",
    ["PatchyFloodedGrotto"]         = "MOON_GROTTO_AREA",
    ["VeryFloodedGrotto"]           = "MOON_GROTTO_AREA",

    --boiling springs, technically.
    ["Badlands"]                    = "BOILING_SPRINGS_AREA",

    ["BrolingHills_IA"]             = "BOILING_SPRINGS_AREA",
    ["BrolingHills_IA_2"]           = "BOILING_SPRINGS_AREA",

    ["UMMakeABeehat"]               = "GRASS_AREA",
    ["GiantTrees_IA"]               = "UM_HOODED_FOREST_AREA",

    --[[
    ["SwampySinkhole"] = "UM_CAVE_SWAMP",
    ["CaveSwamp"] = "UM_CAVE_SWAMP",


    ]]
}

for k, v in pairs(ROOMS) do
    ROOMS_TO_LOOT_KEY[k] = v
end

for k, v in pairs(TASKS) do
    TASKS_TO_LOOT_KEY[k] = v
end

for k, v in pairs(WEIGHTED_LOOT) do
    WEIGHTED_VINE_LOOT[k] = v
end

for k, v in pairs(LOOT_DATA) do
    VINE_LOOT_DATA[k] = v
end
