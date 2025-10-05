-- Several squeltch (common name is marsh or swamp) adjustments are made in UM, namely rice and the USELESS STUPID STINKY marsh bushes


GLOBAL.require("map/rooms/forest/extraswamp")

-- Add mist and marsh bushes
AddRoomPreInit("BGMarsh", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(2, 6) end, marshmist = function() return math.random(4, 6) end } end)

AddRoomPreInit("Marsh", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(2, 6) end, marshmist = function() return math.random(4, 6) end } end)

AddRoomPreInit("SpiderMarsh", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(4, 8) end, marshmist = function() return math.random(4, 6) end } end)

AddRoomPreInit("SlightlyMermySwamp", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(4, 8) end, marshmist = function() return math.random(4, 6) end } end)


-- Add Rice
if GetModConfigData("rice") then
    -- Add the rice rooms
    AddTaskPreInit("Squeltch", function(task)
        task.room_choices["ricepatch"] = 1
        task.room_choices["densericepatch"] = 1
        task.room_choices["Marsh"] = function() return (3 + math.random(GLOBAL.SIZE_VARIATION)) end -- Decrease the size of the marsh a bit to counterbalance the added rooms
    end)

    -- Make the world require to have rice spawners in it
    AddTaskSetPreInitAny(function(tasksetdata)
        if tasksetdata.location ~= "forest" then
            return
        end
        table.insert(tasksetdata.required_prefabs, "riceplantspawnerlarge")
        table.insert(tasksetdata.required_prefabs, "riceplantspawner")
    end)

    -- Allow disconnected tiles for the HOLES made by the rice
    AddLevelPreInitAny(function(level)
        if level.location == "forest" then
            level.overrides.keep_disconnected_tiles = true
        end
    end)

    local Layouts = GLOBAL.require("map/layouts").Layouts
    local StaticLayout = GLOBAL.require("map/static_layout")
    -- Register the layouts
    for i = 1, 4 do
        Layouts["ricepatchsmall" .. i] = StaticLayout.Get("map/static_layouts/ricepatchsmall" .. i)
    end
    for i = 1, 1 do
        Layouts["ricepatchlarge" .. i] = StaticLayout.Get("map/static_layouts/ricepatchlarge" .. i)
    end

    -- Add the layouts
    AddRoomPreInit("ricepatch", function(room)
        if not room.contents.countstaticlayouts then
            room.contents.countstaticlayouts = {}
        end
        local roomchoice = math.random(1, 4)
        local roomchoice2 = roomchoice
        while roomchoice2 == roomchoice do
            roomchoice2 = math.random(1, 4)
        end
        room.contents.countstaticlayouts["ricepatchsmall" .. roomchoice] = 1
        if math.random() > 0.5 then
            room.contents.countstaticlayouts["ricepatchsmall" .. roomchoice2] = 1
        end
    end)

    AddRoomPreInit("densericepatch", function(room)
        if not room.contents.countstaticlayouts then
            room.contents.countstaticlayouts = {}
        end
        room.contents.countstaticlayouts["ricepatchlarge1"] = 1
    end)
end
