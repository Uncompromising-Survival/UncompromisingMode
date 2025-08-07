--  [           Required stuff          ]   --
-- The global objects needed for recipe changes
-- Find the default recipes in recipes.lua
local require = GLOBAL.require
require("recipe")

local TECH = GLOBAL.TECH
local Ingredient = GLOBAL.Ingredient

-- List of Vanilla Recipe Filters
-- "FAVORITES", "CRAFTING_STATION", "SPECIAL_EVENT", "MODS", "CHARACTER", "TOOLS", "LIGHT",
-- "PROTOTYPERS", "REFINE", "WEAPONS", "ARMOUR", "CLOTHING", "RESTORATION", "MAGIC", "DECOR",
-- "STRCUTURES", "CONTAINERS", "COOKING", "GARDENING", "FISHING", "SEAFARING", "RIDING",
-- "WINTER", "SUMMER", "RAIN", "EVERYTHING"

--Turfs
AddRecipe2("turf_um_hotspring_grass", { Ingredient("cutlichen", 2), Ingredient("pinecone", 2) }, TECH.TURFCRAFTING_TWO, { numtogive = 4 }, { "DECOR" })
ChangeSortKey("turf_um_hotspring_grass", "turf_um_hotspring_grass", "DECOR", true)

AddRecipe2("turf_um_hotspring_whiterock", { Ingredient("rocks", 2), Ingredient("marble", 2) }, TECH.TURFCRAFTING_TWO, { numtogive = 4 }, { "DECOR" })
ChangeSortKey("turf_um_hotspring_whiterock", "turf_um_hotspring_whiterock", "DECOR", true)

AddRecipe2("turf_um_hotspring_yellowrock", { Ingredient("rocks", 2), Ingredient("nitre", 2) }, TECH.TURFCRAFTING_TWO, { numtogive = 4 }, { "DECOR" })
ChangeSortKey("turf_um_hotspring_yellowrock", "turf_um_hotspring_yellowrock", "DECOR", true)

if GetModConfigData("hoodedforest") then
    AddRecipe2("turf_hoodedmoss", { Ingredient("twigs", 1), Ingredient("greenfoliage", 4) }, TECH.TURFCRAFTING_TWO, { numtogive = 4 }, { "DECOR" })
    ChangeSortKey("turf_hoodedmoss", "turf_deciduous", "DECOR", true)
    AddRecipe2("turf_ancienthoodedturf", { Ingredient("turf_hoodedmoss", 2), Ingredient("moonrocknugget", 1) }, TECH.TURFCRAFTING_TWO, { numtogive = 4 }, { "DECOR" })
    ChangeSortKey("turf_ancienthoodedturf", "turf_hoodedmoss", "DECOR", true)
end

-----------------------
-------Equipment-------
-----------------------

AddRecipe2("scrap_monoclehat", { Ingredient("wagpunk_bits", 4), Ingredient("transistor", 1), Ingredient("messagebottleempty", 1) }, TECH.SCIENCE_TWO, nil, { "CLOTHING", "TOOLS" })
ChangeSortKey("scrap_monoclehat", "moonstorm_goggleshat", "CLOTHING", true)
ChangeSortKey("scrap_monoclehat", "antlionhat", "TOOLS", false)

if GetModConfigData("snowstorms") then
    AddRecipe2("snowgoggles", { Ingredient("catcoonhat", 1), Ingredient("goggleshat", 1), Ingredient("beefalowool", 2) }, TECH.SCIENCE_TWO, nil, { "WINTER", "CLOTHING" })
    ChangeSortKey("snowgoggles", "catcoonhat", "WINTER", true)
    ChangeSortKey("snowgoggles", "catcoonhat", "CLOTHING", true)
end

AddRecipe2("diseasecurebomb", { Ingredient("cactus_flower", 2), Ingredient("moonrocknugget", 2), Ingredient("spidergland", 3) }, TECH.SCIENCE_TWO, nil, { "GARDENING", "TOOLS", "RESTORATION" })
ChangeSortKey("diseasecurebomb", "compostwrap", "GARDENING", true)
ChangeSortKey("diseasecurebomb", "premiumwateringcan", "TOOLS", true)
ChangeSortKey("diseasecurebomb", "lifeinjector", "RESTORATION", true)

AddRecipe2("gasmask", { Ingredient("goose_feather", 10), Ingredient("red_cap", 2), Ingredient("pigskin", 2) }, TECH.SCIENCE_TWO, nil, { "CLOTHING", "RAIN", "SUMMER" })
ChangeSortKey("gasmask", "beehat", "CLOTHING", true)
ChangeSortKey("gasmask", "beehat", "RAIN", true)

AddRecipe2("plaguemask", { Ingredient("gasmask", 1), Ingredient("red_cap", 2), Ingredient("rat_tail", 4) }, TECH.SCIENCE_TWO, nil, { "CLOTHING", "RAIN", "SUMMER" })
ChangeSortKey("plaguemask", "gasmask", "CLOTHING", true)
ChangeSortKey("plaguemask", "gasmask", "RAIN", true)
ChangeSortKey("plaguemask", "gasmask", "SUMMER", true)

AddRecipe2("sporepack", { Ingredient("shroom_skin", 1), Ingredient("rope", 2), Ingredient("spoiled_food", 2) }, TECH.SCIENCE_TWO, nil, { "CLOTHING", "CONTAINERS" })
ChangeSortKey("sporepack", "icepack", "CLOTHING", true)
ChangeSortKey("sporepack", "icepack", "CONTAINERS", true)

