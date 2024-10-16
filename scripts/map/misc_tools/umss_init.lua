-- Add UMSS to the world!

-- [Forest UMSS] --
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.name == GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.DEFAULT or tasksetdata.name == GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.CLASSIC then
		local Layouts = GLOBAL.require("map/layouts").Layouts
		local StaticLayout = GLOBAL.require("map/static_layout")
		Layouts["umss_biometable"] = StaticLayout.Get("map/static_layouts/umss_biometable")
		tasksetdata.set_pieces["umss_biometable"] = {
		count = math.random(3, 5),
		tasks = {
			"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters", "For a nice walk", "Badlands", "Lightning Bluff", "Befriend the pigs", "Kill the spiders",
				"Killer bees!", "Make a Beehat",  "The hunters", "Magic meadow", "Frogs and bugs", "Mole Colony Deciduous", "Mole Colony Rocks", "MooseBreedingTask","Speak to the king classic",},
		}
	end
end)