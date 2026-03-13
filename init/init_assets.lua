RemapSoundEvent("dontstarve/characters/winky/death_voice", "winky/characters/winky/death_voice")
RemapSoundEvent("dontstarve/characters/winky/hurt", "winky/characters/winky/hurt")
RemapSoundEvent("dontstarve/characters/winky/talk_LP", "winky/characters/winky/talk_LP")
RemapSoundEvent("dontstarve/characters/winky/ghost_LP", "winky/characters/winky/ghost_LP")
RemapSoundEvent("dontstarve/characters/winky/nightmare_LP", "winky/characters/winky/nightmare_LP")
RemapSoundEvent("dontstarve/characters/winky/yawn", "winky/characters/winky/yawn")
RemapSoundEvent("dontstarve/characters/winky/emote", "winky/characters/winky/emote")
RemapSoundEvent("dontstarve/characters/winky/pose", "winky/characters/winky/pose")
RemapSoundEvent("dontstarve/characters/winky/yawn", "winky/characters/winky/yawn")
RemapSoundEvent("dontstarve/characters/winky/eye_rub_vo", "winky/characters/winky/eye_rub_vo")
RemapSoundEvent("dontstarve/characters/winky/carol", "winky/characters/winky/carol")
RemapSoundEvent("dontstarve/characters/winky/sinking", "winky/characters/winky/sinking")

--Items
--Registering all item atlas so we don't have to keep doing it on each craft/prefab.
--PLEASE keep atlas names and image names the same so we can continue to do this like this.
local inventoryitems =
{
    "um_buttery_fly",
    "um_ghost_pepper_item",
    "air_conditioner",
    "ancient_amulet_red",
    "aphid",
    "armor_glassmail",
    "beargerclaw",
    "beefalowings",
    "berniebox",
    "blowgunammo_electric",
    "blowgunammo_fire",
    "blowgunammo_sleep",
    "blowgunammo_tooth",
    "blue_mushed_room",
    "blueberrypancakes",
    "bluegem_cracked",
    "book_rain_um",
    "bugzapper",
    "californiaking",
    "cctrinket_don",
    "cctrinket_freddo",
    "cctrinket_jazzy",
    "cctrinket_names",
    "codex_mantra",
    "chester_eyebone_closed_lazy",
    "chester_eyebone_lazy",
    "cookedmonstersmallmeat",
    "corncan",
    "corvushat",
    "crabclaw",
    "critterlab_real",
    "cursed_antler",
    "um_exhumer",
    "um_exhumer_powered",
    "um_wingsuit",
    "silksack",
    "silken_bundle_large",
    "silken_bundle_medium",
    "silken_bundle_small",
    "um_moonfly_lantern",
    "dart_red",
    "devilsfruitcake",
    "diseasebomb",
    "diseasecurebomb",
    "dormant_rain_horn",
    "driftwoodfishingrod",
    "feather_frock",
    "floral_bandage",
    "um_rimeweed_icepack",
    "gasmask",
    "giant_blueberry",
    "glass_scales",
    "gore_horn_hat",
    "grassgekko",
    "green_mushed_room",
    "green_vomit",
    "greenfoliage",
    "greengem_cracked",
    "hat_bagmask",
    "hat_blackcatmask",
    "hat_clownmask",
    "hat_devilmask",
    "hat_fiendmask",
    "hat_ghostmask",
    "hat_globmask",
    "hat_hockeymask",
    "hat_joyousmask",
    "hat_mandrakemask",
    "hat_mermmask",
    "hat_oozemask",
    "hat_opossummask",
    "hat_orangecatmask",
    "hat_phantommask",
    "hat_pigmask",
    "hat_pumpgoremask",
    "hat_ratmask",
    "hat_redskullmask",
    "hat_spectremask",
    "hat_technomask",
    "hat_wathommask",
    "hat_whitecatmask",
    "honey_log",
    "iceboomerang",
    "klaus_amulet",
    "liceloaf",
    "monstersmallmeat",
    "monstersmallmeat_dried",
    "moon_tear",
    "moonglass_geode",
    "mutator_trapdoor",
    "nervoustick_1",
    "nervoustick_2",
    "nervoustick_3",
    "nervoustick_4",
    "nervoustick_5",
    "nervoustick_6",
    "nervoustick_7",
    "nervoustick_8",
    "um_meat_cube",
    "um_monster_cube",
    "um_veggie_cube",
    "um_sugar_cube",
    "um_roughage_cube",
    "um_bland_cube",
    "oculet",
    "opalpreciousgem_cracked",
    "orange_vomit",
    "orangegem_cracked",
    "pale_vomit",
    "pied_piper_flute",
    "pink_vomit",
    "plaguemask",
    "purple_vomit",
    "purplegem_cracked",
    "rain_horn",
    "rat_fur",
    "rat_tail",
    "rat_whip",
    "ratpoisonbottle",
    "red_mushed_room",
    "red_vomit",
    "redgem_cracked",
    "rice",
    "rice_cooked",
    "rne_goodiebag",
    "saltpack",
    --"sand",
    "screecher_trinket",
    "seafoodpaella",
    "shadow_crown",
    "shroom_skin_fragment",
    "simpsalad",
    "skeletonmeat",
    "skullchest_child",
    "skullflask",
    "skullflask_empty",
    "slobberlobber",
    "snapplant",
    "snotroast",
    "um_ghost_fajita",
    "um_boom_tart",
    "snowcone",
    "snowgoggles",
    "spider_trapdoor",
    "spider_trapdoor_hooded",
    "sporepack",
    "stanton_shadow_tonic",
    "stanton_shadow_tonic2",
    "stuffed_peeper_poppers",
    "sunglasses",
    "theatercorn",
    "turf_ancienthoodedturf",
    "turf_hoodedmoss",


    "turf_um_hotspring_grass",
    "turf_um_hotspring_yellowrock",
    "turf_um_hotspring_whiterock",
    "turf_um_magma",

    "um_bear_trap_equippable",
    "um_bear_trap_equippable_gold",
    "um_bear_trap_equippable_tooth",
    "um_deviled_eggs",
    "um_magnerang",
    "um_monsteregg",
    "um_monsteregg_cooked",
    "uncompromising_blowgun",
    "uncompromising_fishingnet",
    "uncompromising_harpoon",
    "viperfruit",
    "viperfruit_lesser",
    "viperjam",
    "watermelon_lantern",
    "whisperpod",
    "widowsgrasp",
    "widowshead",
    "woodpecker",
    "yellow_vomit",
    "yellowgem_cracked",
    "zaspberry",
    "zaspberry_lesser",
    "zaspberryparfait",
    "um_beegun",
    "um_beegun_cherry",
    "bulletbee",
    "cherrybulletbee",
    "sludge",
    "sludge_cork",
    "sludge_sack",
    "cannonball_sludge_item",
    "boatpatch_sludge",
    "uncompromising_harpoon_heavy",
    "rockjawleather",
    "armor_sharksuit_um",
    "boat_bumper_sludge_kit",
    "armor_reed_um",
    "boat_bumper_copper_kit",
    "um_copper_pipe",
    "powercell",
    "winona_toolbox",
    "winona_upgradekit_electrical",
    "portableboat_item",
    "critter_figgy_builder",
    "ocupus_tentacle",
    "ocupus_tentacle_eye",
    "ocupus_tentacle_cooked",
    "ocupus_beak",
    "beakbasher",
    "plaunt_manny",
    "um_brineishmoss",
    "brine_balm",
    "sludge_oil",
    "mastupgrade_windturbine_item",
    "charles_t_horse",
    "the_real_charles_t_horse",
    "um_ornament_opossum",
    "um_ornament_rat",
    "trinket_wathom1",
    "wooden_queen_piece",
    "wixie_piano_card",
    "wathgrithr_shield_dreadstone",

    --Magma Caves icons
    "um_smolder_spore",
    "um_armor_pyre_nettles",
    "um_blowdart_pyre",
    "um_fyrite",
    "um_fyre_bomb",
    -- Mutation Extrapolation
    "um_staff_meteor",

    -- Ghosts of the Past

    "maxwell_vetskull",
    "walter_vetskull",
    "wanda_vetskull",
    "warly_vetskull",
    "webber_vetskull",
    "wendy_vetskull",
    "wes_vetskull",
    "wickerbottom_vetskull",
    "wathgrithr_vetskull",
    "willow_vetskull",
    "wilson_vetskull",
    "wixie_vetskull",
    "winona_vetskull",
    "wolfgang_vetskull",
    "wonkey_vetskull",
    "woodie_vetskull",
    "wormwood_vetskull",
    "wortox_vetskull",
    "wurt_vetskull",
    "wx78_vetskull",

    -- Records

    "um_record_menu",
    "um_record_walter",
    "um_record_wixie",
    "um_record_shadow_wixie",
    "um_record_hooded_widow",
    "um_record_wathom",
    "um_record_stranger",
    "um_record_winky",
    "um_record_moonmaw",
    "um_record_tot",

    --Wixie related inventory icons

    "slingshot_gnasher",
    "slingshot_matilda",
    "slingshot_jessie",
    "slingshot_jessie_1",
    "slingshot_jessie_2",
    "slingshot_jessie_3",
    "slingshot_claire",
    "slingshotammo_firecrackers",
    "slingshotammo_honey",
    "slingshotammo_rubber",
    "slingshotammo_tremor",
    "slingshotammo_moonrock",
    "slingshotammo_moonglass",
    "slingshotammo_salt",
    "slingshotammo_limestone",
    "slingshotammo_tar",
    "slingshotammo_obsidian",
    "slingshotammo_goop",
    "slingshotammo_slime",
    "slingshotammo_lazy",
    "slingshotammo_shadow",
    "slingshotammo_flare",
    "bagofmarbles",

    "placeholder_ingredient_ia",
    "placeholder_ingredient_ia_um",

    --Walters jerky hats
    "meatrack_hat",
    "meatrack_hat_batnose",
    "meatrack_hat_batwing",
    "meatrack_hat_drumstick",
    "meatrack_hat_eel",
    "meatrack_hat_fish",
    "meatrack_hat_fishmeat",
    "meatrack_hat_fishmeat_small",
    "meatrack_hat_froglegs",
    "meatrack_hat_humanmeat",
    "meatrack_hat_kelp",
    "meatrack_hat_meat",
    "meatrack_hat_monstermeat",
    "meatrack_hat_monstersmallmeat",
    "meatrack_hat_default",
    "meatrack_hat_plantmeat",
    "meatrack_hat_smallmeat",

    --ia (and possibly hamlet) related wixie icons
    "meatrack_hat_solofish_dead",
    "meatrack_hat_swordfish_dead",
    "meatrack_hat_jellyfish_dead",
    "meatrack_hat_rainbowjellyfish_dead",
    "meatrack_hat_fish_tropical",
    "meatrack_hat_seaweed",
    "meatrack_hat_venus_stalk",
    "meatrack_hat_froglegs_poison",

    --skins
    "ms_ancient_amulet_red_demoneye",
    "ms_hat_plaguemask_formal",
    "ms_plaguemask_formal", --dunno??
    "ms_feather_frock_fancy",
    "ms_twisted_antler",

    --winona stuff
    "winona_battery_low_item_um",
    "winona_battery_high_item_um",
    "winona_spotlight_item_um",
    "winona_catapult_item_um",

    --crab king items
    "hat_crab",
    "staff_starfall",


    -- Rimeweed Stuff
    "um_rimeweed_spagett",
    "um_rimeweed_tequila",
    "um_rimeweed_itemvine",
    "um_rimeweed_itemflower",
    "um_blowdart_rime",
    "um_armor_bramble_rimeweed",
    "rimeweed_whip",
    "um_hat_rime",
    "um_ice_tail",

    -- Snaildrake related
    "snaildrakehat",
    "snaildrakebucket_empty",

    "snaildrakebucket_lava_low",
    "snaildrakebucket_lava_med",
    "snaildrakebucket_lava_full",

    "snaildrakebucket_water_low",
    "snaildrakebucket_water_med",
    "snaildrakebucket_water_full",

    "snapalm",

    -- Lava Caves
    "gloomcap",
    "gloomcap_cooked",

    -- Misc from this update
    "um_durian_cream_marshcake",
    "um_chiles_en_nogada",
    "um_rice_pudding",
    "um_kebab",

    --Boat bottle
    "um_boatbottle",
    "jawed_scythe",
    "um_ice_sicle",
    "snappy_jaw",
    "um_hat_leafwing",
    "um_leafwing",
    "um_detonator",
    "um_bee_moon",
    "um_fyre_bomb",
    "um_meatcomb",
    "um_meathoney",
    "um_hat_bee_moon",
    "um_eyebalm",
    "um_beemine_moon_item",
    "um_ribopod",
    "um_ribopodden",
    "um_spongeplant_item",
    "um_sponge_cake",
    "um_moss",


    "um_gemologybluegem1",
    "um_gemologybluegem2",
    "um_gemologyredgem1",
    "um_gemologyredgem2",
    "um_gemologypurplegem1",
    "um_gemologypurplegem2",
    "um_gemologyyellowgem1",
    "um_gemologyyellowgem2",
    "um_gemologygreengem1",
    "um_gemologygreengem2",
    "um_gemologyorangegem1",
    "um_gemologyorangegem2",
    "um_gemologypalegem1",
    "um_gemologypalegem2",

    "um_gemology_geode_red",
    "um_gemology_geode_blue",
    "um_gemology_geode_green",
    "um_gemology_geode_guano",
    "um_gemology_geode_lobster",
    "um_gemology_geode_glass",
    "um_gemology_geode_slime",
    "um_gemology_geode_ruins",

    "um_flamethrower",
    "um_firecream",
    "um_pepperdragon_bladder",
    "um_hat_pepperdragon",
    "um_boomberry_bomb",
    "um_boomberrypie",

    "um_magnifier",
    "um_gemology_pouch",
    --"um_gemology_pouch_open",
}


