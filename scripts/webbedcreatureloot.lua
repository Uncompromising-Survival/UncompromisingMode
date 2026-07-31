UMWebbedCreatureUtil = {}

---@param item string|function The loot item prefab, or a function that returns a prefab.
---@param count? number The number of items to spawn
---@param chance? number The chance to spawn the item
---@param use_durability? boolean Whether to set the durability of the item, if any durability-esque component is present
---@param lootfn? function A function that gets called when the item is dropped, with the spawned item prefab as an argument.
---@return table loot_table
UMWebbedCreatureUtil.Item = function(item, count, chance, use_durability, lootfn)
    return {
        prefab = item,
        amount = count or 1,
        chance = chance or 1,
        use_durability = use_durability or false,
        lootfn = lootfn
    }
end

---@param ... string number of item prefabs - NOT A TABLE! var-arg!
---@return function item a function that returns a random str from the provided strings.
UMWebbedCreatureUtil.RandomItem = function(...)
    return function() return arg[math.random(#arg)] end
end

local Item = UMWebbedCreatureUtil.Item
local RandomItem = UMWebbedCreatureUtil.RandomItem

UMWebbedCreatureUtil.COCOON_SIZE = {
    SMALL = 0,
    MEDIUM = 1,
    LARGE = 2
}

--automatically populated by metatable.
UMWebbedCreatureUtil.COCOON_CREATURES_DEFAULT = {}
UMWebbedCreatureUtil.COCOON_CREATURES_SHIPWRECKED = {}
UMWebbedCreatureUtil.COCOON_CHARACTERS = {}

UMWebbedCreatureUtil.COCOON_DEFS = {}
UMWebbedCreatureUtil.COCOON_DEFS.CHARACTER = {}
UMWebbedCreatureUtil.COCOON_DEFS.DEFAULT = {}
UMWebbedCreatureUtil.COCOON_DEFS.SHIPWRECKED = {}

setmetatable(UMWebbedCreatureUtil.COCOON_DEFS.CHARACTER, {
    __newindex = function(t, k, v)
        --[[printwrap("t", t)
        print(k)
        printwrap("v", v)]]
        table.insert(UMWebbedCreatureUtil.COCOON_CHARACTERS, k)

        v.size = 1          --automatically set size
        v.name = "Shrouded" --and name for character cocoons.

        rawset(t, k, v)
    end
})

setmetatable(UMWebbedCreatureUtil.COCOON_DEFS.DEFAULT, {
    __newindex = function(t, k, v)
        table.insert(UMWebbedCreatureUtil.COCOON_CREATURES_DEFAULT, k)
        rawset(t, k, v)
    end
})

setmetatable(UMWebbedCreatureUtil.COCOON_DEFS.SHIPWRECKED, {
    __newindex = function(t, k, v)
        table.insert(UMWebbedCreatureUtil.COCOON_CREATURES_SHIPWRECKED, k)
        rawset(t, k, v)
    end
})

local characters = {
    GENERIC = {
        loot = {
            Item("skeleton"),
            Item("boneshard", 2),
            Item("boneshard", 2, .5),
            Item("cutgrass", 6),
            Item("cutgrass", 6, .5),
            Item("twigs", 6),
            Item("twigs", 6, .5),
            Item("armorwood", 1, 1, true),
            Item("footballhat", 1, 1, true),
            Item("tentaclespike", 1, 1, true)
        }
    },
    WILSON = {
        loot = {
            Item("blueprint", 3),
            Item("blueprint", 2, .5),
            Item("beardhair", 4),
            Item("beardhair", 2, .5),
            Item(RandomItem("bluegem", "redgem", "purplegem"), 2)
        }
    },
    WILLOW = {
        loot = {
            Item("firestaff"),
            Item("sludge_oil"),
            Item("lighter", 1, 1, true),
            Item(RandomItem("snapalm", "slurtleslime"), 4, .5)
        }
    },
    WOLFGANG = {
        loot = {
            Item("armormarble", 1, 1, true),
            Item("marble", 6),
            Item("pigskin"),
            Item("potato_cooked", 3, 1, true),
            Item("potato_cooked", 3, .3, true),
            Item("armorslurper", 1, .2, true),
            Item("bonestew", 1, .3, true)
        }
    },
    WENDY = {
        loot = {
            Item("ghostflowerhat", 1, 1, true),
            Item("moon_tree_blosson", 6, .5, true),
            Item("petals_evil", 4, 1, true),
            Item(RandomItem("ghostlyelixir_fastregen", "ghostlyelixir_slowregen"), 2),
            Item(RandomItem("ghostlyelixir_retaliation", "ghostlyelixir_shield"), 2, .5),
            Item(RandomItem("ghostlyelixir_attack", "ghostlyelixir_speed"), 2, .5),
            Item("ghostlyelixir_revive", 2, .5),
            Item(RandomItem("halloweenpotion_sanity_large", "halloweenpotion_sanity_small"), 2),
            Item(RandomItem("halloweenpotion_health_large", "halloweenpotion_health_small"), 2),
            Item("butterfly", 4, .5)
        }
    },
    WX78 = {
        loot = {
            Item("gears", 2),
            Item("gears", 1, .5),
            Item("transistor", 2),
            Item("goatmilk", 2, 1, true),
            Item("goatmilk", 1, .5, true),
            Item("zaspberry_lesser", 2, 1, true),
            Item("zaspberry_lesser", 2, .5, true),
            Item("zaspberry", 1, .5),
            Item(function() return TheWorld.state.isspring and RandomItem("raincoat", "rainhat") or nil end, 1, .1, true)
        }
    },
    WICKERBOTTOM = {
        loot = {
            Item("papyrus", 4),
            Item("papyrus", 2, .5),
            Item("featherpencil", 3),
            Item("featherpencil", 1, .5),
            Item("tentaclespots", 2, .2),
            Item("featherhat", 1, 1, true),
            Item("green_cap", 4, 1, true),
            Item("green_cap", 2, .5, true),
            Item("fx_book_birds", 1, 1, nil, function(inst)
                local birdspawner = TheWorld.components.birdspawner
                if not birdspawner then return false end
                local pt = inst:GetPosition()
                local BIRDSMAXCHECK_MUST_TAGS = { "magicalbird" }
                local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 10, BIRDSMAXCHECK_MUST_TAGS)
                if #ents > 30 then return false end
                local num = math.random(10, 20)
                if #ents <= 10 then num = num + 10 end
                local delay = 0
                for k = 1, num do
                    local pos = birdspawner:GetSpawnPoint(pt)
                    if pos then
                        local bird = birdspawner:SpawnBird(pos, true)
                        if bird then
                            bird:AddTag("magicalbird")
                            bird.sg:GoToState("delay_glide", delay)
                            delay = delay + .034 + .033 * math.random()
                        end
                    end
                end
            end)
        }
    },
    WOODIE = {
        loot = {
            Item("walking_stick", 1, 1, true),
            Item("boards", 10, .5),
            Item("log", 10),
            Item("log", 20, .75),
            Item(RandomItem("wereitem_beaver", "wereitem_moose", "wereitem_goose"), 1, 1, true)
        }
    },
    WAXWELL = {
        loot = {
            Item("nightmarefuel", 4),
            Item("nightmarefuel", 6, .5),
            Item("tophat", 1, 1, true),
            Item("rabbit"),
            Item("purpleamulet", 1, .2),
            Item(RandomItem("nightsword", "armor_sanity"), 1, 1, true)
        }
    },
    WATHGRITHR = {
        loot = {
            Item(function()
                return TheWorld.state.iswinter and "trunk_winter" or "trunk_summer"
            end, 1, 1, true),
            Item("meat", 6, 1, true),
            Item("meat", 2, .5, true),
            Item("wathgrithrhat"),
            Item("wathgrithrhat", 1, .5, true),
            Item("spear_wathgrithr", 1, 1, true),
            Item("spear_wathgrithr", 1, .5, true)
        }
    },
    WEBBER = {
        loot = {
            Item("silk", 6),
            Item("silk", 6, .5),
            Item("spidereggsack"),
            Item("healingsalve", 3),
            Item("healingsalve", 3, .5),
            Item(RandomItem("monstermeat", "monstersmallmeat"), 6, .5, true),
            Item("sewing_kit")
        }
    },
    WINONA = {
        loot = {
            Item("sewing_tape", 2),
            Item("sewing_tape", 2, .5),
            Item("nitre", 4),
            Item("nitre", 4, .5),
            Item("rocks", 6),
            Item("rocks", 8, .8),
            Item("wagpunk_bits", 4, .5),
            Item("powercell", 2, .5),
            Item(RandomItem("nightstick", "bugzapper"), 1, .1, true)
        }
    },
    WARLY = {
        loot = {
            Item("yotc_seedpacket_rare", 3),
            Item("saltrock"),
            Item("saltrock", 5, .5),
            Item(RandomItem("pepper", "garlic"), 3, 1, true),
            Item(RandomItem("pepper", "garlic"), 3, .5, true),
            Item("voltgoatjelly", 1, .1, true),
            Item(RandomItem("glowberrymousse_spice_sugar", "nightmarepie", "potatosouffle_spice_chili"), 1, .3, true),
            Item(RandomItem("moqueca_spice_salt", "bonesoup_spice_garlic", "freshfruitcrepes"), 1, .3, true),
            Item(RandomItem("theatercorn_spice_salt", "beefalowings_spice_garlic", "stuffed_peeper_poppers"), 1, .3, true),
            Item(RandomItem("zaspberryparfait_spice_sugar", "snotroast_spice_chili", "viperjam_spice_sugar"), 1, .3, true),
            Item(RandomItem("um_rimeweed_spagett", "um_rimeweed_tequila"), 1, .3, true)
        }

    },
    WORTOX = {
        loot = {
            Item("wortox_soul", 4),
            Item("wortox_soul", 16, .3),
            Item("redgem"),
            Item("redgem", 2, .5),
            Item("pomegranate", 2),
            Item("pomegranate", 3, .5),
            Item("devilsfruitcake"),
            Item("beemine"),
            Item("cotl_trinket", 1, .3),
            Item("panflute", 1, .1),
            Item("krampus_sack", 1, .01)
        }
    },
    WORMWOOD = {
        loot = {
            Item("yotc_seedpacket_rare", 5),
            Item("livinglog", 2),
            Item("livinglog", 4, .5),
            Item(RandomItem("compostwrap", "tillweedsalve"), 4, 1, true),
            Item(RandomItem("gloomcap", "moon_cap"), 6, .5, true),
            Item(function() return TheWorld.state.issummer and "cactus_flower" or "dragonfruit" end, 4, .5, true),
            Item("cactus_meat", 2),
            Item("cactus_meat", 4, .5),
            Item("lightflier", 6, .3),
            Item(function() return TheWorld.state.iswinter and "um_armor_bramble_rimeweed" or "armor_bramble" end, 1, .5, true),
            Item("trap_bramble", 3, .5),
            Item("lureplantbulb", 1, .2)
        }
    },
    WURT = {
        loot = {
            Item("cutreeds", 4),
            Item("cutreeds", 8, .5),
            Item("tentaclespots", 2, .5),
            Item("mosquito", 4, .1),
            Item("mosquitobomb", 3, .5),
            Item("mosquitofertilizer", 4, .5),
            Item("mosquitomusk", 1, 1, true),
            Item("mosquitosack", 6, .5),
            Item("pondfish", 4, .5),
            Item("tentaclespike", 3, .75, true),
            Item("mermhat", 1, .2, true)
        }
    },
    WALTER = {
        loot = {
            Item(RandomItem("fishmeat_small_dried", "smallmeat_dried"), 4, 1, true),
            Item(RandomItem("monstermeat_dried", "monstersmallmeat_dried"), 5, .5, true),
            Item("kelp_dried", 4),
            Item("kelp_dried", 2, .5),
            Item(RandomItem("healingsalve", "bandage_butterflywings"), 5, .5, true),
            Item(RandomItem("floral_bandage", "bandage"), 2, .5, true),
            Item("brine_balm", 2, .2),
            Item(RandomItem("portabletent_item", "bedroll_furry"), 1, .3, true),
            Item(RandomItem("meatrack_hat", "walterhat", "bushhat"), 1, .5, true),
            Item("um_record_walter", 1, .05)
        }
    },
    WANDA = {
        loot = {
            Item("thulecite_pieces", 4),
            Item("thulecite_pieces", 8, .5),
            Item("nightmarefuel", 2),
            Item("nightmarefuel", 6, .5),
            Item("marble", 6, .5),
            Item("armor_sanity", 1, .5, true),
            Item("walrus_tusk", 1, .5),
            Item("purplegem", 1, .5),
            Item("oldager_become_younger_front_fx", 1, .5)
        }
    },
    WINKY = {
        loot = {
            Item("trinket_20", 1),
            Item("spoiled_food", 6),
            Item("spoiled_food", 12, .5),
            Item("rat_tail", 2),
            Item("rat_tail", 4, .5),
            Item("monstersmallmeat", 8, .5),
            Item(RandomItem("trinket_1", "trinket_2"), 1, .15),
            Item(RandomItem("trinket_3", "trinket_4"), 1, .15),
            Item(RandomItem("trinket_5", "trinket_6"), 1, .15),
            Item(RandomItem("trinket_7", "trinket_8"), 1, .15),
            Item(RandomItem("trinket_9", "trinket_10"), 1, .15),
            Item(RandomItem("trinket_11", "trinket_12"), 1, .15),
            Item(RandomItem("trinket_13", "trinket_14"), 1, .15),
            Item(RandomItem("trinket_17", "trinket_18"), 1, .15),
            Item(RandomItem("trinket_19", "trinket_21"), 1, .15),
            Item(RandomItem("trinket_22", "trinket_23"), 1, .15),
            Item(RandomItem("trinket_24", "trinket_25"), 1, .15),
            Item(RandomItem("trinket_26", "trinket_27"), 1, .2),
            Item(RandomItem("cctrinket_don", "cctrinket_freddo"), 1, .2),
            Item(RandomItem("cctrinket_names", "trinket_jazzy"), 1, .2),
            Item("corncan", 1, .2),
            Item("um_record_winky", 1, .05)
        }
    },
    WATHOM = {
        loot = {
            Item("purplegem", 1),
            Item("meat", 2, 1, true),
            Item("meat", 4, .5, true),
            Item("nightmarefuel", 4),
            Item("nightmarefuel", 8, .5),
            Item(RandomItem("ancient_amulet_red", "amulet"), 1, .5, true),
            Item(RandomItem("ruins_bat", "hambat"), 1, .5, true),
            Item("thulecite", 1),
            Item("thulecite", 5, .3),
            Item("um_record_wathom", 1, .05)
        }
    },
    WIXIE = {
        loot = {
            Item("bagofmarbles", 1),
            Item("bagofmarbles", 3, .5),
            Item(RandomItem("um_blowdart_pyre", "um_blowdart_rime"), 3, .5),
            Item(RandomItem("slingshotammo_honey", "slingshotammo_goop"), 20, .75),
            Item("nitre", 3),
            Item("nitre", 5, .5),
            Item("mosquitosack", 2),
            Item("mosquitosack", 4, .5),
            Item(RandomItem("livinglog", "driftwood_log"), 2, .5),
            Item(RandomItem("sludge", "saltrock"), 4, .5),
            Item(RandomItem("moonrocknugget", "moonglass"), 6),
            Item("townportaltalisman", 3, .1),
            Item("um_record_wixie", 1, .05)
        }

    },
    WES = {
        loot = {
            Item("balloonparty_confetti_cloud", 5),
            Item("balloonspeed", 10, .5),
            Item("balloon", 1, .01),
            Item("freshfruitcrepes", 1),
            Item("balloonhat", 1),
            Item("balloonvest", 1),
            Item("waterballoon", 10, .3)
        }
    },
    WAGSTAFF = {
        loot = {
            Item("wagpunk_bits", 4),
            Item("wagpunk_bits", 4, .5),
            Item("cutstone", 2),
            Item("cutstone", 1, .5),
            Item("transistor", 1),
            Item("moonglass", 6),
            Item("moonglass", 6, .5),
            Item("goggleshat", 1, 1, true)
        }
    },
}

local function GemologyRoll(inst)
    if inst and inst:HasTag("gemology_gem") then
        if math.random() <= .1 then
            inst:SetTier(3)
        else
            inst:SetTier(2)
        end
    end
end

local default = {
    BEEGUARD = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Buggy",
        loot = {
            Item("honeycomb", 2),
            Item("honey", 5),
            Item("honey", 1, .5),
            Item("stinger", 1, .1),
            Item("royal_jelly", 1)
        }
    },
    EYEOFTERROR_MINI = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Grotesque",
        loot = {
            Item("milkywhites", 3),
            Item("milkywhites", 1, .5),
            Item("monstermeat", 1),
            Item("monstermeat", 1, .5)
        }
    },
    CATCOON = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("coontail", 4),
            Item(RandomItem("pondfish", "robin", "robin_winter", "canary", "rabbit", "mole", "butterfly", "um_buttery_fly"), 1, 1, false, function(inst)
                if inst and inst.sg and inst.sg:HasState("stunned") then
                    inst.sg:GoToState("stunned")
                end
                if inst and Prefabs["feather_" .. inst.prefab] then
                    for i = 1, 2 do
                        inst.components.lootdropper:SpawnLootPrefab("feather_" .. inst.prefab)
                    end
                end
            end)
        }
    },
    ALPHA_LIGHTNINGGOAT = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Hairy",
        loot = {
            Item("meat", 1, .5),
            Item("lightninggoathorn")
        }
    },
    BISHOP = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Hardened",
        loot = {
            Item("trinket_6", 2)
        }
    },
    MERM = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Soggy",
        loot = {
            Item("froglegs", 1, 1),
            Item("tentaclespots", 2),
            Item("cutreeds", 6),
            Item("cutreeds", 2, .5)
        }
    },
    PIGMAN = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Leathery",
        loot = {
            Item("meat"),
            Item("pigskin"),
            Item("pigskin", 1, .5),
            Item("tophat"),
            Item("goldnugget", 3),
            Item("goldnugget", 1, .5),
            Item("pig_token", 1, .1)
        }
    },
    OTTER = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Soggy",
        loot = {
            Item("smallmeat"),
            Item("kelp", 4),
            Item("kelp", 2, .75),
            Item("kelp", 1, .5),
            Item("barnacle", 1, .5),
            Item("barnacle", 1, .25),
            Item("messagebottle"),
            Item("bullkelp_root", 3),
            Item("bullkelp_root", 1, .5),
            Item(RandomItem("oceanfish_small_4_inv", "oceanfish_small_3_inv", "oceanfish_small_9_inv", "oceanfish_medium_1_inv"), 1),
            Item(function()
                return TheWorld.state.isautumn and "oceanfish_small_6_inv" or
                    TheWorld.state.iswinter and "oceanfish_medium_8_inv" or
                    TheWorld.state.isspring and "oceanfish_small_7_inv" or
                    TheWorld.state.issummer and "oceanfish_small_8_inv" or
                    "wobster_sheller_land"
            end, 1, 1)
        }
    },
    SLURTLE = { --50/50 for snurtle
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Soggy",
        loot = {
            Item("slurtleslime", 4),
            Item("slurtleslime", 2, .5),
            Item("slurtle_shellpieces", 4),
            Item("nitre", 5),
            Item("nitre", 3, .5),
            Item("greengem", 1, .3),
            Item(RandomItem("um_gemologygreengem1", "um_gemologygreengem2"), 1, 1, nil, GemologyRoll)
        }
    },
    PIED_RAT = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Grotesque",
        loot = {
            Item("monstermeat", 2),
            Item("monstermeat", 1, .5),
            Item("rat_tail", 2),
            Item("rat_tail", 1, .5),
            Item("beardhair", 3),
            Item("beardhair", 1, .5)
        }
    },
    MOSSLING = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Feathery",
        loot = {
            Item(RandomItem("meat", "drumstick"), 1),
            Item("drumstick"),
            Item("goose_feather"),
            Item("goose_feather", 1, .5)
        }
    },
    TALLBIRD = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Feathery",
        loot = {
            Item("tallbirdegg"),
            Item("meat"),
            Item("meat", 1, .5),
            Item("feather_crow", 2),
            Item("feather_crow", 1, .25),
            Item("feather_robin", 2),
            Item("feather_robin", 1, .25),
            Item("feather_robin_winter", 2),
            Item("feather_canary", 2),
            Item("feather_canary", 1, .25)
        }
    },
    UM_FERN_FOX = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Hairy",
        loot = {
            Item("plantmeat", 1, 1),
            Item("um_moss", 3),
            Item("um_moss", 1, .5),
            Item("cutgrass", 4),
            Item("twigs", 4),
            Item("cactus_flower", 3),
            Item("cactus_flower", 1, .5)
        }
    },
    KRAMPUS = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Grotesque",
        loot = {
            Item("monstermeat", 1, .5),
            Item("charcoal", 2),
            Item("boneshard"),
            Item("krampus_sack", 1, .05),
            Item("bluegem"),
            Item("redgem")
        }
    },
    WALRUS = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Leathery",
        loot = {
            Item("meat", 1, .5),
            Item("walrus_tusk"),
            Item(RandomItem("um_bear_trap_equippable_tooth", "um_bear_trap_equippable_gold"), 1),
            Item(RandomItem("um_blowdart_pyre", "um_blowdart_rime", "blowdart_pipe", "blowdart_fire", "blowdart_sleep", "blowdart_yellow"), 1)
        }
    },
    GLACIALHOUND = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Grotesque",
        loot = {
            Item("monstermeat", 1, .5),
            Item("ice", 6),
            Item("ice", 4, .5),
            Item("bluegem"),
            Item("houndstooth", 2),
            Item("houndstooth", 1, .5),
            Item("um_rimeweed_itemflower")
        }
    },
    SNOWMONG = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Soggy",
        loot = {
            Item("charcoal", 2),
            Item("um_ice_tail"),
            Item("um_ice_tail", 1, .5),
            Item("snowball_item", 4),
            Item("snowball_item", 2, .5),
            Item("ice", 10),
            Item("ice", 4, .5),
            Item("um_rimeweed_itemvine", 3, 1),
            Item("um_rimeweed_itemvine", 1, .5),
            Item(RandomItem("um_gemologybluegem1", "um_gemologybluegem2"), 1, 1, nil, GemologyRoll)
        }
    },
    SNAILDRAKE_MAGMA = { --50/50 for snaildrake_slime
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Soggy",
        loot = {
            Item("snapalm", 5),
            Item("snapalm", 1, .5),
            Item("slurtle_shellpieces", 4),
            Item("slurtle_shellpieces", 1, .5),
            Item("redgem"),
            Item("redgem", 1, .5),
            Item("um_fyrite", 5),
            Item("um_fyrite", 1, .5),
            Item(RandomItem("um_gemologyredgem1", "um_gemologyredgem2"), 1, 1, nil, GemologyRoll)
        }
    },
    LORDFRUITFLY = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Buggy",
        loot = {
            Item("plantmeat"),
            Item("seeds", 4),
            Item("seeds", 4, .25),
            Item(RandomItem("dug_sapling", "dug_grass", "dug_monkeytail", "dug_berrybush", "dug_berrybush2", "dug_berrybush_juicy"), 4)
        }
    },
    SPIDERQUEEN = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Buggy",
        loot = {
            Item("monstermeat", 2),
            Item("monstermeat", 1, .5),
            Item("silk"),
            Item("silk", 1, .5),
            Item("spidereggsack", 1, .25),
            Item("spider_healer", 1, 1)
        }
    },
    BEEFALO = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("meat", 1, .5),
            Item("beefalowool", 2, 1),
            Item("beefalowool", 1, .5),
            Item("horn"),
            Item("poop", 3),
            Item("poop", 1, .5)
        }
    },
    WARG = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Hairy",
        loot = {
            Item("monstermeat"),
            Item("houndstooth", 3),
            Item("houndstooth", 1, .5),
            Item("boneshard", 4),
            Item("boneshard", 1, .5),
            Item("bluegem"),
            Item("redgem"),
            Item("purplegem")
        }
    },
    KOALEFANT_SUMMER = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Leathery",
        loot = {
            Item("meat", 3),
            Item("meat", 1, .5),
            Item("poop", 1, .5)
        }
    },
    LEIF_SPARSE = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Hardened",
        loot = {
            Item("plantmeat", 1),
            Item("livinglog", 2, .5),
            Item("log", 10, .75),
            Item("log", 10)
        }
    },
    ROCKY = { --Used to be Boulder Crab, RIP. -CB
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Hardened",
        loot = {
            Item("meat", 2),
            Item("meat", 1, .5),
            Item("smallmeat", 3, .5),
            Item("moonrocknugget", 3),
            Item("moonrocknugget", 2, .5),
            Item("rocks", 10),
            Item("rocks", 2, .5),
            Item("flint", 4),
            Item("flint", 2, .5),
            Item("goldnugget", 3),
            Item("goldnugget", 2, .5),
            Item("nitre", 3),
            Item("nitre", 2, .5),
            Item("marble", 4),
            Item("marble", 2, .5),
            Item(RandomItem("um_gemologypalegem1", "um_gemologypalegem2"), 1, 1, nil, GemologyRoll)
        }
    },
    --[[
    DEER = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("meat", 1, .5),
            Item("deer_antler"),
            Item("redgem"),
            Item("bluegem")
        }
    },
    ROOK = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Hardened",
        loot = {
            Item("gears", 2),
            Item("gears", 1, .5),
            Item("transistor", 2),
            Item("trinket_6", 2),
            Item("trinket_6", 1, .5),
            Item("trinket_1", 1)
        }
    },
    SHARK = { --I don't like this one i'm ngl. - Atobá
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Leathery",
        loot = {
            Item("fishmeat", 1, .5),
            Item("barnacle", 3),
            Item("rocks", 3),
            Item("nitre", 2),
            Item("nitre", 2, .5)
        }
    },
    GRASSGATOR = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Leafy",
        loot = {
            Item("plantmeat", 1, .5),
            Item("cutgrass", 4),
            Item("twigs", 4),
            Item("cactus_flower", 3),
            Item("cactus_flower", 3, .5)
        }
    },]]
}

