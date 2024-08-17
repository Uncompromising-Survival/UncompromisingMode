if GetModConfigData("hoodedforest") then -- Lock Everything Behind the Mod Config

-- Giant Trees (Hooded Forest) replaces the "Forest hunters" task. In DST layman's speak this is the moonbase forest with the single mactusk camp.
AddTaskPreInit("Forest hunters", function(task)
	GLOBAL.require("map/rooms/forest/gianttreesrooms")
	-- Room Redux
	task.level_set_piece_blocker = true
	task.room_choices={
			["GiantTrees"] = 1,
			["SnapDragons"] = 1,
			["SpideryGiantTrees"] = 1,
			["WalrusGiantTrees"] = 1,
			["MoonBaseGiantTrees"] = 1,

			["AphidLand"] = function() return math.random(0,1) end,
			["ShroomInfestedGiantTrees"] = function() return math.random(0,1) end,
			["HoodedTown"] = function() return math.random(0,1) end,
			["HFHolidays"] = function() return math.random(0,1) end,
			["RoseGarden"] = function() return math.random(0,1) end,

			--["QuestionableDecisions"] = 1 -- Goofy aaa lush caves
		}
	task.room_bg=GLOBAL.WORLD_TILES.HOODEDFOREST
	task.background_room="BGGiantTrees"
end)

-- Setpiece adjustments
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "forest" then -- HF only spawns on Surface
		return
	end
	
	local target_task = "Forest hunters"
	local remove_setpiece_list = {"ResurrectionStone","WormholeGrass","CaveEntrance","MooseNest"} -- Ensure these setpieces cannot spawn in hooded forest, they aren't prevented by level_set_piece_blocker
	for j,setpiece in ipairs(remove_setpiece_list) do
		for i,task in ipairs(tasksetdata.set_pieces[setpiece].tasks) do
			if task == target_task then
				table.remove(tasksetdata.set_pieces[setpiece].tasks,i)
			end
		end
	end
	
end)


-- Special HF setpieces
local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
Layouts["hooded_town"] = StaticLayout.Get("map/static_layouts/hooded_town")
Layouts["rose_garden"] = StaticLayout.Get("map/static_layouts/rose_garden")
Layouts["hf_holidays"] = StaticLayout.Get("map/static_layouts/hf_holidays")

AddRoomPreInit("HoodedTown", function(room)
	if not room.contents.countstaticlayouts then
		room.contents.countstaticlayouts = {}
	end
	room.contents.countstaticlayouts["hooded_town"] = 1
end)

AddRoomPreInit("RoseGarden", function(room)
	if not room.contents.countstaticlayouts then
		room.contents.countstaticlayouts = {}
	end
	room.contents.countstaticlayouts["rose_garden"] = 1
end)

AddRoomPreInit("HFHolidays", function(room)
	if not room.contents.countstaticlayouts then
		room.contents.countstaticlayouts = {}
	end
	room.contents.countstaticlayouts["hf_holidays"] = 1
end)


	-- [IA Compatibility] -- 
-- [Create New Giant Trees IA Task] -- 
AddTask("GiantTrees_IA", {
	locks={LOCKS.ISLAND2},
	keys_given={KEYS.ISLAND3},
	--region_id = "hoodedforest",
	level_set_piece_blocker = true,
	room_choices={
		["GiantTrees"] = 1,
		["RoseGarden"] = 1,
		["AphidLand"] = 1,
		--["RoadGiantTrees"] = 1,
		--["WalrusGiantTrees"] = 1,
		--["MoonBaseGiantTrees"] = 1,
		["ShroomInfestedGiantTrees"] = 1,
		["SnapDragons"] = 1,
		["SpideryGiantTrees"] = 1,
		["HoodedTown"] = 1,
		["HFHolidays"] = 1,
		--["QuestionableDecisions"] = 1,
	},
	room_bg=WORLD_TILES.HOODEDFOREST,
	background_room="BGGiantTrees",
	colour={r=.1,g=.1,b=.1,a=1}
})

AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.name == GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.SHIPWRECKED then
		-- IA Giant Trees
		if GetModConfigData("hoodedforest") then
			table.insert(tasksetdata.tasks, "GiantTrees_IA")
		end
	end
end)


end

