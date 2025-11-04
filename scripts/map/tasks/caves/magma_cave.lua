-- Magma Cave Worldgen Code

-- Load new rooms for the magma caves
GLOBAL.require("map/rooms/caves/moltenregions")


-- Adjust the big bat cave to be smaller, and adjust keys so it connects to magma caves
AddTaskPreInit("BigBatCave", function(task)
    task.keys_given = { KEYS.MAGMA_CAVES }
end)

-- Create New Magma Caves Tasks
AddTask("MagmaCaves", { -- Branches in several ways, fumarole, atrium pillar, first gemology forge
    locks = { LOCKS.MAGMA_CAVES_ENTRANCE, LOCKS.MAGMA_CAVES, LOCKS.TIER1 },
    keys_given = { KEYS.MAGMA_CAVES_ENTRANCE, KEYS.MAGMA_CAVES, KEYS.TIER2 },
    level_set_piece_blocker = true,
    room_tags = { "RoadPoison", "nohunt", "nohasslers" },
    room_choices = {
        ["GloomyMagma"] = 2,            -- WORMS and Fissures
        ["FossilMagma"] = 3,            -- Bones and Isopods		
        ["ShroomyMagma"] = 2,           -- Fissure and Shrooms
        ["GrassMagma"] = 3,             -- Pyre Nettle Thickets, Pyrite, and Capsidragon
    },
    entrance_room = "GrassMagmaCliffs", -- Pyre Nettle Thicket
    background_room = "BGMagma",
    room_bg = WORLD_TILES.UM_MAGMA,
    colour = { r = .1, g = .1, b = .1, a = 1 },
})

AddTask("MagmaOcean", {
    locks = { LOCKS.MAGMA_CAVES_ENTRANCE, LOCKS.MAGMA_CAVES, LOCKS.TIER2 },
    keys_given = { KEYS.MAGMA_CAVES_SACRED },
    level_set_piece_blocker = true,
    room_tags = { "RoadPoison", "nohunt", "nohasslers" },
    room_choices = {
        ["MagmaOcean"] = 4,                  -- Lava ocean.
        ["MagmaOceanExit"] = 1
    },
    entrance_room = "GrassMagmaCliffsDragon", -- Pyre Nettle Thicket
    background_room = "BGMagmaOcean",
    room_bg = WORLD_TILES.UM_MAGMA_LAVAMOLTEN,
    colour = { r = .1, g = .1, b = .1, a = 1 },
})

AddTask("MagmaSacred", { -- Dead End
    locks = { LOCKS.MAGMA_CAVES_SACRED },
    keys_given = {},
    level_set_piece_blocker = true,
    room_tags = { "RoadPoison", "nohunt", "nohasslers" },
    room_choices = {
        ["GemForge1"] = 1, -- Gemology Forge
    },
    entrance_room = "MagmaOceanExit",
    background_room = "FossilMagma",
    room_bg = WORLD_TILES.UM_MAGMA,
    colour = { r = .1, g = .1, b = .1, a = 1 },
})

AddTask("MagmaCavesEntrance", {
    locks = { LOCKS.MAGMA_CAVES },
    keys_given = { KEYS.MAGMA_CAVES_ENTRANCE, KEYS.MAGMA_CAVES, KEYS.TIER1 },
    level_set_piece_blocker = true,
    room_tags = { "RoadPoison", "nohunt", "nohasslers" },
    room_choices = {
        ["BGMagma"] = 2,
        ["MagmaStairs"] = 1,
        ["Shroomy"] = 1,
    },
    background_room = "BGMagma",
    room_bg = WORLD_TILES.UM_MAGMA,
    colour = { r = .1, g = .1, b = .1, a = 1 },
})

AddTaskPreInit("CentipedeCaveTask", function(task)
    task.locks = { LOCKS.MAGMA_CAVES_ENTRANCE, LOCKS.MAGMA_CAVES, LOCKS.TIER2 }
    task.entrance_room = "MagmaRole"
end)

local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")

Layouts["cave_exit_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_exit_magmabiome")
AddTaskSetPreInitAny(function(tasksetdata)
    if tasksetdata.location ~= "cave" then
        return
    end
    if tasksetdata.required_prefabs then
        table.insert(tasksetdata.required_prefabs, "cave_exit_magmabiome")
        table.insert(tasksetdata.required_prefabs, "um_gemologyforge_umss")
    else
        tasksetdata.required_prefabs = { "cave_exit_magmabiome", "um_gemologyforge_umss" }
    end

    -- Introduce new magma caves tasks
    table.insert(tasksetdata.tasks, "MagmaOcean")
    table.insert(tasksetdata.tasks, "MagmaSacred")
    table.insert(tasksetdata.tasks, "MagmaCaves")
    table.insert(tasksetdata.tasks, "MagmaCavesEntrance")
    tasksetdata.set_pieces["TentaclePillarToAtrium"] = { count = 1, tasks = { "CentipedeCaveTask" } } -- Force atrium to always be in fumarole, which is always part of the magma caves cluster
end)
