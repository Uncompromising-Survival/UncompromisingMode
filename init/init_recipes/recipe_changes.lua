local TechTree = require("techtree")
local TECH = GLOBAL.TECH
local Ingredient = GLOBAL.Ingredient
local AllRecipes = GLOBAL.AllRecipes
local CONSTRUCTION_PLANS = GLOBAL.CONSTRUCTION_PLANS

CONSTRUCTION_PLANS["multiplayer_portal_moonrock_constr"] = {
    Ingredient("moonrocknugget", 20),
    Ingredient("purplemooneye", 1),
    Ingredient("moonglass", 5)
}

AllRecipes["compass"].ingredients = { Ingredient("goldnugget", 2), Ingredient("flint", 2) }

if TUNING.DSTU.WARLY_CHANGES == 1 then
    AllRecipes["spicepack"].ingredients = { Ingredient("pigskin", 2), Ingredient("silk", 4), Ingredient("nitre", 4) }
end

if GetModConfigData("longpig") then
    AllRecipes["reviver"].ingredients = {
        Ingredient("skeletonmeat", 1),
        Ingredient("spidergland", 1)
    }

    local ghostlyelixir_fastregen = AllRecipes["ghostlyelixir_fastregen"]
    ghostlyelixir_fastregen.ingredients = {Ingredient("ghostflower", 3)}
    ghostlyelixir_fastregen.character_ingredients = {Ingredient(GLOBAL.CHARACTER_INGREDIENT.HEALTH, 40)}
end

if GetModConfigData("compostoverrot") then
    -- Rot Related Recipe Changes [AXE]
    AllRecipes["lifeinjector"].ingredients = {
        Ingredient("nitre", 2),
        Ingredient("red_cap", 6),
        Ingredient("stinger", 1),
    }
    AllRecipes["mushroom_farm"].ingredients = {
        Ingredient("compost", 4),
        Ingredient("poop", 5),
        Ingredient("livinglog", 2),
    }
    AllRecipes["compostwrap"].ingredients = {
        Ingredient("poop", 5),
        Ingredient("compost", 1),
        Ingredient("nitre", 1),
    }
    AllRecipes["compostingbin"].ingredients = {
        Ingredient("boards", 3),
        Ingredient("twigs", 2),
        Ingredient("cutgrass", 1),
    }

    --wormwood stuffs
    AllRecipes["ipecacsyrup"].ingredients = { Ingredient("red_cap", 1), Ingredient("honey", 1), Ingredient("compost", 1) }
    AllRecipes["wormwood_berrybush"].ingredients = { Ingredient("compost", 2), Ingredient("berries_juicy", 8) }
    AllRecipes["wormwood_berrybush2"].ingredients = { Ingredient("compost", 2), Ingredient("berries_juicy", 8) }
    AllRecipes["wormwood_juicyberrybush"].ingredients = { Ingredient("compost", 2), Ingredient("berries", 8) }

    --turf
    AllRecipes["turf_marsh"].ingredients = { Ingredient("cutreeds", 1), Ingredient("compost", 1) }
    AllRecipes["wurt_turf_marsh"].ingredients = { Ingredient("cutreeds", 1), Ingredient("compost", 1) }
end

-- Funcap Change
if GetModConfigData("funcap_fun") then
    AllRecipes["red_mushroomhat"].ingredients = {
        Ingredient("red_cap", 6),
        Ingredient("slurper_pelt", 4),
    }

    AllRecipes["green_mushroomhat"].ingredients = {
        Ingredient("green_cap", 6),
        Ingredient("slurper_pelt", 4),
    }

    AllRecipes["blue_mushroomhat"].ingredients = {
        Ingredient("blue_cap", 6),
        Ingredient("slurper_pelt", 4),
    }
end

if GetModConfigData("celestialitems_revert") then
    AllRecipes["glasscutter"].ingredients = {
        Ingredient("boards", 1),
        Ingredient("moonglass", 6),
    }
    AllRecipes["glasscutter"].nounlock = true

    AllRecipes["moonglassaxe"].nounlock = true

    AllRecipes["moon_mushroomhat"].ingredients = {
        Ingredient("moon_cap", 4),
        Ingredient("livinglog", 2),
    }
end
--woodie stuff

