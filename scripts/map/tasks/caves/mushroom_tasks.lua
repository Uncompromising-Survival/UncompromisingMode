--AXE All Mushroom Biome Changes, this includes the lunar grotto


--AXE Toadstool Spawn Location Changes - instead of spawning in 3 mud biome tasks, a static layout is inserted in rooms that only spawn once in each of the r/g/b mushroom biomes
AddRoomPreInit("RedMushPillars", function(room) -- red
	room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
end)

AddRoomPreInit("GreenMushNoise", function(room) -- green
	room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
end)
AddRoomPreInit("DropperDesolation", function(room) -- blue
	room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
end)
	
--AXE The Old Tasks that contain the Toadstool spawners must be removed

local toadstool_tasks = {"ToadStoolTask1","ToadStoolTask2","ToadStoolTask3"}

AddTaskSetPreInitAny(function(tasksetdata)
	for i,v in ipairs(toadstool_tasks) do --AXE need to loop around the outside specifically, it's somehow missing one of the tasks if we do it like prior...
		for _, task in pairs(tasksetdata.tasks) do
			if task == v then
				table.remove(tasksetdata.tasks, _)
			end
		end
	end
end)


-------------------------------------------
-- Lunar Grotto and Archives Changes
-------------------------------------------

GLOBAL.require("map/rooms/caves/moonregions") --AXE We need to require the rooms that are used by the following Tasks

-- AXE Here is the following generation order of the new lunar grotto tasks, LOCK/KEY ensure that this order is followed
-- Sever the Grotto from the Mainland.... Consider that we'll have 5 different Tasks that make up the original grotto - this is accomplished by giving room_tags "not_mainland" and the region_id "underisland", which is under lunar
-- Task 1 Lunar beach turf cave entrance with grass and reeds
-- Task 2 Flooded Grotto + Swampy
-- Task 3 Standard Grotto, one part lightly flooded
-- Task 4 Eel Zone, Heavy Flooding
-- Task 5 Archives
-- AXE a bit of adjustment to this, between task 3/4 there's a "Dark" task where the grotto has little light.



AddTask("GrottoEntrance", {
		locks={},
		keys_given={KEYS.TIER1},
		level_set_piece_blocker = true,
		region_id = "underisland",
		room_tags = {"lunacyarea","not_mainland","eels_only"},
		room_choices={
			["GrottoStairs"] = 1,
			["GrottoGrassNoise"] = 1,
						
		},
		background_room="BGGrottoReeds",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("PatchyFloodedGrotto", {
		region_id = "underisland",
		room_tags = {"lunacyarea","not_mainland","MushGnomeSpawnArea","eels_only"},
		locks={LOCKS.TIER1},
		keys_given={KEYS.TIER2},
		level_set_piece_blocker = true,
		room_choices={
			["GrottoGrass"] = 1,
			["GrottoLightFlood"] = 3,
			["GrottoLightFloodNoise"] = 2,			
		},
		background_room="GrottoLightFlood",
		room_bg=WORLD_TILES.UM_GROTTO_LIGHTFLOODED,
		colour={r=.1,g=.1,b=.1,a=1},
})

-- Keep the vanilla task and redefine the room choices, incase another mod tries to reference it. If it is removed, it could result in a crash. (This happened with removing the forest that used to be the Hooded Forest and the black plague mod)
AddTaskPreInit("MoonCaveForest", function(task)
	task.region_id = "underisland"
	task.locks={LOCKS.TIER2}
	task.keys_given={KEYS.TIER3}
	task.room_tags = {"lunacyarea","not_mainland","MushGnomeSpawnArea","eels_only"}
    task.room_choices={
        ["MoonMushForest"] = 2,
		["MoonMushForest_entrance"] = 1,
    }
end)

local mushroom_rooms = {"MoonMushForest","MoonMushForest_entrance"}

for i,v in ipairs(mushroom_rooms) do
	AddRoomPreInit(v, function(room)
		if room.tags then
			--table.insert(room.tags,"ForceDisconnected")
			table.insert(room.tags,"not_mainland")
			table.insert(room.tags,"um_grottowar")
		else
			room.tags = {"not_mainland","um_grottowar"}
		end
		room.SafeFromDisconnect = true -- Thank you Klei, this is a very nice option to have
	end)
end

AddTask("VeryFloodedGrotto", {
		region_id = "underisland",
		room_tags = {"lunacyarea","not_mainland","eels_only"},
		locks={LOCKS.TIER3},
		keys_given={KEYS.TIER4},
		level_set_piece_blocker = true,
		room_choices={
			
			["GrottoHeavyFloodWorms"] = 2,		
			["GrottoHeavyFloodBoth"] = 1,
			["GrottoHeavyFloodTentacles"] = 2,

		},
		
		background_room="GrottoHeavyFloodTentacles",
		--[[cove_room_name = "Empty_Cove",
		cove_room_chance = 1,
		cove_room_max_edges = 2,]]
		room_bg=WORLD_TILES.UM_GROTTO_HEAVYFLOODED,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("DarkFloodedGrotto", {
		region_id = "underisland",
		room_tags = {"lunacyarea","not_mainland","eels_only"},
		locks={LOCKS.TIER4},
		keys_given={KEYS.ARCHIVE},
		level_set_piece_blocker = true,
		room_choices={
			
			["GrottoDarknessWorms"] = 6,		
			["GrottoDarknessTentacles"] = 1,	
		},
		
		room_bg=WORLD_TILES.UM_FLOODWATER_GROTTO,
		colour={r=.1,g=.1,b=.1,a=1},
})


AddTaskPreInit("ArchiveMaze", function(task)
	task.region_id = "underisland"
	task.room_tags = {"not_mainland","nocavein","eels_only"}
	task.entrance_room = "ArchiveMazeEntrance_Flooded"
    task.room_choices =
    {
        ["ArchiveMazeRooms"] = math.random(8,10),
    }
end)
	
AddRoomPreInit("ArchiveMazeRooms", function(room)
	if room.tags then
		table.insert(room.tags,"UMMazeGrotto")
	else
		room.tags = {"UMMazeGrotto"}
	end
end)
	
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "cave" then
		return
	end
	table.insert(tasksetdata.tasks,"GrottoEntrance")
	table.insert(tasksetdata.tasks,"PatchyFloodedGrotto")
	table.insert(tasksetdata.tasks,"VeryFloodedGrotto")
	table.insert(tasksetdata.tasks,"DarkFloodedGrotto")
	if tasksetdata.required_prefabs ~= nil then
		table.insert(tasksetdata.required_prefabs,"cave_exit_moon")
	else
		tasksetdata.required_prefabs = {"cave_exit_moon"}
	end
end)


-- AXE Add lunar mushrooms
AddRoomPreInit("MoonMushForest", function(room)
	room.contents.distributeprefabs["um_mushroom_moon"] = 0.03
end)
