-- Merge the content from both deserts into Lightning Bluff, which is the Oasis desert

-- Redux the Lightning Bluff Task -- Oasis Renovation - Give Oasis versions of several Badlands rooms, but they can have sandstorm
AddTaskPreInit("Lightning Bluff", function(task)
	GLOBAL.require("map/rooms/forest/UM_LightningBluff")
	task.room_choices["LightningBluff_Scorpion"] = function() return math.random(3, 4) end

	task.room_choices["BarePlain_Oasis"] = 1
	task.room_choices["Houndy_Oasis"] = 1 
	--task.room_choices["Badlands_Oasis"] = 1
	--task.room_choices["BuzzardyBadlands_Oasis"] = 1 
	task.room_choices["BGLightningBluff"] = 0 -- No more BGLightningBluff
	task.background_room = "BGBadlands_Oasis"
end)

-- Room tag adjustments, mainly get rid of road poison...
AddRoomPreInit("LightningBluffLightning", function(room) 
	room.tags = {"sandstorm"}
end)
AddRoomPreInit("LightningBluffAntlion", function(room)
	room.tags = {"sandstorm"}
end)

AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "forest" then
		return
	end
	
	-- Enable several setpieces to spawn within the merged desert
	table.insert(tasksetdata.set_pieces["ResurrectionStone"].tasks,"Lightning Bluff") 
	table.insert(tasksetdata.set_pieces["WormholeGrass"].tasks,"Lightning Bluff")
	table.insert(tasksetdata.set_pieces["CaveEntrance"].tasks,"Lightning Bluff") 
end)