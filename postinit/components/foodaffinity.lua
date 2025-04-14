--[[
Documentation: KoreanWaffles

-- favorite_foods is a table storing key-value pairs mapping a character's
-- favorite foods to their bonus sanity values (characters gain bonus sanity
-- from eating their favorite foods).

-- An example of how to specify multiple favorite foods with specific bonus sanity values.
-- Adds Breakfast Skillet, Honey Ham, and Tall Scotch Eggs as Wilson's favorite foods
-- with bonus sanity values of 10, 20, and 50 respectively.
AddPrefabPostInit("wilson", function(inst)
    inst.components.foodaffinity.favorite_foods = {
        ["veggieomlet"] = 10,
        ["honeyham"] = 20,
        ["talleggs"] = 50,
    }
end)

-- favorite_food_fn can specify more complex ways to check if a food is a
-- character's favorite food. favorite_food_fn should be a function that 
-- takes a food as an argument and returns whether that food is this 
-- character's favorite food or not.

-- An example of how to define an favorite_food_fn function.
-- Adds all dried food as Walter's favorite foods.
AddPrefabPostInit("walter", function(inst)
    inst.components.foodaffinity.favorite_food_fn = function(food)
        -- dried foods don't have any identifying tags
        -- but do have a common naming convention.
        return string.sub(food.prefab, -6) == "_dried"
    end
end)
]]

if not GLOBAL.TheNet:GetIsServer() then return end

AddComponentPostInit("foodaffinity", function(self)
    self.favorite_foods = {}
    self.favorite_food_fn = nil
    -- All foods defined in favorite_foods will be initialized using
    -- Klei's food affinity system for mod compatibility. Unfortunately,
    -- there's no good way to do this with favorite_food_fn since
    -- the prefab name needs to be known beforehand.
    self.inst:DoTaskInTime(0, function(inst)
        for food, bonus_sanity in pairs(self.favorite_foods) do
            self:AddPrefabAffinity(food, 1)
        end
    end)
end)

AddPrefabPostInit("wilson", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["baconeggs"] = 15,
    }
end)

AddPrefabPostInit("willow", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["hotchili"] = 15,
    }
end)

AddPrefabPostInit("wolfgang", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["potato_cooked"] = 15,
    }
end)

AddPrefabPostInit("wendy", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["bananapop"] = 15,
    }
end)

AddPrefabPostInit("wx78", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["butterflymuffin"] = 15,
    }
end)

AddPrefabPostInit("wickerbottom", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["surfnturf"] = 15,
    }
end)

AddPrefabPostInit("woodie", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["honeynuggets"] = 15,
    }
end)

AddPrefabPostInit("wes", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["freshfruitcrepes"] = 15,
    }
end)

AddPrefabPostInit("waxwell", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["lobsterdinner"] = 15,
    }
end)

AddPrefabPostInit("wathgrithr", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["turkeydinner"] = 15,
    }
end)

AddPrefabPostInit("webber", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["icecream"] = 15,
    }
end)

AddPrefabPostInit("winona", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["vegstinger"] = 15,
    }
end)

AddPrefabPostInit("wortox", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["pomegranate"] = 15,
		["pomegranate_cooked"] = 15,
		["devilsfruitcake"] = 15,
    }
end)

AddPrefabPostInit("wormwood", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["cave_banana_cooked"] = 15,
    }
end)

AddPrefabPostInit("wurt", function(inst)
    inst.components.foodaffinity.favorite_foods = {
		["durian"] = 15,
		["durian_cooked"] = 15,
    }
end)

AddPrefabPostInit("walter", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["smallmeat_dried"] = 15,
        ["meat_dried"] = 15,
        ["kelp_dried"] = 15,
		["smallfishmeat_dried"] = 15,
		["fishmeat_dried"] = 15,
		["trailmix"] = 15,
    }
end)

AddPrefabPostInit("wanda", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["taffy"] = 15,
    }
end)

AddPrefabPostInit("wathom", function(inst)
    inst.components.foodaffinity.favorite_foods = {
		["um_kebab"] = 15,
    }
end)

AddPrefabPostInit("winky", function(inst)
    inst.components.foodaffinity.favorite_foods = {
		["powcake"] = 0,
    }
end)

AddPrefabPostInit("wixie", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["blueberrypancakes"] = 15,
    }
end)

AddPrefabPostInit("wonkey", function(inst)
    inst.components.foodaffinity.favorite_foods = {
	    ["cave_banana"] = 15,
    }
end)
