local env = env
GLOBAL.setfenv(1, GLOBAL)

local IngredientUI = require("widgets/ingredientui")

local GEM_DEFS = require("gemology_defs").GEM_DEFS

local __ctor = IngredientUI._ctor
function IngredientUI._ctor(self, atlas, image, quantity, on_hand, has_enough, name, owner, recipe_type, quant_text_scale, ingredient_recipe, ...)
    __ctor(self, atlas, image, quantity, on_hand, has_enough, name, owner, recipe_type, quant_text_scale, ingredient_recipe, ...)

    if recipe_type and GEM_DEFS[recipe_type] ~= nil then
        local learned, tier = TheMineralLogbook:IsGemKnown(recipe_type)
        local color = "DEFAULT"

        if string.find(recipe_type, "um_gemology") ~= nil then --just UM has the color stuff idk if any addons will apply, so we'll use the default.
            color = string.upper(string.gsub(string.gsub(recipe_type, "um_gemology", ""), "gem%d", ""))
        end

        if not learned or tier <= 0 then
            self:SetTooltip(STRINGS.NAMES.UM_GEMOLOGYGEM_UNKNOWN[color])
        end
    end
end