if GetModConfigData("snowstorms") then
    AddRecipe2("saltpack", { Ingredient("gears", 1), Ingredient("boards", 2), Ingredient("saltrock", 4) }, TECH.SCIENCE_TWO, nil, { "TOOLS", "WINTER" })
    ChangeSortKey("saltpack", "brush", "TOOLS", true)
    ChangeSortKey("saltpack", "beargervest", "WINTER", true)

	AddRecipe2("um_armor_bramble_rimeweed", { Ingredient("armor_bramble", 1), Ingredient("um_rimeweed_itemvine", 8), Ingredient("um_rimeweed_itemflower", 1) }, TECH.NONE, { builder_tag = "plantkin" }, { "CHARACTER", "ARMOUR" })
	ChangeSortKey("um_armor_bramble_rimeweed", "armor_bramble", "CHARACTER", true)
	ChangeSortKey("um_armor_bramble_rimeweed", "armor_bramble", "ARMOUR", true)
	
	AddRecipe2("um_rimeweed_icepack", { Ingredient("papyrus", 1), Ingredient("ice", 2), Ingredient("um_rimeweed_itemvine", 2) }, TECH.SCIENCE_TWO, nil, { "RESTORATION", "SUMMER" })
	ChangeSortKey("um_rimeweed_icepack", "healingsalve_acid", "RESTORATION", true)
	ChangeSortKey("um_rimeweed_icepack", "blueamulet", "SUMMER", false)

	AddRecipe2("um_blowdart_rime", { Ingredient("cutreeds", 2), Ingredient("um_rimeweed_itemvine", 1), Ingredient("feather_robin_winter", 1) }, TECH.SCIENCE_TWO, nil, { "WEAPONS" })
	ChangeSortKey("um_blowdart_rime", "blowdart_pipe", "WEAPONS", true)
end


AddRecipe2("um_armor_bramble_rimeweed", { Ingredient("armor_bramble", 1), Ingredient("um_rimeweed_itemvine", 8), Ingredient("um_rimeweed_itemflower", 1) }, TECH.NONE, { builder_tag = "plantkin" }, { "CHARACTER" })
ChangeSortKey("um_armor_bramble_rimeweed", "armor_bramble", "CHARACTER", true)


AddRecipe2("bugzapper", { Ingredient("spear", 1), Ingredient("transistor", 2), Ingredient("feather_canary", 2) }, TECH.SCIENCE_TWO, nil, { "WEAPONS" })
ChangeSortKey("bugzapper", "nightstick", "WEAPONS", true)

AddRecipe2("um_fyre_bomb", { Ingredient("um_fyrite", 1), Ingredient("twigs", 1),Ingredient("rocks", 2)}, TECH.SCIENCE_TWO, { numtogive = 4 }, { "WEAPONS" })
ChangeSortKey("um_fyre_bomb", "nightstick", "WEAPONS", true)

AddRecipe2("um_hat_bee_moon", { Ingredient("um_bee_moon", 2), Ingredient("um_meathoney", 3),Ingredient("silk", 1)}, TECH.SCIENCE_TWO, { numtogive = 1 }, { "CLOTHING","WEAPONS" })
ChangeSortKey("um_hat_bee_moon", "roseglasseshat", "CLOTHING", true)
ChangeSortKey("um_hat_bee_moon", "armor_glassmail", "WEAPONS", true)

AddRecipe2("um_eyebalm", { Ingredient("um_meatcomb", 1), Ingredient("um_meathoney", 3), Ingredient("mosquitosack",3)}, TECH.SCIENCE_TWO, { numtogive = 3 }, { "RESTORATION" })
ChangeSortKey("um_eyebalm", "bandage_butterflywings", "RESTORATION", true)

AddRecipe2("um_beemine_moon_item", { Ingredient("log", 2), Ingredient("um_bee_moon", 1), Ingredient("um_meathoney",2)}, TECH.SCIENCE_TWO, { numtogive = 1 }, { "WEAPONS" })
ChangeSortKey("um_beemine_moon_item", "um_fyre_bomb", "WEAPONS", true)

AddRecipe2("ancient_amulet_red", { Ingredient("thulecite", 2), Ingredient("nightmarefuel", 3), Ingredient("redgem", 2) }, TECH.ANCIENT_FOUR, { nounlock = true }, { "CRAFTING_STATION" })
ChangeSortKey("ancient_amulet_red", "orangeamulet", "CRAFTING_STATION", true)


AddRecipe2(
    "um_bear_trap_equippable_tooth",
    { Ingredient("twigs", 4), Ingredient("houndstooth", 2), Ingredient("snappy_jaw", 1) },
    TECH.SCIENCE_ONE,
    { nil },
    { "WEAPONS" }
)
ChangeSortKey("um_bear_trap_equippable_tooth", "trap_teeth", "WEAPONS", true)

AddRecipe2(
    "um_bear_trap_equippable_gold",
    { Ingredient("goldnugget", 3), Ingredient("houndstooth", 2), Ingredient("snappy_jaw", 1)},
    TECH.SCIENCE_TWO,
    { nil },
    { "WEAPONS" }
)
ChangeSortKey("um_bear_trap_equippable_gold", "um_bear_trap_equippable_tooth", "WEAPONS", true)

AddRecipe2(
    "um_detonator",
    { Ingredient("moonstorm_spark", 6), Ingredient("wagpunk_bits", 2), Ingredient("lightninggoathorn", 1)},
    TECH.SCIENCE_TWO,
    { nil },
    { "WEAPONS" }
)
ChangeSortKey("um_detonator", "um_bear_trap_equippable_gold", "WEAPONS", true)


if GetModConfigData("wiltfly") then
    AddRecipe2("armor_glassmail", { Ingredient("glass_scales", 1), Ingredient("moonglass_charged", 10) }, TECH.CELESTIAL_THREE, { nounlock = true }, { "CRAFTING_STATION" })
    ChangeSortKey("armor_glassmail", "glasscutter", "CRAFTING_STATION", true)
end

if GetModConfigData("rat_raids") or GetModConfigData("funny rat") then
    AddRecipe2("rat_whip", { Ingredient("twigs", 3), Ingredient("mosquitosack", 1), Ingredient("rat_tail", 3) }, TECH.SCIENCE_TWO, nil, { "WEAPONS" })
    ChangeSortKey("rat_whip", "whip", "WEAPONS", true)
end

if GetModConfigData("rat_raids") then
    AddRecipe2("hat_ratmask", { Ingredient("rope", 2), Ingredient("beardhair", 3), Ingredient("sewing_kit", 1) }, TECH.SCIENCE_TWO, nil, { "CLOTHING" })
    ChangeSortKey("hat_ratmask", "plaguemask", "CLOTHING", true)
end

