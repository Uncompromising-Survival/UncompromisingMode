if GetModConfigData("hoodedforest") then               -- Lock Everything Behind the Mod Config
    GLOBAL.require("map/rooms/forest/gianttreesrooms") -- just in case

	AddTaskSetPreInitAny(function(tasksetdata)
		if tasksetdata.location ~= "forest" then -- HF only spawns on Surface
			return
		end
	table.insert(tasksetdata.required_prefabs, "widowwebspawner") 
	end)
		

    -- Giant Trees (Hooded Forest) replaces the "Forest hunters" task. In DST layman's speak this is the moonbase forest with the single mactusk camp.
    AddTaskPreInit("Forest hunters", function(task)
        GLOBAL.require("map/rooms/forest/gianttreesrooms")
        -- Room Redux
        task.level_set_piece_blocker = true
        task.entrance_room = "HoodedEntrance"
        task.room_choices = {

            ["SpideryGiantTrees"] = 1,
            ["WalrusGiantTrees"] = 1,
            ["MoonBaseGiantTrees"] = 1,
            ["HoodedTown"] = function() return math.random(0, 1) end,
            ["HFHolidays"] = function() return math.random(0, 1) end,
            ["RoseGarden"] = function() return math.random(0, 1) end,
            ["FoxGathering"] = 1,
            ["GiantTrees"] = 1,

            --["QuestionableDecisions"] = 1 -- Goofy aaa lush caves
        }
        task.room_bg = GLOBAL.WORLD_TILES.HOODEDFOREST
        task.background_room = "BGGiantTrees"
    end)

    -- Setpiece adjustments
    AddTaskSetPreInitAny(function(tasksetdata)
        if tasksetdata.location ~= "forest" then -- HF only spawns on Surface
            return
        end

        if not table.contains(tasksetdata.tasks, "Forest hunters") then
            return
        end

        local target_task = "Forest hunters"
        local remove_setpiece_list = { "ResurrectionStone", "WormholeGrass", "CaveEntrance", "MooseNest" } -- Ensure these setpieces cannot spawn in hooded forest, they aren't prevented by level_set_piece_blocker
        for j, setpiece in ipairs(remove_setpiece_list) do
            for i, task in ipairs(tasksetdata.set_pieces[setpiece].tasks) do
                if task == target_task then
                    table.remove(tasksetdata.set_pieces[setpiece].tasks, i)
                end
            end
        end
    end)



    -- [IA Compatibility] --
    -- [Create New Giant Trees IA Task] --
    AddTask("GiantTrees_IA", {
        locks = { LOCKS.ISLAND2, LOCKS.ISLAND3 },
        keys_given = { KEYS.ISLAND3, KEYS.ISLAND4 },
        --region_id = "hoodedforest",
        entrance_room = "HoodedEntrance",
        --level_set_piece_blocker = true,
        room_choices = {
            ["SpideryGiantTrees"] = 1,
            ["GiantTrees"] = 1,
            ["RoseGarden"] = 1,
            --["RoadGiantTrees"] = 1,
            --["WalrusGiantTrees"] = 1,
            --["MoonBaseGiantTrees"] = 1,
            --["ShroomInfestedGiantTrees"] = 1,
            --["SnapDragons"] = 1,

			["FoxGathering"] = 1,
            ["SpideryGiantTrees"] = 1,

            ["FoxGathering"] = 1,
            ["HoodedTown"] = 1,
            ["HFHolidays"] = 1,
            --["QuestionableDecisions"] = 1,
        },
        room_bg = WORLD_TILES.HOODEDFOREST,
        background_room = "BGGiantTrees",
        room_tags = { "hoodedcanopy" },
        colour = { r = .1, g = .1, b = .1, a = 1 }
    })

    AddTaskSetPreInit("shipwrecked", function(tasksetdata)
        -- IA Giant Trees
        if GetModConfigData("hoodedforest") then
            table.insert(tasksetdata.tasks, "GiantTrees_IA")
            table.insert(tasksetdata.required_prefabs, "widowwebspawner")
        end
    end)
end
