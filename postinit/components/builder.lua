local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local TechTree = require("techtree")

local PROTOTYPER_TAGS = {"prototyper"}

local BLOCKCRAFTING_FNNAMES = {"MakeRecipeFromMenu", "MakeRecipeAtPoint", "BufferBuild"}
local function CraftCancellingBlockout(self, fnname)
    local _OldFunction = self[fnname]
    self[fnname] = function(self, ...)
        if self.inst.sg and self.inst.sg:HasStateTag("busy") then return end
        return _OldFunction(self, ...)
    end
end

local old_ischaringred = IsCharacterIngredient
IsCharacterIngredient = function(ingredienttype)
	return ingredienttype == CHARACTER_INGREDIENT.HUNGER or old_ischaringred(ingredienttype)
end

CHARACTER_INGREDIENT.HUNGER = "decrease_hunger"

env.AddComponentPostInit("builder", function(self)
    for num, tag in pairs(self.exclude_tags) do
        if tag == "bookbuilder" then
            table.remove(self.exclude_tags, num)
            break
        end
    end

    for _, fnname in pairs(BLOCKCRAFTING_FNNAMES) do
        CraftCancellingBlockout(self, fnname)
    end

    -- The code below up until the AddClassPostConstruct("components/builder_replica") is all from the character mod "The Sniper (DST)"
    -- I had no idea how to do this on my own so all credits goes to Daniel. -Carlos
    local old_haschar = self.HasCharacterIngredient
	function self:HasCharacterIngredient(ingredient)
		if ingredient.type == CHARACTER_INGREDIENT.HUNGER then
			if self.inst.components.hunger then
				local current = math.ceil(self.inst.components.hunger.current)
				return current >= ingredient.amount, current
			end
		else
			return old_haschar(self, ingredient)
		end
	end

	local old_remove = self.RemoveIngredients
	function self:RemoveIngredients(ingredients, recname)
		old_remove(self, ingredients, recname)

		local recipe = AllRecipes[recname]
		if recipe then
			for k, v in pairs(recipe.character_ingredients) do
				if v.type == CHARACTER_INGREDIENT.HUNGER then
					self.inst.components.hunger:DoDelta(-v.amount)
				end
			end
		end
	end
end)

env.AddClassPostConstruct("components/builder_replica", function(self)
	local old_haschar = self.HasCharacterIngredient
	function self:HasCharacterIngredient(ingredient)
		if ingredient.type == CHARACTER_INGREDIENT.HUNGER then
			if self.inst.components.builder then
				return self.inst.components.builder:HasCharacterIngredient(ingredient)
			elseif self.classified then
				local hunger = self.inst.replica.hunger
				if hunger then
					local current = math.ceil(hunger:GetCurrent())
					return current >= ingredient.amount, current
				end
			end
		else
			return old_haschar(self, ingredient)
		end
		return false, 0
	end
end)