AddRecipe2("driftwoodfishingrod", { Ingredient("driftwood_log", 3), Ingredient("silk", 3), Ingredient("rope", 2) }, TECH.SCIENCE_TWO, nil, { "TOOLS", "FISHING" })
ChangeSortKey("driftwoodfishingrod", "fishingrod", "TOOLS", true)
ChangeSortKey("driftwoodfishingrod", "fishingrod", "FISHING", true)

AddRecipe2("uncompromising_fishingnet", { Ingredient("rope", 1), Ingredient("rocks", 2), Ingredient("silk", 3) }, TECH.SCIENCE_ONE, nil, { "TOOLS", "FISHING" })
ChangeSortKey("uncompromising_fishingnet", "driftwoodfishingrod", "TOOLS", true)
ChangeSortKey("uncompromising_fishingnet", "driftwoodfishingrod", "FISHING", true)

AddRecipe2("um_magnerang", { Ingredient("boomerang", 1), Ingredient("transistor", 2), Ingredient("wagpunk_bits", 1) }, TECH.SCIENCE_TWO, nil, { "WEAPONS" })
ChangeSortKey("um_magnerang", "boomerang", "WEAPONS", true)

AddRecipe2("hermitshop_rain_horn", { Ingredient("dormant_rain_horn", 1), Ingredient("oceanfish_small_9_inv", 3), Ingredient("messagebottleempty", 2) }, TECH.HERMITCRABSHOP_SEVEN, { nounlock = true, product = "rain_horn" }, { "CRAFTING_STATION" })
ChangeSortKey("hermitshop_rain_horn", "hermitshop_oceanfishingbobber_malbatross", "CRAFTING_STATION", true)

AddRecipe2("sludge_sack", { Ingredient("sludge", 6), Ingredient("rockjawleather", 2), Ingredient("rope", 3) }, TECH.SCIENCE_TWO, nil, { "CONTAINERS", "CLOTHING" })
ChangeSortKey("sludge_sack", "piggyback", "CONTAINERS", true)
ChangeSortKey("sludge_sack", "piggyback", "CLOTHING", true)

------------------------------------------------
----------------------Misc----------------------
------------------------------------------------

if GetModConfigData("rat_raids") then
    AddRecipe2("ratpoisonbottle", { Ingredient("red_cap", 2), Ingredient("jammypreserves", 1), Ingredient("rocks", 1) }, TECH.SCIENCE_ONE, { numtogive = 4 }, { "TOOLS" })
    ChangeSortKey("ratpoisonbottle", "trap", "TOOLS", true)
end

if GetModConfigData("snowstorms") then
    AddRecipe2("ice", { Ingredient("snowball_item", 4) }, TECH.SCIENCE_ONE, nil, { "REFINE", "COOKING" })
    ChangeSortKey("ice", "beeswax", "REFINE", true)
end

if GetModConfigData("sporehounds") then
    AddRecipe2("shroom_skin", { Ingredient("shroom_skin_fragment", 4), Ingredient("froglegs", 2) }, TECH.SCIENCE_TWO, nil, { "REFINE" })
    ChangeSortKey("shroom_skin", "bearger_fur", "REFINE", true)
end

AddRecipe2("watermelon_lantern", { Ingredient("watermelon", 1), Ingredient("fireflies", 1) }, TECH.SCIENCE_TWO, nil, { "LIGHT" })
ChangeSortKey("watermelon_lantern", "pumpkin_lantern", "LIGHT", true)

if GetModConfigData("hayfever_disable") then -- not in dev build since the config is commented off, but live does have it.
    AddRecipe2("honey_log", { Ingredient("livinglog", 1), Ingredient("honey", 2) }, TECH.NONE, { builder_tag = "plantkin" }, { "CHARACTER" })
    ChangeSortKey("honey_log", "livinglog", "CHARACTER", true)
end

if GetModConfigData("trapdoorspiders") then
    AddRecipe2("mutator_trapdoor", { Ingredient("monstermeat", 2), Ingredient("spidergland", 3), Ingredient("cutgrass", 5) }, TECH.SPIDERCRAFT_ONE, { builder_tag = "spiderwhisperer" }, { "CHARACTER" })
    ChangeSortKey("mutator_trapdoor", "mutator_warrior", "CHARACTER", true)
end

AddRecipe2("floral_bandage", { Ingredient("bandage", 1), Ingredient("cactus_flower", 2) }, TECH.SCIENCE_TWO, nil, { "RESTORATION" })
ChangeSortKey("floral_bandage", "bandage", "RESTORATION", true)

if GetModConfigData("winona_items") then
    AddRecipe2("winona_toolbox", { Ingredient("boards", 2), Ingredient("goldnugget", 4), Ingredient("sewing_tape", 2) }, TECH.NONE, { builder_tag = "handyperson" }, { "CONTAINERS", "CHARACTER" })
    ChangeSortKey("winona_toolbox", "battlesong_container", "CONTAINERS", false)
    ChangeSortKey("winona_toolbox", "sewing_tape", "CHARACTER", true)
    AddRecipe2("winona_upgradekit_electrical", { Ingredient("goldnugget", 6), Ingredient("sewing_tape", 2), Ingredient("wagpunk_bits", 4) }, TECH.SCIENCE_TWO, { builder_tag = "handyperson" }, { "CHARACTER", "LIGHT" })
    ChangeSortKey("winona_upgradekit_electrical", "winona_toolbox", "CHARACTER", true)
    AddRecipe2("powercell", { Ingredient("sewing_tape", 1), Ingredient("goldnugget", 1), Ingredient("nitre", 2) }, TECH.NONE, { builder_tag = "handyperson", numtogive = 3 }, { "CHARACTER" })
    ChangeSortKey("powercell", "winona_upgradekit_electrical", "CHARACTER", true)
end

AddRecipe2("boatpatch_sludge", { Ingredient("sludge", 3), Ingredient("driftwood_log", 2) }, TECH.NONE, nil, { "SEAFARING" })
ChangeSortKey("boatpatch_sludge", "oar", "SEAFARING", false)


------------------------------
----------Structures----------
------------------------------

