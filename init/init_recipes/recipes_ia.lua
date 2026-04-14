local Ingredient = GLOBAL.Ingredient
local AllRecipes = GLOBAL.AllRecipes

--TODO: replace with actual mod check.
if GLOBAL.NAUGHTY_VALUE["ballphin"] ~= nil then
    local RECIPE_GAMETYPE_DEFS = require("prefabs/recipe_gametype_defs")
    local RECIPE_GAME_TYPE = GLOBAL.RECIPE_GAME_TYPE
    local RECIPE_BOAT_TYPE = GLOBAL.RECIPE_BOAT_TYPE

    local VALID_FOR_ROG_ONLY = {
        -- Sludge
        "boat_bumper_sludge_kit",
        "boatpatch_sludge",
        "sludge_sack",
        "sludge_oil",
        "sludge_cork",
        "cannonball_sludge_item",
        -- Toadstool
        "sporepack",
        "air_conditioner",
        "shroom_skin",
        -- Rime and winter stuff
        "um_rimeweed_icepack",
        "um_armor_bramble_rimeweed",
        "um_blowdart_rime",
        "um_ice_sicle",
        "um_hat_rime",
        "saltpack",
        "snowgoggles",
        -- Magma caves
        --"um_fyre_bomb",
        "um_detonator",
        -- Lunar bees
        "um_beemine_moon_item",
        "um_hat_bee_moon",
        "um_eyebalm",
        -- Sea stuff
        "driftwoodfishingrod",
        "armor_sharksuit_um",
        "houndious_observious",
        "beakbasher",
        -- Cactus flowers
        "floral_bandage",
        "diseasecurebomb",

        "slingshotammo_goop",
        "slingshotammo_slime",
        "slingshotammo_tremor",

        -- Shadow Rifts
        "wathgrithr_shield_dreadstone",

        -- pyre stuff
        --"um_armor_pyre_nettles", tteeeeechnically still craftable.
        --"um_blowdart_pyre"

        -- Scrap
        -- winona can craft these, plus content expansion mod adds the scrapyard
        --"um_magnerang",
        --"winona_upgradekit_electrical",
        -- "scrap_monoclehat",
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

    SetRecipeIngredientsForGameTypes("portableboat_item", RECIPE_GAME_TYPE.SW, { Ingredient("mosquitosack_yellow", 2), Ingredient("rope", 2) })                                      --TODO: replace sacks with shark fins.
    SetRecipeIngredientsForGameTypes("slingshot_gnasher", RECIPE_GAME_TYPE.SW, { Ingredient("livinglog", 1), Ingredient("nightmarefuel", 2), Ingredient("mosquitosack_yellow", 2) }) --TODO: replace sacks with shark fins.
    SetRecipeIngredientsForGameTypes("slingshot_matilda", RECIPE_GAME_TYPE.SW, { Ingredient("ox_horn", 1), Ingredient("vine", 2), Ingredient("mosquitosack_yellow", 3) })            --TODO: replace sacks with shark fins.
    SetRecipeIngredientsForGameTypes("slingshotammo_rubber", RECIPE_GAME_TYPE.SW, { Ingredient("mosquitosack_yellow", 1) })                                                          --TODO: replace sacks with shark fins.
    SetRecipeIngredientsForGameTypes("gasmask", RECIPE_GAME_TYPE.SW, { Ingredient("doydoyfeather", 10), Ingredient("red_cap", 2), Ingredient("pigskin", 2) })

    SetRecipeIngredientsForGameTypes("um_record_menu", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_wixie", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_walter", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_wathom", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_winky", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_hooded_widow", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })
    SetRecipeIngredientsForGameTypes("um_record_stranger", RECIPE_GAME_TYPE.SW, { Ingredient("dorsalfin", 2) })

    SetRecipeIngredientsForGameTypes("brine_balm", RECIPE_GAME_TYPE.SW, { Ingredient("saltrock", 2), Ingredient("seaweed", 1) })
    SetRecipeIngredientsForGameTypes("winona_spotlight", RECIPE_GAME_TYPE.SW, { Ingredient("sewing_tape", 1), Ingredient("goldnugget", 2), Ingredient("bioluminescence", 1) })
    SetRecipeIngredientsForGameTypes("winona_spotlight_item", RECIPE_GAME_TYPE.SW, { Ingredient("sewing_tape", 1), Ingredient("goldnugget", 2), Ingredient("bioluminescence", 1) })

    SetRecipeIngredientsForGameTypes("bugzapper", RECIPE_GAME_TYPE.SW, { Ingredient("spear", 1), Ingredient("transistor", 2), Ingredient("jellyfish", 1) })

    SetRecipeIngredientsForGameTypes("scrap_monoclehat", RECIPE_GAME_TYPE.SW, { Ingredient("wagpunk_bits", 4), Ingredient("transistor", 1), Ingredient("ia_messagebottleempty", 1) })
    SetRecipeIngredientsForGameTypes("jawed_scythe", RECIPE_GAME_TYPE.SW, { Ingredient("twigs", 4), Ingredient("vine", 1), Ingredient("snappy_jaw", 3) })


    SetRecipeIngredientsForGameTypes("mast_item", RECIPE_GAME_TYPE.SW, { Ingredient("log", 3), Ingredient("rope", 2), Ingredient("fabric", 2) })
    SetRecipeIngredientsForGameTypes("mast", RECIPE_GAME_TYPE.SW, { Ingredient("log", 2), Ingredient("rope", 2), Ingredient("fabric", 2) })
end

if GLOBAL.NAUGHTY_VALUE["glowfly"] ~= nil then
    AddRecipe2("slingshotammo_scrapfeather", { Ingredient("iron", 1), Ingredient("feather_thunder", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })

    --SetRecipeIngredientsForGameTypes("slingshotammo_scrapfeather", RECIPE_GAME_TYPE.PORKLAND, { Ingredient("iron", 1), Ingredient("feather_thunder", 1) })
end
