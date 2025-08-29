-- Magma Cave Worldgen Code

-- Load new rooms for the magma caves
GLOBAL.require("map/rooms/caves/moltenregions")


-- Adjust the big bat cave to be smaller, and adjust keys so it connects to magma caves
AddTaskPreInit("BigBatCave",function(task)
	task.keys_given={KEYS.MAGMA_CAVES}
end)

-- Create New Magma Caves Tasks
AddTask("MagmaCaves", {
		locks={LOCKS.MAGMA_CAVES_ENTRANCE,LOCKS.MAGMA_CAVES,LOCKS.TIER1},
		keys_given={KEYS.MAGMA_CAVES_TIER1},
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers"},
		room_choices={
			["GrassMagma"] = 2,
			["GloomyMagma"] = 1,
			["FossilMagma"] = 1,		
			["ShroomyMagma"] = 1,
		},
		background_room="GrassMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})
AddTask("MagmaCavesEntrance", {
		locks={LOCKS.MAGMA_CAVES},
		keys_given={KEYS.MAGMA_CAVES_ENTRANCE,KEYS.MAGMA_CAVES,KEYS.TIER1},
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers"},
		room_choices={
			["MagmaStairs"] = 1,
			["ShroomyMagma"] = 1,			
		},
		background_room="BGMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})

local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")

Layouts["cave_exit_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_exit_magmabiome")
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "cave" then
		return
	end	
	if tasksetdata.required_prefabs then
		table.insert(tasksetdata.required_prefabs, "cave_exit_magmabiome")
	else
		tasksetdata.required_prefabs = {"cave_exit_magmabiome"}
	end
	
	-- Introduce new magma caves tasks
	table.insert(tasksetdata.tasks, "MagmaCaves")
	table.insert(tasksetdata.tasks, "MagmaCavesEntrance")
end)