AddRecipe2("air_conditioner", { Ingredient("shroom_skin", 2), Ingredient("gears", 1), Ingredient("cutstone", 2) }, TECH.SCIENCE_TWO, { placer = "air_conditioner_placer" }, { "STRUCTURES" })
ChangeSortKey("air_conditioner", "firesuppressor", "STRUCTURES", true)

AddRecipe2("houndious_observious", { Ingredient("livinglog", 12), Ingredient("mandrake", 1), Ingredient("ocupus_tentacle_eye", 5) }, TECH.MAGIC_TWO, { placer = "houndious_observious_placer" }, { "STRUCTURES", "MAGIC" })
ChangeSortKey("houndious_observious", "firesuppressor", "STRUCTURES", true)
ChangeSortKey("houndious_observious", "magician_chest", "MAGIC", true)

AddRecipe2("skullchest_child", { Ingredient("fossil_piece", 2), Ingredient("nightmarefuel", 4), Ingredient("boards", 3) }, TECH.LOST, { placer = "skullchest_child_placer" }, { "STRUCTURES", "CONTAINERS", "MAGIC" })
ChangeSortKey("skullchest_child", "magician_chest", "STRUCTURES", true)
ChangeSortKey("skullchest_child", "magician_chest", "CONTAINERS", true)
ChangeSortKey("skullchest_child", "magician_chest", "MAGIC", true)

AddRecipe2("um_ribopodden", { Ingredient("boneshard", 8), Ingredient("um_ribopod", 6),Ingredient("rocks", 12)}, TECH.SCIENCE_TWO, { placer = "um_ribopodden_placer" }, { "STRUCTURES"})
ChangeSortKey("um_ribopodden", "rabbithouse", "STRUCTURES", true)
GLOBAL.STRINGS.RECIPE_DESC.UM_RIBOPODDEN = "A home for opportunistic scavengers."

--[[
AddRecipe2(
"uncompromising_harpoon",
{Ingredient("twigs", 2), Ingredient("rope", 2), Ingredient("flint", 1)},
TECH.SCIENCE_TWO,
nil,
{"TOOLS", "FISHING"})
ChangeSortKey("uncompromising_harpoon", "uncompromising_fishingnet", "TOOLS", true)

AddRecipe2(
"uncompromising_harpoon_heavy",
{Ingredient("twigs", 2), Ingredient("goldnugget", 3), Ingredient("flint", 1)},
TECH.SCIENCE_TWO,
nil,
{"TOOLS", "FISHING"})
ChangeSortKey("uncompromising_harpoon_heavy", "uncompromising_harpoon", "TOOLS", true)]]


--This is the part where I give up on that "sorting" thing. This is way too boring, I've already been working on this damn refactor for the past hour.


AddRecipe2("boat_bumper_sludge_kit", { Ingredient("sludge", 4), Ingredient("driftwood_log", 2) }, TECH.SEAFARING_ONE, { numtogive = 2 }, { "SEAFARING" })
ChangeSortKey("boat_bumper_sludge_kit", "boat_bumper_shell_kit", "SEAFARING", true)

AddRecipe2("cannonball_sludge_item", { Ingredient("sludge", 1), Ingredient("nitre", 1), Ingredient("charcoal", 1) }, TECH.SEAFARING_ONE, { numtogive = 6 }, { "WEAPONS", "SEAFARING" })
ChangeSortKey("cannonball_sludge_item", "cannonball_rock_item", "SEAFARING", true)
ChangeSortKey("cannonball_sludge_item", "cannonball_rock_item", "WEAPONS", true)

-- AddRecipe2("cannonball_incendiary_item", { Ingredient("snapalm", 1), Ingredient("gunpowder", 1), Ingredient("slurtle_shellpieces", 2) }, TECH.SEAFARING_ONE, { numtogive = 4 }, { "WEAPONS", "SEAFARING" })
-- ChangeSortKey("cannonball_incendiary_item", "cannonball_sludge_item", "SEAFARING", true)
-- ChangeSortKey("cannonball_incendiary_item", "cannonball_sludge_item", "WEAPONS", true)


AddRecipe2("sludge_oil", { Ingredient("sludge", 3), Ingredient("messagebottleempty", 1) }, TECH.SCIENCE_TWO, nil, { "TOOLS", "LIGHT" })
ChangeSortKey("sludge_oil", "sewing_tape", "TOOLS", true)
ChangeSortKey("sludge_oil", "coldfirepit", "LIGHT", true)

AddRecipe2("armor_reed_um", { Ingredient("cutreeds", 8), Ingredient("twigs", 3) }, TECH.NONE, nil, { "ARMOUR", "RAIN" })
ChangeSortKey("armor_reed_um", "armorgrass", "ARMOUR", true)
ChangeSortKey("armor_reed_um", "raincoat", "RAIN", true)

-- ChangeSortKey("PREFAB_NAME_OF_ITEM_THAT_YOURE_SORTING","PREFAB_NAME_OF_ITEM_YOU_WANT_IT_TO_GO_AFTER","THE_TAB",true) you need to do this for each tab that you want it to be sorted in -AXE
-- need to add the inv atlases

AddRecipe2("armor_sharksuit_um", { Ingredient("armorwood", 1), Ingredient("rockjawleather", 1), Ingredient("sludge", 4) }, TECH.SCIENCE_TWO, nil, { "SEAFARING", "ARMOUR", "RAIN" })
ChangeSortKey("armor_sharksuit_um", "armordragonfly", "ARMOUR", true)
ChangeSortKey("armor_sharksuit_um", "balloonvest", "SEAFARING", true)
ChangeSortKey("armor_sharksuit_um", "armor_reed_um", "RAIN", true)

AddRecipe2("brine_balm", { Ingredient("saltrock", 2), Ingredient("kelp", 1) }, TECH.SCIENCE_ONE, nil, { "RESTORATION" })
ChangeSortKey("brine_balm", "floral_bandage", "RESTORATION", true)

AddRecipe2("sludge_cork", { Ingredient("driftwood_log", 2), Ingredient("rope", 2) }, TECH.SCIENCE_ONE, nil, { "TOOLS", "SEAFARING" })
ChangeSortKey("sludge_cork", "oceanfishingrod", "TOOLS", true)
ChangeSortKey("sludge_cork", "boat_magnet_beacon", "SEAFARING", true)

