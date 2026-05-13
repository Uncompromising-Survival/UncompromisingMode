AddTaskPreInit("Speak to the king", function(task)
	task.room_choices={
			["MagicalDeciduous"] = 1,
			["DeepDeciduous"] = function() return 3 + math.random(3) end,
			["PigKingdom"] = 1,
		} -- reorder...
end)
