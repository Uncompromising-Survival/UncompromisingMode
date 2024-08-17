-- All Mushroom Biome Changes

-- Toadstool Spawn Location Changes

AddRoomPreInit("RedMushPillars", function(room) -- red
	room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
end)

AddRoomPreInit("GreenMushNoise", function(room) -- green
	room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
end)
AddRoomPreInit("DropperDesolation", function(room) -- blue
	room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
end)
	
-- Remove the Toadstool Tasks from the Mud biome
AddTaskSetPreInitAny(function(tasksetdata)
	for _, task in pairs(tasksetdata.tasks) do
		if task == "ToadStoolTask1" or task == "ToadStoolTask2" or task == "ToadStoolTask3" then
			table.remove(tasksetdata.tasks, _)
		end
	end
end)

-- Insert Depths Eels in Lunar Grotto (if enabled)
if GetModConfigData("depthseels") then
	AddTaskPreInit("MoonCaveForest", function(task)
		task.room_choices["WormyMoonMushForest"] = 1
	end)
end