--local config_skilltrees = GetModConfigData("woodie_skilltree")
--if config_skilltrees then
--AllRecipes["walking_stick"].ingredients = { Ingredient("lucy", 0), Ingredient("log", 3), Ingredient("wereitem_goose", 1) }
--end

if GetModConfigData("wanda_nerf") then
    AllRecipes["pocketwatch_revive"].ingredients = {
        Ingredient("pocketwatch_parts", 3),
        Ingredient("livinglog", 2),
        Ingredient("boneshard", 4)
    }
end

if TUNING.DSTU.GOTOBED ~= false then
    AllRecipes["siestahut"].ingredients = {
        Ingredient("silk", 6),
        Ingredient("boards", 4),
        Ingredient("rope", 3)
    }
end

if GetModConfigData("beebox_nerf") then
    AllRecipes["beebox"].ingredients = {
        Ingredient("boards", 2),
        Ingredient("honeycomb", 1),
        Ingredient("bee", 2)
    }
end

AllRecipes["moonrockidol"].ingredients = {
    Ingredient("moonrocknugget", GLOBAL.TUNING.DSTU.RECIPE_MOONROCK_IDOL_MOONSTONE_COST),
    Ingredient("purplegem", 1)
}

AllRecipes["minifan"].ingredients = {
    Ingredient("twigs", 3),
    Ingredient("petals", 4)
}

AllRecipes["seedpouch"].ingredients = {
    Ingredient("slurtle_shellpieces", 2),
    Ingredient("waxpaper", 1),
    Ingredient("seeds", 2)
}

AllRecipes["catcoonhat"].ingredients = {
    Ingredient("coontail", 4),
    Ingredient("silk", 4)
}

AllRecipes["goggleshat"].ingredients = {
    Ingredient("goldnugget", 4),
    Ingredient("pigskin", 1),
    Ingredient("houndstooth", 2)
}

AllRecipes["lantern"].level = TechTree.Create(TECH.SCIENCE_ONE)

AllRecipes["saddle_race"].ingredients = {
    Ingredient("livinglog", 2),
    Ingredient("silk", 4),
    Ingredient("glommerwings", 1)
}



AllRecipes["walterhat"].ingredients = {
    Ingredient("silk", 4),
    Ingredient("pinecone", 1)
}

--if GetModConfigData("wicker_inv_regen") ~= "vanilla" then
    --AllRecipes["bookstation"].ingredients = {
        --Ingredient("boards", 4),
        --Ingredient("papyrus", 4),
        --Ingredient("featherpencil", 1)
    --}
--end

--if GetModConfigData("applied horticulture") then
    --AllRecipes["book_horticulture"].ingredients = {
        --Ingredient("papyrus", 2),
        --Ingredient("plantmeat", 1),
        --Ingredient("poop", 5)
    --}
--end

--if GetModConfigData("horticulture, expanded") then
    --AllRecipes["book_horticulture_upgraded"].ingredients = {
        --Ingredient("book_horticulture", 1),
        --Ingredient("treegrowthsolution", 1),
        --Ingredient("papyrus", 2)
    --}
--end

--if GetModConfigData("the angler") then
    --AllRecipes["book_fish"].ingredients = {
        --Ingredient("papyrus", 2),
        --Ingredient("oceanfishingbobber_oval", 2)
    --}
--end

--if GetModConfigData("lux aeterna") then
    --AllRecipes["book_light_upgraded"].ingredients = {
        --Ingredient("book_light", 1),
        --Ingredient("wormlight", 1),
        --Ingredient("papyrus", 2)
    --}
--end

if TUNING.DSTU.WICKERCHANGES == 2 then
    AllRecipes["book_moon"].ingredients = {
        Ingredient("papyrus", 2),
        Ingredient("moonrocknugget", 2),
        Ingredient("moon_cap", 2)
    }
end

--if GetModConfigData("apicultural notes") then
    --AllRecipes["book_bees"].ingredients = {
        --Ingredient("papyrus", 2),
        --Ingredient("honeycomb", 1),
        --Ingredient("stinger", 8)
    --}
--end