--[[AddRecipe2(  "boat_bumper_copper_kit",  { Ingredient("um_copper_pipe", 14) },  TECH.SEAFARING_ONE,  { numtogive = 2 },  { "SEAFARING" })
ChangeSortKey("boat_bumper_copper_kit", "boat_bumper_shell_kit", "SEAFARING", true)]]

--[[AddRecipe2(  "steeringwheel_copper_item",  { Ingredient("um_copper_pipe", 3), Ingredient("gears", 1) },  TECH.SEAFARING_ONE,  nil,  { "SEAFARING" })
ChangeSortKey("steeringwheel_copper_item", "steeringwheel_item", "SEAFARING", true)]]

if GetModConfigData("monstersmallmeat") then
    AddRecipe2("transmute_monstermeat", { Ingredient("monstersmallmeat", 3) }, TECH.NONE, { product = "monstermeat", builder_skill = "wilson_alchemy_4", description = "transmute_monstermeat" }, { "CHARACTER" })
    AddRecipe2("transmute_monstersmallmeat", { Ingredient("monstermeat", 1) }, TECH.NONE, { product = "monstersmallmeat", builder_skill = "wilson_alchemy_4", description = "transmute_monstersmallmeat", numtogive = 2 }, { "CHARACTER" })
    ChangeSortKey("transmute_monstermeat", "transmute_meat", "CHARACTER", true)
    ChangeSortKey("transmute_monstersmallmeat", "transmute_smallmeat", "CHARACTER", true)
end


