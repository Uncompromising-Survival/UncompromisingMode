local env = env
GLOBAL.setfenv(1, GLOBAL)

-- This code probably can be run outside of this postinit.


env.AddComponentPostInit("cooking", function(self)

	require "tuning"

	local official_foods = {}
	
	local cooking = require "cooking"
	
	function AddCookerRecipe(cooker, recipe)
		cooking.recipes[cooker][recipe.name] = recipe
	end

	local foods = require("preparedfoods")
	for k,recipe in pairs (foods) do
		AddCookerRecipe("um_cookpot_wagstaff", recipe)
	end

end)