--todo:
--snake monster morsel

--[[

    palm treeguard
    doydoy
]]
local sw = {
    SHARKITTEN = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Leathery",
        loot = {
            Item("shark_gills"),
            Item("shark_gills", 1, .5),
            Item("mysterymeat", 1, 1, true),
            Item("fishmeat", 4, .5, true)
        }
    },
    MERMFISHER = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Scaly",
        loot = {
            Item(RandomItem("pondpurple_grouper", "pondneon_quattro", "pondpierrot_fish")),
            Item("blowdart_flup")
        }
    },
    PRIMEAPE = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Hairy",
        loot = {
            Item("poop", 2),
            Item("poop", 4, .25),
            Item("cave_banana", 2),
            Item("cave_banana", 4, .25),
            Item("purplegem", 1, .1),
            Item("dubloon", 4, .5)
        }
    },
    OX = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("meat", 1, .5),
            Item("ox_horn"),
            Item("poop", 2),
            Item("poop", 4, .25)
        }
    },
    CROCODOG = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Scaly",
        loot = {
            Item("houndstooth"),
            Item("venomgland", 1, .5)
        }
    },
    WILDBORE = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Leathery",
        loot = {
            Item("meat"),
            Item("pigskin"),
            Item(RandomItem("tophat", "gashat", "piratehat", "snakeskinhat", "shark_teethhat"))
        }
    },
    STUNGRAY = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.SMALL,
        name = "Leathery",
        loot = {
            Item("monstermeat"),
            Item("venomgland"),
            Item("venongland", 1, .5)
        }
    },
    DOYDOY = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Feathery",
        loot = {
            Item("doydoyegg")
        }
    },
    LEIF_PALM = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.LARGE,
        name = "Leafy",
        loot = {
            Item("plantmeat", 1),
            Item("livinglog", 2, .5),
            Item("log", 5, .75),
            Item("log", 5),
            Item("coconut", 3),
            Item("coconut", 3, .5)
        }
    },
    DRAGOON = {
        size = UMWebbedCreatureUtil.COCOON_SIZE.MEDIUM,
        name = "Scaly",
        loot = {
            Item("obsidian"),
            Item("obsidian", 3, .5),
            Item("monstermeat")
        }
    },
    KRAMPUS = default.KRAMPUS,
    BEEGUARD = default.BEEGUARD,
    TALLBIRD = default.TALLBIRD,
    SPIDERQUEEN = default.SPIDERQUEEN
}