-- AddRecipe2("cursed_antler", { Ingredient("um_deerclops_soul", 1), Ingredient("boneshard", 6), Ingredient("um_dark_vestiges", 1) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("armor_sharksuit_um", "armordragonfly", "MAGIC", true)

-- AddRecipe2("beargerclaw", { Ingredient("um_bearger_soul", 1), Ingredient("rocks", 10), Ingredient("um_dark_vestiges", 1) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("beargerclaw", "cursed_antler", "MAGIC", true)

-- AddRecipe2("klaus_amulet", { Ingredient("um_klaus_soul", 1), Ingredient("purplegem", 1), Ingredient("um_dark_vestiges", 1) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("klaus_amulet", "beargerclaw", "MAGIC", true)

-- AddRecipe2("silksack", { Ingredient("um_hoodedwidow_soul", 1), Ingredient("silk", 6), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("feather_frock", "klaus_amulet", "MAGIC", true)

-- AddRecipe2("feather_frock", { Ingredient("um_goose_soul", 1), Ingredient("goose_feather", 3), Ingredient("um_dark_vestiges", 1) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("feather_frock", "klaus_amulet", "MAGIC", true)

-- AddRecipe2("gore_horn_hat", { Ingredient("um_minotaur_soul", 1), Ingredient("catcoonhat", 1), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("gore_horn_hat", "feather_frock", "MAGIC", true)

-- AddRecipe2("crabclaw", { Ingredient("um_crabking_soul", 1), Ingredient("fishmeat", 3), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("crabclaw", "gore_horn_hat", "MAGIC", true)

-- AddRecipe2("slobberlobber", { Ingredient("um_dragonfly_soul", 1), Ingredient("redgem", 2), Ingredient("um_dark_vestiges", 1) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("slobberlobber", "crabclaw", "MAGIC", true)

-- AddRecipe2("um_beegun", { Ingredient("um_beequeen_soul", 1), Ingredient("royal_jelly", 2), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("um_beegun", "slobberlobber", "MAGIC", true)

-- AddRecipe2("um_wingsuit", { Ingredient("um_malbatross_soul", 1), Ingredient("malbatross_feathered_weave", 2), Ingredient("um_dark_vestiges", 1) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("um_wingsuit", "um_beegun", "MAGIC", true)

-- AddRecipe2("um_exhumer", { Ingredient("um_fuelweaver_soul", 1), Ingredient("fossil_piece", 2), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("um_exhumer", "um_wingsuit", "MAGIC", true)

-- AddRecipe2("um_moonfly_lantern", { Ingredient("um_moonmaw_soul", 1), Ingredient("fireflies", 2), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("um_moonfly_lantern", "um_exhumer", "MAGIC", true)

-- AddRecipe2("um_beegun_cherry", { Ingredient("um_cherry_beequeen_soul", 1), Ingredient("royal_jelly", 2), Ingredient("um_dark_vestiges", 2) }, TECH.VETERANSHRINE_ONE, { nounlock = true }, { "MAGIC" })
-- --ChangeSortKey("um_beegun_cherry", "um_wingsuit", "MAGIC", true)

--Deconstruct Recipes
AddDeconstructRecipe("widowshead", { Ingredient("silk", 4), Ingredient("monstermeat", 2), Ingredient("spidergland", 2) })
AddDeconstructRecipe("widowsgrasp", { Ingredient("monstermeat", 2) })
AddDeconstructRecipe("shadow_crown", { Ingredient("nightmarefuel", 5), Ingredient("beardhair", 3) })
AddDeconstructRecipe("rain_horn", { Ingredient("slurtle_shellpieces", 4), Ingredient("rocks", 2), Ingredient("oceanfish_small_9_inv", 3) })
AddDeconstructRecipe("dormant_rain_horn", { Ingredient("cookiecuttershell", 4), Ingredient("rocks", 2), Ingredient("barnacle", 1) })
AddDeconstructRecipe("staff_moonfall", { Ingredient("opalpreciousgem", 3), Ingredient("slurtle_shellpieces", 5), Ingredient("livinglog", 3) })
AddDeconstructRecipe("rimeweed_whip", { Ingredient("um_rimeweed_itemvine", 6) })
AddDeconstructRecipe("snaildrakehat", { Ingredient("slurtle_shellpieces", 3) })
AddDeconstructRecipe("snaildrakebucket", { Ingredient("slurtle_shellpieces", 3) })
AddDeconstructRecipe("slurtlehat", { Ingredient("slurtle_shellpieces", 3) })
AddDeconstructRecipe("armorsnurtleshell", { Ingredient("slurtle_shellpieces", 3) })
AddDeconstructRecipe("snappy_jaw", { Ingredient("flint", 3), Ingredient("rope", 1), Ingredient("houndstooth", 3) })
AddDeconstructRecipe("pied_piper_flute", { Ingredient("twigs", 3), Ingredient("goldnugget", 1) })
AddDeconstructRecipe("skullflask", { Ingredient("boneshard", 2), Ingredient("nightmarefuel", 6), Ingredient("livinglog", 1) })
AddDeconstructRecipe("skullflask_empty", { Ingredient("boneshard", 2), Ingredient("nightmarefuel", 1), Ingredient("livinglog", 1) })
AddDeconstructRecipe("corvushat", { Ingredient("silk", 6), Ingredient("feather_robin", 2), Ingredient("seeds", 1) }) --:)

--Vet Curse Deconstruct Recipes
AddDeconstructRecipe("cursed_antler", { Ingredient("boneshard", 8) })
AddDeconstructRecipe("beargerclaw", { Ingredient("boneshard", 4), Ingredient("furtuft", 10) })
AddDeconstructRecipe("klaus_amulet", { Ingredient("goldnugget", 4), Ingredient("nightmarefuel", 6) })
AddDeconstructRecipe("feather_frock", { Ingredient("goose_feather", 6) })
AddDeconstructRecipe("gore_horn_hat", { Ingredient("nightmarefuel", 10) })
AddDeconstructRecipe("crabclaw", { Ingredient("meat", 1), Ingredient("rocks", 6) })
AddDeconstructRecipe("slobberlobber", { Ingredient("meat", 1), Ingredient("dragon_scales", 1) })
AddDeconstructRecipe("um_beegun", { Ingredient("honeycomb", 6), Ingredient("royal_jelly", 2) })
AddDeconstructRecipe("silksack", { Ingredient("silk", 6), Ingredient("monstermeat", 2), Ingredient("spidergland", 2) })
AddDeconstructRecipe("um_moonfly_lantern", { Ingredient("moonglass", 3), Ingredient("moonglass_charged", 3), Ingredient("moonrocknugget", 4) }) --temp moon rocks.
AddDeconstructRecipe("um_wingsuit", { Ingredient("malbatross_feather", 6) })
AddDeconstructRecipe("um_exhumer", { Ingredient("boneshard", 9), Ingredient("fossil_piece", 1), Ingredient("nightmarefuel", 2) })

----deconstruct recipes for craftable items
--AddDeconstructRecipe("steeringwheel_copper", { Ingredient("um_copper_pipe", 3), Ingredient("gears", 1) })

-- Sailing Rebalance related recipes.

-- hermitshop expansion
AddRecipe2("hermitshop_hermit_bundle_lures", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, numtogive = 1, product = "hermit_bundle_lures", sg_state = "give", image = "hermit_bundle.tex" })
ChangeSortKey("hermitshop_hermit_bundle_lures", "hermitshop_hermit_bundle_shells", "CRAFTING_STATION", false)

AddRecipe2("hermitshop_boat", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, product = "boat_item", sg_state = "give" })
ChangeSortKey("hermitshop_boat", "hermitshop_hermit_bundle_shells", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_boat_rotator", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, product = "boat_rotator_kit", sg_state = "give" })

AddRecipe2("hermitshop_mast", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, product = "mast_item", sg_state = "give" })
ChangeSortKey("hermitshop_mast", "hermitshop_boat", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_anchor", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, product = "anchor_item", sg_state = "give" })
ChangeSortKey("hermitshop_anchor", "hermitshop_mast", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_steeringwheel", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, product = "steeringwheel_item", sg_state = "give" })
ChangeSortKey("hermitshop_steeringwheel", "hermitshop_anchor", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_patch", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_ONE, { nounlock = true, product = "boatpatch", sg_state = "give", numtogive = 3 })
ChangeSortKey("hermitshop_patch", "hermitshop_steeringwheel", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_blueprint", { Ingredient("messagebottleempty", 1) }, GLOBAL.TECH.HERMITCRABSHOP_THREE, { nounlock = true, product = "blueprint", sg_state = "give" })
ChangeSortKey("hermitshop_blueprint", "hermitshop_turf_shellbeach_blueprint", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_waterplant", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_THREE, { nounlock = true, product = "waterplant_planter", sg_state = "give" })
ChangeSortKey("hermitshop_waterplant", "hermitshop_chum", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_seedpacket", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_THREE, { nounlock = true, product = "yotc_seedpacket", sg_state = "give", numtogive = 2 })
ChangeSortKey("hermitshop_seedpacket", "hermitshop_chum", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_seedpacket_rare", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_FIVE, { nounlock = true, product = "yotc_seedpacket_rare", sg_state = "give", numtogive = 2 })
ChangeSortKey("hermitshop_seedpacket_rare", "hermitshop_chum", "CRAFTING_STATION", true)

AddRecipe2("hermitshop_cookies", { Ingredient("messagebottleempty", 1) }, TECH.HERMITCRABSHOP_SEVEN, { nounlock = true, product = "pumpkincookie", sg_state = "give" })
ChangeSortKey("hermitshop_cookies", "hermitshop_supertacklecontainer", "CRAFTING_STATION", true)

--[[
AddRecipe2(
"hermitshop_oil",
{Ingredient("messagebottleempty", 3)},
TECH.HERMITCRABSHOP_FIVE,
{nounlock = true, product = "diseasecurebomb", sg_state = "give"})
ChangeSortKey("hermitshop_oil", "hermitshop_cookies", "CRAFTING_STATION", true)]]
-- better moonstorm
AddRecipe2("moonstorm_static_item", { Ingredient("transistor", 1), Ingredient("moonstorm_spark", 2), Ingredient("goldnugget", 3) }, TECH.LOST, nil, { "REFINE" })
AddRecipe2("alterguardianhatshard", { Ingredient("moonglass_charged", 1), Ingredient("moonstorm_spark", 2), Ingredient("lightbulb", 1) }, TECH.LOST, nil, { "LIGHT", "REFINE" })

AddDeconstructRecipe("alterguardianhat", { Ingredient("alterguardianhatshard", 5), Ingredient("alterguardianhatshard_blueprint", 1) })

AddRecipe2("critter_figgy_builder", { Ingredient("steelwool", 1), Ingredient("blueberrypancakes", 1) }, TECH.ORPHANAGE_ONE, { nounlock = true, actionstr = "ORPHANAGE" })
ChangeSortKey("critter_figgy_builder", "critter_eyeofterror_builder", "CRAFTING_STATION", true)

AddRecipe2("portableboat_item", { Ingredient("mosquitosack", 2), Ingredient("rope", 2) }, TECH.SEAFARING_ONE, nil, { "SEAFARING" })
ChangeSortKey("portableboat_item", "boat_item", "SEAFARING", true)

AddRecipe2("mastupgrade_windturbine_item", { Ingredient("cutstone", 2), Ingredient("transistor", 2) }, TECH.SEAFARING_ONE, nil, { "SEAFARING" })
ChangeSortKey("mastupgrade_windturbine_item", "mastupgrade_lightningrod_item", "SEAFARING", true)

--if GetModConfigData("ck_loot") then
    --AddRecipe2("hat_crab", { Ingredient("cutstone", 2), Ingredient("orangegem", 2), Ingredient("slurtle_shellpieces", 1) }, TECH.LOST, nil, { "CLOTHING" })
    --AddRecipe2("hat_crab_ice", { Ingredient("cutstone", 2), Ingredient("bluegem", 2), Ingredient("slurtle_shellpieces", 1) }, TECH.LOST, nil, { "ARMOUR" })
    --AddRecipe2("armor_crab_maxhp", { Ingredient("cutstone", 1), Ingredient("redgem", 3), Ingredient("slurtle_shellpieces", 3) }, TECH.LOST, nil, { "ARMOUR" })
    --AddRecipe2("armor_crab_regen", { Ingredient("cutstone", 1), Ingredient("greengem", 3), Ingredient("slurtle_shellpieces", 3) }, TECH.LOST, nil, { "ARMOUR" })
    --AddRecipe2("staff_starfall", { Ingredient("yellowgem", 3), Ingredient("slurtle_shellpieces", 5), Ingredient("livinglog", 3) }, TECH.LOST, nil, { "WEAPONS", "SHADOWMAGIC" })
    --AddRecipe2("kaleidoscope", { Ingredient("moonglass", 3), Ingredient("moonbutterfly", 5), Ingredient("redgem", 1), Ingredient("greengem", 1), Ingredient("bluegem", 1) }, TECH.LOST, nil, { "WEAPONS" })
    --ChangeSortKey("staff_starfall", "firestaff", "WEAPONS", true)
    --ChangeSortKey("staff_starfall", "firestaff", "MAGIC", true)
--end

-- Pyre Nettles stuff
-- Pyre Mantle
AddRecipe2("um_armor_pyre_nettles", { Ingredient("firenettles", 5), Ingredient("silk", 1) }, TECH.SCIENCE_TWO, nil, { "ARMOUR", "WINTER" })
ChangeSortKey("um_armor_pyre_nettles", "armordragonfly", "ARMOUR", false)
ChangeSortKey("um_armor_pyre_nettles", "sweatervest", "WINTER", false)
-- Pyre Dart
AddRecipe2("um_blowdart_pyre", { Ingredient("cutreeds", 2), Ingredient("um_smolder_spore", 1), Ingredient("firenettles", 1) }, TECH.SCIENCE_TWO, nil, { "WEAPONS" })
ChangeSortKey("um_blowdart_pyre", "blowdart_fire", "WEAPONS", true)

--AddRecipe2("um_boat_engine", { Ingredient("wagpunk_bits", 4), Ingredient("cutstone", 2), Ingredient("palmcone_scale", 6)}, TECH.SCIENCE_TWO, { placer = "um_boat_engine_placer",min_spacing=1.5 }, { "SEAFARING" })


--AddRecipe2("codex_mantra", { Ingredient("papyrus", 2), Ingredient("nightmarefuel", 2), Ingredient(GLOBAL.CHARACTER_INGREDIENT.HEALTH, 50) }, TECH.NONE, { builder_tag = "codexmantrareader" }, { "CHARACTER" })
--ChangeSortKey("codex_mantra", "waxwelljournal", "CHARACTER", true)

if TUNING.DSTU.WAXWELL then
    AddCharacterRecipe("um_maxwell_armor_sanity", {Ingredient("nightmarefuel", 3), Ingredient("waxwelljournal", 0)}, TECH.LOST, {builder_tag = "shadowmagic", product = "armor_sanity", image = "armor_sanity.tex", description = "pact_armor_sanity", actionstr = "UM_WAXWELL_SUMMON", sg_state = "usewaxwelljournal_pre"}, {"MAGIC", "ARMOUR"})
    ChangeSortKey("um_maxwell_armor_sanity", "waxwelljournal", "CHARACTER", true)
    ChangeSortKey("um_maxwell_armor_sanity", "armor_sanity", "ARMOUR", true)
    ChangeSortKey("um_maxwell_armor_sanity", "nightsword", "MAGIC", true)
    AddCharacterRecipe("um_maxwell_nightsword", {Ingredient("nightmarefuel", 3), Ingredient("waxwelljournal", 0)}, TECH.LOST, {builder_tag = "shadowmagic", product = "nightsword", image = "nightsword.tex", description = "pact_sword_sanity", actionstr = "UM_WAXWELL_SUMMON", sg_state = "usewaxwelljournal_pre"}, {"MAGIC", "WEAPONS"})
    ChangeSortKey("um_maxwell_nightsword", "um_maxwell_armor_sanity", "CHARACTER", true)
    ChangeSortKey("um_maxwell_nightsword", "nightsword", "WEAPONS", true)
    ChangeSortKey("um_maxwell_nightsword", "um_maxwell_armor_sanity", "MAGIC", true)
end
--AddRecipe2("pact_armor_sanity", { Ingredient("nightmarefuel", 2) }, TECH.LOST, { builder_tag = "codexmantrareader", sg_state = "pact_armor_craft", image = "armor_sanity.tex" }, { "CHARACTER", "ARMOUR" })
--AddRecipe2("pact_sword_sanity", { Ingredient("nightmarefuel", 2) }, TECH.LOST, { builder_tag = "codexmantrareader", sg_state = "pact_sword_craft", image = "nightsword.tex" }, { "CHARACTER", "WEAPONS" })

AddRecipe2("um_record_menu", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_menu.xml" }, { "DECOR" })
AddRecipe2("um_record_wixie", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_wixie.xml" }, { "DECOR" })
AddRecipe2("um_record_walter", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_walter.xml" }, { "DECOR" })
AddRecipe2("um_record_wathom", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_wathom.xml" }, { "DECOR" })
AddRecipe2("um_record_winky", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_winky.xml" }, { "DECOR" })
AddRecipe2("um_record_hooded_widow", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_hooded_widow.xml" }, { "DECOR" })
AddRecipe2("um_record_stranger", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_stranger.xml" }, { "DECOR" })
AddRecipe2("um_record_tot", { Ingredient("batwing", 1), Ingredient("charcoal", 1) }, TECH.SCIENCE_TWO, { atlas = "images/inventoryimages/um_record_stranger.xml" }, { "DECOR" })
AddRecipe2("um_record_moonmaw", { Ingredient("batwing", 1), Ingredient("moonglass", 1) }, TECH.CELESTIAL_ONE, { nounlock = true }, { atlas = "images/inventoryimages/um_record_stranger.xml" }, { "DECOR", "CRAFTING_STATION" })

ChangeSortKey("um_record_menu", "record", "DECOR", true)
ChangeSortKey("um_record_winky", "um_record_menu", "DECOR", true)
ChangeSortKey("um_record_wathom", "um_record_winky", "DECOR", true)
ChangeSortKey("um_record_wixie", "um_record_wathom", "DECOR", true)
ChangeSortKey("um_record_walter", "um_record_wixie", "DECOR", true)
ChangeSortKey("um_record_stranger", "um_record_walter", "DECOR", true)
ChangeSortKey("um_record_hooded_widow", "um_record_stranger", "DECOR", true)
ChangeSortKey("um_record_tot", "um_record_hooded_widow", "DECOR", true)
ChangeSortKey("um_record_moonmaw", "um_record_tot", "DECOR", true)

AddRecipe2("um_scrapper", { Ingredient("gears", 1), Ingredient("houndstooth", 4), Ingredient("thulecite", 2) }, GLOBAL.TECH.LOST, { placer = "um_scrapper_placer" }, { "STRUCTURES", "TOOLS" })
AddRecipe2("um_inkubator", { Ingredient("gears", 1), Ingredient("nightmarefuel", 4), Ingredient("thulecite", 2) }, GLOBAL.TECH.LOST, { placer = "um_inkubator_placer" }, { "STRUCTURES" })

AddRecipe2("um_astral_projector", { Ingredient("moonglass", 3), Ingredient("purplegem", 1), Ingredient("moonrocknugget", 3) }, GLOBAL.TECH.LOST, { placer = "um_astral_projector_placer" }, { "STRUCTURES" })

AddRecipe2("um_astral_projector_target", { Ingredient("moonglass", 1), Ingredient("purplegem", 1), Ingredient("moonrocknugget", 1) }, GLOBAL.TECH.LOST, { placer = "um_astral_projector_target_placer" }, { "STRUCTURES" })

AddRecipe2("boat_ancient_item", { Ingredient("livinglog", 16) }, GLOBAL.TECH.MAGIC_TWO, nil, { "SEAFARING" })
ChangeSortKey("boat_ancient_item", "boat_item", "SEAFARING", true)

AddRecipe2("beakbasher", { Ingredient("driftwood_log", 2), Ingredient("kelp", 8), Ingredient("ocupus_beak", 1) }, TECH.SCIENCE_TWO, nil, { "TOOLS" })
ChangeSortKey("beakbasher", "goldenshovel", "TOOLS", true)

AddRecipe2("um_hat_leafwing", { Ingredient("um_leafwing", 2), Ingredient("foliage", 4), Ingredient("log", 3) }, TECH.SCIENCE_TWO, nil, { "CLOTHING" })
ChangeSortKey("um_hat_leafwing", "beehat", "CLOTHING", true)


AddRecipe2(
	"jawed_scythe",
	{ Ingredient("twigs", 4), Ingredient("steelwool", 1), Ingredient("snappy_jaw", 3) },
	TECH.SCIENCE_ONE,
	nil,
	{ "TOOLS" }
)
ChangeSortKey("jawed_scythe", "pitchfork", "TOOLS", true)
GLOBAL.STRINGS.RECIPE_DESC.JAWED_SCYTHE = "Cut down dense flora."

AddRecipe2(
	"um_ice_sicle",
	{ Ingredient("icestaff", 1), Ingredient("livinglog", 1), Ingredient("um_rimeweed_itemflower", 1) },
	TECH.MAGIC_TWO,
	nil,
	{ "TOOLS" }
)
ChangeSortKey("um_ice_sicle", "goldenpitchfork", "TOOLS", true)
GLOBAL.STRINGS.RECIPE_DESC.UM_ICE_SICLE = "Cut down flora in the heat."

AddRecipe2(
	"um_hat_rime",
	{ Ingredient("um_ice_tail", 1), Ingredient("um_rimeweed_itemflower", 1), Ingredient("rocks", 3) },
	TECH.MAGIC_ONE,
	nil,
	{ "ARMOUR" }
)
ChangeSortKey("um_hat_rime", "armor_sharksuit_um", "ARMOUR", true)
GLOBAL.STRINGS.RECIPE_DESC.UM_HAT_RIME = "A chilly helmet for a chilly wearer."


AddRecipe2("hermitshop_bootleg", { Ingredient("messagebottleempty", 8) }, TECH.HERMITCRABSHOP_SEVEN, { nounlock = true, product = "bootleg", sg_state = "give" })
AddRecipe2("um_boatbottle", {Ingredient("chestupgrade_stacksize", 1),  Ingredient("wagpunk_bits", 2), Ingredient("moonglass", 8)}, TECH.LOST, nil, {"TOOLS", "CONTAINERS", "SEAFARING"})