-- magnets and dock
if GetModConfigData("no4crafts") then -- :desolate:
    AllRecipes["dock_kit"].ingredients = {
        Ingredient("boards", 4),
        Ingredient("stinger", 2),
        Ingredient("palmcone_scale", 4)
    }
    --[[AllRecipes["boat_magnet_kit"].ingredients = {
     Ingredient("gears", 1),
     Ingredient("transistor", 2),
     Ingredient("um_copper_pipe", 3)--copper isn't fucking obtainable yet what the fuck
}
AllRecipes["boat_magnet_beacon"].ingredients = {
     Ingredient("messagebottleempty", 1),
     Ingredient("transistor", 1),
     Ingredient("um_copper_pipe", 1)
}]]
end

AllRecipes["boat_bumper_shell_kit"].numtogive = 4 -- 8
AllRecipes["boat_bumper_kelp_kit"].numtogive = 4  -- 8
AllRecipes["boat_bumper_shell_kit"].ingredients = {
    Ingredient("slurtle_shellpieces", 3),
    Ingredient("rope", 3)
}
AllRecipes["boat_bumper_kelp_kit"].ingredients = {
    Ingredient("kelp", 3),
    Ingredient("cutgrass", 6)
}

if TUNING.DSTU.ISLAND_ADVENTURES_CLIENT then
    AllRecipes["boat_bumper_limestone_kit"].numtogive = 4
end

if TUNING.DSTU.WOLFGANG_HUNGERMIGHTY then
    AllRecipes["mighty_gym"].ingredients = { Ingredient("boards", 4), Ingredient("cutstone", 2), Ingredient("rope", 3) }
    AllRecipes["dumbbell"].ingredients = { Ingredient("rocks", 4), Ingredient("twigs", 1) }
    AllRecipes["dumbbell_golden"].ingredients = {
        Ingredient("goldnugget", 2),
        Ingredient("cutstone", 2),
        Ingredient("twigs", 2)
    }
    AllRecipes["dumbbell_gem"].ingredients = {
        Ingredient("purplegem", 1),
        Ingredient("cutstone", 2),
        Ingredient("twigs", 2)
    }
end

if TUNING.DSTU.WATHGRITHR_REWORK.ENABLED then
    AllRecipes["battlesong_shadowaligned"] = nil
    --AllRecipes["battlesong_lunaraligned"] = nil
    --AllRecipes["battlesong_shadowaligned"].builder_skill ="wathgrithr_allegiance_lunar"  
    AllRecipes["battlesong_lunaraligned"].builder_skill ="wathgrithr_allegiance_lunar"  
    AllRecipes["battlesong_container"].ingredients = { 
        Ingredient("boards", 2), 
        Ingredient("goldnugget", 4), 
        Ingredient("beeswax", 2) 
    }
    AllRecipes["battlesong_fireresistance"].ingredients = {
        Ingredient("papyrus", 1),
        Ingredient("featherpencil", 1),
        Ingredient("dragon_scales", 1)
    }
end

if GetModConfigData("telestaff_rework") then
    AllRecipes["telebase"].ingredients = {
        Ingredient("nightmarefuel", 4),
        Ingredient("livinglog", 4),
        Ingredient("goldnugget", 8),
        Ingredient("purplegem", 3)
    }
    --AllRecipes["telestaff"].ingredients = {
    --Ingredient("nightmarefuel", 2),
    --Ingredient("spear", 1),
    --Ingredient("purplegem", 1)
    --}
    AllRecipes["purpleamulet"].ingredients = {
        Ingredient("goldnugget", 3),
        Ingredient("nightmarefuel", 2),
        Ingredient("purplegem", 1)
    }
end

--I HATE FRAZZLED WIRES!!!!!!!!
AllRecipes["boat_magnet_kit"].ingredients = { Ingredient("boards", 2), Ingredient("cutstone", 2), Ingredient("transistor", 1), Ingredient("wagpunk_bits", 1) }
AllRecipes["boat_magnet"].ingredients = { Ingredient("boards", 2), Ingredient("cutstone", 2), Ingredient("transistor", 1), Ingredient("wagpunk_bits", 1) }
AllRecipes["boat_magnet_beacon"].ingredients = { Ingredient("cutstone", 2), Ingredient("transistor", 1), Ingredient("wagpunk_bits", 1) }

AllRecipes["anchor_item"].ingredients = { Ingredient("boards", 2), Ingredient("rope", 2), Ingredient("cutstone", 1) }
AllRecipes["anchor"].ingredients = { Ingredient("boards", 2), Ingredient("rope", 2), Ingredient("cutstone", 1) }