--poopulate globals.
for k, v in pairs(characters) do
    UMWebbedCreatureUtil.COCOON_DEFS.CHARACTER[k] = v
end

for k, v in pairs(default) do
    UMWebbedCreatureUtil.COCOON_DEFS.DEFAULT[k] = v
end

for k, v in pairs(sw) do
    UMWebbedCreatureUtil.COCOON_DEFS.SHIPWRECKED[k] = v
end

---@param modid string The mod id of the character's mod. You can see the modid in the end of the link of the workshop page.
---@param character string The character's prefab name.
---@param loot_pool table The loot pool for the character. See above and below for examples.
UMWebbedCreatureUtil.AddCompatCharacterCocoon = function(modid, character, loot_pool)
    assert(type(modid), "Bad argument #1 to AddCompatCharacterCocoon. Expected string, got " .. type(modid))
    assert(type(character), "Bad argument #2 to AddCompatCharacterCocoon. Expected string, got " .. type(character))
    assert(type(loot_pool) == "table", "Bad argument #3 to AddCompatCharacterCocoon. Expected table, got " .. type(loot_pool))

    if KnownModIndex:IsModEnabled("workshop-" .. modid) then
        UMWebbedCreatureUtil.COCOON_DEFS.CHARACTER[string.upper(character)] = { loot = loot_pool }
    end
