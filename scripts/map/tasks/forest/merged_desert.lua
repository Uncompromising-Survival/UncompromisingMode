-- Merge the content from both deserts into Lightning Bluff, which is the Oasis desert

-- Redux the Lightning Bluff Task -- Oasis Renovation - Give Oasis versions of several Badlands rooms, but they can have sandstorm
AddTaskPreInit("Lightning Bluff", function(task)
    GLOBAL.require("map/rooms/forest/UM_LightningBluff")

    task.room_choices["BarePlain_Oasis"] = 1
    task.room_choices["Houndy_Oasis"] = 1
    --task.room_choices["Badlands_Oasis"] = 1
    --task.room_choices["BuzzardyBadlands_Oasis"] = 1
    task.room_choices["BGLightningBluff"] = 0 -- No more BGLightningBluff
    task.background_room = "BGBadlands_Oasis"
end)

-- Room tag adjustments, mainly get rid of road poison...
AddRoomPreInit("LightningBluffLightning", function(room)
    room.tags = { "sandstorm" }
end)
AddRoomPreInit("LightningBluffAntlion", function(room)
    room.tags = { "sandstorm" }
end)

local function InsertIntoSetpieceTasks(name, task)
    local setpiece = tasksetdata.set_pieces[name]
    if not setpiece then return end
    table.insert(setpiece.tasks, "Lightning Bluff")
end

local setpiece_list = {"ResurrectionStone", "WormholeGrass", "CaveEntrance"}
AddTaskSetPreInitAny(function(tasksetdata)
    if tasksetdata.location ~= "forest" then return end

    -- Enable several setpieces to spawn within the merged desert
    if table.contains(tasksetdata.tasks, "Lightning Bluff") then
        for _, name in pairs(setpiece_list) do
            InsertIntoSetpieceTasks(name, "Lightning Bluff")
        end
    end
end)
