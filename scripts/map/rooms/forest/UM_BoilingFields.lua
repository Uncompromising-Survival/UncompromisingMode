require "map/room_functions"

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")


Layouts["boilingfields_dragonfly_arena"] = StaticLayout.Get("map/static_layouts/boilingfields_dragonfly_arena")
Layouts["cave_entrance_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_entrance_magmabiome")

AddRoom("BoilingFields_BasaltHounds", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    tags = { "RoadPoison","Mist" },
    value = WORLD_TILES.UM_HOTSPRING_YELLOWROCK,
    contents = {
        distributepercent = 0.3,
        distributeprefabs =
        {
            --rock_ice = .1,
            marsh_tree = 1,
            houndbone = .5,
            houndmound = .15,
            marsh_bush = 0.1,
            springrock1 = 0.1,
            --basalt = 0.6,
            rock_lichen = 0.1,
            um_hotspring = 0.1,
        },
    }
})

AddRoom("BoilingFields_Rocky_IA", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    tags = { "RoadPoison", "Mist" },
    value = WORLD_TILES.UM_HOTSPRING_IA,
    contents = {
        distributepercent = 1,
        distributeprefabs =
        {
            springrock2 = 0.1, --These rocks place fun tiles below them
            springrock3 = 0.1, --These rocks place fun tiles below them
            rock_limpet = 0.05,
            um_hotspring = 0.05,
            nothing = 3,
            jungletree_burnt = 3,
            magmarock = 3,
        },
        countprefabs = {
            snaildrake_hole = function() return math.random(2, 3) end,
        }
    }
})

AddRoom("BoilingFields_Rocky", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    tags = {"RoadPoison","Mist"},
    value = WORLD_TILES.UM_HOTSPRING,
    contents =  {
        distributepercent = 1,
        distributeprefabs =
        {
            springrock2 = 0.1, --These rocks place fun tiles below them
            springrock3 = 0.1, --These rocks place fun tiles below them
            rock_lichen = 0.05,
            um_hotspring = 0.05,
            nothing = 3,
            evergreen_sparse = 10,
            rocks=.03,
            flint=.03,
        },
        countprefabs = {
            snaildrake_hole = function() return math.random(2, 3) end,
        }
    }
})
AddRoom("BoilingFields_Crabby", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    tags = {"RoadPoison","Mist"},
    value = WORLD_TILES.UM_HOTSPRING,
    contents =  {
        distributepercent = 1,
        distributeprefabs =
        {
            springrock3 = 0.1,
            springrock2 = 0.2,
            rock_lichen = 0.05,
            molehill = 0.02,
            um_hotspring = 0.05,
            nothing = 1.5,
            evergreen_sparse = 10,
            rocks=.03,
            flint=.03,
        },
        countprefabs = {
            boulder_crab = function() return math.random(4, 6) end,
        }
    }
})

AddRoom("BoilingFields_Crabby_IA", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    tags = { "RoadPoison", "Mist" },
    value = WORLD_TILES.UM_HOTSPRING_IA,
    contents = {
        distributepercent = 1,
        distributeprefabs =
        {
            springrock3 = 0.1,
            springrock2 = 0.2,
            rock_limpet = 0.05,
            --molehill = 0.02,
            um_hotspring = 0.05,
            nothing = 1.5,
            jungletree_burnt = 3,
            magmarock = 3,
        },
        countprefabs = {
            boulder_crab = function() return math.random(4, 6) end,
        }
    }
})


AddRoom("BoilingFields_Hotsprings", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    tags = {"RoadPoison","Mist"},
    value = WORLD_TILES.UM_HOTSPRING,
    contents =  {
        distributepercent = 1,
        distributeprefabs =
        {
            springrock1 = 0.08, --These rocks place fun tiles below them
            springrock2 = 0.04,
            boulder_crab = .01,
            rock_lichen = 0.025,
            um_hotspring = 0.09,
            rabbithole = 0.01,
            molehill = 0.02,
            nothing = 3,
            evergreen_sparse = 10,
            grass = .01,
        },
    }
})

AddRoom("BoilingFields_Hotsprings_IA", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    tags = { "RoadPoison", "Mist" },
    value = WORLD_TILES.UM_HOTSPRING_IA,
    contents = {
        distributepercent = 1,
        distributeprefabs =
        {
            springrock1 = 0.08, --These rocks place fun tiles below them
            springrock2 = 0.04,
            boulder_crab = .01,
            rock_limpet = 0.025,
            um_hotspring = 0.09,
            crabhole = 0.01,
            --molehill = 0.02,
            nothing = 3,
            jungletree_burnt = 0.1,
            magmarock = 1,
        },
    }
})


AddRoom("BoilingFields_DragonflyArena", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    tags = { "RoadPoison" },
    value = WORLD_TILES.UM_HOTSPRING_YELLOWROCK,
    contents = {
        countstaticlayouts = { ["boilingfields_dragonfly_arena"] = 1 }, -- using a static layout because this can force it to be in the center of the room
        distributepercent = 0.2,
        distributeprefabs =
        {
            marsh_bush = 0.25,
            marsh_tree = 0.75,
            houndbone = .3,
        },
    }
})

AddRoom("BoilingFields_Sinkhole", {
    colour = { r = 0, g = .9, b = 0, a = .50 },
    value = WORLD_TILES.UM_HOTSPRING,
    tags = { "RoadPoison","Mist" },
    contents = {
        countstaticlayouts = {
            ["cave_entrance_magmabiome"] = 1,
        },
        distributepercent = .3,
        distributeprefabs =
        {
            fireflies = 0.1,
            marsh_bush = .25,
            rocks = .03,
            flint = .03,

        },
    }
})

if KnownModIndex:IsModEnabled("workshop-1467214795") then
    Layouts["cave_entrance_magmabiome_IA"] = StaticLayout.Get("map/static_layouts/cave_entrance_magmabiome_IA")
    AddRoom("BoilingFields_Sinkhole_IA", {
        colour = { r = 0, g = .9, b = 0, a = .50 },
        value = WORLD_TILES.UM_HOTSPRING_IA,
        tags = { "RoadPoison","Mist" },
        contents = {
            countstaticlayouts = {
                ["cave_entrance_magmabiome_IA"] = 1,
            },
            distributepercent = .3,
            distributeprefabs =
            {
                fireflies = 0.1,
                marsh_bush = .25,
                rocks = .03,
                flint = .03,

            },
        }
    })
end