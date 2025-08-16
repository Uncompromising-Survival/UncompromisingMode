-- All Mushroom Biome Changes

-- Toadstool Spawn Location Changes

-- AddRoomPreInit("RedMushPillars", function(room) -- red
	-- room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
-- end)

-- AddRoomPreInit("GreenMushNoise", function(room) -- green
	-- room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
-- end)
-- AddRoomPreInit("DropperDesolation", function(room) -- blue
	-- room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
-- end)
	
-- -- Remove the Toadstool Tasks from the Mud biome
-- AddTaskSetPreInitAny(function(tasksetdata)
	-- for _, task in pairs(tasksetdata.tasks) do
		-- if task == "ToadStoolTask1" or task == "ToadStoolTask2" or task == "ToadStoolTask3" then
			-- table.remove(tasksetdata.tasks, _)
		-- end
	-- end
-- end)

AddLevelPreInitAny(function(level)
	if level.location == "cave" then
		level.overrides.keep_disconnected_tiles = true
	end
end)

-- Insert Depths Eels in Lunar Grotto (if enabled)
if GetModConfigData("depthseels") then
	AddTaskPreInit("MoonCaveForest", function(task)
		task.room_choices["WormyMoonMushForest"] = 1
		
	end)
end

--Sever from Mainland.... Consider that we'll have 5 different Tasks that make up the original grotto
-- Task 1 Lunar beach turf cave entrance with grass and reeds
-- Task 2 Standard Grotto
-- Task 3 Flooded Grotto + Swampy
-- Task 4 Eel Zone, Heavy Flooding
-- Task 5 Archives

AddTask("GrottoEntrance", {
		locks={},
		keys_given={KEYS.TIER1},
		level_set_piece_blocker = true,
		region_id = "underisland",
		room_tags = {"lunacyarea","RoadPoison", "nohunt", "nohasslers","not_mainland"},
		room_choices={
			["GrottoStairs"] = 1,
			["GrottoGrass"] = 1,			
		},
		background_room="BGGrottoReeds",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("PatchyFloodedGrotto", {
		region_id = "underisland",
		room_tags = {"lunacyarea","RoadPoison", "nohunt", "nohasslers","not_mainland"},
		locks={LOCKS.TIER1},
		keys_given={KEYS.TIER2},
		level_set_piece_blocker = true,
		room_choices={
			["GrottoLightFlood"] = 3,
			["GrottoLightFloodNoise"] = 2,			
		},
		background_room="GrottoLightFlood",
		room_bg=WORLD_TILES.UM_GROTTO_LIGHTFLOODED,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTaskPreInit("MoonCaveForest", function(task)
	task.region_id = "underisland"
	task.locks={LOCKS.TIER2}
	task.keys_given={KEYS.TIER3}
	task.room_tags = {"lunacyarea","RoadPoison", "nohunt", "nohasslers","not_mainland"}
    task.room_choices={
        ["MoonMushForest"] = 2,
		["MoonMushForest_entrance"] = 1,
    }
end)



AddTask("VeryFloodedGrotto", {
		region_id = "underisland",
		room_tags = {"lunacyarea","RoadPoison", "nohunt", "nohasslers","not_mainland"},
		locks={LOCKS.TIER3},
		keys_given={KEYS.ARCHIVE},
		level_set_piece_blocker = true,
		room_choices={
			["GrottoHeavyFlood"] = 3,		
			["GrottoHeavyFloodNoise"] = 2,
		},
		background_room="GrottoHeavyFlood",
		room_bg=WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTaskPreInit("ArchiveMaze", function(task)
	task.region_id = "underisland"
	task.room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","nocavein"}
	task.entrance_room = "ArchiveMazeEntrance_Flooded"
    task.room_choices =
    {
        ["ArchiveMazeRooms"] = math.random(8,12),
    }
end)


AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "cave" then
		return
	end
	table.insert(tasksetdata.tasks,"GrottoEntrance")
	table.insert(tasksetdata.tasks,"PatchyFloodedGrotto")
	table.insert(tasksetdata.tasks,"VeryFloodedGrotto")
	if tasksetdata.required_prefabs ~= nil then
		table.insert(tasksetdata.required_prefabs,"cave_exit_moon")
	else
		tasksetdata.required_prefabs = {"cave_exit_moon"}
	end
end)


-- What's this doing here..... (we don't have any specific file to put it in (yet))
-- These bits here force glommer to get away from pig king
-- AddRoomPreInit("PigKingdom", function(room) 
	-- room.random_node_exit_weight = 0
	-- room.random_node_entrance_weight = 1
-- end)

-- AddRoomPreInit("MagicalDeciduous", function(room) 
	-- room.random_node_entrance_weight = 1
	-- room.random_node_exit_weight = 0
-- end)

-- AddRoomPreInit("DeepDeciduous", function(room) 
	-- room.random_node_entrance_weight = 0
	-- room.random_node_exit_weight = 0
-- end)
-- AddRoomPreInit("BGDeciduous", function(room) 
	-- room.random_node_entrance_weight = 0
	-- room.random_node_exit_weight = 0
-- end)

AddTaskPreInit("Speak to the king", function(task)
	task.room_choices={
			["MagicalDeciduous"] = 1,
			["DeepDeciduous"] = function() return 3 + math.random(3) end,
			["PigKingdom"] = 1,
		} -- reorder...
end)
