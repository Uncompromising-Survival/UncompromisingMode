if GetModConfigData("moon_bees") then
    AddRoomPreInit("MoonIsland_Beach", function(room)
        room.contents.countprefabs = { um_beehive_moon = function() return math.random(1, 2) end }
    end)

    AddTaskPreInit("MoonIsland_Mine", function(task)
        GLOBAL.require("map/rooms/forest/UM_moonisland")

        task.room_choices["moonrock_bees"] = 1
    end)

    AddTaskPreInit("MoonIsland_Forest", function(task)
        GLOBAL.require("map/rooms/forest/UM_moonisland")

        task.room_choices["moonforest_bees"] = 1
    end)
end

if GetModConfigData("flooded_caves") == "lunar_cave" then
    AddTaskPreInit("MoonIsland_Beach", function(task)
        GLOBAL.require("map/rooms/forest/UM_moonisland")

        task.room_choices["moonswamp_cave"] = 1
    end)
end

AddTaskSetPreInitAny(function(tasksetdata)
    if tasksetdata.location ~= "forest" or GetModConfigData("flooded_caves") ~= "lunar_cave" then return end

    if tasksetdata.required_prefabs ~= nil then
        table.insert(tasksetdata.required_prefabs, "cave_entrance_moon")
    else
        tasksetdata.required_prefabs = { "cave_entrance_moon" }
    end
end)
