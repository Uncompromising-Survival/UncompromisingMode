local Ingredient = GLOBAL.Ingredient

if GLOBAL.NAUGHTY_VALUE["glowfly"] ~= nil then
    local RECIPE_GAMETYPE_DEFS = require("prefabs/recipe_gametype_defs")
    local RECIPE_GAME_TYPE = GLOBAL.RECIPE_GAME_TYPE
    local RECIPE_BOAT_TYPE = GLOBAL.RECIPE_BOAT_TYPE

    local VALID_FOR_ROG_ONLY = {
        "boat_bumper_sludge_kit",
        "boatpatch_sludge",
        "sludge_sack",
        "armor_sharksuit_um",
        "sludge_oil",
        "sludge_cork",
        "cannonball_sludge_item",
        --"um_armor_pyre_nettles", tteeeeechnically still craftable.
        --"um_blowdart_pyre"
        "driftwoodfishingrod",
        "saltpack",
        "um_magnerang",
        "winona_upgradekit_electrical",
        "sporepack",
        "scrap_monoclehat",
        "floral_bandage",
        "um_rimeweed_icepack",
        "um_armor_bramble_rimeweed",
        "um_blowdart_rime",
        "diseasecurebomb",
        "houndious_observious",
        "terrorguise",
        "slingshotammo_goop",
        "slingshotammo_slime",
        "slingshotammo_tremor",
        "beakbasher"
    }

    local VALID_FOR_DST_BOATS_ONLY = {
        "boat_bumper_sludge_kit",
        "boatpatch_sludge",
        "mastupgrade_windturbine_item",
        "portableboat_item",
        "boat_ancient_item"
    }


    local SetRecipeIngredientsForGameTypes = RECIPE_GAMETYPE_DEFS.SetRecipeIngredientsForGameTypes
    local SetRecipeValidForBoatType = RECIPE_GAMETYPE_DEFS.SetRecipeValidForBoatType
    local SetRecipeValidForGameTypes = RECIPE_GAMETYPE_DEFS.SetRecipeValidForGameTypes

    for k, v in pairs(VALID_FOR_ROG_ONLY) do
        if AllRecipes[v] ~= nil then
            SetRecipeValidForGameTypes(v, { RECIPE_GAME_TYPE.ROG })
        end
    end

    for k, v in pairs(VALID_FOR_DST_BOATS_ONLY) do
        if AllRecipes[v] ~= nil then
            SetRecipeValidForBoatType(v, RECIPE_BOAT_TYPE.DST)
        end
    end

    SetRecipeIngredientsForGameTypes("ice", RECIPE_GAME_TYPE.SW, { Ingredient("hail_ice", 4) })
    SetRecipeIngredientsForGameTypes("ice", RECIPE_GAME_TYPE.ROG, { Ingredient("snowball_item", 4) })

    SetRecipeIngredientsForGameTypes("slingshotammo_tar", RECIPE_GAME_TYPE.SW, { Ingredient("tar", 1) })
    SetRecipeIngredientsForGameTypes("slingshotammo_tar", RECIPE_GAME_TYPE.ROG, { Ingredient("sludge", 1) })

    SetRecipeValidForGameTypes("slingshotammo_obsidian", { RECIPE_GAME_TYPE.SW })

    SetRecipeIngredientsForGameTypes("portableboat_item", RECIPE_GAME_TYPE.SW, { Ingredient("mosquitosack_yellow", 2), Ingredient("rope", 2) })
    SetRecipeIngredientsForGameTypes("slingshot_gnasher", RECIPE_GAME_TYPE.SW, { Ingredient("livinglog", 1), Ingredient("nightmarefuel", 2), Ingredient("mosquitosack_yellow", 2) })
    SetRecipeIngredientsForGameTypes("slingshot_matilda", RECIPE_GAME_TYPE.SW, { Ingredient("ox_horn", 1), Ingredient("vine", 2), Ingredient("mosquitosack_yellow", 3) })
    SetRecipeIngredientsForGameTypes("slingshotammo_rubber", RECIPE_GAME_TYPE.SW, { Ingredient("mosquitosack_yellow", 1) })
    SetRecipeIngredientsForGameTypes("gasmask", RECIPE_GAME_TYPE.SW, { Ingredient("doydoyfeather", 10), Ingredient("red_cap", 2), Ingredient("pigskin", 2) })

    SetRecipeIngredientsForGameTypes("um_record_menu", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_wixie", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_walter", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_wathom", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_winky", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_hooded_widow", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_stranger", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })

    SetRecipeIngredientsForGameTypes("brine_balm", RECIPE_GAME_TYPE.SW, { Ingredient("saltrock", 2), Ingredient("seaweed", 1) })
