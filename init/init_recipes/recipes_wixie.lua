local TECH = GLOBAL.TECH
local Ingredient = GLOBAL.Ingredient
local AllRecipes = GLOBAL.AllRecipes
local STRINGS = GLOBAL.STRINGS

-- WIXIE RELATED CRAFTS
AddRecipe2("the_real_charles_t_horse", { Ingredient("nightmarefuel", 2), Ingredient("cane", 1), Ingredient("gears", 1) }, TECH.LOST, nil, { "TOOLS", "CLOTHING" })
ChangeSortKey("the_real_charles_t_horse", "cane", "TOOLS", true)
ChangeSortKey("the_real_charles_t_horse", "cane", "CLOTHING", true)

AddRecipe2("slingshot_gnasher", { Ingredient("livinglog", 1), Ingredient("nightmarefuel", 2), Ingredient("mosquitosack", 2) }, TECH.MAGIC_THREE, { builder_tag = "pebblemaker" }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshot_gnasher", "slingshot", "WEAPONS", true)
ChangeSortKey("slingshot_gnasher", "slingshot", "CHARACTER", true)

AddRecipe2("slingshot_matilda", { Ingredient("driftwood_log", 1), Ingredient("coontail", 1), Ingredient("mosquitosack", 3) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker" }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshot_matilda", "slingshot_gnasher", "WEAPONS", true)
ChangeSortKey("slingshot_matilda", "slingshot_gnasher", "CHARACTER", true)

AddRecipe2("slingshot_jessie", { Ingredient("horrorfuel", 2), Ingredient("voidcloth", 2) }, TECH.SHADOWFORGING_TWO, { builder_tag = "skill_wixie_allegiance_shadow", nounlock = true, station_tag = "shadow_forge" }, { "CRAFTING_STATION", "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshot_jessie", "slingshot_matilda", "WEAPONS", true)
ChangeSortKey("slingshot_jessie", "slingshot_matilda", "CHARACTER", true)
ChangeSortKey("slingshot_jessie", "slingshotammo_gelblob", "CRAFTING_STATION", false)

AddRecipe2("slingshot_claire", { Ingredient("purebrilliance", 2), Ingredient("lunarplant_husk", 2) }, TECH.LUNARFORGING_TWO, { builder_tag = "skill_wixie_allegiance_lunar", nounlock = true, station_tag = "lunar_forge" }, { "CRAFTING_STATION", "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshot_claire", "slingshot_jessie", "WEAPONS", true)
ChangeSortKey("slingshot_claire", "slingshot_jessie", "CHARACTER", true)
ChangeSortKey("slingshot_claire", "slingshotammo_lunarplanthusk", "CRAFTING_STATION", false)

AddRecipe2("bagofmarbles", { Ingredient("slingshotammo_marble", 10), Ingredient("rope", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker" }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("bagofmarbles", "winona_catapult", "WEAPONS", false)
ChangeSortKey("bagofmarbles", "slingshotammo_container", "CHARACTER", false)

GLOBAL.GetValidRecipe("slingshotammo_rock").numtogive = 15

GLOBAL.GetValidRecipe("slingshotammo_freeze").ingredients = { Ingredient("bluegem", 1) }

GLOBAL.GetValidRecipe("slingshotammo_slow").ingredients = { Ingredient("purplegem", 1) }
GLOBAL.STRINGS.NAMES.SLINGSHOTAMMO_SLOW = "Vortex Rounds"

AddRecipeToFilter("slingshotammo_rock", "WEAPONS")
AddRecipeToFilter("slingshotammo_gold", "WEAPONS")
AddRecipeToFilter("slingshotammo_marble", "WEAPONS")
AddRecipeToFilter("slingshotammo_poop", "WEAPONS")
AddRecipeToFilter("slingshotammo_freeze", "WEAPONS")
AddRecipeToFilter("slingshotammo_slow", "WEAPONS")
AddRecipeToFilter("slingshotammo_thulecite", "WEAPONS")
AddRecipeToFilter("slingshotammo_thulecite", "CRAFTING_STATION")
AddRecipeToFilter("slingshotammo_shadow", "WEAPONS")

ChangeSortKey("slingshotammo_rock", "slingshot_claire", "WEAPONS", true)
ChangeSortKey("slingshotammo_rock", "slingshot_claire", "CHARACTER", true)

ChangeSortKey("slingshotammo_gold", "slingshotammo_rock", "WEAPONS", true)
ChangeSortKey("slingshotammo_gold", "slingshotammo_rock", "CHARACTER", true)

ChangeSortKey("slingshotammo_marble", "slingshotammo_gold", "WEAPONS", true)
ChangeSortKey("slingshotammo_marble", "slingshotammo_gold", "CHARACTER", true)

ChangeSortKey("slingshotammo_poop", "slingshotammo_marble", "WEAPONS", true)
ChangeSortKey("slingshotammo_poop", "slingshotammo_marble", "CHARACTER", true)

AddRecipe2("slingshotammo_rubber", { Ingredient("mosquitosack", 1) }, TECH.SCIENCE_ONE, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_rubber", "slingshotammo_poop", "WEAPONS", true)
ChangeSortKey("slingshotammo_rubber", "slingshotammo_poop", "CHARACTER", true)

AddRecipe2("slingshotammo_firecrackers", { Ingredient("nitre", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_firecrackers", "slingshotammo_rubber", "WEAPONS", true)
ChangeSortKey("slingshotammo_firecrackers", "slingshotammo_rubber", "CHARACTER", true)

AddRecipe2("slingshotammo_moonrock", { Ingredient("moonrocknugget", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_moonrock", "slingshotammo_firecrackers", "WEAPONS", true)
ChangeSortKey("slingshotammo_moonrock", "slingshotammo_firecrackers", "CHARACTER", true)

AddRecipe2("slingshotammo_slime", { Ingredient("slurtleslime", 1), Ingredient("rocks", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_slime", "slingshotammo_moonrock", "CHARACTER", true)
ChangeSortKey("slingshotammo_slime", "slingshotammo_moonrock", "WEAPONS", true)

AddRecipe2("slingshotammo_honey", { Ingredient("honey", 3) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_honey", "slingshotammo_slime", "WEAPONS", true)
ChangeSortKey("slingshotammo_honey", "slingshotammo_slime", "CHARACTER", true)

AddRecipe2("slingshotammo_tar", { Ingredient("sludge", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_tar", "slingshotammo_honey", "WEAPONS", true)
ChangeSortKey("slingshotammo_tar", "slingshotammo_honey", "CHARACTER", true)

AddRecipe2("slingshotammo_salt", { Ingredient("saltrock", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_salt", "slingshotammo_tar", "WEAPONS", true)
ChangeSortKey("slingshotammo_salt", "slingshotammo_tar", "CHARACTER", true)

AddRecipe2("slingshotammo_goop", { Ingredient("glommerfuel", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 5, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_goop", "slingshotammo_salt", "CHARACTER", true)
ChangeSortKey("slingshotammo_goop", "slingshotammo_salt", "WEAPONS", true)

AddRecipe2("slingshotammo_tremor", { Ingredient("townportaltalisman", 1) }, TECH.SCIENCE_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_tremor", "slingshotammo_goop", "WEAPONS", true)
ChangeSortKey("slingshotammo_tremor", "slingshotammo_goop", "CHARACTER", true)

ChangeSortKey("slingshotammo_freeze", "slingshotammo_tremor", "WEAPONS", true)
ChangeSortKey("slingshotammo_freeze", "slingshotammo_tremor", "CHARACTER", true)

AddRecipe2("slingshotammo_flare", { Ingredient("redgem", 1) }, TECH.MAGIC_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_flare", "slingshotammo_freeze", "WEAPONS", true)
ChangeSortKey("slingshotammo_flare", "slingshotammo_freeze", "CHARACTER", true)

ChangeSortKey("slingshotammo_slow", "slingshotammo_flare", "WEAPONS", true)
ChangeSortKey("slingshotammo_slow", "slingshotammo_flare", "CHARACTER", true)

AddRecipe2("slingshotammo_lazy", { Ingredient("orangegem", 1), Ingredient("nightmarefuel", 1) }, TECH.ANCIENT_TWO, { builder_tag = "pebblemaker", numtogive = 20, no_deconstruction = true, force_hint=true }, { "CHARACTER", "WEAPONS", "CRAFTING_STATION" })
ChangeSortKey("slingshotammo_lazy", "slingshotammo_slow", "WEAPONS", true)
ChangeSortKey("slingshotammo_lazy", "slingshotammo_slow", "CHARACTER", true)
ChangeSortKey("slingshotammo_lazy", "ruins_bat", "CRAFTING_STATION", true)

ChangeSortKey("slingshotammo_thulecite", "slingshotammo_lazy", "WEAPONS", true)
ChangeSortKey("slingshotammo_thulecite", "slingshotammo_lazy", "CHARACTER", true)
ChangeSortKey("slingshotammo_thulecite", "slingshotammo_lazy", "CRAFTING_STATION", true)

AddRecipe2("slingshotammo_moonglass", { Ingredient("moonglass", 1) }, TECH.CELESTIAL_THREE, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true, force_hint=true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_moonglass", "slingshotammo_thulecite", "WEAPONS", true)
ChangeSortKey("slingshotammo_moonglass", "slingshotammo_thulecite", "CHARACTER", true)
ChangeSortKey("slingshotammo_moonglass", "glasscutter", "CRAFTING_STATION", true)

AddRecipe2("slingshotammo_obsidian", { Ingredient("placeholder_ingredient_ia", 0) }, TECH.OBSIDIAN_TWO, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true, nounlock = true }, { "CRAFTING_STATION", "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_obsidian", "armorobsidian", "CRAFTING_STATION", true)
ChangeSortKey("slingshotammo_obsidian", "slingshotammo_moonglass", "CHARACTER", true)
ChangeSortKey("slingshotammo_obsidian", "slingshotammo_moonglass", "WEAPONS", true)

AddRecipe2("slingshotammo_shadow", { Ingredient("nightmarefuel", 1) }, TECH.LOST, { builder_tag = "pebblemaker", numtogive = 10, no_deconstruction = true }, { "CHARACTER", "WEAPONS" })
ChangeSortKey("slingshotammo_shadow", "slingshotammo_obsidian", "WEAPONS", true)
ChangeSortKey("slingshotammo_shadow", "slingshotammo_obsidian", "CHARACTER", true)

AllRecipes["slingshotammo_stinger"].builder_skill = "wixie_slingshot_ammo_stinger"
AllRecipes["slingshotammo_dreadstone"].builder_skill = "wixie_slingshot_ammo_dreadstone"
AllRecipes["slingshotammo_scrapfeather"].builder_skill = "wixie_slingshot_ammo_scrapfeather"
AllRecipes["slingshotammo_gunpowder"].builder_skill = "wixie_slingshot_ammo_gunpowder"
AllRecipes["slingshotammo_lunarplanthusk"].builder_skill = "wixie_allegiance_lunar"
AllRecipes["slingshotammo_purebrilliance"].builder_skill = "wixie_allegiance_lunar"
AllRecipes["slingshotammo_gelblob"].builder_skill = "wixie_allegiance_shadow"
AllRecipes["slingshotammo_horrorfuel"].builder_skill = "wixie_allegiance_shadow"
AllRecipes["slingshotammo_container"].builder_skill = "wixie_ammo_bag"

AllRecipes["slingshot_jessie"].builder_tag = "pebblemaker"
AllRecipes["slingshot_claire"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_stinger"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_dreadstone"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_scrapfeather"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_gunpowder"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_lunarplanthusk"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_purebrilliance"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_gelblob"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_horrorfuel"].builder_tag = "pebblemaker"
AllRecipes["slingshotammo_container"].builder_tag = "pebblemaker"

AllRecipes["slingshotammo_stinger"].numtogive = 10
AllRecipes["slingshotammo_dreadstone"].numtogive = 10
AllRecipes["slingshotammo_scrapfeather"].numtogive = 10
AllRecipes["slingshotammo_gunpowder"].numtogive = 10
AllRecipes["slingshotammo_lunarplanthusk"].numtogive = 10
AllRecipes["slingshotammo_purebrilliance"].numtogive = 15
AllRecipes["slingshotammo_gelblob"].numtogive = 10
AllRecipes["slingshotammo_horrorfuel"].numtogive = 10

--(In reverse order to what shows up in-game)
AddRecipeToFilter("slingshotammo_purebrilliance", "WEAPONS")
ChangeSortKey("slingshotammo_purebrilliance", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_lunarplanthusk", "WEAPONS")
ChangeSortKey("slingshotammo_lunarplanthusk", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_gelblob", "WEAPONS")
ChangeSortKey("slingshotammo_gelblob", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_horrorfuel", "WEAPONS")
ChangeSortKey("slingshotammo_horrorfuel", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_dreadstone", "WEAPONS")
ChangeSortKey("slingshotammo_dreadstone", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_gunpowder", "WEAPONS")
ChangeSortKey("slingshotammo_gunpowder", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_scrapfeather", "WEAPONS")
ChangeSortKey("slingshotammo_scrapfeather", "slingshotammo_shadow", "WEAPONS", true)
AddRecipeToFilter("slingshotammo_stinger", "WEAPONS")
ChangeSortKey("slingshotammo_stinger", "slingshotammo_shadow", "WEAPONS", true)

local function calc_slingshotammo_numtogive_basic(recipe, doer)
	return doer.components.skilltreeupdater
		and doer.components.skilltreeupdater:IsActivated("wixie_ammocraft_2")
		and recipe.numtogive + 5
		or nil
end
AllRecipes["slingshotammo_rock"].override_numtogive_fn = calc_slingshotammo_numtogive_basic
AllRecipes["slingshotammo_gold"].override_numtogive_fn = calc_slingshotammo_numtogive_basic
AllRecipes["slingshotammo_marble"].override_numtogive_fn = calc_slingshotammo_numtogive_basic
AllRecipes["slingshotammo_poop"].override_numtogive_fn = calc_slingshotammo_numtogive_basic
AllRecipes["slingshotammo_stinger"].override_numtogive_fn = calc_slingshotammo_numtogive_basic
AllRecipes["slingshotammo_gunpowder"].override_numtogive_fn = calc_slingshotammo_numtogive_basic

local function calc_slingshotammo_numtogive_special(recipe, doer)
	return doer.components.skilltreeupdater
		and doer.components.skilltreeupdater:IsActivated("wixie_ammocraft_3")
		and recipe.numtogive + 5
		or nil
end

AllRecipes["slingshotammo_freeze"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_slow"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_thulecite"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_dreadstone"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_scrapfeather"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_lunarplanthusk"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_purebrilliance"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_gelblob"].override_numtogive_fn = calc_slingshotammo_numtogive_special
AllRecipes["slingshotammo_horrorfuel"].override_numtogive_fn = calc_slingshotammo_numtogive_special

AddRecipe2("meatrack_hat", { Ingredient("twigs", 2), Ingredient("rope", 1), Ingredient("charcoal", 1) }, TECH.NONE, { builder_tag = "pinetreepioneer" }, { "CHARACTER", "COOKING", "CLOTHING" })
ChangeSortKey("meatrack_hat", "walterhat", "CLOTHING", true)
ChangeSortKey("meatrack_hat", "walterhat", "CHARACTER", true)
ChangeSortKey("meatrack_hat", "meatrack", "COOKING", true)

AllRecipes["bandage_butterflywings"].ingredients = { Ingredient("butterflywings", 3), Ingredient("petals", 1) }
ChangeSortKey("woby_treat", "portabletent_item", "CHARACTER", false) --Get it farther away from unused slingshot upgrades
ChangeSortKey("woby_treat_small", "woby_treat", "CHARACTER", true)

STRINGS.CHARACTERS.GENERIC.DESCRIBE.WIXIEGUN = "Shhh, don't spoil it! ;)"

AddPrefabPostInit("forest", function(inst)
    inst:DoTaskInTime(0, function(inst) if Prefabs["obsidian"] then AllRecipes["slingshotammo_obsidian"].ingredients = { Ingredient("obsidian", 1) } end end)
end)