for _, item in ipairs(inventoryitems) do
    RegisterInventoryItemAtlas(GLOBAL.resolvefilepath("images/inventoryimages/" .. item .. ".xml"), item .. ".tex")
end

Assets = {
    -- Cookbook HQ Icons
    Asset("IMAGE", "images/cookbook_beefalowings.tex"),
    Asset("ATLAS", "images/cookbook_beefalowings.xml"),
    Asset("IMAGE", "images/cookbook_blueberrypancakes.tex"),
    Asset("ATLAS", "images/cookbook_blueberrypancakes.xml"),
    Asset("IMAGE", "images/cookbook_californiaking.tex"),
    Asset("ATLAS", "images/cookbook_californiaking.xml"),
    Asset("IMAGE", "images/cookbook_devilsfruitcake.tex"),
    Asset("ATLAS", "images/cookbook_devilsfruitcake.xml"),
    Asset("IMAGE", "images/cookbook_liceloaf.tex"),
    Asset("ATLAS", "images/cookbook_liceloaf.xml"),
    Asset("IMAGE", "images/cookbook_seafoodpaella.tex"),
    Asset("ATLAS", "images/cookbook_seafoodpaella.xml"),
    Asset("IMAGE", "images/cookbook_simpsalad.tex"),
    Asset("ATLAS", "images/cookbook_simpsalad.xml"),
    Asset("IMAGE", "images/cookbook_snotroast.tex"),
    Asset("ATLAS", "images/cookbook_snotroast.xml"),
    Asset("IMAGE", "images/cookbook_snowcone.tex"),
    Asset("ATLAS", "images/cookbook_snowcone.xml"),
    Asset("IMAGE", "images/cookbook_stuffed_peeper_poppers.tex"),
    Asset("ATLAS", "images/cookbook_stuffed_peeper_poppers.xml"),
    Asset("IMAGE", "images/cookbook_theatercorn.tex"),
    Asset("ATLAS", "images/cookbook_theatercorn.xml"),
    Asset("IMAGE", "images/cookbook_um_deviled_eggs.tex"),
    Asset("ATLAS", "images/cookbook_um_deviled_eggs.xml"),
    Asset("IMAGE", "images/cookbook_um_rimeweed_spagett.tex"),
    Asset("ATLAS", "images/cookbook_um_rimeweed_spagett.xml"),
    Asset("IMAGE", "images/cookbook_um_rimeweed_tequila.tex"),
    Asset("ATLAS", "images/cookbook_um_rimeweed_tequila.xml"),
    Asset("IMAGE", "images/cookbook_viperjam.tex"),
    Asset("ATLAS", "images/cookbook_viperjam.xml"),
    Asset("IMAGE", "images/cookbook_zaspberryparfait.tex"),
    Asset("ATLAS", "images/cookbook_zaspberryparfait.xml"),

    Asset("IMAGE", "images/cookbook_um_durian_cream_marshcake.tex"),
    Asset("ATLAS", "images/cookbook_um_durian_cream_marshcake.xml"),

    Asset("IMAGE", "images/cookbook_um_chiles_en_nogada.tex"),
    Asset("ATLAS", "images/cookbook_um_chiles_en_nogada.xml"),

    Asset("IMAGE", "images/cookbook_um_rice_pudding.tex"),
    Asset("ATLAS", "images/cookbook_um_rice_pudding.xml"),

    Asset("IMAGE", "images/cookbook_um_kebab.tex"),
    Asset("ATLAS", "images/cookbook_um_kebab.xml"),

    Asset("IMAGE", "images/cookbook_um_sponge_cake.tex"),
    Asset("ATLAS", "images/cookbook_um_sponge_cake.xml"),

    Asset("IMAGE", "images/cookbook_um_boomberrypie.tex"),
    Asset("ATLAS", "images/cookbook_um_boomberrypie.xml"),

    --crafting menu avatars
    Asset("IMAGE", "images/crafting_menu_avatars/avatar_wixie.tex"),
    Asset("ATLAS", "images/crafting_menu_avatars/avatar_wixie.xml"),
    Asset("IMAGE", "images/crafting_menu_avatars/avatar_winky.tex"),
    Asset("ATLAS", "images/crafting_menu_avatars/avatar_winky.xml"),
    Asset("IMAGE", "images/crafting_menu_avatars/avatar_wathom.tex"),
    Asset("ATLAS", "images/crafting_menu_avatars/avatar_wathom.xml"),

    Asset("ATLAS", "images/wixie_skilltree.xml"),
    Asset("IMAGE", "images/wixie_skilltree.tex"),

    Asset("ATLAS", "images/wathom_skilltree.xml"),
    Asset("IMAGE", "images/wathom_skilltree.tex"),


    ----TURF
    Asset("IMAGE", "levels/textures/noise_hoodedmoss.tex"),
    Asset("IMAGE", "levels/textures/ground_noise_hoodedfoliage.tex"),
    Asset("ANIM", "anim/hfturf.zip"),
    Asset("ANIM", "anim/swturf.zip"),
    ----ASSET("ATLAS_BUILD", "images/inventoryimages/turf_jungle.xml"),
    --Asset("ATLAS", "images/inventoryimages/turf_jungle.xml"),
    --Asset("IMAGE", "images/inventoryimages/turf_jungle.tex"),
    ----Turf



    --WINKY!!!

    Asset("IMAGE", "images/saveslot_portraits/winky.tex"),
    Asset("ATLAS", "images/saveslot_portraits/winky.xml"),

    Asset("IMAGE", "images/selectscreen_portraits/winky.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/winky.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/winky_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/winky_silho.xml"),

    Asset("IMAGE", "bigportraits/winky.tex"),
    Asset("ATLAS", "bigportraits/winky.xml"),
    Asset("IMAGE", "bigportraits/winky_none.tex"),
    Asset("ATLAS", "bigportraits/winky_none.xml"),

    Asset("IMAGE", "images/map_icons/winky.tex"),
    Asset("ATLAS", "images/map_icons/winky.xml"),

    Asset("IMAGE", "images/avatars/avatar_winky.tex"),
    Asset("ATLAS", "images/avatars/avatar_winky.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_winky.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_winky.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_winky.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_winky.xml"),

    Asset("IMAGE", "images/names_gold_winky.tex"),
    Asset("ATLAS", "images/names_gold_winky.xml"),

    Asset("IMAGE", "images/names_winky.tex"),
    Asset("ATLAS", "images/names_winky.xml"),

    Asset("SOUNDPACKAGE", "sound/winky.fev"),
    Asset("SOUND", "sound/winky.fsb"),

    -- WATHOM!!!
    Asset("ANIM", "anim/vvathom_run.zip"),
    Asset("ANIM", "anim/ampbadge.zip"),

    Asset("IMAGE", "images/colour_cubes/bat_vision_on_cc.tex"),
    --Asset("ATLAS", "images/colour_cubes/hamlet_colour_cubes_import.xml"),

    Asset("IMAGE", "images/saveslot_portraits/wathom.tex"),
    Asset("ATLAS", "images/saveslot_portraits/wathom.xml"),

    Asset("IMAGE", "images/selectscreen_portraits/wathom.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/wathom.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/wathom_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/wathom_silho.xml"),

    Asset("IMAGE", "bigportraits/wathom.tex"),
    Asset("ATLAS", "bigportraits/wathom.xml"),
    Asset("IMAGE", "bigportraits/wathom_none.tex"),
    Asset("ATLAS", "bigportraits/wathom_none.xml"),

    Asset("IMAGE", "images/map_icons/wathom.tex"),
    Asset("ATLAS", "images/map_icons/wathom.xml"),

    Asset("IMAGE", "images/avatars/avatar_wathom.tex"),
    Asset("ATLAS", "images/avatars/avatar_wathom.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_wathom.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_wathom.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_wathom.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_wathom.xml"),

    Asset("IMAGE", "images/names_wathom.tex"),
    Asset("ATLAS", "images/names_wathom.xml"),

    Asset("IMAGE", "images/names_gold_wathom.tex"),
    Asset("ATLAS", "images/names_gold_wathom.xml"),

    Asset("ANIM", "anim/wathom_triumphant.zip"),
    Asset("ANIM", "anim/wathom_shadow_triumphant.zip"),

    Asset("IMAGE", "bigportraits/wathom_triumphant.tex"),
    Asset("ATLAS", "bigportraits/wathom_triumphant.xml"),

    -- ITS WIXIE!!! (Also walter...)

    Asset("ANIM", "anim/wixie.zip"),
    Asset("ANIM", "anim/ghost_wixie_build.zip"),
    Asset("ANIM", "anim/wixie_idle.zip"),
    Asset("ANIM", "anim/player_pistol.zip"),

    Asset("ANIM", "anim/swap_jessie_1.zip"),
    Asset("ANIM", "anim/swap_jessie_2.zip"),
    Asset("ANIM", "anim/swap_jessie_3.zip"),

    Asset("ANIM", "anim/wixie_shadowclone.zip"),

    Asset("ANIM", "anim/wixieammo.zip"),
    Asset("ANIM", "anim/wixieammo_IA.zip"),
    Asset("ANIM", "anim/shadowvortex.zip"),
    Asset("ANIM", "anim/goldshattered.zip"),
    Asset("ANIM", "anim/curse_muncher.zip"),
    Asset("ANIM", "anim/bowlingping.zip"),
    Asset("ANIM", "anim/walterwhistle.zip"),
    Asset("ANIM", "anim/walter_heal_fx.zip"),
    Asset("ANIM", "anim/marblebag.zip"),
    Asset("ANIM", "anim/swap_marblebag.zip"),
    Asset("ANIM", "anim/baggedmarbles.zip"),

    Asset("ANIM", "anim/wixie_reticuleline.zip"),

    Asset("ANIM", "anim/swap_wixiegun.zip"),

    Asset("ANIM", "anim/wixie_slimeball.zip"),

    Asset("ANIM", "anim/slingshot_matilda.zip"),
    Asset("ANIM", "anim/swap_slingshot_matilda.zip"),
    Asset("ANIM", "anim/slingshot_gnasher.zip"),
    Asset("ANIM", "anim/swap_slingshot_gnasher.zip"),


    Asset("ANIM", "anim/meatrack_hat_swap.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_batnose.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_batwing.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_default.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_drumstick.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_eel.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fish.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fishmeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fishmeat_small.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_froglegs.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_humanmeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_kelp.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_meat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_monstermeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_plantmeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_smallmeat.zip"),

    --Uncompromising Mode
    Asset("ANIM", "anim/meatrack_hat_swap_monstersmallmeat.zip"),

    --Shipwrecked and Hamlet Jerky Hats

    Asset("ANIM", "anim/meatrack_hat_swap_solofish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_swordfish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_jellyfish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_rainbowjellyfish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fish_tropical.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_seaweed.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_venus_stalk.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_froglegs_poison.zip"),

    Asset("ANIM", "anim/status_meter_woby_small.zip"),
    Asset("ANIM", "anim/woby_big_command.zip"),
    Asset("ANIM", "anim/woby_does_a_flip.zip"),

    Asset("IMAGE", "bigportraits/wixie.tex"),
    Asset("ATLAS", "bigportraits/wixie.xml"),
    Asset("IMAGE", "bigportraits/wixie_none.tex"),
    Asset("ATLAS", "bigportraits/wixie_none.xml"),

    Asset("IMAGE", "images/names_gold_wixie.tex"),
    Asset("ATLAS", "images/names_gold_wixie.xml"),

    Asset("IMAGE", "images/map_icons/wixie.tex"),
    Asset("ATLAS", "images/map_icons/wixie.xml"),

    Asset("IMAGE", "images/avatars/avatar_wixie.tex"),
    Asset("ATLAS", "images/avatars/avatar_wixie.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_wixie.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_wixie.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_wixie.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_wixie.xml"),

    Asset("SOUNDPACKAGE", "sound/wixie.fev"),
    Asset("SOUND", "sound/wixie.fsb"),

    Asset("ATLAS", "images/claustrophobia.xml"),
    Asset("IMAGE", "images/claustrophobia.tex"),



    Asset("ANIM", "anim/um_minotaur_actions.zip"),

    Asset("ANIM", "anim/wackycocoons.zip"),
    Asset("ANIM", "anim/wackycocoonsmall.zip"), --Had to seperate into second build, too big for a single build, -- Still broken though, this needs to be recompiled.

    Asset("ANIM", "anim/woodpecker_build.zip"),

    Asset("ANIM", "anim/um_bq_actions.zip"),
    Asset("ANIM", "anim/um_beeguard.zip"),
    Asset("ANIM", "anim/bee_mine_explode_reset.zip"),

    Asset("ANIM", "anim/uncompromising_dragonflyactions.zip"),
    Asset("ANIM", "anim/uncompromising_goosemooseactions.zip"),

    Asset("ANIM", "anim/moonmaw_dragonfly.zip"),
    Asset("ANIM", "anim/moonmaw_lavae.zip"),

    Asset("ANIM", "anim/deerclops_mutation_anims.zip"),
    Asset("ANIM", "anim/deerclops_barrier.zip"),
    Asset("ANIM", "anim/laserclops_anims.zip"),
    Asset("ANIM", "anim/deerclops_build_old.zip"), --Until I fix the anims, this'll be the solution (AXE)

    Asset("ANIM", "anim/nymph.zip"),

    Asset("ANIM", "anim/carnival_host_death.zip"),

    Asset("ANIM", "anim/wilton.zip"),


    Asset("IMAGE", "bigportraits/wathom.tex"),
    Asset("ATLAS", "bigportraits/wathom.xml"),
    Asset("IMAGE", "bigportraits/wathom_none.tex"),
    Asset("ATLAS", "bigportraits/wathom_none.xml"),

    Asset("IMAGE", "images/map_icons/wathom.tex"),
    Asset("ATLAS", "images/map_icons/wathom.xml"),

    Asset("IMAGE", "images/avatars/avatar_wathom.tex"),
    Asset("ATLAS", "images/avatars/avatar_wathom.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_wathom.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_wathom.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_wathom.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_wathom.xml"),

    Asset("IMAGE", "images/names_wathom.tex"),
    Asset("ATLAS", "images/names_wathom.xml"),

    Asset("IMAGE", "images/names_gold_wathom.tex"),
    Asset("ATLAS", "images/names_gold_wathom.xml"),

    Asset("ANIM", "anim/wathom_triumphant.zip"),
    Asset("ANIM", "anim/wathom_shadow_triumphant.zip"),

    Asset("IMAGE", "bigportraits/wathom_triumphant.tex"),
    Asset("ATLAS", "bigportraits/wathom_triumphant.xml"),

    -- ITS WIXIE!!! (Also walter...)

    Asset("ANIM", "anim/wixie.zip"),
    Asset("ANIM", "anim/ghost_wixie_build.zip"),
    Asset("ANIM", "anim/wixie_idle.zip"),
    Asset("ANIM", "anim/player_pistol.zip"),

    Asset("ANIM", "anim/swap_jessie_1.zip"),
    Asset("ANIM", "anim/swap_jessie_2.zip"),
    Asset("ANIM", "anim/swap_jessie_3.zip"),

    Asset("ANIM", "anim/wixie_shadowclone.zip"),

    Asset("ANIM", "anim/wixieammo.zip"),
    Asset("ANIM", "anim/wixieammo_IA.zip"),
    Asset("ANIM", "anim/shadowvortex.zip"),
    Asset("ANIM", "anim/goldshattered.zip"),
    Asset("ANIM", "anim/curse_muncher.zip"),
    Asset("ANIM", "anim/bowlingping.zip"),
    Asset("ANIM", "anim/walterwhistle.zip"),
    Asset("ANIM", "anim/walter_heal_fx.zip"),
    Asset("ANIM", "anim/marblebag.zip"),
    Asset("ANIM", "anim/swap_marblebag.zip"),
    Asset("ANIM", "anim/baggedmarbles.zip"),

    Asset("ANIM", "anim/wixie_reticuleline.zip"),

    Asset("ANIM", "anim/swap_wixiegun.zip"),

    Asset("ANIM", "anim/wixie_slimeball.zip"),

    Asset("ANIM", "anim/slingshot_matilda.zip"),
    Asset("ANIM", "anim/swap_slingshot_matilda.zip"),
    Asset("ANIM", "anim/slingshot_gnasher.zip"),
    Asset("ANIM", "anim/swap_slingshot_gnasher.zip"),


    Asset("ANIM", "anim/meatrack_hat_swap.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_batnose.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_batwing.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_default.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_drumstick.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_eel.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fish.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fishmeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fishmeat_small.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_froglegs.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_humanmeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_kelp.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_meat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_monstermeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_plantmeat.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_smallmeat.zip"),

    --Uncompromising Mode
    Asset("ANIM", "anim/meatrack_hat_swap_monstersmallmeat.zip"),

    --Shipwrecked and Hamlet Jerky Hats

    Asset("ANIM", "anim/meatrack_hat_swap_solofish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_swordfish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_jellyfish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_rainbowjellyfish_dead.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_fish_tropical.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_seaweed.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_venus_stalk.zip"),
    Asset("ANIM", "anim/meatrack_hat_swap_froglegs_poison.zip"),

    Asset("ANIM", "anim/status_meter_woby_small.zip"),
    Asset("ANIM", "anim/woby_big_command.zip"),
    Asset("ANIM", "anim/woby_does_a_flip.zip"),

    Asset("IMAGE", "bigportraits/wixie.tex"),
    Asset("ATLAS", "bigportraits/wixie.xml"),
    Asset("IMAGE", "bigportraits/wixie_none.tex"),
    Asset("ATLAS", "bigportraits/wixie_none.xml"),

    Asset("IMAGE", "images/names_gold_wixie.tex"),
    Asset("ATLAS", "images/names_gold_wixie.xml"),

    Asset("IMAGE", "images/map_icons/wixie.tex"),
    Asset("ATLAS", "images/map_icons/wixie.xml"),

    Asset("IMAGE", "images/avatars/avatar_wixie.tex"),
    Asset("ATLAS", "images/avatars/avatar_wixie.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_wixie.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_wixie.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_wixie.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_wixie.xml"),

    Asset("SOUNDPACKAGE", "sound/wixie.fev"),
    Asset("SOUND", "sound/wixie.fsb"),

    Asset("ATLAS", "images/claustrophobia.xml"),
    Asset("IMAGE", "images/claustrophobia.tex"),



    Asset("ANIM", "anim/um_minotaur_actions.zip"),

    Asset("ANIM", "anim/wackycocoons.zip"),
    Asset("ANIM", "anim/wackycocoonsmall.zip"), --Had to seperate into second build, too big for a single build

    Asset("ANIM", "anim/woodpecker_build.zip"),

    Asset("ANIM", "anim/um_bq_actions.zip"),
    Asset("ANIM", "anim/um_beeguard.zip"),
    Asset("ANIM", "anim/bee_mine_explode_reset.zip"),

    Asset("ANIM", "anim/uncompromising_dragonflyactions.zip"),
    Asset("ANIM", "anim/uncompromising_goosemooseactions.zip"),

    Asset("ANIM", "anim/moonmaw_dragonfly.zip"),
    Asset("ANIM", "anim/moonmaw_lavae.zip"),

    Asset("ANIM", "anim/deerclops_mutation_anims.zip"),
    Asset("ANIM", "anim/deerclops_barrier.zip"),
    Asset("ANIM", "anim/laserclops_anims.zip"),
    Asset("ANIM", "anim/deerclops_build_old.zip"), --Until I fix the anims, this'll be the solution (AXE), considering just redoing the entire UM deerclops.

    Asset("ANIM", "anim/nymph.zip"),

    Asset("ANIM", "anim/carnival_host_death.zip"), -- This is an actual animation XD?

    Asset("ANIM", "anim/wilton.zip"),

    Asset("ANIM", "anim/magmahound.zip"),
    Asset("ANIM", "anim/viperworm.zip"),

    Asset("ANIM", "anim/bight.zip"),
    Asset("ANIM", "anim/knook.zip"),
    Asset("ANIM", "anim/roship.zip"),
    Asset("ANIM", "anim/roship_attack.zip"),


    Asset("ANIM", "anim/rnegrabby.zip"),
    Asset("ANIM", "anim/rne_grabbylarge.zip"),
    Asset("ANIM", "anim/rnesushadow.zip"),
    Asset("ANIM", "anim/mindweaver.zip"),
    Asset("ANIM", "anim/um_fuelseeker.zip"),
    Asset("ANIM", "anim/um_heckler.zip"),

    Asset("ANIM", "anim/figgy_newton.zip"),

    Asset("ANIM", "anim/hound_jump_attack.zip"),
    -- update for pawn
    Asset("ANIM", "anim/um_pawn.zip"),
    Asset("ANIM", "anim/um_pawn_nightmare.zip"),
    Asset("ANIM", "anim/shambler.zip"),

    Asset("ANIM", "anim/nervoustick.zip"),

    Asset("ANIM", "anim/um_food_cube.zip"),

    Asset("ANIM", "anim/graspingfear.zip"),

    Asset("ANIM", "anim/koalefant_scare.zip"),
    Asset("ANIM", "anim/koalefant_paw.zip"),
    Asset("ANIM", "anim/koalefant_stomp.zip"),

    Asset("ANIM", "anim/ancient_trepidation.zip"),
    Asset("ANIM", "anim/ancient_trepidation_arm.zip"),
    Asset("ANIM", "anim/ancient_trepidation_nomouth.zip"),

    Asset("ANIM", "anim/ds_pig_charge.zip"),
    Asset("ANIM", "anim/ds_pig_uppercut.zip"),

    Asset("ANIM", "anim/lazy_chester.zip"),

    Asset("ANIM", "anim/um_buttery_fly.zip"),

    Asset("ANIM", "anim/um_ghost_pepper_item.zip"),

    Asset("ANIM", "anim/hound_jump_attack.zip"),

    Asset("ANIM", "anim/krampus_bag_smack.zip"),

    Asset("ANIM", "anim/goosemoose_hopattack.zip"),
    Asset("ANIM", "anim/goosemoose_hopattack_pre.zip"),

    Asset("ANIM", "anim/dragonfly_charge_attack.zip"),
    Asset("ANIM", "anim/vomit_atk.zip"),

    Asset("ANIM", "anim/lureplague_rat.zip"),

    Asset("ANIM", "anim/snapperturtle.zip"),
    Asset("ANIM", "anim/snapperturtlebaby.zip"),

    Asset("ANIM", "anim/chomper.zip"),

    Asset("ANIM", "anim/widow1.zip"),
    Asset("ANIM", "anim/widow2.zip"),
    Asset("ANIM", "anim/widow1_backup.zip"),
    Asset("ANIM", "anim/widow2_backup.zip"),

    Asset("ANIM", "anim/silken_bundle.zip"),

    Asset("ANIM", "anim/sheeplet.zip"),
    Asset("ANIM", "anim/sheepletbomb.zip"),

    Asset("ANIM", "anim/aphid.zip"),
    Asset("ANIM", "anim/weevole.zip"),

    Asset("ANIM", "anim/fruitbat.zip"),

    Asset("ANIM", "anim/mushdrake_red.zip"),

    --Asset("ANIM", "anim/gatorsnake.zip"),

    Asset("ANIM", "anim/swilson.zip"),

    Asset("ANIM", "anim/stumpling.zip"),
    Asset("ANIM", "anim/birchling.zip"),


    Asset("ANIM", "anim/bat_vamp_build.zip"),
    Asset("ANIM", "anim/bat_vamp_shadow.zip"),

    Asset("ANIM", "anim/tree_leaf_spike_lt.zip"),

    Asset("ANIM", "anim/frog_yellow_build.zip"),

    Asset("ANIM", "anim/deerclops_ground_fx.zip"),

    Asset("ANIM", "anim/deerclopsfalling.zip"),

    Asset("ANIM", "anim/player_sneeze.zip"),

    Asset("ANIM", "anim/rhino_stun.zip"),

    Asset("ANIM", "anim/bush_crab.zip"),

    Asset("ANIM", "anim/creepingfear.zip"),

    Asset("ANIM", "anim/dreadeye.zip"),
    Asset("ANIM", "anim/dreadeye_circle.zip"),
    Asset("ANIM", "anim/shadow_eye.zip"),

    Asset("ANIM", "anim/hippo_attacks.zip"),
    Asset("ANIM", "anim/hippo_basic.zip"),
    Asset("ANIM", "anim/toadling.zip"),

    Asset("ANIM", "anim/spider_trapdoor.zip"),
    Asset("ANIM", "anim/spider_trapdoor_hooded.zip"),
    Asset("ANIM", "anim/spider_trapdoor_action.zip"),

    Asset("ANIM", "anim/pied_piper.zip"),

    Asset("ANIM", "anim/uncompromising_packrat_water.zip"),
    Asset("ANIM", "anim/uncompromising_packrat.zip"),

    Asset("ANIM", "anim/mosquito_yellow_build.zip"),

    Asset("ANIM", "anim/walrus_build_summer.zip"),
    Asset("ANIM", "anim/walrus_baby_build_summer.zip"),

    Asset("ANIM", "anim/gnat_cocoon.zip"),
    Asset("ANIM", "anim/pollenmites.zip"),
    Asset("ANIM", "anim/acsporecloud.zip"),

    Asset("ANIM", "anim/shadow_teleporter.zip"),

    Asset("ANIM", "anim/snapdragon.zip"),
    Asset("ANIM", "anim/snapdragon_build.zip"),
    Asset("ANIM", "anim/snapdragon_build_pale.zip"),
    Asset("ANIM", "anim/snapdragon_build_pink.zip"),
    Asset("ANIM", "anim/snapdragon_build_yellow.zip"),
    Asset("ANIM", "anim/snapdragon_build_purple.zip"),
    Asset("ANIM", "anim/snapdragon_build_red.zip"),
    Asset("ANIM", "anim/snapdragon_build_orange.zip"),
    Asset("ANIM", "anim/snapdragon_build_green.zip"),
    Asset("ANIM", "anim/snapdragon_build_neck.zip"),
    Asset("ANIM", "anim/snapdragon_build_frozen.zip"),
    Asset("ANIM", "anim/snapplant.zip"), --if it is what I remember it being, this goes here.

    Asset("ANIM", "anim/hound_lightning.zip"),
    Asset("ANIM", "anim/hound_lightning_ocean.zip"),
    Asset("ANIM", "anim/hound_spore.zip"),
    Asset("ANIM", "anim/hound_spore_ocean.zip"),
    Asset("ANIM", "anim/glacial_hound.zip"),
    Asset("ANIM", "anim/glacial_hound_ocean.zip"),
    Asset("ANIM", "anim/um_ice_warg.zip"),


    Asset("ANIM", "anim/hippo_water_attacks.zip"),
    Asset("ANIM", "anim/hippo_water.zip"),

    Asset("ANIM", "anim/deerclops_yule_blue.zip"),
    --Asset("ANIM", "anim/yuleclops_actions_UM.zip"),
    Asset("ANIM", "anim/deerclops_laser_hit_sparks_fx_blue.zip"),
    Asset("ANIM", "anim/bearger_rockthrow.zip"),
    Asset("ANIM", "anim/bearger_build_old.zip"),

    Asset("ANIM", "anim/sea_shadow.zip"),

    --MISC.
    Asset("ANIM", "anim/sludgestack_short.zip"),

    Asset("ANIM", "anim/boat_repair_cork_build.zip"),

    Asset("ANIM", "anim/speaker_test.zip"),

    Asset("ANIM", "anim/siren_throne.zip"),

    Asset("ANIM", "anim/sunken_royalchest.zip"),
    Asset("ANIM", "anim/sunken_royalchest_rainbow.zip"),
    Asset("ANIM", "anim/sunken_royalchest_purple.zip"),
    Asset("ANIM", "anim/sunken_royalchest_red.zip"),
    Asset("ANIM", "anim/sunken_royalchest_blue.zip"),
    Asset("ANIM", "anim/sunken_royalchest_green.zip"),
    Asset("ANIM", "anim/sunken_royalchest_orange.zip"),
    Asset("ANIM", "anim/sunken_royalchest_yellow.zip"),
    Asset("ANIM", "anim/sunken_royalchest_naked.zip"),

    Asset("ANIM", "anim/driftwood_normal.zip"),

    Asset("ANIM", "anim/sorrel.zip"),

    Asset("ANIM", "anim/Bigspin.zip"),

    Asset("ANIM", "anim/um_whirlpool.zip"),

    Asset("ANIM", "anim/um_waterfall.zip"),

    Asset("ANIM", "anim/um_waterfall_pool.zip"),

    Asset("ANIM", "anim/alpha_lightning_goat_build.zip"),
    Asset("ANIM", "anim/alpha_lightning_goat_stomp.zip"),

    Asset("ANIM", "anim/marshmist.zip"),

    Asset("ANIM", "anim/ratking.zip"),
    Asset("ANIM", "anim/rattotem.zip"),
    Asset("ANIM", "anim/garbage_pile.zip"),

    Asset("ANIM", "anim/harpoon_rope.zip"),

    Asset("ANIM", "anim/armor_glassmail_shards.zip"),

    Asset("ANIM", "anim/cocoondecor.zip"),

    Asset("ANIM", "anim/skull_chest.zip"),

    Asset("ANIM", "anim/lush_grass.zip"),
    Asset("ANIM", "anim/lush_trapdoorgrass.zip"),

    Asset("ANIM", "anim/close_wardrobe.zip"),

    Asset("ANIM", "anim/guardian_splat.zip"),

    Asset("ANIM", "anim/moondialtear_build.zip"),

    Asset("ANIM", "anim/player_boat_death.zip"),
    Asset("ANIM", "anim/boat_death_shadows.zip"),
    Asset("ANIM", "anim/rne_player_grabbed.zip"),

    Asset("ANIM", "anim/player_actions_speargun.zip"),
    Asset("ANIM", "anim/player_mount_actions_speargun.zip"),

    Asset("ANIM", "anim/portableboat.zip"),
    Asset("ANIM", "anim/portableboat_test.zip"),
    Asset("ANIM", "anim/portableboat_placer.zip"),

    Asset("ANIM", "anim/lava_spitball.zip"),

    Asset("ANIM", "anim/shadowvortex.zip"),
    Asset("ANIM", "anim/shadow_leech_nt.zip"),
    Asset("ANIM", "anim/um_voxolophone.zip"),
    Asset("ANIM", "anim/um_haunt.zip"),
    Asset("ANIM", "anim/um_nightcrawler.zip"),

    Asset("ANIM", "anim/um_beegun_dart.zip"),
    Asset("ANIM", "anim/um_beegun_ball.zip"),


    Asset("ANIM", "anim/glacial_hound_projectile.zip"),

    Asset("ANIM", "anim/magmaanims.zip"),

    Asset("ANIM", "anim/mothergoosemoose_nest.zip"),

    Asset("ANIM", "anim/dragonfly_egg.zip"),

    Asset("ANIM", "anim/UM_harpoonreel.zip"),

    Asset("ANIM", "anim/um_windturbine.zip"),
    Asset("ANIM", "anim/mastupgrade_windturbine.zip"),

    Asset("ANIM", "anim/trapdoorgrass.zip"),

    Asset("ANIM", "anim/bush_marsh.zip"),

    Asset("ANIM", "anim/web_net_splat.zip"),
    Asset("ANIM", "anim/web_net_splash.zip"),
    Asset("ANIM", "anim/web_net_shot.zip"),
    Asset("ANIM", "anim/web_net_trap.zip"),
    Asset("ANIM", "anim/widowwebgoop.zip"),

    Asset("ANIM", "anim/hoodedcanopy.zip"),



    Asset("ANIM", "anim/largefern.zip"),

    Asset("ANIM", "anim/blueberryplant.zip"),
    Asset("ANIM", "anim/pitcher.zip"),

    Asset("ANIM", "anim/giant_tree_infested.zip"),

    Asset("ANIM", "anim/lava_vomit.zip"),

    Asset("ANIM", "anim/leif_root.zip"),
    Asset("ANIM", "anim/root_spike.zip"),
    Asset("ANIM", "anim/chop_root_spike.zip"),

    Asset("ANIM", "anim/snow_dune.zip"),
    --Asset("ANIM", "anim/sandhill.zip"),
    Asset("ANIM", "anim/snowpile.zip"),

    Asset("ANIM", "anim/tar.zip"),
    Asset("ANIM", "anim/tar_trap.zip"),

    Asset("ANIM", "anim/swap_minotaur_boulder.zip"),
    Asset("ANIM", "anim/pillar_ruins_damaged.zip"),

    Asset("ANIM", "anim/rat_note.zip"),

    Asset("ANIM", "anim/ratdroppings.zip"),

    Asset("ANIM", "anim/trapdoor.zip"),
    Asset("ANIM", "anim/rock_flipping.zip"),
    Asset("ANIM", "anim/rock_flipping_moss.zip"),

    Asset("ANIM", "anim/saltpile.zip"),

    Asset("ANIM", "anim/airconditioner.zip"),
    Asset("ANIM", "anim/air_conditioner_cloud.zip"),

    Asset("ANIM", "anim/veteranshrine.zip"),
    Asset("ANIM", "anim/um_vetskull.zip"),
    Asset("ANIM", "anim/um_soul_ball.zip"),

    Asset("ANIM", "anim/wortox_soul_ball_blue.zip"),
    Asset("ANIM", "anim/wortox_soul_ball_green.zip"),

    Asset("ANIM", "anim/um_records.zip"),

    Asset("ANIM", "anim/walrus_house_summer.zip"),

    Asset("ANIM", "anim/critterlab_broken.zip"),

    Asset("ANIM", "anim/whisperpod_normal_ground.zip"),

    Asset("ANIM", "anim/nightmaregrowth_shrink.zip"),

    Asset("ANIM", "anim/ancient_soul_ball.zip"),

    Asset("ANIM", "anim/gems_crabclaw.zip"),

    Asset("ANIM", "anim/bearger_boulder.zip"),

    Asset("ATLAS", "images/the_men.xml"),
    Asset("IMAGE", "images/the_men.tex"),

    Asset("ATLAS", "images/tele_icon1.xml"),
    Asset("IMAGE", "images/tele_icon1.tex"),
    Asset("ATLAS", "images/tele_icon2.xml"),
    Asset("IMAGE", "images/tele_icon2.tex"),
    Asset("ATLAS", "images/tele_icon3.xml"),
    Asset("IMAGE", "images/tele_icon3.tex"),
    Asset("ATLAS", "images/tele_icon1b.xml"),
    Asset("IMAGE", "images/tele_icon1b.tex"),
    Asset("ATLAS", "images/tele_icon2b.xml"),
    Asset("IMAGE", "images/tele_icon2b.tex"),
    Asset("ATLAS", "images/tele_icon3b.xml"),
    Asset("IMAGE", "images/tele_icon3b.tex"),
    Asset("ATLAS", "images/tele_icon1c.xml"),
    Asset("IMAGE", "images/tele_icon1c.tex"),
    Asset("ATLAS", "images/tele_icon1d.xml"),
    Asset("IMAGE", "images/tele_icon1d.tex"),
    Asset("ATLAS", "images/tele_icon5.xml"),
    Asset("IMAGE", "images/tele_icon5.tex"),
    Asset("ATLAS", "images/tele_icon5b.xml"),
    Asset("IMAGE", "images/tele_icon5b.tex"),

    --OVERLAYS
    Asset("ATLAS", "images/UM_pollenover.xml"),
    Asset("IMAGE", "images/UM_pollenover.tex"),

    Asset("ATLAS", "images/californiakingoverlay.xml"),
    Asset("IMAGE", "images/californiakingoverlay.tex"),

    Asset("ANIM", "anim/snow_over.zip"),

    Asset("ANIM", "anim/um_storm_over.zip"),

    --FX
    Asset("ANIM", "anim/electric_explosion.zip"),

    Asset("ANIM", "anim/um_harpoonhitfx.zip"),

    Asset("ANIM", "anim/um_magneranghitfx.zip"),

    Asset("ATLAS", "images/fx5.xml"),
    Asset("IMAGE", "images/fx5.tex"),

    --VET SKULLS
    --[[Asset("ATLAS", "images/inventoryimages/maxwell_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/maxwell_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/walter_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/walter_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wanda_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wanda_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/warly_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/warly_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/webber_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/webber_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wendy_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wendy_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wes_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wes_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wickerbottom_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wickerbottom_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wathgrithr_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wathgrithr_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/willow_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/willow_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wilson_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wilson_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wixie_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wixie_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/winona_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/winona_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wolfgang_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wolfgang_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wonkey_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wonkey_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/woodie_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/woodie_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wormwood_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wormwood_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wortox_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wortox_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wurt_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wurt_vetskull.tex"),
    Asset("ATLAS", "images/inventoryimages/wx78_vetskull.xml"),
    Asset("IMAGE", "images/inventoryimages/wx78_vetskull.tex"),


    --RECORDS

    Asset("ATLAS", "images/inventoryimages/um_record_menu.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_menu.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_walter.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_walter.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_wixie.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_wixie.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_shadow_wixie.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_shadow_wixie.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_hooded_widow.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_hooded_widow.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_wathom.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_wathom.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_stranger.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_stranger.tex"),
    Asset("ATLAS", "images/inventoryimages/um_record_winky.xml"),
    Asset("IMAGE", "images/inventoryimages/um_record_winky.tex"),]]

    --
    Asset("ATLAS", "images/wixiepiano_whitekey.xml"),
    Asset("IMAGE", "images/wixiepiano_whitekey.tex"),
    Asset("ATLAS", "images/wixiepiano_blackkey.xml"),
    Asset("IMAGE", "images/wixiepiano_blackkey.tex"),
    --[[Asset("IMAGE", "images/inventoryimages/charles_t_horse.tex"),
    Asset("ATLAS", "images/inventoryimages/charles_t_horse.xml"),
    Asset("IMAGE", "images/inventoryimages/the_real_charles_t_horse.tex"),
    Asset("ATLAS", "images/inventoryimages/the_real_charles_t_horse.xml"),]]

    Asset("ANIM", "anim/swap_charles_shadow.zip"),

    Asset("ANIM", "anim/uncompromising_shadow_projectile1_fx.zip"),
    Asset("ANIM", "anim/uncompromising_shadow_projectile2_fx.zip"),

    Asset("ANIM", "anim/um_spikes.zip"),
    Asset("ANIM", "anim/spikes_cookie.zip"),
    Asset("ANIM", "anim/spikes_crow.zip"),
    Asset("ANIM", "anim/spikes_goose.zip"),
    Asset("ANIM", "anim/spikes_malbatross.zip"),
    Asset("ANIM", "anim/spikes_robin.zip"),
    Asset("ANIM", "anim/spikes_robinwinter.zip"),
    Asset("ANIM", "anim/spikes_canary.zip"),

    Asset("ANIM", "anim/mara_boss1.zip"),
    Asset("ANIM", "anim/mara_boss1_bullets.zip"),
    Asset("ANIM", "anim/um_WITCH.zip"),

    -- Pyre Nettle stuff
    Asset("ANIM", "anim/um_pyre_nettles.zip"),
    Asset("ANIM", "anim/um_smolder_spore.zip"),
    Asset("ANIM", "anim/umdebuff_pyre_toxin_fx.zip"),
    Asset("ANIM", "anim/um_armor_pyre_nettles.zip"), -- This file is both a swap and a floor item. Hell if I know where to put it...so it's here!
    Asset("ANIM", "anim/um_blowdart_pyre.zip"),
    Asset("ANIM", "anim/um_blowdart_rime.zip"),
    Asset("ANIM", "anim/swap_blowdart.zip"), -- Same here. Naming convention is vanilla, blame Mr. Kelly Entertainment.

    -- Rimeweed stuff
    Asset("ANIM", "anim/rimeweed.zip"),
    Asset("ANIM", "anim/um_armor_bramble_rime.zip"),
    Asset("ANIM", "anim/um_armor_bramble_rimeweed.zip"), -- One of these is the ground sprite, the other is the swap for the body symbol...

    -- Mutation Extrapolation
    Asset("ANIM", "anim/umdebuff_moonburn_fx.zip"),
    Asset("ANIM", "anim/um_staff_meteor.zip"),
    Asset("ANIM", "anim/um_pathfinderpulse.zip"),

    --INVENTORY ITEMS [ANIMS & INV_IMAGE]
    Asset("ANIM", "anim/um_boatbottle.zip"),
    Asset("ANIM", "anim/hat_crab.zip"),
    Asset("ANIM", "anim/staff_starfall.zip"),
    Asset("ANIM", "anim/cannonball_sludge.zip"),
    Asset("ANIM", "anim/boat_repair_cork_build.zip"),

    Asset("ANIM", "anim/ancient_amulet_red_demoneye.zip"),

    Asset("ANIM", "anim/driftwood_rod_ground.zip"),

    Asset("ANIM", "anim/oculet_ground.zip"),

    Asset("ANIM", "anim/skullflask.zip"),
    Asset("ANIM", "anim/skullflask_empty.zip"),

    Asset("ANIM", "anim/um_blowguns.zip"),
    Asset("ANIM", "anim/um_darts.zip"),

    Asset("ANIM", "anim/glass_scales.zip"),
    Asset("ANIM", "anim/moonglass_geode.zip"),
    Asset("ANIM", "anim/armor_glassmail.zip"),

    --[[Asset("INV_IMAGE", "images/inventoryimages/chester_eyebone_closed_lazy"),
    Asset("INV_IMAGE", "images/inventoryimages/chester_eyebone_lazy"),]]

    Asset("ANIM", "anim/hat_corvus.zip"),

    Asset("ANIM", "anim/armor_steelsweater.zip"),
    Asset("ANIM", "anim/steelsweater.zip"),

    Asset("ANIM", "anim/amulets_ancient.zip"),

    Asset("ANIM", "anim/viperfruit.zip"),

    Asset("ANIM", "anim/viperjam.zip"),

    Asset("ANIM", "anim/snotroast.zip"),
    Asset("ANIM", "anim/um_ghost_fajita.zip"),
    Asset("ANIM", "anim/um_boom_tart.zip"),
    Asset("ANIM", "anim/rne_goodiebag.zip"),

    Asset("ANIM", "anim/hat_spectremask.zip"),

    Asset("ANIM", "anim/hat_skullmask.zip"),

    Asset("ANIM", "anim/hat_redskullmask.zip"),

    Asset("ANIM", "anim/hat_pumpgoremask.zip"),

    Asset("ANIM", "anim/hat_pigmask.zip"),

    Asset("ANIM", "anim/hat_phantommask.zip"),

    Asset("ANIM", "anim/hat_orangecatmask.zip"),

    Asset("ANIM", "anim/hat_oozemask.zip"),

    Asset("ANIM", "anim/hat_mermmask.zip"),

    Asset("ANIM", "anim/hat_joyousmask.zip"),

    Asset("ANIM", "anim/hat_hockeymask.zip"),

    Asset("ANIM", "anim/hat_globmask.zip"),

    Asset("ANIM", "anim/hat_ghostmask.zip"),

    Asset("ANIM", "anim/hat_fiendmask.zip"),

    Asset("ANIM", "anim/hat_devilmask.zip"),

    Asset("ANIM", "anim/hat_wathommask.zip"),

    Asset("ANIM", "anim/hat_clownmask.zip"),

    Asset("ANIM", "anim/hat_blackcatmask.zip"),

    Asset("ANIM", "anim/hat_bagmask.zip"),

    Asset("ANIM", "anim/hat_whitecatmask.zip"),

    Asset("ANIM", "anim/hat_mandrakemask.zip"),

    Asset("ANIM", "anim/hat_technomask.zip"),

    Asset("ANIM", "anim/hat_opossummask.zip"),

    Asset("ANIM", "anim/hat_ratmask.zip"),
    Asset("ANIM", "anim/fumes_fx.zip"),

    Asset("ANIM", "anim/um_beegun.zip"),

    Asset("ANIM", "anim/boat_bumper_sludge.zip"),

    Asset("ANIM", "anim/portableboat_item.zip"),

    Asset("ANIM", "anim/corncan.zip"),

    Asset("ANIM", "anim/hat_gore_horn.zip"),

    Asset("ANIM", "anim/chester_eyebone_lazy.zip"),

    Asset("ANIM", "anim/um_trap_snare.zip"),
    Asset("ANIM", "anim/um_bear_trap_old.zip"),
    Asset("ANIM", "anim/um_bear_trap.zip"),
    Asset("ANIM", "anim/um_bear_trap_tooth.zip"),
    Asset("ANIM", "anim/um_bear_trap_gold.zip"),

    Asset("ANIM", "anim/slobberlobber.zip"),

    Asset("ANIM", "anim/beargerclaw.zip"),

    Asset("ANIM", "anim/featherfrock.zip"),
    Asset("ANIM", "anim/featherfrock_ground.zip"),
    Asset("ANIM", "anim/featherfrock_fancy.zip"),
    Asset("ANIM", "anim/featherfrock_fancy_ground.zip"),

    Asset("ANIM", "anim/um_harpoon.zip"),

    Asset("ANIM", "anim/magnerang.zip"),
    Asset("ANIM", "anim/um_magnerang_reel.zip"),

    Asset("ANIM", "anim/californiaking.zip"),

    Asset("ANIM", "anim/cursed_antler.zip"),
    Asset("ANIM", "anim/twisted_antler.zip"),

    Asset("ANIM", "anim/swap_exhumer.zip"),
    Asset("ANIM", "anim/swap_exhumer_powered.zip"),

    Asset("ANIM", "anim/um_moonfly_lantern.zip"),

    Asset("ANIM", "anim/um_astralpool.zip"),

    Asset("ANIM", "anim/blueberry.zip"),

    Asset("ANIM", "anim/widowsgrasp.zip"),
    Asset("ANIM", "anim/silksack.zip"),
    Asset("ANIM", "anim/swap_silksack.zip"),
    Asset("ANIM", "anim/hat_widowshead.zip"),

    Asset("ANIM", "anim/greenfoliage.zip"),

    Asset("ANIM", "anim/beefalowings.zip"),

    Asset("ANIM", "anim/snowcone.zip"),

    Asset("ANIM", "anim/liceloaf.zip"),
    Asset("ANIM", "anim/stuffed_peeper_poppers.zip"),
    Asset("ANIM", "anim/seafoodpaella.zip"),
    Asset("ANIM", "anim/um_deviled_eggs.zip"),
    Asset("ANIM", "anim/zaspberryparfait.zip"),
    Asset("ANIM", "anim/blueberrypancakes.zip"),
    Asset("ANIM", "anim/devilsfruitcake.zip"),
    Asset("ANIM", "anim/simpsalad.zip"),
    Asset("ANIM", "anim/um_rimeweed_spagett.zip"),
    Asset("ANIM", "anim/um_rimeweed_tequila.zip"),
    Asset("ANIM", "anim/um_durian_cream_marshcake.zip"),
    Asset("ANIM", "anim/um_chiles_en_nogada.zip"),
    Asset("ANIM", "anim/um_rice_pudding.zip"),
    Asset("ANIM", "anim/um_kebab.zip"),

    Asset("ANIM", "anim/cctrinkets.zip"),

    Asset("ANIM", "anim/berniebox.zip"),

    Asset("ANIM", "anim/screecher_trinket.zip"),

    Asset("ANIM", "anim/hat_gasmask.zip"),

    Asset("ANIM", "anim/hat_snowgoggles.zip"),

    Asset("ANIM", "anim/iceboomerang.zip"),

    Asset("ANIM", "anim/diseasecurebomb.zip"),

    Asset("ANIM", "anim/um_spider_mutators.zip"),

    Asset("ANIM", "anim/pied_piper_flute.zip"),

    Asset("ANIM", "anim/rat_tail.zip"),

    Asset("ANIM", "anim/rat_fur.zip"),

    Asset("ANIM", "anim/shroom_skin_fragment.zip"),

    Asset("ANIM", "anim/saltpack.zip"),

    Asset("ANIM", "anim/sporepack.zip"),

    Asset("ANIM", "anim/honey_log.zip"),

    Asset("ANIM", "anim/bugzapper.zip"),

    Asset("ANIM", "anim/plaguemask.zip"),
    Asset("ANIM", "anim/hat_plaguemask_formal.zip"),

    Asset("ANIM", "anim/hat_sunglasses.zip"),

    Asset("ANIM", "anim/moontear.zip"),

    Asset("ANIM", "anim/hat_shadowcrown.zip"),

    Asset("ANIM", "anim/whisperpod.zip"),

    Asset("ANIM", "anim/watermelon_lantern.zip"),

    Asset("ANIM", "anim/rat_whip.zip"),

    Asset("ANIM", "anim/amulet_klaus.zip"),

    Asset("ANIM", "anim/cursedcrabclaw.zip"),

    --monster morsels from waffles, thanks
    Asset("ANIM", "anim/extra_monsterfoods.zip"),
    Asset("ANIM", "anim/extra_monsterfoods_dried.zip"),

    Asset("ANIM", "anim/snapdragon_fertilizer.zip"),

    Asset("ANIM", "anim/theatercorn.zip"),

    Asset("ANIM", "anim/bulletbee_guard.zip"),
    Asset("ANIM", "anim/fatbee_guard_build.zip"),
    Asset("ANIM", "anim/hivehead_bee_guard.zip"),

    Asset("ANIM", "anim/bulletbee_build.zip"),

    Asset("ANIM", "anim/um_shadowarena.zip"),

    Asset("ANIM", "anim/um_wortox_shadow.zip"),

    Asset("ANIM", "anim/trinket_wathom1.zip"),

    Asset("ANIM", "anim/winona_portables.zip"),

    Asset("ANIM", "anim/ui_um_cookpot_wagstaff_1x4.zip"),

    Asset("ATLAS", "images/wortox_lunar_stealer.xml"),
    Asset("IMAGE", "images/wortox_lunar_stealer.tex"),

    Asset("ATLAS", "images/wortox_lunar_summoner.xml"),
    Asset("IMAGE", "images/wortox_lunar_summoner.tex"),

    Asset("ATLAS", "images/wortox_shadow_weaver.xml"),
    Asset("IMAGE", "images/wortox_shadow_weaver.tex"),




    --SWAPS
    Asset("ANIM", "anim/swap_driftwood_fishingrod.zip"),
    Asset("ANIM", "anim/torso_amulets_klaus.zip"), --Not quite sure...
    Asset("ANIM", "anim/swap_hat_crab.zip"),
    Asset("ANIM", "anim/swap_staff_starfall.zip"),
    Asset("ANIM", "anim/torso_amulets_ancient.zip"),
    Asset("ANIM", "anim/torso_ancient_amulet_red_demoneye.zip"),

    Asset("ANIM", "anim/oculet.zip"),

    Asset("ANIM", "anim/swap_driftwood_fishingrod.zip"),

    Asset("ANIM", "anim/swap_um_beegun.zip"),
    Asset("ANIM", "anim/swap_um_beegun_cherry.zip"),

    Asset("ANIM", "anim/hat_gore_horn_swap_on.zip"),
    Asset("ANIM", "anim/hat_gore_horn_swap_off.zip"),

    Asset("ANIM", "anim/swap_um_beartrap.zip"),
    Asset("ANIM", "anim/swap_um_beartrap_tooth.zip"),
    Asset("ANIM", "anim/swap_um_beartrap_gold.zip"),

    Asset("ANIM", "anim/swap_sporepack.zip"),

    Asset("ANIM", "anim/swap_iceboomerang.zip"),

    Asset("ANIM", "anim/swap_saltpack.zip"),

    Asset("ANIM", "anim/swap_diseasecurebomb.zip"),

    Asset("ANIM", "anim/swap_bugzapper.zip"),

    Asset("ANIM", "anim/swap_nightstick_off.zip"),

    Asset("ANIM", "anim/swap_rat_whip.zip"),

    Asset("ANIM", "anim/swap_crabclaw.zip"),

    Asset("ANIM", "anim/swap_cursed_antler.zip"),

    Asset("ANIM", "anim/swap_exhumer.zip"),

    Asset("ANIM", "anim/swap_twisted_antler.zip"),

    Asset("ANIM", "anim/swap_widowsgrasp.zip"),

    Asset("ANIM", "anim/swap_slobberlobber.zip"),

    Asset("ANIM", "anim/swap_beargerclaw.zip"),

    Asset("ANIM", "anim/swap_um_harpoon.zip"),

    Asset("ANIM", "anim/swap_magnerang.zip"),

    Asset("ANIM", "anim/swap_um_staff_meteor.zip"),

    Asset("ANIM", "anim/winona_toolbox.zip"),
    Asset("ANIM", "anim/winona_upgradekit_electrical.zip"),

    Asset("ANIM", "anim/um_goo_honey.zip"),

    Asset("ANIM", "anim/um_alpha_lightninggoat.zip"),
    Asset("ANIM", "anim/swap_um_fyre_bomb.zip"),

    --UI
    Asset("IMAGE", "images/dragonflycontainerborder.tex"),
    Asset("ATLAS", "images/dragonflycontainerborder.xml"),

    Asset("ANIM", "anim/acid_meter.zip"),

    Asset("ATLAS", "images/mushroom_slot.xml"),
    Asset("IMAGE", "images/mushroom_slot.tex"),

    --Silk Sack
    Asset("ATLAS", "images/silk_slot.xml"),
    Asset("IMAGE", "images/silk_slot.tex"),
    Asset("ATLAS", "images/um_nettleslot.xml"),
    Asset("IMAGE", "images/um_nettleslot.tex"),
    Asset("ATLAS", "images/general_slot.xml"),
    Asset("IMAGE", "images/general_slot.tex"),
    Asset("ATLAS", "images/bundle_slot.xml"),
    Asset("IMAGE", "images/bundle_slot.tex"),

    Asset("ATLAS", "images/wardrobe_tool_slot.xml"),
    Asset("IMAGE", "images/wardrobe_tool_slot.tex"),

    Asset("ATLAS", "images/wardrobe_hat_slot.xml"),
    Asset("IMAGE", "images/wardrobe_hat_slot.tex"),

    Asset("ATLAS", "images/wardrobe_chest_slot.xml"),
    Asset("IMAGE", "images/wardrobe_chest_slot.tex"),

    Asset("ATLAS", "images/gem_slot.xml"),
    Asset("IMAGE", "images/gem_slot.tex"),

    Asset("ATLAS", "images/feather_slot.xml"),
    Asset("IMAGE", "images/feather_slot.tex"),

    Asset("ATLAS", "images/fish_slot.xml"),
    Asset("IMAGE", "images/fish_slot.tex"),

    Asset("ATLAS", "images/bee_slot.xml"),
    Asset("IMAGE", "images/bee_slot.tex"),

    Asset("ATLAS", "images/um_inkubator_fuelslot.xml"),
    Asset("IMAGE", "images/um_inkubator_fuelslot.tex"),
    Asset("ATLAS", "images/um_inkubator_meatslot.xml"),
    Asset("IMAGE", "images/um_inkubator_meatslot.tex"),

    Asset("ANIM", "anim/um_status_wx.zip"),

    Asset("ANIM", "anim/wathgrithr_shield_dreadstone.zip"),
    Asset("ANIM", "anim/swap_wathgrithr_shield_dreadstone.zip"),

    --ICONS
    Asset("IMAGE", "images/vetskull.tex"),
    Asset("ATLAS", "images/vetskull.xml"),

    Asset("IMAGE", "images/UM_TT.tex"),
    Asset("ATLAS", "images/UM_TT.xml"),

    Asset("IMAGE", "images/PP_TT.tex"),
    Asset("ATLAS", "images/PP_TT.xml"),

    Asset("IMAGE", "images/WIX_TT.tex"),
    Asset("ATLAS", "images/WIX_TT.xml"),

    Asset("IMAGE", "images/engineering_tip.tex"),
    Asset("ATLAS", "images/engineering_tip.xml"),

    --SOUND
    Asset("SOUNDPACKAGE", "sound/UCSounds.fev"),
    Asset("SOUND", "sound/UCSounds_bank00.fsb"),

    Asset("SOUNDPACKAGE", "sound/UMMusic.fev"),
    Asset("SOUND", "sound/UMMusic.fsb"),

    Asset("SOUNDPACKAGE", "sound/UMMusic2.fev"),
    Asset("SOUND", "sound/UMMusic2.fsb"),

    Asset("SOUNDPACKAGE", "sound/tiddle_stranger.fev"),
    Asset("SOUND", "sound/tiddle_stranger.fsb"),

    Asset("SOUNDPACKAGE", "sound/stmpwyfs.fev"),
    Asset("SOUND", "sound/stmpwyfs.fsb"),

    Asset("SOUNDPACKAGE", "sound/um_detonator.fev"),
    --Asset("SOUND", "sound/um_detonator_bank00.fsb"),
    Asset("SOUND", "sound/um_detonator_bank01.fsb"),

    --MAP ICONS
    Asset("IMAGE", "images/map_icons/rock_lichen.tex"),
    Asset("ATLAS", "images/map_icons/rock_lichen.xml"),

    Asset("IMAGE", "images/map_icons/riceplant.tex"),
    Asset("ATLAS", "images/map_icons/riceplant.xml"),

    Asset("IMAGE", "images/map_icons/sporepack_map.tex"),
    Asset("ATLAS", "images/map_icons/sporepack_map.xml"),

    Asset("IMAGE", "images/map_icons/air_conditioner_map.tex"),
    Asset("ATLAS", "images/map_icons/air_conditioner_map.xml"),
    Asset("IMAGE", "images/map_icons/blueberryplant_map.tex"),
    Asset("ATLAS", "images/map_icons/blueberryplant_map.xml"),

    Asset("IMAGE", "images/map_icons/giant_tree.tex"),
    Asset("ATLAS", "images/map_icons/giant_tree.xml"),

    Asset("IMAGE", "images/map_icons/pitcher.tex"),
    Asset("ATLAS", "images/map_icons/pitcher.xml"),

    Asset("IMAGE", "images/map_icons/snapplant_map.tex"),
    Asset("ATLAS", "images/map_icons/snapplant_map.xml"),

    Asset("IMAGE", "images/map_icons/veteranshrine_map.tex"),
    Asset("ATLAS", "images/map_icons/veteranshrine_map.xml"),

    Asset("IMAGE", "images/map_icons/lazychester_minimap.tex"),
    Asset("ATLAS", "images/map_icons/lazychester_minimap.xml"),



    Asset("IMAGE", "images/map_icons/webbedcreature_small_minimap.tex"),
    Asset("ATLAS", "images/map_icons/webbedcreature_small_minimap.xml"),
    Asset("IMAGE", "images/map_icons/webbedcreature_medium_minimap.tex"),
    Asset("ATLAS", "images/map_icons/webbedcreature_medium_minimap.xml"),
    Asset("IMAGE", "images/map_icons/webbedcreature_large_minimap.tex"),
    Asset("ATLAS", "images/map_icons/webbedcreature_large_minimap.xml"),

    Asset("IMAGE", "images/map_icons/pollenmiteden_map.tex"),
    Asset("ATLAS", "images/map_icons/pollenmiteden_map.xml"),

    Asset("IMAGE", "images/map_icons/um_pawn.tex"),
    Asset("ATLAS", "images/map_icons/um_pawn.xml"),

    Asset("IMAGE", "images/map_icons/um_pawn_nightmare.tex"),
    Asset("ATLAS", "images/map_icons/um_pawn_nightmare.xml"),
    Asset("IMAGE", "images/map_icons/uncompromising_ratburrow.tex"),
    Asset("ATLAS", "images/map_icons/uncompromising_ratburrow.xml"),
    Asset("IMAGE", "images/map_icons/uncompromising_winkyhomeburrow.tex"),
    Asset("ATLAS", "images/map_icons/uncompromising_winkyhomeburrow.xml"),
    Asset("IMAGE", "images/map_icons/sludge_sack.tex"),
    Asset("ATLAS", "images/map_icons/sludge_sack.xml"),

    Asset("IMAGE", "images/map_icons/telebase_active.tex"),
    Asset("ATLAS", "images/map_icons/telebase_active.xml"),

    Asset("IMAGE", "images/map_icons/um_pyre_nettles_map.tex"),
    Asset("ATLAS", "images/map_icons/um_pyre_nettles_map.xml"),

    Asset("IMAGE", "images/map_icons/um_tornado_map.tex"),
    Asset("ATLAS", "images/map_icons/um_tornado_map.xml"),

    --BIGPORTRAITS
    Asset("IMAGE", "bigportraits/willow.tex"),
    Asset("ATLAS", "bigportraits/willow.xml"),
    Asset("IMAGE", "bigportraits/willow_none.tex"),
    Asset("ATLAS", "bigportraits/willow_none.xml"),


    --FX TEXTURES

    Asset("IMAGE", "fx/smog1.tex"),
    Asset("IMAGE", "fx/smog2.tex"),
    Asset("IMAGE", "fx/smog3.tex"),
    Asset("IMAGE", "fx/smog4.tex"),

    --SHADER TEXTURES

    --PRELOAD THESE IN MODMAIN INSTEAD!!
    Asset("IMAGE", "images/giant_tree.tex"), --OR NOT!!!!!
    -- SKILL TREES

    Asset("IMAGE", "images/wathgrithr_rework_skilltree.tex"),
    Asset("ATLAS", "images/wathgrithr_rework_skilltree.xml"),

    Asset("IMAGE", "images/wolfgang_rework_skilltree.tex"),
    Asset("ATLAS", "images/wolfgang_rework_skilltree.xml"),
}

for _, asset in pairs(inventoryitems) do
    table.insert(Assets, Asset("IMAGE", "images/inventoryimages/" .. asset .. ".tex"))
    table.insert(Assets, Asset("ATLAS", "images/inventoryimages/" .. asset .. ".xml"))
    table.insert(Assets, Asset("ATLAS_BUILD", "images/inventoryimages/" .. asset .. ".xml", 256))
end