end

--MARKED FOR REMOVAL!! VVV REFER ABOVE FOR REPLACEMENT!
AddPrefabPostInit("forest", function(inst)
    AddRecipePostInitAny(function(recipe)
        if recipe.FindAndConvertIngredient ~= nil then
            local tar = recipe:FindAndConvertIngredient("tar")             -- tar/sludge can replace eachother!
            local sludge = recipe:FindAndConvertIngredient("sludge")
            local shark_fin = recipe:FindAndConvertIngredient("shark_fin") -- shark fins/rockjaw leather can replace eachother!
            local rockjawleather = recipe:FindAndConvertIngredient("rockjawleather")
            local mosquitosack = recipe:FindAndConvertIngredient("mosquitosack")

            if tar and tar.AddDictionaryPrefab ~= nil then
                tar:AddDictionaryPrefab("sludge")
            end

            if sludge and sludge.AddDictionaryPrefab ~= nil then
                if GLOBAL.Prefabs["tar"] ~= nil then
                    sludge:AddDictionaryPrefab("tar")
                end
            end

            if sludge and sludge.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["tar"] ~= nil then
                sludge:AddDictionaryPrefab("tar")
            end

            if shark_fin and shark_fin.AddDictionaryPrefab ~= nil then
                shark_fin:AddDictionaryPrefab("rockjawleather")
            end

            if rockjawleather and rockjawleather.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["shark_fin"] ~= nil then
                rockjawleather:AddDictionaryPrefab("shark_fin")
            end

            if mosquitosack and mosquitosack.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["mosquitosack_yellow"] then
                mosquitosack:AddDictionaryPrefab("mosquitosack_yellow")
            end
        end
    end)

    AddRecipePostInit("slingshot_matilda", function(recipe)
        if recipe.FindAndConvertIngredient ~= nil then
            local coontail = recipe:FindAndConvertIngredient("coontail")
            if coontail and coontail.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["vine"] ~= nil then
                coontail:AddDictionaryPrefab("vine")
            end

            local driftwood_log = recipe:FindAndConvertIngredient("driftwood_log")
            if driftwood_log and driftwood_log.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["ox_horn"] ~= nil then
                driftwood_log:AddDictionaryPrefab("ox_horn")
            end
        end
    end)

    AddRecipePostInit("brine_balm", function(recipe)
        if recipe.FindAndConvertIngredient ~= nil then
            local kelp = recipe:FindAndConvertIngredient("kelp")
            if kelp and kelp.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["seaweed"] ~= nil then
                kelp:AddDictionaryPrefab("seaweed")
            end
        end
    end)

    AddRecipePostInit("sludge_oil", function(recipe)
        if recipe.FindAndConvertIngredient ~= nil then
            local bottle = recipe:FindAndConvertIngredient("messagebottleempty")
            if bottle and bottle.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["ia_messagebottleempty"] ~= nil then
                bottle:AddDictionaryPrefab("ia_messagebottleempty")
            end
        end
    end)

    AddRecipePostInit("gasmask", function(recipe)
        if recipe.FindAndConvertIngredient ~= nil then
            local feather = recipe:FindAndConvertIngredient("goose_feather")
            if feather and feather.AddDictionaryPrefab ~= nil and GLOBAL.Prefabs["doydoyfeather"] ~= nil then
                feather:AddDictionaryPrefab("doydoyfeather")
            end
        end
    end)
end)