AllRecipes["steeringwheel_item"].ingredients = {Ingredient("boards", 1), Ingredient("twigs", 4), Ingredient("rope", 1)}
AllRecipes["steeringwheel"].ingredients = {Ingredient("boards", 1), Ingredient("twigs", 4), Ingredient("rope", 1)}

AllRecipes["mast_item"].ingredients = { Ingredient("log", 3), Ingredient("rope", 2), Ingredient("silk", 3) }
AllRecipes["mast"].ingredients = { Ingredient("log", 2), Ingredient("rope", 2), Ingredient("silk", 3) }

AllRecipes["mast_malbatross_item"].ingredients = {
    Ingredient("driftwood_log", 4),
    Ingredient("rope", 2),
    Ingredient("malbatross_feathered_weave", 3)
}
AllRecipes["mast_malbatross"].ingredients = {
    Ingredient("driftwood_log", 4),
    Ingredient("rope", 2),
    Ingredient("malbatross_feathered_weave", 3)
}

AllRecipes["winona_spotlight"].ingredients = { Ingredient("sewing_tape", 1), Ingredient("goldnugget", 2), Ingredient("lightbulb", 1) }
AllRecipes["winona_spotlight_item"].ingredients = { Ingredient("sewing_tape", 1), Ingredient("goldnugget", 2), Ingredient("lightbulb", 1) }

AllRecipes["featherpencil"].numtogive = 4 -- 8

AllRecipes["armorwagpunk"].ingredients = { Ingredient("armorwood", 1), Ingredient("wagpunk_bits", 8), Ingredient("transistor", 2) }
AllRecipes["wagpunkhat"].ingredients = { Ingredient("footballhat", 1), Ingredient("wagpunk_bits", 8), Ingredient("transistor", 2) }
AllRecipes["fence_electric_item"].ingredients = { Ingredient("wagpunk_bits", 6), Ingredient("moonglass_charged", 6), Ingredient("moonstorm_spark", 6) }

-- Wormwood Crafts
if GetModConfigData("wormwood_trapbuffs") then
    GLOBAL.GetValidRecipe("trap_bramble").numtogive = 2
end

-- trident buff
AllRecipes["trident"].ingredients = { Ingredient("boneshard", 2), Ingredient("gnarwail_horn", 1), Ingredient("twigs", 4) }

if GetModConfigData("pocket_powertrip_") then
    AddRecipeToFilter("raincoat", "CONTAINERS")
    ChangeSortKey("raincoat", "sporepack", "CONTAINERS", true)

    AddRecipeToFilter("reflectivevest", "CONTAINERS")
    ChangeSortKey("reflectivevest", "sporepack", "CONTAINERS", true)

    AddRecipeToFilter("hawaiianshirt", "CONTAINERS")
    ChangeSortKey("hawaiianshirt", "sporepack", "CONTAINERS", true)

    AddRecipeToFilter("trunkvest_winter", "CONTAINERS")
    ChangeSortKey("trunkvest_winter", "sporepack", "CONTAINERS", true)

    AddRecipeToFilter("trunkvest_summer", "CONTAINERS")
    ChangeSortKey("trunkvest_summer", "sporepack", "CONTAINERS", true)
end

AddRecipeToFilter("wardrobe", "CONTAINERS")
ChangeSortKey("wardrobe", "icebox", "CONTAINERS", false)

AddRecipeToFilter("tophat", "MAGIC")
ChangeSortKey("tophat", "tophat_magician", "MAGIC", false)
if GetModConfigData("snowstorms") then
    AddRecipeToFilter("wall_hay_item", "WINTER")
    ChangeSortKey("wall_hay_item", "dragonflyfurnace", "WINTER", true)
    AddRecipeToFilter("wall_wood_item", "WINTER")
    ChangeSortKey("wall_wood_item", "wall_hay_item", "WINTER", true)
    AddRecipeToFilter("wall_stone_item", "WINTER")
    ChangeSortKey("wall_stone_item", "wall_wood_item", "WINTER", true)
    AddRecipeToFilter("wall_scrap_item", "WINTER")
    ChangeSortKey("wall_scrap_item", "wall_stone_item", "WINTER", true)
    AddRecipeToFilter("wall_moonrock_item", "WINTER")
    ChangeSortKey("wall_moonrock_item", "wall_scrap_item", "WINTER", true)
    AddRecipeToFilter("wall_dreadstone_item", "WINTER")
    ChangeSortKey("wall_dreadstone_item", "wall_moonrock_item", "WINTER", true)
