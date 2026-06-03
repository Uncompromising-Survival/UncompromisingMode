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
    gore_horn_hat = CreateCursedItemData("gore_horn_hat", "hat_gore_horn", "hat_gore_horn", nil, { weapondamage = 200, deps = { "minotaur", "nightmarefuel" } }),
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
    hoodedwidow = { name = "hoodedwidow", sanityaura = -TUNING.SANITYAURA_HUGE, tex = "hoodedwidow.tex", type = "giant", prefab = "hoodedwidow", health = TUNING.DSTU.WIDOW_HEALTH, damage = "75-150", build = "widow1", bank = "widow", anim = "idle", deps = { "widowsgrasp", "monstermeat", "widowshead", "spider"}, use_bg = true },
    moonmaw_dragonfly = { name = "moonmaw_dragonfly", sanityaura = TUNING.SANITYAURA_HUGE, tex = "moonmaw_dragonfly.tex", type = "giant", prefab = "moonmaw_dragonfly", health = TUNING.DSTU.MOONFLY_HEALTH, damage = "75-150", build = "moonmaw_dragonfly", bank = "moonmaw_dragonfly", anim = "idle", deps = { "meat", "glass_scales", "moonglass_geode", "moonmaw_lavae" }, use_bg = true, notes = { lunar_aligned = true } },
    mock_dragonfly = { name = "mock_dragonfly", sanityaura = -TUNING.SANITYAURA_HUGE, tex = "mock_dragonfly.tex", type = "giant", prefab = "mock_dragonfly", health = TUNING.DSTU.WILTFLY_HEALTH, damage = "75-150", build = "dragonfly_fire_build", bank = "dragonfly", anim = "idle", deps = { "dragon_scales", "meat" }, use_bg = true },
    --different icon for mock_dragonfly so they're distinguished from normal dfly

    --widow
    widowsgrasp = { name = "widowsgrasp", tex = "widowsgrasp.tex", weapondamage = TUNING.DSTU.WIDOWSGRASP_DAMAGE, finiteuses = TUNING.DSTU.WIDOWSGRASP_USES, type = "item", prefab = "widowsgrasp", build = "widowsgrasp", bank = "widowsgrasp", anim = "idle", deps = { "hoodedwidow", "webbedcreature" } },
    widowshead = { name = "widowshead", tex = "widowshead.tex", type = "item", perishable = 7.5 * TUNING.PERISH_TWO_DAY, prefab = "widowshead", build = "catcoonhat", bank = "hat_widowshead", anim = "idle", deps = { "hoodedwidow" } },
    webbedcreature = { name = "webbedcreature", tex = "webbedcreature.tex", type = "creature", prefab = "webbedcreature", build = "wackycocoons", bank = "wackycocoons", anim = "idle_medium_scrapbook", deps = { "hoodedwidow", "widowsgrasp" }, use_bg = true },
    spider_trapdoor_hooded = { name = "spider_trapdoor_hooded", tex = "spider_trapdoor_hooded.tex", subcat = "spider", type = "creature", prefab = "spider_trapdoor_hooded", sanityaura = -0.66666666666667, health = 400, damage = 34, build = "spider_trapdoor_hooded", bank = "spider", anim = "idle", perishable = 2400, deps = { "monstermeat", "silk", "spidergland", "hoodedwidow" }, use_bg = true },


    --moonmaw
    armor_glassmail = { name = "armor_glassmail", tex = "armor_glassmail.tex", subcat = "armor", type = "item", prefab = "armor_glassmail", armor = 945, absorb_percent = 0.7, build = "armor_glassmail", bank = "armor_glassmail", anim = "anim", deps = { "glass_scales", "moonglass_charged" } },
    glass_scales = { name = "glass_scales", tex = "glass_scales.tex", type = "item", prefab = "glass_scales", stacksize = 10, build = "glass_scales", bank = "glass_scales", anim = "idle" },
    moonglass_geode = { name = "moonglass_geode", tex = "moonglass_geode.tex", type = "item", prefab = "moonglass_geode", build = "moonglass_geode", bank = "moonglass_geode", anim = "idle", workable = "MINE", deps = { "moonglass_charged" } },
    moonmaw_lavae = { name = "moonmaw_lavae", tex = "moonmaw_lavae.tex", type = "creature", prefab = "moonmaw_lavae", health = 250, damage = 50, build = "moonmaw_lavae", bank = "moonmaw_lavae", anim = "hover", use_bg = true },

    --bee queen
    um_beeguard_seeker = { name = "um_beeguard_seeker", tex = "um_beeguard_seeker.tex", subcat = "insect", type = "creature", prefab = "um_beeguard_seeker", health = 180 * 0.5, damage = 15, build = "fatbee_guard_build", bank = "bee_guard", anim = "idle", animoffsety = 100, deps = { "beequeen", "stinger" }, use_bg = true },
    um_beeguard_shooter = { name = "um_beeguard_shooter", tex = "um_beeguard_shooter.tex", subcat = "insect", type = "creature", prefab = "bulletbee_guard", health = 180 * 0.5, damage = 15, build = "fatbee_guard_build", bank = "bee_guard", anim = "idle", animoffsety = 100, deps = { "beequeen", "stinger" }, use_bg = true },
    um_beeguard_blocker = { name = "um_beeguard_blocker", tex = "um_beeguard_blocker.tex", subcat = "insect", type = "creature", prefab = "um_beeguard_blocker", health = 180 * 15, damage = 15, build = "hivehead_bee_guard", bank = "bee_guard", anim = "idle", animoffsety = 100, deps = { "beequeen", "stinger" }, use_bg = true },

    -- lunar/grotto
    um_bee_moon = { name = "um_bee_moon", tex = "um_bee_moon.tex", subcat = "insect", type = "creature", prefab = "um_bee_moon", health = 250, damage = 34, stacksize = 20, build = "um_bee_moon", bank = "um_bee_moon", anim = "idle", animoffsety = 150, perishable = 960, workable = "NET", deps = { "um_meathoney", "houndstooth" }, notes = { lunar_aligned = true } },
    um_astral_projector = { name = "um_astral_projector", tex = "um_astral_projector.tex", subcat = "structure", type = "thing", prefab = "um_astral_projector", build = "um_archives_projectinator", bank = "um_archives_projectinator", anim = "idle", workable = "HAMMER", deps = { "um_astral_projector_target", "purplemooneye", "thulecite", "moonrocknugget" } },
    um_astral_projector_target = { name = "um_astral_projector_target", tex = "um_astral_projector_target.tex", subcat = "structure", type = "thing", prefab = "um_astral_projector_target", build = "um_archives_receptionator", bank = "um_archives_receptionator", anim = "idle", workable = "HAMMER", deps = { "moonglass", "thulecite", "moonrocknugget" } }

    --hooded forest
    

    --broiling

    --misc.


}

return data
