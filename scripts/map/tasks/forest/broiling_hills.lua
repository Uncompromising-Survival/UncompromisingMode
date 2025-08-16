--TODO: ADD CONFIG.
-- Broiling Hills replaces the "Badlands" task. In DST layman's speak this dragonfly desert

-- New StaticLayouts
local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
Layouts["boilingfields_dragonfly_arena"] = StaticLayout.Get("map/static_layouts/boilingfields_dragonfly_arena")
Layouts["cave_entrance_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_entrance_magmabiome")
GLOBAL.require("map/rooms/forest/UM_BoilingFields") -- just in case

-- Task overhaul
AddTaskPreInit("Badlands", function(task)
    GLOBAL.require("map/rooms/forest/UM_BoilingFields")


    -- Room removal! lots of desert things are gone now! Make room for hot springs
    task.room_choices["Badlands"] = 0
    task.room_choices["BarePlain"] = 0
    task.room_choices["BuzzardyBadlands"] = 0
    task.room_choices["HoundyBadlands"] = 0
    task.room_choices["DragonflyArena"] = 0

    task.room_choices["BoilingFields_Crabby"] = 1         -- Crabs
	task.room_choices["BoilingFields_Rocky"] = 1          -- Snaildrakes
	task.room_choices["BoilingFields_WAR"] = 1          -- Snaildrakes
    task.room_choices["BoilingFields_Hotsprings"] = 1     -- Hotsprings
    task.room_choices["BoilingFields_Hounds"] = 1   -- Hounds
    task.room_choices["BoilingFields_DragonflyArena"] = 1 -- Dfly
    task.room_choices["BoilingFields_Sinkhole"] = 1       -- Sinkhole
    task.background_room = "BoilingFields_Hotsprings"
end)

-- Setpiece adjustments
AddTaskSetPreInitAny(function(tasksetdata)
    if tasksetdata.location ~= "forest" then
        return
    end


    local target_task = "Badlands"
    local remove_setpiece_list = { "ResurrectionStone", "WormholeGrass", "CaveEntrance" } -- Ensure these setpieces cannot spawn in hooded forest, they aren't prevented by level_set_piece_blocker
    for j, setpiece in ipairs(remove_setpiece_list) do
        for i, task in ipairs(tasksetdata.set_pieces[setpiece].tasks) do
            if task == target_task then
                table.remove(tasksetdata.set_pieces[setpiece].tasks, i)
            end
        end
    end

    -- Add required prefabs
    table.insert(tasksetdata.required_prefabs, "dragonfly_spawner")
    table.insert(tasksetdata.required_prefabs, "cave_entrance_magmabiome")
end)


AddTask("BrolingHills_IA", {
    locks = { LOCKS.ISLAND2 },
    keys_given = { KEYS.ISLAND3 },
    --region_id = "hoodedforest",
    level_set_piece_blocker = true,
    room_choices = {
        ["BoilingFields_Crabby_IA"] = math.random(2),
        ["BoilingFields_Hotsprings_IA"] = math.random(2),
        ["BoilingFields_Rocky_IA"] = math.random(2),
        --["BoilingFields_BasaltHounds"] = 1,
        --["BoilingFields_Sinkhole_IA"] = 1,
    },
    room_bg = WORLD_TILES.MAGMAFIELD,
    background_room = {"BoilingFields_Hotsprings_IA"},
    colour = { r = .1, g = .1, b = .1, a = 1 }
})

-- Chance to Swap Mosaic and Broiling Hills
if math.random() > 0.5 then
	AddTaskPreInit("Dig that rock", function(task)
		task.locks={LOCKS.ADVANCED_COMBAT,LOCKS.MONSTERS_DEFEATED,LOCKS.TIER4}
		task.keys_given={KEYS.HOUNDS,KEYS.TIER5, KEYS.ROCKS}
	end)

	AddTaskPreInit("Badlands", function(task)
		task.locks={LOCKS.ROCKS}
		task.keys_given={KEYS.TRINKETS,KEYS.STONE,KEYS.WOOD,KEYS.TIER1}	
	end)
end





AddTask("BrolingHills_IA_2", {
    locks = { LOCKS.ISLAND4 },
    keys_given = { KEYS.ISLAND5 },
    --region_id = "hoodedforest",
    level_set_piece_blocker = true,
    room_choices = {
        ["BoilingFields_Crabby_IA"] = math.random(2),
        ["BoilingFields_Hotsprings_IA"] = math.random(2),
        ["BoilingFields_Rocky_IA"] = math.random(2),
        --["BoilingFields_BasaltHounds"] = 1,
        --["BoilingFields_Sinkhole_IA"] = 1,
    },
    room_bg = WORLD_TILES.MAGMAFIELD,
    background_room = {"BoilingFields_Hotsprings_IA"},
    colour = { r = .1, g = .1, b = .1, a = 1 }
})


AddTaskSetPreInitAny(function(tasksetdata)
    if tasksetdata.name == GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.SHIPWRECKED then
        -- IA Giant Trees
        table.insert(tasksetdata.tasks, "BrolingHills_IA")
        table.insert(tasksetdata.tasks, "BrolingHills_IA_2")

    end
end)