end

---@param creature string The creature prefab
---@param size number the size number, 0 to 2 (see COCOON_SIZE)
---@param prefix string the cocoon prefix
---@param loot_pool table the loot table.
---@param sw? boolean whether it's a shipwrecked cocoon
UMWebbedCreatureUtil.AddCocoon = function(creature, size, prefix, loot_pool, sw)
    assert(type(creature), "Bad argument #1 to AddCocoon. Expected string, got " .. type(creature))
    assert(type(size), "Bad argument #2 to AddCocoon. Expected number, got " .. type(size))
    assert(type(prefix), "Bad argument #3 to AddCocoon. Expected string, got " .. type(prefix))
    assert(type(loot_pool) == "table", "Bad argument #4 to AddCocoon. Expected table, got " .. type(loot_pool))

    assert(size >= 0 and size <= 2, "Cocoon size for " .. creature .. " must be between 0 and 2. (was " .. size .. ")")

    if sw then
        UMWebbedCreatureUtil.COCOON_DEFS.SHIPWRECKED[string.upper(creature)] = {
            size = size,
            name = prefix,
            loot = loot_pool
        }
    else
        UMWebbedCreatureUtil.COCOON_DEFS.DEFAULT[string.upper(creature)] = {
            size = size,
            name = prefix,
            loot = loot_pool
        }
    end
