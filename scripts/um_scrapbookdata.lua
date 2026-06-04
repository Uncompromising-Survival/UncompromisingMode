-- for reference of what kind of data goes here, take a look at vanilla scripts/screens/redux/scrapbookdata
local function CreateCursedItemData(name, build, bank, anim, extra_data)
    local data = {
        name = name,
        prefab = name,
        subcat = "veteranscurse",
        type = "item",
        tex = name .. ".tex",
        build = build or name,
        bank = bank or name,
        anim = anim or "idle",
        notes = { cursed_item = true }
    }

    if extra_data ~= nil then
        for k, v in pairs(extra_data) do
            data[k] = v

            if k == "deps" then
                table.insert(data.deps, "veteranshrine")
            end
        end
    end

    printwrap("UM Cursed Item Data", data)

    return data
end

local data = {
    -- some examples. Does not include every field.
    --[[
    alterguardian_phase4_lunarrift = {name="alterguardian_phase4_lunarrift", tex="alterguardian_phase4_lunarrift.tex", subcat="gestalt", type="giant", prefab="alterguardian_phase4_lunarrift", sanityaura=1.6666666666667, health=16000, damage=168.75, planardamage=35, build="wagboss_lunar", bank="wagboss_lunar", anim="scrapbook", symbolcolours={{"lb_glow", "1", "1", "1", "0.375"}}, deps={"gears", "lunar_seed", "purebrilliance", "sketch", "trinket_6", "wagstaff_item_1", "wagstaff_item_2"}, notes={lunar_aligned=true}},
    alterguardianhat = {name="alterguardianhat", tex="alterguardianhat.tex", subcat="hat", type="item", prefab="alterguardianhat", build="hat_alterguardian", bank="alterguardianhat", anim="anim", dapperness=0.16666666666667, snowmandecor=true, deps={"alterguardianhatshard"}},
    alterguardianhatshard = {name="alterguardianhatshard", tex="alterguardianhatshard.tex", type="item", prefab="alterguardianhatshard", build="alterguardianhatshard", bank="alterguardianhatshard", anim="idle"},
    amulet = {name="amulet", tex="amulet.tex", subcat="clothing", type="item", prefab="amulet", finiteuses=20, build="amulets", bank="amulets", anim="redamulet", dapperness=0.033333333333333, deps={"goldnugget", "nightmarefuel", "redgem"}, specialinfo="REDAMULET"},
    anchor = {name="anchor", tex="anchor.tex", subcat="seafaring", type="thing", prefab="anchor", build="boat_anchor", bank="boat_anchor", anim="untethered_idle_loop", workable="HAMMER", burnable=true, deps={"anchor_item", "boards", "cutstone", "rope"}},
    anchor_item = {name="anchor_item", tex="anchor_item.tex", subcat="seafaring", type="item", prefab="anchor_item", build="seafarer_anchor", bank="seafarer_anchor", anim="idle", fueltype="BURNABLE", fuelvalue=180, burnable=true, deps={"anchor", "boards", "cutstone", "rope"}},
    battlesong_shadowaligned = {name="battlesong_shadowaligned", tex="battlesong_shadowaligned.tex", subcat="battlesong", type="item", prefab="battlesong_shadowaligned", build="battlesongs", bank="battlesongs", anim="battlesong_shadowaligned", fueltype="BURNABLE", fuelvalue=15, burnable=true, craftingprefab="wathgrithr", deps={"featherpencil", "horrorfuel", "papyrus"}},
    ]]
    -- cursed items
    veteranshrine = { name = "veteranshrine", tex = "veteranshrine.tex", type = "POI", prefab = "veteranshrine", build = "veteranshrine", bank = "veteranshrine", anim = "idle", subcat = "veteranscurse", use_bg = true },

    cursed_antler = CreateCursedItemData("cursed_antler", nil, nil, nil, { weapondamage = "34-66", areadamage = 34, deps = { "boneshard", "deerclops" } }),
    crystal_cursed_antler = CreateCursedItemData("crystal_cursed_antler", nil, nil, nil, { weapondamage = 34, planardamage = "17-116", areadamage = "34", planarareadamage = 17, deps = { "boneshard", "purebrilliance", "mutateddeerclops" } }),
    beargerclaw = CreateCursedItemData("beargerclaw", nil, nil, nil, { areadamage = "20-60", weaponrange = 20, deps = { "boneshard", "bearger", "furtuft" } }), --toolactions = {"DIG"} toolactions looks wierd without  finiteuses
    slobberlobber = CreateCursedItemData("slobberlobber", nil, nil, nil, { weapondamage = "20/0.6s", weaponrange = 15, deps = { "meat", "dragon_scales", "dragonfly", "mock_dragonfly" } }),
    feather_frock = CreateCursedItemData("feather_frock", "featherfrock_ground", "featherfrock_ground", "anim", { weapondamage = "10-50", deps = { "goose_feather", "moose", "feather_robin", "feather_robin_winter", "feather_crow", "feather_canary", "malbatross_feather" } }),
    gore_horn_hat = CreateCursedItemData("gore_horn_hat", "hat_gore_horn", "hat_gore_horn", nil, { weapondamage = 200, deps = { "minotaur", "nightmarefuel" }, animoffsetx = -30 }),
    klaus_amulet = CreateCursedItemData("klaus_amulet", "amulet_klaus", "amulet_klaus", "klausamulet", { deps = { "klaus", "goldnugget", "nightmarefuel" }, absorb_percent = 0.3, }),
    crabclaw = CreateCursedItemData("crabclaw", "cursedcrabclaw", "cursedcrabclaw", nil, { weapondamage = "40-60", deps = { "meat", "rocks", "crabking", "redgem", "bluegem", "purplegem", "yellowgem", "greengem", "orangegem", "opalpreciousgem" } }),
    um_beegun = CreateCursedItemData("um_beegun", nil, nil, nil, { weapondamage = 10, weaponrange = 14, deps = { "beequeen", "honeycomb", "royal_jelly" } }),
    silksack = CreateCursedItemData("silksack", "swap_silksack", "swap_silksack", nil, { deps = { "silken_bundle", "silk", "hoodedwidow" } }),
    um_moonfly_lantern = CreateCursedItemData("um_moonfly_lantern", nil, nil, "idle_loop", { weapondamage = 17, deps = { "moonmaw_dragonfly", "moonglass", "moonglass_charged", "moonrocknugget" } }),

    --curse-related/adjacent
    --crabclaw gems are in additions file.
    bulletbee = { name = "bulletbee", tex = "bulletbee.tex", subcat = "insect", type = "creature", prefab = "bulletbee", health = 10, damage = 10, stacksize = 20, build = "bulletbee_build", bank = "bee", anim = "idle", animoffsety = 150, perishable = 960, workable = "NET", deps = { "beemine", "um_beegun" }, use_bg = true },
    silken_bundle = { name = "silken_bundle", tex = "silken_bundle_large.tex", type = "item", prefab = "silken_bundle", build = "um_silken_bundle", bank = "um_silken_bundle", anim = "idle_large", burnable = true, deps = { "ash", "silk", "silksack" } },

    --bosses
    hoodedwidow = { name = "hoodedwidow", sanityaura = -TUNING.SANITYAURA_HUGE, tex = "hoodedwidow.tex", type = "giant", prefab = "hoodedwidow", health = TUNING.DSTU.WIDOW_HEALTH, damage = "75-150", build = "widow1", bank = "widow", anim = "idle", deps = { "widowsgrasp", "monstermeat", "widowshead", "spider" }, use_bg = true },
    moonmaw_dragonfly = { name = "moonmaw_dragonfly", sanityaura = TUNING.SANITYAURA_HUGE, tex = "moonmaw_dragonfly.tex", type = "giant", prefab = "moonmaw_dragonfly", health = TUNING.DSTU.MOONFLY_HEALTH, damage = "75-150", build = "moonmaw_dragonfly", bank = "moonmaw_dragonfly", anim = "idle", deps = { "meat", "glass_scales", "moonglass_geode", "moonmaw_lavae" }, use_bg = true, notes = { lunar_aligned = true } },
    mock_dragonfly = { name = "mock_dragonfly", sanityaura = -TUNING.SANITYAURA_HUGE, tex = "mock_dragonfly.tex", type = "giant", prefab = "mock_dragonfly", health = TUNING.DSTU.WILTFLY_HEALTH, damage = "75-150", build = "dragonfly_fire_build", bank = "dragonfly", anim = "idle", deps = { "dragon_scales", "meat" }, use_bg = true },
    --different icon for mock_dragonfly so they're distinguished from normal dfly

    --widow-related
    widowsgrasp = { name = "widowsgrasp", tex = "widowsgrasp.tex", weapondamage = TUNING.DSTU.WIDOWSGRASP_DAMAGE, finiteuses = TUNING.DSTU.WIDOWSGRASP_USES, type = "item", prefab = "widowsgrasp", build = "widowsgrasp", bank = "widowsgrasp", anim = "idle", deps = { "hoodedwidow", "webbedcreature" } },
    widowshead = { name = "widowshead", tex = "widowshead.tex", type = "item", perishable = 7.5 * TUNING.PERISH_TWO_DAY, prefab = "widowshead", build = "hat_widowshead", bank = "catcoonhat", anim = "anim", deps = { "hoodedwidow" }, animoffsety = -10 },
    webbedcreature = { name = "webbedcreature", tex = "webbedcreature.tex", type = "creature", prefab = "webbedcreature", build = "wackycocoons", bank = "wackycocoons", anim = "idle_medium_scrapbook", deps = { "hoodedwidow", "widowsgrasp" }, use_bg = true },
    spider_trapdoor_hooded = { name = "spider_trapdoor_hooded", tex = "spider_trapdoor_hooded.tex", subcat = "spider", type = "creature", prefab = "spider_trapdoor_hooded", sanityaura = -0.66666666666667, health = 400, damage = 34, build = "spider_trapdoor_hooded", bank = "spider", anim = "idle", perishable = 2400, deps = { "monstermeat", "silk", "spidergland", "hoodedwidow" }, use_bg = true },

    --moonmaw
    armor_glassmail = { name = "armor_glassmail", tex = "armor_glassmail.tex", subcat = "armor", type = "item", prefab = "armor_glassmail", armor = 945, absorb_percent = 0.7, build = "armor_glassmail", bank = "armor_glassmail", anim = "anim", deps = { "glass_scales", "moonglass_charged" } },
    glass_scales = { name = "glass_scales", tex = "glass_scales.tex", type = "item", prefab = "glass_scales", stacksize = 10, build = "glass_scales", bank = "glass_scales", anim = "idle", animoffsetx = -35 },
    moonglass_geode = { name = "moonglass_geode", tex = "moonglass_geode.tex", type = "item", prefab = "moonglass_geode", build = "moonglass_geode", bank = "moonglass_geode", anim = "idle", workable = "MINE", deps = { "moonglass_charged" } },
    moonmaw_lavae = { name = "moonmaw_lavae", tex = "moonmaw_lavae.tex", type = "creature", prefab = "moonmaw_lavae", health = 250, damage = 50, build = "moonmaw_lavae", bank = "moonmaw_lavae", anim = "hover", use_bg = true },

    --bee queen
    um_beeguard_seeker = { name = "um_beeguard_seeker", tex = "um_beeguard_seeker.tex", subcat = "insect", type = "creature", prefab = "um_beeguard_seeker", health = 180 * 0.5, damage = 15, build = "fatbee_guard_build", bank = "bee_guard", anim = "idle", animoffsety = 100, deps = { "beequeen", "stinger" }, use_bg = true },
    um_beeguard_shooter = { name = "um_beeguard_shooter", tex = "um_beeguard_shooter.tex", subcat = "insect", type = "creature", prefab = "um_beeguard_shooter", health = 180 * 0.5, damage = 15, build = "bulletbee_guard", bank = "bee_guard", anim = "idle", animoffsety = 100, deps = { "beequeen", "stinger" }, use_bg = true },
    um_beeguard_blocker = { name = "um_beeguard_blocker", tex = "um_beeguard_blocker.tex", subcat = "insect", type = "creature", prefab = "um_beeguard_blocker", health = 180 * 15, damage = 15, build = "hivehead_bee_guard", bank = "bee_guard", anim = "idle", animoffsety = 100, deps = { "beequeen", "stinger" }, use_bg = true },

    -- lunar/grotto
    --missing deps
    --um_bee_moon = { name = "um_bee_moon", tex = "um_bee_moon.tex", subcat = "insect", type = "creature", prefab = "um_bee_moon", health = 250, damage = 34, stacksize = 20, build = "um_bee_moon", bank = "um_bee_moon", anim = "idle", animoffsety = 150, perishable = 960, workable = "NET", deps = { "um_meathoney", "houndstooth" }, notes = { lunar_aligned = true } },
    um_astral_projector = { name = "um_astral_projector", tex = "um_astral_projector.tex", subcat = "structure", type = "thing", prefab = "um_astral_projector", build = "um_archives_projectinator", bank = "um_archives_projectinator", anim = "idle", workable = "HAMMER", deps = { "um_astral_projector_target", "purplemooneye", "thulecite", "moonrocknugget" } },
    um_astral_projector_target = { name = "um_astral_projector_target", tex = "um_astral_projector_target.tex", subcat = "structure", type = "thing", prefab = "um_astral_projector_target", build = "um_archives_receptionator", bank = "um_archives_receptionator", anim = "idle", workable = "HAMMER", deps = { "moonglass", "thulecite", "moonrocknugget" } },

    --hooded forest
    hoodedtrapdoor = { name = "hoodedtrapdoor", tex = "hoodedtrapdoor.tex", type = "thing", prefab = "hoodedtrapdoor", build = "rock_flipping_moss", bank = "flipping_rock", anim = "idle", workable = "MINE", deps = { "rocks", "spider_trapdoor_hooded" }, use_bg = true },
    giant_blueberry = { name = "giant_blueberry", tex = "giant_blueberry.tex", type = "food", prefab = "giant_blueberry", stacksize = 20, hungervalue = 18.8, healthvalue = 1, sanityvalue = 0, foodtype = "VEGGIE", build = "blueberry", bank = "blueberry", anim = "idle", perishable = TUNING.PERISH_FAST * 2, deps = { "spoiled_food", "blueberryplant" } },
    blueberryplant = { name = "blueberryplant", tex = "blueberryplant.tex", type = "thing", prefab = "blueberryplant", build = "blueberryplant", bank = "blueberryplant", anim = "idle1", burnable = true, workable = "SHOVEL", deps = { "ice" }, use_bg = true, animoffsetx = -15 },
    giant_tree = { name = "giant_tree", tex = "giant_tree.tex", type = "thing", prefab = "giant_tree", build = "um_hoodedtree", bank = "um_hoodedtree", anim = "idle_moss_full", workable = "AXE", deps = { "frog", "twigs", "log", "feather_robin", "feather_robin_winter", "feather_canary", "feather_crow", "spider", "aphid", "um_moss" }, specialinfo = "GIANT_TREE", use_bg = true },
    um_moss = { name = "um_moss", tex = "um_moss.tex", type = "food", prefab = "um_moss", stacksize = 20, hungervalue = TUNING.CALORIES_SMALL / 2, healthvalue = TUNING.HEALING_SMALL, sanityvalue = TUNING.SANITY_SUPERTINY, foodtype = FOODTYPE.UM_HORRIBLE_VEGGIE, build = "um_moss", bank = "um_moss", anim = "idle", fueltype = "BURNABLE", fuelvalue = TUNING.SMALL_FUEL, burnable = true },

    um_bear_trap_equippable_gold = { name = "um_bear_trap_equippable_gold", tex = "um_bear_trap_equippable_gold.tex", type = "item", prefab = "um_bear_trap_equippable_gold", weapondamage = 60, finiteuses = 8, health = TUNING.WALRUS_HEALTH / 1.5, bank = "um_bear_trap", build = "um_bear_trap_gold", anim = "idle", deps = { "goldnugget", "houndstooth", "snappy_jaw" }, animoffsetx = -50 },
    um_bear_trap_equippable_tooth = { name = "um_bear_trap_equippable_tooth", tex = "um_bear_trap_equippable_tooth.tex", type = "item", prefab = "um_bear_trap_equippable_tooth", weapondamage = 60, finiteuses = 1, health = TUNING.WALRUS_HEALTH / 1.5, bank = "um_bear_trap", build = "um_bear_trap_tooth", anim = "idle", deps = { "rocks", "snappy_jaw" }, animoffsetx = -50 },
    um_bear_trap_old = { name = "um_bear_trap_old", tex = "um_bear_trap_old.tex", type = "thing", prefab = "um_bear_trap_old", damage = 60, health = TUNING.WALRUS_HEALTH, bank = "um_bear_trap", build = "um_bear_trap_old", anim = "idle", deps = { "walrus_camp", "hooded_fern", "snappy_jaw" }, animoffsetx = -50, use_bg = true },
    um_bear_trap = { name = "um_bear_trap", tex = "um_bear_trap.tex", type = "thing", prefab = "um_bear_trap", damage = 60, health = TUNING.WALRUS_HEALTH, bank = "um_bear_trap", build = "um_bear_trap", anim = "idle", deps = { "walrus", "snappy_jaw" }, animoffsetx = -50, use_bg = true },
    snappy_jaw = { name = "snappy_jaw", tex = "snappy_jaw.tex", type = "item", prefab = "snappy_jaw", stacksize = 10, bank = "um_bear_trap", build = "um_bear_trap_old", anim = "item", deps = { "flint", "rope", "houndstooth" } },
    jawed_scythe = { name = "jawed_scythe", tex = "jawed_scythe.tex", subcat = "tool", type = "item", prefab = "jawed_scythe", weapondamage = TUNING.SPEAR_DAMAGE * 1.3, finiteuses = 100, toolactions = { "SCYTHE" }, build = "scythe_jawed", bank = "scythe_voidcloth", anim = "idle", deps = { "twigs", "steelwool", "snappy_jaw" } },
    um_boomberry_bomb = { name = "um_boomberry_bomb", tex = "um_boomberry_bomb.tex", subcat = "weapon", type = "item", prefab = "um_boomberry_bomb", stacksize = 20, weapondamage = TUNING.DSTU.BOOMBERRYBOMB_DAMAGE, weaponrange = 10, build = "um_boomberry_bomb", bank = "um_boomberry_bomb", anim = "idle", deps = { "giant_blueberry", "cutgrass", "twigs" } },
    aphid = { name = "aphid", tex = "aphid.tex", subcat = "insect", type = "creature", prefab = "aphid", health = 100, damage = 10, build = "aphid", bank = "weevole", anim = "idle", perishable = TUNING.BUTTERFLY_PERISH_TIME, deps = { "monstermeat", "steelwool", "hooded_fern" }, use_bg = true },
    woodpecker = { name = "woodpecker", tex = "woodpecker.tex", subcat = "bird", type = "creature", prefab = "woodpecker", health = 25, build = "woodpecker_build", bank = "crow", anim = "idle", perishable = 2400, deps = { "cookedsmallmeat", "cutgrass", "feather_crow", "feather_robin", "flint", "seeds", "smallmeat", "twigs" }, use_bg = true },
    um_hat_leafwing = { name = "um_hat_leafwing", tex = "um_hat_leafwing.tex", subcat = "hat", type = "item", prefab = "um_hat_leafwing", build = "um_hat_leafwing", scale = 0.5, animoffsetx = -45, animoffsety = -10 bank = "catcoonhat", anim = "anim", perishable = 4800, waterproofer = TUNING.WATERPROOFNESS_SMALL, snowmandecor = true, deps = { "um_moss", "log", "um_leafwing", "spoiled_food" } },
    um_leafwing = { name = "um_leafwing", tex = "um_leafwing.tex", type = "item", prefab = "um_leafwing", build = "um_leafwing", bank = "um_leafwing", anim = "idle", fueltype = "BURNABLE", fuelvalue = TUNING.LARGE_FUEL, perishable = TUNING.PERISH_FAST, stackable = TUNING.STACK_SIZE_SMALLITEM, foodtype = "MEAT", hungervalue = TUNING.CALORIES_TINY, healthvalue = TUNING.HEALING_SMALL, sanityvalue = -TUNING.SANITY_TINY },

    hooded_fern = { name = "hooded_fern", tex = "hooded_fern.tex", type = "thing", prefab = "hooded_fern", build = "um_thicket", bank = "um_thicket", anim = "idle", pickable = true, burnable = true, deps = { "um_hat_leafwing", "armor_bramble", --[["um_armor_bramble_rimeweed",]] "armor_lunarplant_husk", "ash", "mound", "spider", "aphid", "seeds", "cutgrass", "twigs", "carrot_seeds", "corn_seeds", "dragonfruit_seeds", "durian_seeds", "eggplant_seeds", "pomegranate_seeds", "pumpkin_seeds", "asparagus_seeds", "tomato_seeds", "potato_seeds", "onion_seeds", "pepper_seeds", "garlic_seeds", "watermelon_seeds" }, use_bg = true },

    um_fern_fox = { name = "um_fern_fox", tex = "um_fern_fox.tex", type = "creature", prefab = "um_fern_fox", health = 150, build = "fern_fox", bank = "fern_fox", anim = "idle_loop", deps = { "plantmeat", "um_moss", "um_fern_fox_den" }, use_bg = true },
    um_fern_fox_den = { name = "um_fern_fox_den", tex = "um_fern_fox_den.tex", type = "thing", prefab = "um_fern_fox_den", build = "um_fox_den", bank = "um_fox_den", anim = "idle", workable = "DIG", burnable = true, deps = { "rocks", "um_moss", "twigs" }, use_bg = true },
    giant_tree_birdnest = { name = "giant_tree_birdnest", tex = "giant_tree_birdnest.tex", type = "thing", prefab = "giant_tree_birdnest", build = "giant_tree_nest", bank = "giant_tree_nest", anim = "idle_3", burnable = true, deps = { "bird_egg", "twigs", "ash", "bird_egg_cooked", "giant_tree" }, use_bg = true },
    fruitbat = { name = "fruitbat", tex = "fruitbat.tex", type = "creature", prefab = "fruitbat", health = 100, damage = "20-" .. TUNING.STARFISH_TRAP_DAMAGE, build = "fruitbat", bank = "fruitbat", anim = "idle", deps = { "um_leafwing", "giant_blueberry", "blueberryplant" }, animoffsetx = -20, use_bg = true },

    pitcherplant = { name = "pitcherplant", tex = "pitcherplant.tex", type = "thing", prefab = "pitcherplant", build = "pitcher", bank = "pitcher", anim = "swing", deps = { "honey", "fruitbat" }, animoffsety = -70, animoffsetx = 20, use_bg = true },

    --[[
        items
        giant_blueberry [x]
        um_moss [x]
        um_bear_trap_equippable_gold [x]
        um_bear_trap_equippable_tooth [x]
        um_boomberry_bomb [x]
        aphid --technically. [ ]
        jawed_scythe [x]
        woodpecker --also technically [ ]
        snappy_jaw [x]
        um_hat_leafwing [x]
        um_leafwing [x]

        hooded_fern [ ]
        um_fern_fox [ ]
        um_fern_fox_den [ ]
        giant_tree [ ]
        giant_tree_nest [ ]
        blueberryplant [ ]
        fruitbat [ ]
        um_bear_trap_old [ ]
        um_bear_trap [ ]
        pitcherplant [ ]
    ]]

    --broiling
    springrock1 = { name = "springrock1", tex = "springrock1.tex", type = "thing", prefab = "springrock1", build = "springrock1", bank = "springrock1", anim = "full", workable = "MINE", deps = { "nitre", "rocks" }, use_bg = true },
    springrock2 = { name = "springrock2", tex = "springrock2.tex", type = "thing", prefab = "springrock2", build = "springrock2", bank = "springrock2", anim = "full", workable = "MINE", deps = { "flint", "nitre", "rocks" }, use_bg = true },
    springrock3 = { name = "springrock3", tex = "springrock3.tex", type = "thing", prefab = "springrock3", build = "springrock3", bank = "springrock3", anim = "full", workable = "MINE", deps = { "flint", "goldnugget", "nitre", "rocks" }, use_bg = true },
    cave_entrance_magmabiome = { name = "cave_entrance_magmabiome", tex = "cave_entrance_magmabiome.tex", type = "POI", prefab = "cave_entrance_magmabiome", build = "cave_entrance_magmabiome", bank = "cave_entrance_magmabiome", anim = "full", workable = "MINE", deps = { "bat", "flint", "nitre", "rocks" }, use_bg = true },
    um_hotspring = { name = "um_hotspring", tex = "um_hotspring.tex", type = "thing", prefab = "um_hotspring", build = "um_hotspring", bank = "um_hotspring", anim = "med_idle", deps = { "bathbomb" }, animoffsety = 45, animoffsetx = 15, use_bg = true },

    um_spongeplant_item = { name = "um_spongeplant_item", tex = "um_spongeplant_item.tex", type = "food", prefab = "um_spongeplant_item", stacksize = 20, hungervalue = 18.8, healthvalue = 3, sanityvalue = -10, foodtype = "VEGGIE", build = "um_spongeplant", bank = "um_spongeplant_item", anim = "idle", perishable = TUNING.PERISH_FAST, deps = { "spoiled_food", "um_spongeplant" } },
    um_spongeplant = { name = "um_spongeplant", tex = "um_spongeplant.tex", type = "thing", prefab = "um_spongeplant", build = "um_spongeplant", bank = "um_spongeplant", anim = "idle", burnable = true, workable = "MINE", deps = { "um_spongeplant_item", "marble" }, use_bg = true },

    snapalm = { name = "snapalm", tex = "snapalm.tex", type = "item", prefab = "snapalm", stacksize = 40, build = "snapalm", bank = "snapalm", anim = "idle", burnable = true },
    snaildrakehat = { name = "snaildrakehat", tex = "snaildrakehat.tex", subcat = "armor", type = "item", prefab = "snaildrakehat", armor = TUNING.ARMOR_SLURTLEHAT, absorb_percent = 0.7, build = "snaildrakehat", bank = "snaildrakehat", anim = "anim", waterproofer = TUNING.WATERPROOFNESS_SMALL, snowmandecor = true, deps = { "snaildrake_magma", "slurtle_shellpieces" } },
    snaildrakebucket = { name = "snaildrakebucket", tex = "snaildrakebucket_empty.tex", type = "item", prefab = "snaildrakebucket", build = "snaildrakebucket", bank = "snaildrakebucket", anim = "empty", deps = { "snaildrake_slime", "slurtle_shellpieces", "pond", "pond_cave", "oasislake", "lava_pond" } },
    snaildrake_hole = { name = "snaildrake_hole", tex = "snaildrake_hole.tex", type = "thing", prefab = "snaildrake_hole", build = "snaildrake_hole", bank = "snaildrake_hole", anim = "idle", deps = { "snaildrake_slime", "snaildrake_magma" }, use_bg = true },
    snaildrake_slime = { name = "snaildrake_slime", tex = "snaildrake_slime.tex", type = "creature", prefab = "snaildrake_slime", health = 450, damage = 25, build = "snaildrake_holeshell", bank = "snaildrake_holeshell", anim = "idle", deps = { "slurtle_shellpieces", "snaildrakebucket", "snapalm" }, scale = 2, animoffsetx = -10, animoffsety = -20, use_bg = true },
    snaildrake_magma = { name = "snaildrake_magma", tex = "snaildrake_magma.tex", type = "creature", prefab = "snaildrake_magma", health = 450, damage = 25, build = "snaildrake_spikeshell", bank = "snaildrake_spikeshell", anim = "idle", deps = { "slurtle_shellpieces", "snaildrakebucket", "snapalm" }, scale = 2, animoffsetx = -10, animoffsety = -20, use_bg = true },

    boulder_crab = { name = "boulder_crab", tex = "boulder_crab.tex", type = "creature", prefab = "boulder_crab", health = 500, damage = 34, build = "boulder_crab", bank = "boulder_crab", anim = "idle", animoffsetx = 15, deps = { "rock1", "rock2", "rock_moon", "rock_flintless", "springrock1", "springrock2", "springrock3", "meat", "rocks" }, scale = 1.5, use_bg = true },

    --misc.
    trapdoor = { name = "trapdoor", tex = "trapdoor.tex", type = "thing", prefab = "trapdoor", build = "trapdoor", bank = "trapdoor", anim = "idle", workable = "MINE", deps = { "rocks", "spider_trapdoor" }, use_bg = true },
    spider_trapdoor = { name = "spider_trapdoor", tex = "spider_trapdoor.tex", subcat = "spider", type = "creature", prefab = "spider_trapdoor", sanityaura = -0.66666666666667, health = 400, damage = 34, build = "spider_trapdoor", bank = "spider", anim = "idle", perishable = 2400, deps = { "monstermeat", "spidergland", "trapdoor", "trapdoorgrass" }, use_bg = true },
    mutator_trapdoor = { name = "mutator_trapdoor", tex = "mutator_trapdoor.tex", subcat = "mutator", type = "food", prefab = "mutator_trapdoor", stacksize = 20, hungervalue = 12.5, healthvalue = -3, sanityvalue = -10, foodtype = "MEAT", build = "um_spider_mutators", bank = "um_spider_mutators", anim = "trapdoor", fueltype = "BURNABLE", fuelvalue = 15, burnable = true, craftingprefab = "webber", deps = { "cutgrass", "monstermeat", "spidergland", "spider_trapdoor" } },
    trapdoorgrass = { name = "trapdoorgrass", tex = "trapdoorgrass.tex", type = "thing", prefab = "trapdoorgrass", build = "trapdoorgrass", bank = "trapdoorgrass", anim = "idle", workable = "DIG", pickable = true, burnable = true, deps = { "cutgrass", "dug_grass", "trapdoor" }, use_bg = true, animoffsety = -20 },

    monstersmallmeat = { name = "monstersmallmeat", tex = "monstersmallmeat.tex", type = "food", prefab = "monstersmallmeat", stacksize = 40, hungervalue = TUNING.CALORIES_TINY, healthvalue = -15, sanityvalue = -10, foodtype = "MEAT", build = "extra_monsterfoods", bank = "extra_monsterfoods", anim = "idle", perishable = TUNING.PERISH_FAST, deps = { "spoiled_food", "meatrack", "meatrack_hermit", "meatrack_hermit_multi" } },
    cookedmonstersmallmeat = { name = "cookedmonstersmallmeat", tex = "cookedmonstersmallmeat.tex", type = "food", prefab = "cookedmonstersmallmeat", stacksize = 40, hungervalue = TUNING.CALORIES_TINY, healthvalue = -5, sanityvalue = -10, foodtype = "MEAT", build = "extra_monsterfoods", bank = "extra_monsterfoods", anim = "cooked", perishable = TUNING.PERISH_SLOW, deps = { "spoiled_food", "monstersmallmeat" } },
    monstersmallmeat_dried = { name = "monstersmallmeat_dried", tex = "monstersmallmeat_dried.tex", type = "food", prefab = "monstersmallmeat_dried", stacksize = 40, hungervalue = TUNING.CALORIES_TINY, healthvalue = -5, sanityvalue = -10, foodtype = "MEAT", build = "extra_monsterfoods", bank = "extra_monsterfoods", anim = "dried", perishable = TUNING.PERISH_PRESERVED, deps = { "spoiled_food", "meatrack", "meatrack_hermit", "meatrack_hermit_multi", "monstersmallmeat" } },

    um_monsteregg = { name = "um_monsteregg", tex = "um_monsteregg.tex", type = "food", prefab = "um_monsteregg", stacksize = 40, hungervalue = 9.375, healthvalue = -15, sanityvalue = -10, foodtype = "MEAT", build = "extra_monsterfoods", bank = "extra_monsterfoods", anim = "egg", perishable = 4800, deps = { "um_monsteregg_cooked", "rottenegg", "birdcage" } },
    um_monsteregg_cooked = { name = "um_monsteregg_cooked", tex = "um_monsteregg_cooked.tex", type = "food", prefab = "um_monsteregg_cooked", stacksize = 40, hungervalue = 9.375, healthvalue = -5, sanityvalue = -10, foodtype = "MEAT", build = "extra_monsterfoods", bank = "extra_monsterfoods", anim = "egg_cooked", perishable = 2880, deps = { "spoiled_food" } },

}

return data
