-- Magma Cave Worldgen Code

-- Load new rooms for the magma caves
GLOBAL.require("map/rooms/caves/moltenregions")


-- Adjust the big bat cave to be smaller, and adjust keys so it connects to magma caves
AddTaskPreInit("BigBatCave", function(task)
    task.keys_given = { KEYS.MAGMA_CAVES }
end)

-- Create New Magma Caves Tasks
AddTask("MagmaCaves", { -- Branches in several ways, fumarole, atrium pillar, first gemology forge
		locks={LOCKS.MAGMA_CAVES_ENTRANCE,LOCKS.MAGMA_CAVES,LOCKS.TIER1},
		keys_given={KEYS.MAGMA_CAVES_ENTRANCE,KEYS.MAGMA_CAVES,KEYS.TIER2},
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers", "magmacaves","vipers_only"},
		room_choices={
			["FossilMagma"] = 5, -- Bones and Isopods		
			["ShroomyMagma"] = 1, -- Fissure and Shrooms
			["GrassMagma"] = 2, -- Pyre Nettle Thickets, Pyrite, and Capsidragon
		},
		entrance_room = "GrassMagmaCliffs", -- Pyre Nettle Thicket
		background_room="BGMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("MagmaSacred", { -- Dead End
		locks={LOCKS.MAGMA_CAVES_ENTRANCE,LOCKS.MAGMA_CAVES,LOCKS.TIER2},
		keys_given={KEYS.MAGMA_CAVES_ENTRANCE,KEYS.MAGMA_CAVES,KEYS.TIER3},
		level_set_piece_blocker = true,
		entrance_room = "ShroomyMagma", -- gloomcaps
		room_tags = {"RoadPoison", "nohunt", "nohasslers", "magmacaves","vipers_only"},
		room_choices={
			["ShroomyMagma"] = 1, -- Fissure and Shrooms
			["GemForge1"] = 1, -- Gemology Forge
			["GrassMagma"] = 1, -- Pyre Nettle Thickets, Pyrite, and Capsidragon
			["GloomyMagma"] = 2, -- WORMS and Fissures
			
		},
		--entrance_room = "GrassMagmaCliffsDragon", -- Pyre Nettle Thicket
		background_room="FossilMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})

AddTask("MagmaCavesEntrance", {
		locks={LOCKS.MAGMA_CAVES},
		keys_given={KEYS.MAGMA_CAVES_ENTRANCE,KEYS.MAGMA_CAVES,KEYS.TIER1},
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers", "magmacaves","vipers_only"},
		room_choices={
			["BGMagma"] = 2,	
			["MagmaStairs"] = 1,
			["Shroomy"] = 1,			
		},
		background_room="BGMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})



AddTaskPreInit("Volcano", function(task)
    task.room_choices[3] = {
        ["VolcanoNoise"] = 6 + math.random(0, 1),             -- in sw it 13, but we have start task in dst, so Subtract 1 to make the volcano more like a garden
        ["MagmaVolcano_IA"] = 5 + math.random(0, 1),
        ["MagmaVolcanoNest_IA"] = 1
    }
end)


AddTaskPreInit("CentipedeCaveTask", function(task)
	task.locks={LOCKS.MAGMA_CAVES_ENTRANCE,LOCKS.MAGMA_CAVES,LOCKS.TIER3}
	task.entrance_room = "MagmaRole"
	if task.room_tags then
		table.insert(task.room_tags,"vipers_only")
	else
		task.room_tags = {"vipers_only"}
	end
end)

local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")

Layouts["cave_exit_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_exit_magmabiome")
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "cave" then
		return
	end	
	if tasksetdata.required_prefabs then
		table.insert(tasksetdata.required_prefabs, "cave_exit_magmabiome")
		table.insert(tasksetdata.required_prefabs, "um_gemologyforge")
	else
		tasksetdata.required_prefabs = {"cave_exit_magmabiome","um_gemologyforge"}
	end
	
	-- Introduce new magma caves tasks
	table.insert(tasksetdata.tasks, "MagmaSacred")
	table.insert(tasksetdata.tasks, "MagmaCaves")
	table.insert(tasksetdata.tasks, "MagmaCavesEntrance")
	tasksetdata.set_pieces["TentaclePillarToAtrium"] = { count = 1, tasks={"CentipedeCaveTask" } } -- Force atrium to always be in fumarole, which is always part of the magma caves cluster
end)