end

---@param character string The character's prefab name.
---@param loot_pool table The loot pool for the character. See above and below for examples.
UMWebbedCreatureUtil.AddCharacterCocoon = function(character, loot_pool)
    assert(type(character), "Bad argument #1 to AddCharacterCocoon. Expected string, got " .. type(character))
    assert(type(loot_pool) == "table", "Bad argument #2 to AddCharacterCocoon. Expected table, got " .. type(loot_pool))

    UMWebbedCreatureUtil.COCOON_DEFS.CHARACTER[string.upper(character)] = { loot = loot_pool }
end

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3484995444", "wieneke", {
    Item("koalefantcorpse", 1, 1, nil, function(inst)
        if TheWorld.state.iswinter then
            inst:SetAltBuild("koalefant_winter_build")
        end
        if inst.SetMeatPercent then
            inst:SetMeatPercent(.33)
            inst.sg:GoToState("corpse_idle")
        end
    end),
    Item("glommerfuel", 2),
    Item("glommerfuel", 2, .5),
    Item("trinket_9"),
    Item("snotroast", 1, 1, true),
    Item("halloweencandy_8")
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("2496686961", "flaire", {
    Item("nightsword"),
    Item("flaire_bolsteredsword", 1, 1, true),
    Item("flaire_cleargem", 2),
    Item("flaire_cleargem", 1, .5),
    Item("bluegem"),
    Item("redgem"),
    Item("flaire_manaflask_potent", 2),
    Item("flaire_manaflask_potent", 1, .5),
    Item("goldnugget", 2),
    Item("goldnugget", 4, .5),
    Item("flaire_spellscroll", 1)
})

