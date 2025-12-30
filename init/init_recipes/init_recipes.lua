local TECH = GLOBAL.TECH
local AllRecipes = GLOBAL.AllRecipes
local STRINGS = GLOBAL.STRINGS
local CRAFTING_FILTERS = GLOBAL.CRAFTING_FILTERS



-- List of Vanilla Recipe Filters
-- "FAVORITES", "CRAFTING_STATION", "SPECIAL_EVENT", "MODS", "CHARACTER", "TOOLS", "LIGHT",
-- "PROTOTYPERS", "REFINE", "WEAPONS", "ARMOUR", "CLOTHING", "RESTORATION", "MAGIC", "DECOR",
-- "STRCUTURES", "CONTAINERS", "COOKING", "GARDENING", "FISHING", "SEAFARING", "RIDING",
-- "WINTER", "SUMMER", "RAIN", "EVERYTHING"

--- Change the sort key of an existing recipe in a particular crafting filter.
--- Note: Recipes are automatically added to the end of a crafting filter tab
--- when the function AddRecipe2 is used. -- KoreanWaffles
-- @recipe_name: (str) the recipe to sort
-- @recipe_reference:(str) the recipe to place the given recipe next to
-- @filter: (str) the crafting filter to sort in
-- @after: (bool) whether the recipe should be sorted after the references
--vscode param defs
---@param recipe_name string the recipe to sort
---@param recipe_reference string the recipe to place the given recipe next to
---@param filter string the crafting filter to sort in
---@param after boolean whether the recipe should be sorted after the references
function ChangeSortKey(recipe_name, recipe_reference, filter, after)
    local recipes = CRAFTING_FILTERS[filter].recipes
    local recipe_name_index
    local recipe_reference_index

    for i = #recipes, 1, -1 do
        if recipes[i] == recipe_name then
            recipe_name_index = i
        elseif recipes[i] == recipe_reference then
            recipe_reference_index = i + (after and 1 or 0)
        end
        if recipe_name_index and recipe_reference_index then
            if recipe_name_index >= recipe_reference_index then
                table.remove(recipes, recipe_name_index)
                table.insert(recipes, recipe_reference_index, recipe_name)
            else
                table.insert(recipes, recipe_reference_index, recipe_name)
                table.remove(recipes, recipe_name_index)
            end
            break
        end
    end
end

-- NEW Vets Curse Item Recipes
local TechTree = require("techtree")
table.insert(TechTree.AVAILABLE_TECH, "VETERANSHRINE")

for k, v in pairs(TUNING.PROTOTYPER_TREES) do
    v.VETERANSHRINE = 0
end

for k, v in pairs(AllRecipes) do
    v.level.VETERANSHRINE = 0
end

TECH.NONE.VETERANSHRINE = 0

TECH.VETERANSHRINE_ONE = { VETERANSHRINE = 1 }

TUNING.PROTOTYPER_TREES.VETERANSHRINE_ONE = TechTree.Create({
    VETERANSHRINE = 1,
})

-- [ PROTOTYPERS ] --
GLOBAL.PROTOTYPER_DEFS.critterlab_real = GLOBAL.PROTOTYPER_DEFS.critterlab

AddPrototyperDef(
    "um_bombmixer",
    {
        icon_atlas = GLOBAL.CRAFTING_ICONS_ATLAS,
        icon_image = "station_madscience_lab.tex",
        is_crafting_station = true,
        action_str = "BOMBMIXER",
        filter_text = STRINGS.UI.CRAFTING_STATION_FILTERS.MADSCIENCE
    }
)

modimport("init/init_recipes/recipes")
modimport("init/init_recipes/recipe_changes")
if GetModConfigData("wixie_walter") then
    modimport("init/init_recipes/recipes_wixie")
end
modimport("init/init_recipes/recipes_ia")
modimport("init/init_recipes/ingredient_ui")
