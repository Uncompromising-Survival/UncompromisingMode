-- Make a Pick changes....

        GLOBAL.require("map/rooms/forest/challengespawner")

-- Veteran's Curse skull man
if GetModConfigData("vetcurse") == "default" then
    AddTaskPreInit("Make a pick", function(task)
        task.room_choices["veteranshrine"] = 1
    end)
end

-- Wixie goofy aaa
if GetModConfigData("wixie_walter") then
    AddTaskSetPreInitAny(function(tasksetdata)
        if tasksetdata.location ~= "forest" then -- HF only spawns on Surface
            return
        end
        table.insert(tasksetdata.required_prefabs, "wixie_wardrobe") -- Make sure wixie appears.
        table.insert(tasksetdata.required_prefabs, "wixie_clock")
        table.insert(tasksetdata.required_prefabs, "wixie_piano")
        table.insert(tasksetdata.required_prefabs, "charles_t_horse")
    end)

    AddTaskPreInit("Make a pick", function(task)
        task.room_choices["wixie_puzzlearea"] = 1
    end)
end

-- Island Adventures Compatibility
AddTaskSetPreInit("shipwrecked", function(tasksetdata)
    -- Starter Biome Changes
    local IA_SPAWN_TASKS = { "HomeIslandVerySmall", "HomeIslandSmall", "HomeIslandSmallBoon", "HomeIslandSingleTree", "HomeIslandMed", "HomeIslandLarge", "HomeIslandLargeBoon" }
    for k, v in ipairs(IA_SPAWN_TASKS) do
        AddTaskPreInit(v, function(task)
            GLOBAL.require("map/rooms/forest/challengespawner")
            if GetModConfigData("wixie_walter") then
                task.room_choices["wixie_puzzlearea_ia"] = 1
            end
            if GetModConfigData("vetcurse") == "default" then
                task.room_choices["veteranshrine_ia"] = 1
            end
        end)
    end
    --IA compat for tornadoes.
    AddRoomPreInit("OceanMedium", function(room) room.contents.countprefabs = { siren_teaser_picker = 3 } end)
end)