--reign of runts
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2010472942", "weerclops", {
    Item("ice", 12),
    Item("ice", 12, .5),
    Item("snowball_item", 4, 1, true),
    Item("snowball_item", 8, .5, true),
    Item("um_rimeweed_itemvine", 3),
    Item("um_rimeweed_itemvine", 3, .5),
    Item("um_rimeweed_itemflower", 1, .5),
    Item("um_rimeweed_icepack"),
    Item("um_rimeweed_icepack", 2, .5),
    Item(RandomItem("um_hat_rime", "rimeweed_whip"), 1, .5),
    Item(RandomItem("beakbasher", "hammer"), 1, .5)
})
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2010472942", "woose", {
    Item("tallbirdegg"),
    Item("dug_sapling"),
    Item("twigs", 6),
    Item("twigs", 8, .5),
    Item("cutgrass", 6),
    Item("cutgrass", 8, .5),
    Item("goose_feather", 3),
    Item("goose_feather", 3, .5),
    Item("feather_crow", .5, 3),
    Item("feather_robin", .5, 3),
    Item("feather_robin_winter", .5, 3),
    Item("feather_canary", .5, 3),
    Item("malbatross_feather", .5, 6),
    Item("featherfan", .5, 3, true)
})
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2010472942", "wearger", {
    Item("honey", 4, 1, true),
    Item("honey", 4, .5, true),
    Item("honeycomb"),
    Item("honeycomb", 2, .5),
    Item("royal_jelly", 1, .5, true),
    Item("honeyham", 1, 1, true),
    Item("bedroll_furry"),
    Item("furtuft", 12),
    Item("furtuft", 30, .5)
})
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2010472942", "wragonfly", {
    Item("ash", 6),
    Item("ash", 14, .5),
    Item("charcoal", 6),
    Item("charcoal", 14, .5),
    Item("goldnugget", 4),
    Item("goldnugget", 4, .5),
    Item("redgem"),
    Item("redgem", .5),
    Item("bluegem"),
    Item("bluegem", .5),
    Item("purplegem", .5, 2),
    Item("orangegem", .1, 2),
    Item("yellowgem", .1, 2),
    Item("greengem", .1, 2),
    Item("lavae_cocoon")
})

--island adventures
UMWebbedCreatureUtil.AddCompatCharacterCocoon("3435352667", "wilbur", {
    Item("dug_monkeytail", 2),
    Item("dug_monkeytail", 2, .5),
    Item("dug_bananabush", .1, 2),
    Item("cave_banana", 3, 1, true),
    Item("cave_banana", 5, .5, true),
    Item(RandomItem("frozenbananadaiquiri", "bananapop"), 1, 1, true),
    Item("monkeyball", 1, 1, true),
    Item(RandomItem("monkey_smallhat", "oar_monkey"), 1, 1, true),
    Item("poop", .5, 6),
    Item("blackflag", 1, 1, true),
    Item(RandomItem("cutlass", "cutless"), 1, .9, true)
})
UMWebbedCreatureUtil.AddCompatCharacterCocoon("3435352667", "walani", {
    Item("seashell", 4),
    Item("seashell", 4, .5),
    Item("boards", 2),
    Item("sunglasses", 1, 1, true),
    Item(RandomItem("bananajuice", "vegstinger"), 1, 1, true),
    Item("palmleaf", 2),
    Item("palmleaf", 4, .5),
    Item("coconut", 3, 1, true),
    Item("coconut", 5, .5, true),
    Item("coconade", .3, 2),
    Item(RandomItem("cutlass", "spear_launcher"), 1, .9, true)
})
UMWebbedCreatureUtil.AddCompatCharacterCocoon("3435352667", "woodlegs", {
    Item("woodlegshat", 1, 1, true),
    Item(RandomItem("supertelescope", "telescope"), 1, 1, true),
    Item("dubloon", 10),
    Item("dubloon", 20, .5),
    Item("boneshard", 6),
    Item(RandomItem("boatpatch_sludge", "boatrepairkit"), 2),
    Item("boatrepairkit", 2, .5),
    Item(RandomItem("boat_cannon_kit", "boatcannon"), 1, 1, true),
    Item("stash_map"),
    Item("cutlass", .1, 1, true)
})

--cherry forest
UMWebbedCreatureUtil.AddCompatCharacterCocoon("1289779251", "wirlywings", {
    Item("cherrytrinket_1"),
    Item("cherrytrinket_2"),
    Item("cherryscepter", 1, 1, true),
    Item("cherryhat", 1, .75, true),
    Item("cherry_cake", 1, .5, true),
    Item("cherry", 2, nil, true),
    Item("cherry", 3, .75, true),
    Item("cherry_double", 3, .3, true),
    Item("wirlycandy_regen", 2, .75),
    Item("wirlycandy_oblivious", 2, .5),
    Item("wirlycandy_blackhole", 1, .3),
    Item("wirlycandy_goop", 3, .3)
})

