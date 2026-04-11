local env = env
GLOBAL.setfenv(1, GLOBAL)

local IngredientUI = require("widgets/ingredientui")

local __ctor = IngredientUI._ctor
function IngredientUI._ctor(self, atlas, image, quantity, on_hand, has_enough, name, owner, recipe_type, quant_text_scale, ingredient_recipe, ...)
    __ctor(self, atlas, image, quantity, on_hand, has_enough, name, owner, recipe_type, quant_text_scale, ingredient_recipe, ...)

    if recipe_type and string.match(recipe_type, "um_gemology") ~= nil then
        local learned, tier = TheMineralLogbook:IsGemKnown(recipe_type)

        if not learned or tier <= 0 then
            self:SetTooltip(STRINGS.NAMES.UM_GEMOLOGYGEM_UNKNOWN)
        end
    end
end