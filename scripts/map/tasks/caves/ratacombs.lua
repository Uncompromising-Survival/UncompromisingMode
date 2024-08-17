GLOBAL.require("map/rooms/caves/ratacombsrooms")

AddTask("Ratty_Entrance", {
		locks={},
		keys_given={KEYS.TIER1},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland"},
		room_choices={
			["RattyStairs"] = 1, 			
		},
		room_bg=WORLD_TILES.FOREST,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("Ratty_Link", {
		locks={LOCKS.TIER2},
		keys_given={KEYS.TIER3},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland"},
		entrance_room= "RattyWall",
		room_choices={
			["RatKingdomCaves"] = 1,
		},
		background_room="RattyLink",
		room_bg=WORLD_TILES.FOREST,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("Ratty_Maze", {
		locks={LOCKS.TIER1},
		keys_given={KEYS.TIER2},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","rattygas", "ratkey1"},
		room_choices={
			["RattyWilds"] = function() return 3 + math.random(4) end,
			["RattyLock1"] = 1,
		},
		room_bg=WORLD_TILES.FOREST,
		background_room="BGRattyCaveRoom",
		colour={r=.1,g=.1,b=.1,a=1},
})
--[[AddTask("Ratty_Shallow_1", {
		locks={LOCKS.TIER2},
		keys_given={KEYS.TIER3},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","rattygas", "ratkey1"},
		room_choices={
			["RattyWilds"] = function() return 3 + math.random(4) end,
		},
		room_bg=WORLD_TILES.FOREST,
		background_room="BGRattyCaveRoom",
		colour={r=.1,g=.1,b=.1,a=1},
})
AddTask("Ratty_Shallow_2", {
		locks={LOCKS.TIER3},
		keys_given={KEYS.TIER4},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","rattygas", "ratkey1"},
		room_choices={
			["RattyWilds"] = function() return 3 + math.random(4) end,
		},
		room_bg=WORLD_TILES.FOREST,
		background_room="BGRattyCaveRoom",
		colour={r=.1,g=.1,b=.1,a=1},
})
AddTask("Ratty_Shallow_3", {
		locks={LOCKS.TIER1},
		keys_given={KEYS.TIER2},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","rattygas", "ratkey1"},
		room_choices={
			["RattyWilds"] = function() return 3 + math.random(4) end,
		},
		room_bg=WORLD_TILES.FOREST,
		background_room="BGRattyCaveRoom",
		colour={r=.1,g=.1,b=.1,a=1},
})]]
AddTask("Ratty_Maze2", {
		locks={LOCKS.TIER3},
		keys_given={},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","rattygas"},
		room_choices={
			["DeepRattyWilds"] = 5,
		},
		room_bg=WORLD_TILES.FOREST,
		background_room="BGRattyCaveRoom",
		colour={r=.1,g=.1,b=.1,a=1},
})
AddTask("Ratty_Maze3", {
		locks={LOCKS.TIER3},
		keys_given={},
		region_id = "ratacombs",
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers","not_mainland","rattygas"},
		room_choices={
			["DeepRattyWilds"] = 5,
		},
		room_bg=WORLD_TILES.FOREST,
		background_room="BGRattyCaveRoom",
		colour={r=.1,g=.1,b=.1,a=1},
})

--[[GLOBAL.require("map/tasks/ratacombs")
	GLOBAL.require("map/rooms/caves/ratacombsrooms")
	GLOBAL.require("map/rooms/forest/ratking")
local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
local STRINGS = GLOBAL.STRINGS
	if GetModConfigData("caved") == false then

		AddTaskSetPreInitAny(function(tasksetdata)
		if tasksetdata.location ~= "forest" or (tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.VOLCANO or tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.SHIPWRECKED) then
				return
			end
			AddTaskPreInit("Dig that rock",function(task)
				task.room_choices["RatKingdom"] = 1
			end)
		end)
	else
		AddTaskPreInit("Dig that rock",function(task)
			task.room_choices["RattySinkhole"] = 1
		end)
	end]]


	--[[AddTaskSetPreInitAny(function(tasksetdata)
		if tasksetdata.location ~= "cave" then
			return
		end
		table.insert(tasksetdata.tasks,"Ratty_Entrance")
		table.insert(tasksetdata.tasks,"Ratty_Link")
		table.insert(tasksetdata.tasks,"Ratty_Maze")
		table.insert(tasksetdata.tasks,"Ratty_Maze")
		table.insert(tasksetdata.tasks,"Ratty_Maze2")
		table.insert(tasksetdata.tasks,"Ratty_Maze3")

		if tasksetdata.required_prefabs ~= nil then
			table.insert(tasksetdata.required_prefabs,"ratking")
			table.insert(tasksetdata.required_prefabs,"ratacombslock")
		else
			tasksetdata.required_prefabs = {"ratking","ratacombslock"}
		end
	end)]]


--Layouts["RatLockBlocker1"] = { type = GLOBAL.LAYOUT.CIRCLE_EDGE, start_mask = GLOBAL.PLACE_MASK.NORMAL, fill_mask = GLOBAL.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED, layout_position = GLOBAL.LAYOUT_POSITION.CENTER, ground_types = { GLOBAL.WORLD_TILES.ROCKY }, defs = { rocks = { "ratacombslock_rock_spawner" } }, count = { rocks = 1 }, scale = 0.1 }
