AddRoom("LivingDeepForest", {
					colour={r=0,g=.9,b=0,a=.50},
					value = WORLD_TILES.FOREST,
					tags = {"ExitPiece", "Chester_Eyebone","Junkyard_Spawner"},
					contents =  {
									countstaticlayouts=
									{
										["LivingTree"]= 1
									},

									-- countprefabs =
									-- {
									-- 	livingtree = function() return (math.random() > TUNING.LIVINGTREE_CHANCE and 1) or 0 end
									-- },
					                distributepercent = .8,
					                distributeprefabs=
					                {
                                        fireflies = 0.1,
										--evergreen = 6,
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

AddTaskPreInit("For a nice walk", function(task)
	task.room_choices["LivingDeepForest"] = 1
	task.room_choices["DeepForest"] = function() return math.random(GLOBAL.SIZE_VARIATION) end
end)

AddTaskSetPreInitAny(function(tasksetdata) -- Require the LivingTree
    if tasksetdata.location ~= "forest" then
        return
    end
	
    table.insert(tasksetdata.required_prefabs, "livingtree")
end)