--black death
UMWebbedCreatureUtil.AddCompatCharacterCocoon("1947892074", "wade", {
    Item("tiddlestick", 1, 1, true),
    Item("tiddle_detector", 1, 1, true),
    Item("tiddle_sponge", 3),
    Item("tiddle_sponge", 3, .5),
    Item(RandomItem("hat_tiddlevirus", "armor_tiddlesapron"), 1, 1, true),
    Item("tiddlebungus_cap", 1, 1, true),
    Item("tiddlebungus_cap", 2, .5, true),
    Item("tiddlelog", 1, .3),
    Item("spoiled_food", 4, nil),
    Item("spoiled_food", 4, .5)
})

--wonderwhy
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2879092392", "wonderwhy", {
    Item("thulecite_pieces", 6),
    Item("thulecite_pieces", 6, .5),
    Item("nitre", 3),
    Item("nitre", 3, .5),
    Item("boneshard", 4),
    Item("boneshard", 4, .5),
    Item("ancientdreams_gemshard", 3),
    Item("ancientdreams_gemshard", 3, .5),
    Item(RandomItem("moonglass", "moonrocknugget", "goldnugget"), 4),
    Item(RandomItem("why_refined_butterfly_moon", "why_refined_butterfly", "why_refined_lightbulb"), 1, 1, true),
    Item(RandomItem("redgem", "bluegem")),
    Item(RandomItem("orangegem", "purplegem")),
    Item(RandomItem("greengem", "yellowgem"), .5)
})

--wuzzy
UMWebbedCreatureUtil.AddCompatCharacterCocoon("1836542884", "zeta", {
    Item("honey_splash"),
    Item("honey", 8, 1, true),
    Item("honey", 6, .5, true),
    Item("royal_jelly", 1, 1, true),
    Item(RandomItem("royal_jelly", "zetapollen"), 3, 1, true),
    Item("zetapollen", 9, .5), true,
    Item("honeycomb", 2),
    Item("honeycomb", 2, .5),
    Item(RandomItem("armor_honey", "melissa"), 1, 1, true),
    Item(RandomItem("um_beemine_moon_item", "beemine"), .5)
})

--whimsy
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2618885209", "whimsy", {
    Item("purplegem"),
    Item(RandomItem("redgem", "bluegem"), 3, .75),
    Item(RandomItem("yellowgem", "orangegem"), 3, .15),
    Item("marble", 4),
    Item("marble", 4, .5),
    Item("brainrock"),
    Item("brainrock", 2, .5),
    Item("wobster_sheller_land", 1, 1, true),
    Item("purpletool", 1, 1, true)
})

--whiskey
local algae = TUNING.DSTU.ISLAND_ADVENTURES and "seaweed" or "kelp" -- Reminded to copy this idea for every modded character!
local seamaterial = TUNING.DSTU.ISLAND_ADVENTURES and "bamboo" or "driftwood_log"
local boatkit = TUNING.DSTU.ISLAND_ADVENTURES and "boatrepairkit" or "boatpatch_sludge"
local sail = TUNING.DSTU.ISLAND_ADVENTURES and "ironwind" or "mast_malbatross_item"

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3118176896", "whiskey", {
    Item("depthsword", 1, 1, true),
    Item("whiskeyhat", 1, 1, true),
    Item("whiskeysonar", 1, 1, true),
    Item(RandomItem(algae, seamaterial), 6),
    Item(RandomItem("greengem", "orangegem"), 1, .25),
    Item(boatkit, 1, .5, true),
    Item(sail, 1, .5)
})

