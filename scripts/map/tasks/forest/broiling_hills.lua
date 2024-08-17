-- Broiling Hills replaces the "Badlands" task. In DST layman's speak this dragonfly desert

-- New StaticLayouts
local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
Layouts["boilingfields_dragonfly_arena"] = StaticLayout.Get("map/static_layouts/boilingfields_dragonfly_arena")
Layouts["cave_entrance_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_entrance_magmabiome")

-- Task overhaul
AddTaskPreInit("Badlands", function(task)
	GLOBAL.require("map/rooms/forest/UM_BoilingFields")
	
	
	-- Room removal! lots of desert things are gone now! Make room for hot springs
	task.room_choices["Badlands"] = 0 
	task.room_choices["BarePlain"] = 0 
	task.room_choices["BuzzardyBadlands"] = 0 
	task.room_choices["HoundyBadlands"] = 0 
	task.room_choices["DragonflyArena"] = 0 

	task.room_choices["BoilingFields_Crabby"] = 1 -- Crabs
	task.room_choices["BoilingFields_Hotsprings"] = 1 -- Hotsprings
	task.room_choices["BoilingFields_Rocky"] = 1 -- Snaildrakes
	task.room_choices["BoilingFields_BasaltHounds"] = 2-- Hounds
	task.room_choices["BoilingFields_DragonflyArena"] = 1 -- Dfly
	task.room_choices["BoilingFields_Sinkhole"] = 1 -- Sinkhole
	task.background_room = "BoilingFields_Hotsprings"
	
	
end)

-- Setpiece adjustments
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "forest" then 
		return
	end
	
	
	local target_task = "Badlands"
	local remove_setpiece_list = {"ResurrectionStone","WormholeGrass","CaveEntrance"} -- Ensure these setpieces cannot spawn in hooded forest, they aren't prevented by level_set_piece_blocker
	for j,setpiece in ipairs(remove_setpiece_list) do
		for i,task in ipairs(tasksetdata.set_pieces[setpiece].tasks) do
			if task == target_task then
				table.remove(tasksetdata.set_pieces[setpiece].tasks,i)
			end
		end
	end

	-- Add required prefabs
	table.insert(tasksetdata.required_prefabs, "dragonfly_spawner")
	table.insert(tasksetdata.required_prefabs, "cave_entrance_magmabiome")	
end)