end

AllRecipes["seafaring_prototyper"].ingredients = { Ingredient("transistor", 1), Ingredient("boards", 1) }

AllRecipes["woby_treat"].numtogive = 1

if not TUNING.DSTU.EYEBRELLAREWORK then
    ChangeSortKey("eyebrellahat", "strawhat", "SUMMER", true)
end

ChangeSortKey("tillweedsalve", "um_feather_totem", "RESTORATION", true)
AddRecipeToFilter("trunkvest_summer", "RAIN")
ChangeSortKey("trunkvest_summer", "armor_sharksuit_um", "RAIN", false)
AddRecipeToFilter("reflectivevest", "RAIN")
ChangeSortKey("reflectivevest", "um_armor_pyre_nettles", "RAIN", true)

if TUNING.DSTU.SHAVE_MODE then
    AllRecipes["razor"].level = TechTree.Create(TECH.NONE)
end

AllRecipes["blowdart_pipe"].numtogive = TUNING.DSTU.DART_YIELD
AllRecipes["blowdart_fire"].numtogive = TUNING.DSTU.DART_YIELD
AllRecipes["blowdart_sleep"].numtogive = TUNING.DSTU.DART_YIELD
AllRecipes["blowdart_yellow"].numtogive = TUNING.DSTU.DART_YIELD

----BIG WATHOM ANCIENT KINSHIP I SECTION----
AllRecipes["thulecite"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["thulecite"].forward_ingredients = {"wathom_thulecite"}
AllRecipes["nightmare_timepiece"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["nightmare_timepiece"].forward_ingredients = {"wathom_nightmare_timepiece"}
AllRecipes["wall_ruins_item"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["wall_ruins_item"].forward_ingredients = {"wathom_wall_ruins_item"}
AllRecipes["orangeamulet"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["orangeamulet"].forward_ingredients = {"wathom_orangeamulet"}
AllRecipes["yellowamulet"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["yellowamulet"].forward_ingredients = {"wathom_yellowamulet"}
AllRecipes["greenamulet"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["greenamulet"].forward_ingredients = {"wathom_greenamulet"}
AllRecipes["orangestaff"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["orangestaff"].forward_ingredients = {"wathom_orangestaff"}
AllRecipes["yellowstaff"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["yellowstaff"].forward_ingredients = {"wathom_yellowstaff"}
AllRecipes["greenstaff"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["greenstaff"].forward_ingredients = {"wathom_greenstaff"}
AllRecipes["multitool_axe_pickaxe"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["multitool_axe_pickaxe"].forward_ingredients = {"wathom_multitool_axe_pickaxe"}
AllRecipes["nutrientsgoggleshat"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["nutrientsgoggleshat"].forward_ingredients = {"wathom_nutrientsgoggleshat"}
AllRecipes["ruinshat"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["ruinshat"].forward_ingredients = {"wathom_ruinshat"}
AllRecipes["armorruins"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["armorruins"].forward_ingredients = {"wathom_armorruins"}
AllRecipes["ruins_bat"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["ruins_bat"].forward_ingredients = {"wathom_ruins_bat"}
AllRecipes["eyeturret_item"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["eyeturret_item"].forward_ingredients = {"wathom_eyeturret_item"}
AllRecipes["shadow_forge_kit"].no_builder_skill = "wathom_allegiance_neutral"
AllRecipes["shadow_forge_kit"].forward_ingredients = {"wathom_shadow_forge_kit"}
AllRecipes["blueprint_craftingset_ruins_builder"].no_builder_skill = "wathom_allegiance_neutral"
--AllRecipes["blueprint_craftingset_ruins_builder"].forward_ingredients = {"wathom_blueprint_craftingset_ruins_builder"}
AllRecipes["blueprint_craftingset_ruinsglow_builder"].no_builder_skill = "wathom_allegiance_neutral"
--AllRecipes["blueprint_craftingset_ruinsglow_builder"].forward_ingredients = {"wathom_blueprint_craftingset_ruinsglow_builder"}