--swire
-- will have better loot once the skilltree comes out. For now funny gold piñata
UMWebbedCreatureUtil.AddCompatCharacterCocoon("2997213431", "swire", {
    Item("goldnugget", 2, 1),
    Item("goldnugget", 2, .5),
    Item("goldnugget", 2, .5),
    Item("goldnugget", 2, .5),
    Item("goldnugget", 2, .15),
    Item("goldnugget", 2, .15),
    Item("goldnugget", 2, .15),
    Item("swire_weapon", 1, 1, true),
    Item("swire_lipstick", 1, .5, true),
    Item("lgd_hat", 1, .5, true),
    Item("swire_nightvisionhat", 1, .75),
    Item("swire_bottle", 10, 1),
    Item("swire_bottle", 10, .5),
    Item("lungmendollars", 20, .5),
    Item("lungmendollars", 20, .5)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3583633595", "kris_m", {
    Item("um_moss", 4, 1),
    Item("um_moss", 3, .5),
    Item("nightsword", 1, 1, true),
    Item("dragonpie", 1, 1, true),
    Item("reviver", 1, 1),
    Item("featherpencil", 4, 1),
    Item("firepen", 1, 1, true),
    Item("nightcaphat", 1, .5, true),
    Item("bedroll_furry", 1, 1, true),
    Item("um_armor_pyre_nettles", 1, .5, true)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3583633595", "susie_m", {
    Item(RandomItem("playing_card", "papyrus"), 1, 1, true),
    Item(RandomItem("beefalofeed", "beefalotreat", "um_moss"), 2, 1, true),
    Item(RandomItem("goldenaxe", "moonglassaxe", "jawed_scythe", "um_ice_sicle"), 1, 1, true),
    Item("brush", 1, .3, true),
    Item("monstermeat", 3, 1, true),
    Item("ash", 1, 1),
    Item("blueberrypancakes", 1, 1, true),
    Item("tillweedsalve", 1, .5),
    Item("mosquitosack", 5, 1),
    Item("houndstooth", 2, 1),
    Item("houndstooth", 4, .75)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3583633595", "ralsei_m", {
    Item("carnival_vest_a", 1, 1, true),
    Item(RandomItem("ralsei_cake", "ralsei_butterscotch_cake"), 1, 1, true),
    Item("nightmarefuel", 4, 1),
    Item("nightmarefuel", 2, .5),
    Item("silk", 5, 1),
    Item("sunglasses", 1, .5, true),
    Item("healingsalve", 3, 1),
    Item(RandomItem("bandage", "um_rimeweed_icepack"), 3, 1),
    Item(RandomItem("floral_bandage", "brine_balm"), 1, 1),
    Item("floral_bandage", 1, .3),
    Item("lightninggoathorn", 1, .05)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("2978133982", "whispy", {
    Item(RandomItem("vegiepick", "vegieaxe", "vegiebat", "vegie_sword"), 1, 1, true),
    Item(RandomItem("potato_hat", "vegie_amu", "vegie_amu2", "wateringcan"), 1, 1, true),
    Item(RandomItem("seed_forget", "seed_fire", "seed_till"), 8, .75, true),
    Item(RandomItem("yotc_seedpacket", "yotc_seedpacket_rare"), 4, 1),
    Item(RandomItem("yotc_seedpacket", "yotc_seedpacket_rare"), 1, .5),
    Item("vegie_bomb", 3, 1),
    Item("vegie_bomb", 3, .5),
    Item("vegiespray", 1, 1, true),
    Item(RandomItem("carrot", "carrot_soup", "carrot_honey", "carrot_puree", "carrot_cake", "carrot_fry"), 1, 1, true),
    Item("manrabbit_tail", 1, 1),
    Item("hareball", 1, 1, true),
    Item("slipper", 1, .25)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("618785273", "womp", {
    Item(RandomItem("kelphat", "watermelonhat", "icehat"), 1, 1, true),
    Item("monstermeat", 6, 1, true),
    Item("waterballoon", 4, 1),
    Item("cutreeds", 16, 1),
    Item("tentaclespots", 2, 1),
    Item(RandomItem("tentaclespots", "um_tentaclespot_moon"), 1, .2),
    Item("tentaclespike", 2, 1, true),
    Item("tentaclespike", 2, .5, true)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3620352512", "weetie", {
    Item("taffy", 2, 1, true),
    Item("honey", 2, 1, true),
    Item("royal_jelly", 4, 1, true),
    Item("weetie_honeybutter", 4, 1, true),
    Item("honeycomb", 4, 1),
    Item("killerbee", 20, 1, true),
    Item("weetie_royalbee", 10, .1, true)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3221411434", "welina", {
    Item(function()
        return RandomItem("rat_tail", "shroom_skin", "phlegm", "spoiled_fish", "spoiled_fish_small", "wetgoop", "rottenegg", "spoiled_food", "slurper_pelt",
            "yotpfood2", "wintersfeastfuel", "pigskin", "manrabbit_tail", "winter_food4")
    end, 3, 1), --Vomit Inducers List
    Item(function()
        return RandomItem("trinket_22", "welina_cattoy", "balloons_empty", "trinket_24", "trinket_1", "trinket_7", "canary_poisoned", "rabbit", "mole",
            "bearger_fur", "crow", "robin", "puffin", "rat_tail", "robin_winter", "canary", "mandrake", "sewing_kit", "spidereggsack", "pondfish", "pondeel", "slurper_pelt", "papyrus", "furtuft",
            "featherpencil", "feather_crow", "goose_feather", "malbatross_feather", "malbatross_feathered_weave", "feather_robin", "feather_robin_winter", "feather_canary",
            "turf_carpetfloor", "turf_beard_rug", "steelwool", "wetgoop", "rope", "winter_food1", "tallbirdegg", "butterflywings", "lightbulb", "cutgrass", "cutreeds", "beardhair",
            "bird_egg", "twigs", "silk", "foliage", "beefalowool", "acorn", "pinecone", "twiggy_nut")
    end, 3, 1), --Play Sanity List, minus Deerclops Eye, Bernie(s), whiskyyarn, celestial orb, maybe others
    Item("pondfish", 1, 1, true),
    Item(RandomItem("pondfish", "pondeel"), 3, .5, true),
    Item("trinket_22", 1, 1),
    Item("coontail", 3, 1),
    Item("coontail", 3, .5),
    Item("rat_tail", 6, 1),
    Item("welina_catnip", 1, 1),
    Item("snowgoggles", 1, 1)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("2858309592", "whisky", {
    Item(RandomItem("whiskysunhat", "whiskysunglasses", "whiskyribbon"), 1, 1, true),
    Item("whiskyyarn", 3, 1),
    Item("whiskyyarn", 3, .5),
    Item("whiskybundlewrap", 4, .5),
    Item("silk", 6, 1),
    Item("silk", 4, .5),
    Item("spidergland", 4, 1),
    Item("spidergland", 4, .5),
    Item("red_cap", 6, 1, true),
    Item(function()
        return RandomItem("spider", "spider_dropper", "spider_healer", "spider_hider", "spider_moon", "spider_spitter", "spider_trapdoor", "spider_trapdoor_hooded",
            "spider_warrior", "spider_water")
    end, 2, 1)
})

UMWebbedCreatureUtil.AddCompatCharacterCocoon("3021568491", "wildcard", {
    Item("nightmarefuel", 2, 1),
    Item("nightmarefuel", 14, .5),
    Item("rabbit", 4, 1, true),
    Item("manrabbit_tail", 4, 1),
    Item("wcard_throwingcard", 4, 1),
    Item("wcard_throwingcard", 4, .5),
    Item("papyrus", 1, 1),
    Item("tophat", 1, 1, true),
    Item(RandomItem("feather_crow", "feather_robin", "feather_robin_winter", "feather_canary", "goose_feather", "malbatross_feather"), 6, 1)
})

--[[UMWebbedCreatureUtil.AddCompatCharacterCocoon("3385306425", "warrick", {
    Item("feather_canary", 1, 1),
    Item("silk", 5, 1),
    Item("horn", 1, 1)
})

-- Wandering Done -- Is crashing for some reason, sooo gonna have to keep this out
UMWebbedCreatureUtil.AddCompatCharacterCocoon("3385306425", "tvheadguy", {
    Item("cctrinket_freddo", 1, 1)
})]]

--[[UMWebbedCreatureUtil.AddCompatCharacterCocoon("???", "warne", {
    Item(RandomItem("warnebone_generic", "warnebone_arm", "warnebone_leg", "warnebone_ribcage", "warnebone_skull"), 4, 1, true),
    Item("boneshard", 6, 1),
    Item("boneshard", 6, .5),
    Item("purplegem", 1, 1),
    Item("purplegem", 1, .5),
    Item("nightmarefuel", 8, 1),
    Item("nightmarefuel", 6, .5)
})]]