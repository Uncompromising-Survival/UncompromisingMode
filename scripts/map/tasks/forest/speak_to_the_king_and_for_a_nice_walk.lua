-- Irrespective of the order, this task must be added for guaranteed living trees
AddRoom("LivingDeepForest", {
	colour={r=0,g=.9,b=0,a=.50},
	value = WORLD_TILES.FOREST,
	tags = {"ExitPiece", "Chester_Eyebone","Junkyard_Spawner"},
	contents =  {
		countstaticlayouts=
		{
			["LivingTree"]= 1
		},
		distributepercent = .8,
		distributeprefabs=
		{
			fireflies = 0.1,
			grass = .05,
			sapling=.5,
			twiggytree = 0.5,
			ground_twigs = 0.3,
			berrybush=.02,
			berrybush_juicy = 0.01,
			blue_mushroom = 0.02,
			trees = {weight = 6, prefabs = {"evergreen", "evergreen_sparse"}}
		},
	}

})
AddTaskSetPreInitAny(function(tasksetdata) -- Require the LivingTree
	if tasksetdata.location ~= "forest" then
		return
	end
	
	table.insert(tasksetdata.required_prefabs, "livingtree")
end)

-- 50% chance to flip their rooms around
if math.random() > 0.5 then
	AddTaskPreInit("Speak to the king", function(task)
		task.room_choices={
			["MagicalDeciduous"] = 1,
			["DeepDeciduous"] = function() return 3 + math.random(3) end,
			["PigKingdom"] = 1,
		} -- reorder...
	end)
	AddTaskPreInit("For a nice walk", function(task)
		task.room_choices["LivingDeepForest"] = 1
		task.room_choices["DeepForest"] = function() return math.random(GLOBAL.SIZE_VARIATION) end
	end)
else
	AddTaskPreInit("Speak to the king", function(task)
		task.room_choices={
			["DeepForest"] = function() return math.random(GLOBAL.SIZE_VARIATION) end,
			["Forest"] = function() return math.random(GLOBAL.SIZE_VARIATION) end,
			["PigKingdom"] = 1,
			["LivingDeepForest"] = 1,
		} -- reorder...
		task.room_bg=WORLD_TILES.FOREST
		task.background_room="BGForest"
		task.colour={r=1,g=0,b=1,a=1}
	end)
	AddTaskPreInit("For a nice walk", function(task)
		task.room_choices={
			["MagicalDeciduous"] = 1,
			["DeepDeciduous"] = function() return 3 + math.random(3) end,
			["BeefalowPlain"] = 1,
			["MandrakeHome"] = function() return 1 + math.random(GLOBAL.SIZE_VARIATION) end,
		}
		task.room_bg=WORLD_TILES.GRASS
		task.background_room="BGDeciduous"
		task.colour={r=1,g=1,b=0,a=1}
	end)
end
