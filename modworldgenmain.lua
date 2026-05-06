--always load tiledefs to prevent nil reference crashes.
modimport("libraries/um_particletilehelper")
modimport("libraries/um_particleworldtilestate")
modimport("scripts/map/misc_tools/tiledefs")

if GetModConfigData("worldgenmastertoggle") then
    modimport("postinit/map/static_layouts")

    local misc_tools = { "locks&keys", "room_tags", "umss_init" }
    for i, tool in ipairs(misc_tools) do
        modimport("scripts/map/misc_tools/" .. tool)
    end

    ---- XX[[ Forest Task Adjustments ]]XX ----
    local tasks_forest = {
        "make_a_pick",     -- Make a Pick changes (Starter Biome), Wixie, Veteran's Curse
        "speak_to_the_king", -- Change to force Glommer to more consistently spawn away from Pig King, to make it easier to escape with him without drawing buffed werepig aggro
        "dig_that_rock",   -- UMSS compatibility changes, Ratacombs entrance
        "squeltch",        -- Rice, Marsh bushes and mist
        "merged_desert",   -- Oasis Overhaul to include rooms lost from Badlands -> Broiling Hills
        "broiling_hills",  -- Changes Badlands -> Broiling Hills
        "giant_trees",     -- Changes Forest Hunters -> Hooded Forest
        "the_hunters",     -- Adds Trapdoors and Ghost Walruses
        "for_a_nice_walk", -- Guarantees a living tree spawns
        "ocean_general",   -- All Ocean Changes (For Now)
        "moonisland",      -- Lunar Bees
    }

    ---- XX[[ Cave Task Adjustments ]]XX ----
    local tasks_caves = {
        "mushroom_tasks", -- Toadstool Spawners and Depths Eels in Lunar Mushroom Forest
        "magma_cave",     -- Shrinks Big Bat Biome, links it to new Magma Caves Tasks
        "ruins",          -- Adds Pawn Spawners
        --"ratacombs", -- We're rats, we're rats, we're the rats.
        "gemology",
    }

    -- Import Adjustments and Additions to Tasks	
    for i, task in ipairs(tasks_forest) do
        modimport("scripts/map/tasks/forest/" .. task)
    end

    for i, task in ipairs(tasks_caves) do
        modimport("scripts/map/tasks/caves/" .. task)
    end
end
