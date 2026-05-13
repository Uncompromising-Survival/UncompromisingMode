---@param item string|function The loot item prefab, or a function that returns a prefab.
---@param count? number The number of items to spawn
---@param chance? number The chance to spawn the item
---@param use_durability? boolean Whether to set the durability of the item, if any durability-esque component is present
---@param lootfn? function A function that gets called when the item is dropped, with the spawned item prefab as an argument.
---@return table loot_table
local function Item(item, count, chance, use_durability, lootfn)
    return {
        prefab = item,
        amount = count or 1,
        chance = chance or 1,
        use_durability = use_durability or false,
        lootfn = lootfn
    }
end

---@param ... string number of item prefabs - NOT A TABLE! var-arg!
---@return string item random item from the list of items.
local function RandomItem(...)
    return arg[math.random(#arg)]
end

COCOON_SIZE = {
    SMALL = 0,
    MEDIUM = 1,
    LARGE = 2
}

--automatically populated by metatable.
COCOON_CREATURES_DEFAULT = {}
COCOON_CREATURES_SHIPWRECKED = {}
COCOON_CHARACTERS = {}


COCOON_DEFS = {}
COCOON_DEFS.CHARACTER = {}
COCOON_DEFS.DEFAULT = {}
COCOON_DEFS.SHIPWRECKED = {}

setmetatable(COCOON_DEFS.CHARACTER, {
    __newindex = function(t, k, v)
        printwrap("t", t)
        print(k)
        printwrap("v", v)
        table.insert(COCOON_CHARACTERS, k)

        v.size = 1          --automatically set size
        v.name = "Shrouded" --and name for character cocoons.

        rawset(t, k, v)
    end
})

setmetatable(COCOON_DEFS.DEFAULT, {
    __newindex = function(t, k, v)
        table.insert(COCOON_CREATURES_DEFAULT, k)
        rawset(t, k, v)
    end
})

setmetatable(COCOON_DEFS.SHIPWRECKED, {
    __newindex = function(t, k, v)
        table.insert(COCOON_CREATURES_SHIPWRECKED, k)
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
            Item(function() return RandomItem("bluegem", "redgem", "purplegem") end, 2) }
    },
    WILLOW = {
        loot = {
            Item("firestaff"),
            Item("sludge_oil"),
            Item("lighter", 1, 1, true),
            Item(function() return RandomItem("snapalm", "slurtleslime") end, 4, .5), }
    },
    WOLFGANG = {
        loot = {
            Item("armormarble", 1, 1, true),
            Item("marble", 6),
            Item("pigskin"),
            Item("potato_cooked", 3, 1, true),
            Item("potato_cooked", 3, .3, true),
            Item("armorslurper", 1, .2, true),
            Item("bonestew", 1, .3, true) }
    },
    WENDY = {
        loot = {
            Item("ghostflowerhat", 1, 1, true),
            Item("moon_tree_blosson", 6, .5, true),
            Item("petals_evil", 4, 1, true),
            Item(function() return RandomItem("ghostlyelixir_fastregen", "ghostlyelixir_slowregen") end, 2),
            Item(function() return RandomItem("ghostlyelixir_retaliation", "ghostlyelixir_shield") end, 2, .5),
            Item(function() return RandomItem("ghostlyelixir_attack", "ghostlyelixir_speed") end, 2, .5),
            Item("ghostlyelixir_revive", 2, .5),
            Item(function() return RandomItem("halloweenpotion_sanity_large", "halloweenpotion_sanity_small") end, 2),
            Item(function() return RandomItem("halloweenpotion_health_large", "halloweenpotion_health_small") end, 2),
            Item("butterfly", 4, .5), }
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
            Item(function() return TheWorld.state.isspring and RandomItem("raincoat", "rainhat") or nil end, 1, .1, true), }
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
            end) }
    },
    WOODIE = {
        loot = {
            Item("walking_stick", 1, 1, true),
            Item("boards", 10, .5),
            Item("log", 10),
            Item("log", 20, .75),
            Item(function() return RandomItem("wereitem_beaver", "wereitem_moose", "wereitem_goose") end, 1, 1, true), }
    },
    WAXWELL = {
        loot = {
            Item("nightmarefuel", 4),
            Item("nightmarefuel", 6, .5),
            Item("tophat", 1, 1, true),
            Item("rabbit"),
            Item("purpleamulet", 1, .2),
            Item(function() return RandomItem("nightsword", "armor_sanity") end, 1, 1, true), }
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
            Item("spear_wathgrithr", 1, .5, true), }
    },
    WEBBER = {
        loot = {
            Item("silk", 6),
            Item("silk", 2, .5),
            Item("spidereggsack"),
            Item("healingsalve", 3),
            Item("healingsalve", 3, .5),
            Item(function() return RandomItem("monstermeat", "monstersmallmeat") end, 6, .5, true),
            Item("sewing_kit") }
    },
    WINONA = {
        loot = {
            Item("sewing_tape", 2),
            Item("sewing_tape", 2, .5),
            Item("nitre", 4),
            Item("niter", 4, .5),
            Item("rocks", 6),
            Item("rocks", 8, .8),
            Item("wagpunk_bits", 4, .5),
            Item("powercell", 2, .5),
            Item(function() return RandomItem("nightstick", "bugzapper") end, 1, .1, true), }
    },
    WARLY = {
        loot = {
            Item("yotc_seedpacket_rare", 3),
            Item("saltrock"),
            Item("saltrock", 5, .5),
            Item(function() return RandomItem("pepper", "garlic") end, 3, 1, true),
            Item(function() return RandomItem("pepper", "garlic") end, 3, .5, true),
            Item("voltgoatjelly", 1, .1, true),
            Item(function() return RandomItem("glowberrymousse_spice_sugar", "nightmarepie", "potatosouffle_spice_chili") end, 1, .3, true),
            Item(function() return RandomItem("moqueca_spice_salt", "bonesoup_spice_garlic", "freshfruitcrepes") end, 1, .3, true),
            Item(function() return RandomItem("theatercorn_spice_salt", "beefalowings_spice_garlic", "stuffed_peeper_poppers") end, 1, .3, true),
            Item(function() return RandomItem("zaspberryparfait_spice_sugar", "snotroast_spice_chili", "viperjam_spice_sugar") end, 1, .3, true),
            Item(function() return RandomItem("um_rimeweed_spagett", "um_rimeweed_tequila") end, 1, .3, true), }

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
            Item("krampus_sack", 1, .01), }
    },
    WORMWOOD = {
        loot = {
            Item("yotc_seedpacket_rare", 5),
            Item("livinglog", 2),
            Item("livinglog", 4, .5),
            Item(function() return RandomItem("compostwrap", "tillweedsalve") end, 4, 1, true),
            Item(function() return RandomItem("gloomcap", "moon_cap") end, 6, .5, true),
            Item(function() return TheWorld.state.issummer and "cactus_flower" or "dragonfruit" end, 4, .5, true),
            Item("cactus_meat", 2),
            Item("cactus_meat", 4, .5),
            Item("lightflier", 6, .3),
            Item(function() return TheWorld.state.iswinter and "um_armor_bramble_rimeweed" or "armor_bramble" end, 1, .5, true),
            Item("trap_bramble", 3, .5),
            Item("lureplantbulb", 1, .2), }
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
            Item("mermhat", 1, .2, true), }
    },
    WALTER = {
        loot = {
            Item(function() return RandomItem("fishmeat_small_dried", "smallmeat_dried") end, 4, 1, true),
            Item(function() return RandomItem("monstermeat_dried", "monstersmallmeat_dried") end, 5, .5, true),
            Item("kelp_dried", 4),
            Item("kelp_dried", 2, .5),
            Item(function() return RandomItem("healingsalve", "bandage_butterflywings") end, 5, .5, true),
            Item(function() return RandomItem("floral_bandage", "bandage") end, 2, .5, true),
            Item("brine_balm", 2, .2),
            Item(function() return RandomItem("portabletent_item", "bedroll_furry") end, 1, .3, true),
            Item(function() return RandomItem("meatrack_hat", "walterhat", "bushhat") end, 1, .5, true),
            Item("um_record_walter", 1, .05), }
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
            Item("oldager_become_younger_front_fx", 1, .5), }
    },
    WINKY = {
        loot = {
            Item("trinket_20", 1),
            Item("spoiled_food", 6),
            Item("spoiled_food", 12, .5),
            Item("rat_tail", 2),
            Item("rat_tail", 4, .5),
            Item("monstersmallmeat", 8, .5),
            Item(function() return RandomItem("trinket_1", "trinket_2") end, 1, .15),
            Item(function() return RandomItem("trinket_3", "trinket_4") end, 1, .15),
            Item(function() return RandomItem("trinket_5", "trinket_6") end, 1, .15),
            Item(function() return RandomItem("trinket_7", "trinket_8") end, 1, .15),
            Item(function() return RandomItem("trinket_9", "trinket_10") end, 1, .15),
            Item(function() return RandomItem("trinket_11", "trinket_12") end, 1, .15),
            Item(function() return RandomItem("trinket_13", "trinket_14") end, 1, .15),
            Item(function() return RandomItem("trinket_17", "trinket_18") end, 1, .15),
            Item(function() return RandomItem("trinket_19", "trinket_21") end, 1, .15),
            Item(function() return RandomItem("trinket_22", "trinket_23") end, 1, .15),
            Item(function() return RandomItem("trinket_24", "trinket_25") end, 1, .15),
            Item(function() return RandomItem("trinket_26", "trinket_27") end, 1, .2),
            Item(function() return RandomItem("cctrinket_don", "cctrinket_freddo") end, 1, .2),
            Item(function() return RandomItem("cctrinket_names", "trinket_jazzy") end, 1, .2),
            Item("corncan", 1, .2),
            Item("um_record_winky", 1, .05), }
    },
    WATHOM = {
        loot = {
            Item("purplegem", 1),
            Item("meat", 2, 1, true),
            Item("meat", 4, .5, true),
            Item("nightmarefuel", 4),
            Item("nightmarefuel", 8, .5),
            Item(function() return RandomItem("ancient_amulet_red", "amulet") end, 1, .5, true),
            Item(function() return RandomItem("ruins_bat", "hambat") end, 1, .5, true),
            Item("thulecite", 1),
            Item("thulecite", 5, .3),
            Item("um_record_wathom", 1, .05), }
    },
    WIXIE = {
        loot = {
            Item("bagofmarbles", 1),
            Item("bagofmarbles", 3, .5),
            Item(function() return RandomItem("um_blowdart_pyre", "um_blowdart_rime") end, 3, .5),
            Item(function() return RandomItem("slingshotammo_honey", "slingshotammo_goop") end, 20, .75),
            Item("nitre", 3),
            Item("nitre", 5, .5),
            Item("mosquitosack", 2),
            Item("mosquitosack", 4, .5),
            Item(function() return RandomItem("livinglog", "driftwood_log") end, 2, .5),
            Item(function() return RandomItem("sludge", "saltrock") end, 4, .5),
            Item(function() return RandomItem("moonrocknugget", "moonglass") end, 6),
            Item("townportaltalisman", 3, .1),
            Item("um_record_wixie", 1, .05), }

    },
    WES = {
        loot = {
            Item("balloonparty_confetti_cloud", 5),
            Item("balloonspeed", 10, .5),
            Item("balloon", 1, .01),
            Item("freshfruitcrepes", 1),
            Item("balloonhat", 1),
            Item("balloonvest", 1),
            Item("waterballoon", 10, .3), }
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
            Item("goggleshat", 1, 1, true), }
    },
}


local default = {
    BEEGUARD = {
        size = COCOON_SIZE.SMALL,
        name = "Buggy",
        loot = {
            Item("honeycomb", 2),
            Item("honey", 5),
            Item("honey", 1, .5),
            Item("stinger", 1, .1),
            Item("royal_jelly", 1),
        }
    },
    PIED_RAT = {
        size = COCOON_SIZE.MEDIUM,
        name = "Grotesque",
        loot = {
            Item("monstermeat", 2),
            Item("monstermeat", 1, .5),
            Item("rat_tail", 2),
        }
    },
    EYEOFTERROR_MINI = {
        size = COCOON_SIZE.SMALL,
        name = "Grotesque",
        loot = {
            Item("milkywhites", 2),
            Item("monstermeat", 1),
            Item("monstermeat", 1, .5),
        }
    },
    CATCOON = {
        size = COCOON_SIZE.SMALL,
        name = "Hairy",
        loot = {
            Item("meat", 1, .5),
            Item("coontail", 4)
        }
    },
    ALPHA_LIGHTNINGGOAT = {
        size = COCOON_SIZE.SMALL,
        name = "Hairy",
        loot = {
            Item("meat", 1, .5),
            Item("lightninggoathorn")
        }
    },
    -- BISHOP = {
        -- size = COCOON_SIZE.SMALL,
        -- name = "Hardened",
        -- loot = {
            -- Item("trinket_6", 2),
        -- }
    -- },
    MERM = {
        size = COCOON_SIZE.SMALL,
        name = "Scaly",
        loot = {
            Item("fishmeat", 1, .5),
            Item("tentaclespots", 2),
        }
    },
    PIGMAN = {
        size = COCOON_SIZE.SMALL,
        name = "Leathery",
        loot = {
            Item("meat"),
            Item("pigskin"),
            Item("tophat"),
            Item("pig_token", 1, .1),
        }
    },
    MOSSLING = {
        size = COCOON_SIZE.MEDIUM,
        name = "Feathery"
    },
    TALLBIRD = {
        size = COCOON_SIZE.MEDIUM,
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
    DEER = {
        size = COCOON_SIZE.MEDIUM,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("meat", 1, .5),
            Item("deer_antler"),
            Item("redgem"),
            Item("bluegem"),
        }
    },
    KRAMPUS = {
        size = COCOON_SIZE.MEDIUM,
        name = "Grotesque",
        loot = {
            Item("monstermeat", 1, .5),
            Item("charcoal", 2),
            Item("boneshard"),
            Item("krampus_sack", 1, .05),
            Item("bluegem"),
            Item("redgem"),
        }
    },
    OTTER = {
        size = COCOON_SIZE.MEDIUM,
        name = "Scaly", -- this doesn't make sense but whatever
        loot = {
            Item("smallmeat"),
            Item("kelp", 2),
            Item("kelp", 2, .75),
            Item("kelp", 1, .5),
            Item("barnacle", 1, .5),
            Item("barnacle", 1, .25),
            Item("messagebottle"),
            Item("bullkelp_root"),
            Item("oceanfish_small_4_inv", 1, .75),
            Item("oceanfish_medium_1_inv", 1, .2),
            Item("oceanfish_small_3_inv", 1, .1),
            Item(function()
                return TheWorld.state.isautumn and "oceanfish_small_6_inv" or
                    TheWorld.state.iswinter and "oceanfish_medium_8_inv" or
                    TheWorld.state.isspring and "oceanfish_small_7_inv" or
                    TheWorld.state.issummer and "oceanfish_small_8_inv" or
                    "wobster_sheller_land"
            end, 1, 1)
        }
    },
    WALRUS = {
        size = COCOON_SIZE.MEDIUM,
        name = "Leathery",
        loot = {
            Item("meat", 1, .5),
            Item("um_bear_trap_equippable_tooth", 1, .5),
            Item("walrus_tusk"),
        }
    },
    LORDFRUITFLY = {
        size = COCOON_SIZE.LARGE,
        name = "Buggy",
        loot = {
            Item("plantmeat", 1, .5),
            Item("seeds", 4),
            Item("seeds", 4, .25)
        }
    },
    SPIDERQUEEN = {
        size = COCOON_SIZE.LARGE,
        name = "Buggy",
        loot = {
            Item("monstermeat"),
            Item("monstermeat", 1, .5),
            Item("silk"),
            Item("silk", 1, .5),
        }
    },
    BEEFALO = {
        size = COCOON_SIZE.LARGE,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("meat", 1, .5),
            Item("beefalowool", 1, .5),
            Item("beefalowool", 1, .25),
            Item("horn"),
            Item("poop", 1, .5)
        }
    },
    WARG = {
        size = COCOON_SIZE.LARGE,
        name = "Hairy",
        loot = {
            Item("monstermeat"),
            Item("houndstooth", 2),
            Item("houndstooth", 1, .5),
            Item("boneshard"),
            Item("boneshard", 1, .5),
            Item("bluegem"),
            Item("redgem"),
        }
    },
    ROOK = {
        size = COCOON_SIZE.LARGE,
        name = "Hardened",
        loot = {
            Item("gears", 2),
            Item("gears", 1, .5),
            Item("transistor", 2),
            Item("trinket_6", 2),
            Item("trinket_6", 1, .5),
            Item("trinket_1", 1),
        }
    },
    KOALEFANT_SUMMER = {
        size = COCOON_SIZE.LARGE,
        name = "Leathery",
        loot = {
            Item("meat", 3),
            Item("meat", 1, .5),
            Item("poop", 1, .5)
        }
    },
    SHARK = { --I don't like this one i'm ngl. - Atobá
        size = COCOON_SIZE.LARGE,
        name = "Leathery",
        loot = {
            Item("fishmeat", 1, .5),
            Item("barnacle", 3),
            Item("rocks", 3),
            Item("nitre", 2),
            Item("nitre", 2, .5),
        }
    },
    GRASSGATOR = {
        size = COCOON_SIZE.LARGE,
        name = "Leafy",
        loot = {
            Item("plantmeat", 1, .5),
            Item("cutgrass", 4),
            Item("twigs", 4),
            Item("cactus_flower", 3),
            Item("cactus_flower", 3, .5),
        }
    },
    LEIF_SPARSE = {
        size = COCOON_SIZE.LARGE,
        name = "Leafy",
        loot = {
            Item("plantmeat", 1),
            Item("livinglog", 2, .5),
            Item("log", 10, .75),
            Item("log", 10),
        }
    }
}


--todo:
--snake monster morsel

--[[

    palm treeguard
    doydoy
]]
local sw = {
    SHARKITTEN = {
        size = COCOON_SIZE.MEDIUM,
        name = "Leathery",
        loot = {
            Item("shark_gills"),
            Item("shark_gills", 1, .5),
            Item("mysterymeat", 1, 1, true),
            Item("fishmeat", 4, .5, true)
        }
    },
    MERMFISHER = {
        size = COCOON_SIZE.SMALL,
        name = "Scaly",
        loot = {
            Item(function() return RandomItem("pondpurple_grouper", "pondneon_quattro", "pondpierrot_fish") end),
            Item("blowdart_flup")
        }
    },
    PRIMEAPE = {
        size = COCOON_SIZE.SMALL,
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
        size = COCOON_SIZE.LARGE,
        name = "Hairy",
        loot = {
            Item("meat"),
            Item("meat", 1, .5),
            Item("ox_horn"),
            Item("poop", 2),
            Item("poop", 4, .25),
        }
    },
    CROCODOG = {
        size = COCOON_SIZE.MEDIUM,
        name = "Scaly",
        loot = {
            Item("houndstooth"),
            Item("venomgland", 1, .5)
        }
    },
    WILDBORE = {
        size = COCOON_SIZE.MEDIUM,
        name = "Leathery",
        loot = {
            Item("meat"),
            Item("pigskin"),
            Item(function() return RandomItem("tophat", "gashat", "piratehat", "snakeskinhat", "shark_teethhat") end),
        }
    },
    STUNGRAY = {
        size = COCOON_SIZE.SMALL,
        name = "Leathery",
        loot = {
            Item("monstermeat"),
            Item("venomgland"),
            Item("venongland", 1, .5)
        }
    },
    DOYDOY = {
        size = COCOON_SIZE.MEDIUM,
        name = "Feathery",
        loot = {
            Item("doydoyegg")
        }
    },
    LEIF_PALM = {
        size = COCOON_SIZE.LARGE,
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
        size = COCOON_SIZE.MEDIUM,
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
    SPIDERQUEEN = default.SPIDERQUEEN,

}

--poopulate globals.
for k, v in pairs(characters) do
    COCOON_DEFS.CHARACTER[k] = v
end

for k, v in pairs(default) do
    COCOON_DEFS.DEFAULT[k] = v
end

for k, v in pairs(sw) do
    COCOON_DEFS.SHIPWRECKED[k] = v
end

---@param modid string The mod id of the character's mod. You can see the modid in the end of the link of the workshop page.
---@param character string The character's prefab name.
---@param loot_pool table The loot pool for the character. See above and below for examples.
function AddCompatCharacterCocoon(modid, character, loot_pool)
    if KnownModIndex:IsModEnabled("workshop-" .. modid) then
        COCOON_DEFS.CHARACTER[string.upper(character)] = { loot = loot_pool }
    end
end

AddCompatCharacterCocoon("3484995444", "wieneke", {
    Item("koalefant_carcass", 1, 1, nil, function(inst)
        if not inst.SetMeatPct then return end
        inst:SetMeatPct(.25) -- Not sure if 25% is the right amount to have the second-to-last decay stage, might need to fiddle to get it right!
    end),
    Item("glommerfuel", 2),
    Item("glommerfuel", 2, .5),
    Item("trinket_9"),
    Item("snotroast", 1, 1, true),
    Item("halloweencandy_8")
})

AddCompatCharacterCocoon("2496686961", "flaire", {
    Item("nightsword"),
    Item("familiarsword", 1, 1, true),
    Item("pureaspectgem"),
    Item("pureaspectgem", 2, .5),
    Item("bluegem"),
    Item("redgem"),
    Item("goldnugget", 2),
    Item("goldnugget", 4, .5),
    Item("spellprint", 1, 1, false, function(inst)
        if not inst.TryRevealSpell then return end
        local flaire = FindClosestEntity(inst, 40, true, { "flaire" })
        if flaire then
            inst:TryRevealSpell(flaire)
        else
            inst:Remove()
        end
    end)
})


--reign of runts
AddCompatCharacterCocoon("2010472942", "weerclops", {
    Item("ice", 12),
    Item("ice", 12, .5),
    Item("snowball_item", 4, 1, true),
    Item("snowball_item", 8, .5, true),
    Item("um_rimeweed_itemvine", 3),
    Item("um_rimeweed_itemvine", 3, .5),
    Item("um_rimeweed_itemflower", 1, .5),
    Item("um_rimeweed_icepack"),
    Item("um_rimeweed_icepack", 2, .5),
    Item(function() return RandomItem("um_hat_rime", "rimeweed_whip") end, 1, .5),
    Item(function() return RandomItem("beakbasher", "hammer") end, 1, .5)
})
AddCompatCharacterCocoon("2010472942", "woose", {
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
AddCompatCharacterCocoon("2010472942", "wearger", {
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
AddCompatCharacterCocoon("2010472942", "wragonfly", {
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
AddCompatCharacterCocoon("3435352667", "wilbur", {
    Item("dug_monkeytail", 2),
    Item("dug_monkeytail", 2, .5),
    Item("dug_bananabush", .1, 2),
    Item("cave_banana", 3, 1, true),
    Item("cave_banana", 5, .5, true),
    Item(function() return RandomItem("frozenbananadaiquiri", "bananapop") end, 1, 1, true),
    Item("monkeyball", 1, 1, true),
    Item(function() return RandomItem("monkey_smallhat", "oar_monkey") end, 1, 1, true),
    Item("poop", .5, 6),
    Item("blackflag", 1, 1, true),
    Item(function() return RandomItem("cutlass", "cutless") end, 1, .9, true)
})
AddCompatCharacterCocoon("3435352667", "walani", {
    Item("seashell", 4),
    Item("seashell", 4, .5),
    Item("boards", 2),
    Item("sunglasses", 1, 1, true),
    Item(function() return RandomItem("bananajuice", "vegstinger") end, 1, 1, true),
    Item("palmleaf", 2),
    Item("palmleaf", 4, .5),
    Item("coconut", 3, 1, true),
    Item("coconut", 5, .5, true),
    Item("coconade", .3, 2),
    Item(function() return RandomItem("cutlass", "spear_launcher") end, 1, .9, true)
})
AddCompatCharacterCocoon("3435352667", "woodlegs", {
    Item("woodlegshat", 1, 1, true),
    Item(function() return RandomItem("supertelescope", "telescope") end, 1, 1, true),
    Item("dubloon", 10),
    Item("dubloon", 20, .5),
    Item("boneshard", 6),
    Item(function() return RandomItem("boatpatch_sludge", "boatrepairkit") end, 2),
    Item("boatrepairkit", 2, .5),
    Item(function() return RandomItem("boat_cannon_kit", "boatcannon") end, 1, 1, true),
    Item("stash_map"),
    Item("cutlass", .1, 1, true)
})

--cherry forest
AddCompatCharacterCocoon("1289779251", "wirlywings", {
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
AddCompatCharacterCocoon("1947892074", "wade", {
    Item("tiddlestick", 1, 1, true),
    Item("tiddle_detector", 1, 1, true),
    Item("tiddle_sponge", 3),
    Item("tiddle_sponge", 3, .5),
    Item(function() return RandomItem("hat_tiddlevirus", "armor_tiddlesapron") end, 1, 1, true),
    Item("tiddlebungus_cap", 1, 1, true),
    Item("tiddlebungus_cap", 2, .5, true),
    Item("tiddlelog", 1, .3),
    Item("spoiled_food", 4, nil),
    Item("spoiled_food", 4, .5)
})

--wonderwhy
AddCompatCharacterCocoon("2879092392", "wonderwhy", {
    Item("thulecite_pieces", 6),
    Item("thulecite_pieces", 6, .5),
    Item("nitre", 3),
    Item("nitre", 3, .5),
    Item("boneshard", 4),
    Item("boneshard", 4, .5),
    Item("ancientdreams_gemshard", 3),
    Item("ancientdreams_gemshard", 3, .5),
    Item(function() return RandomItem("moonglass", "moonrocknugget", "goldnugget") end, 4),
    Item(function() return RandomItem("why_refined_butterfly_moon", "why_refined_butterfly", "why_refined_lightbulb") end, 1, 1, true),
    Item(function() return RandomItem("redgem", "bluegem") end),
    Item(function() return RandomItem("orangegem", "purplegem") end),
    Item(function() return RandomItem("greengem", "yellowgem") end, .5)
})

--wuzzy
AddCompatCharacterCocoon("1836542884", "zeta", {
    Item("honey_splash"),
    Item("honey", 8, 1, true),
    Item("honey", 6, .5, true),
    Item("royal_jelly", 1, 1, true),
    Item(function() return RandomItem("royal_jelly", "zetapollen") end, 3, 1, true),
    Item("zetapollen", 9, .5), true,
    Item("honeycomb", 2),
    Item("honeycomb", 2, .5),
    Item(function() return RandomItem("armor_honey", "melissa") end, 1, 1, true),
    Item(function() return RandomItem("um_beemine_moon_item", "beemine") end, .5)
})

--whimsy
AddCompatCharacterCocoon("2618885209", "whimsy", {
    Item("purplegem"),
    Item(function() return RandomItem("redgem", "bluegem") end, 3, .75),
    Item(function() return RandomItem("yellowgem", "orangegem") end, 3, .15),
    Item("marble", 4),
    Item("marble", 4, .5),
    Item("brainrock"),
    Item("brainrock", 2, .5),
    Item("wobster_sheller_land", 1, 1, true),
    Item("purpletool", 1, 1, true)
})

--whiskey
local algae = TUNING.DSTU.ISLAND_ADVENTURES and "seaweed" or "kelp"
local seamaterial = TUNING.DSTU.ISLAND_ADVENTURES and "bamboo" or "driftwood_log"
local boatkit = TUNING.DSTU.ISLAND_ADVENTURES and "boatrepairkit" or "boatpatch_sludge"
local sail = TUNING.DSTU.ISLAND_ADVENTURES and "ironwind" or "mast_malbatross_item"

AddCompatCharacterCocoon("3118176896", "whiskey", {
    Item("depthsword", 1, 1, true),
    Item("whiskeyhat", 1, 1, true),
    Item("whiskeysonar", 1, 1, true),
    Item(function() return RandomItem(algae, seamaterial) end, 6),
    Item(function() return RandomItem("greengem", "orangegem") end, 1, .25),
    Item(boatkit, 1, .5, true),
    Item(sail, 1, .5),
})

--swire
-- will have better loot once the skilltree comes out. For now funny gold piñata
AddCompatCharacterCocoon("2997213431", "swire", {
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
})

AddCompatCharacterCocoon("3583633595", "kris_m", {
    Item("um_moss", 4, 1),
    Item("um_moss", 3, .5),
    Item("nightsword", 1, 1, true),
    Item("dragonpie", 1, 1, true),
    Item("reviver", 1, 1),
    Item("featherpencil", 4, 1),
    Item("firepen", 1, 1, true),
    Item("nightcaphat", 1, .5, true),
    Item("bedroll_furry", 1, 1, true),
    Item("um_armor_pyre_nettles", 1, .5, true),
})

AddCompatCharacterCocoon("3583633595", "susie_m", {
    Item(function() return RandomItem("playing_card", "papyrus") end, 1, 1, true),
    Item(function() return RandomItem("beefalofeed", "beefalotreat", "um_moss") end, 2, 1, true),
    Item(function() return RandomItem("goldenaxe", "moonglassaxe", "jawed_scythe", "um_ice_sicle") end, 1, 1, true),
    Item("brush", 1, .3, true),
    Item("monstermeat", 3, 1, true),
    Item("ash", 1, 1),
    Item("blueberrypancakes", 1, 1, true),
    Item("tillweedsalve", 1, .5),
    Item("mosquitosack", 5, 1),
    Item("houndstooth", 2, 1),
    Item("houndstooth", 4, .75),
})

AddCompatCharacterCocoon("3583633595", "ralsei_m", {
    Item("carnival_vest_a", 1, 1, true),
    Item(function() return RandomItem("ralsei_cake", "ralsei_butterscotch_cake") end, 1, 1, true),
    Item("nightmarefuel", 4, 1),
    Item("nightmarefuel", 2, .5),
    Item("silk", 5, 1),
    Item("sunglasses", 1, .5, true),
    Item("healingsalve", 3, 1),
    Item(function() return RandomItem("bandage", "um_rimeweed_icepack") end, 3, 1),
    Item(function() return RandomItem("floral_bandage", "brine_balm") end, 1, 1),
    Item("floral_bandage", 1, .3),
    Item("lightninggoathorn", 1, .05),
})

AddCompatCharacterCocoon("2978133982", "whispy", {
    Item(function() return RandomItem("vegiepick", "vegieaxe", "vegiebat", "vegie_sword") end, 1, 1, true),
    Item(function() return RandomItem("potato_hat", "vegie_amu", "vegie_amu2", "wateringcan") end, 1, 1, true),
    Item(function() return RandomItem("seed_forget", "seed_fire", "seed_till") end, 8, .75, true),
    Item(function() return RandomItem("yotc_seedpacket", "yotc_seedpacket_rare") end, 4, 1),
    Item(function() return RandomItem("yotc_seedpacket", "yotc_seedpacket_rare") end, 1, .5),
    Item("vegie_bomb", 3, 1),
    Item("vegie_bomb", 3, .5),
    Item("vegiespray", 1, 1, true),
    Item(function() return RandomItem("carrot", "carrot_soup", "carrot_honey", "carrot_puree", "carrot_cake", "carrot_fry") end, 1, 1, true),
    Item("manrabbit_tail", 1, 1),
    Item("hareball", 1, 1, true),
    Item("slipper", 1, .25),
})

return COCOON_DEFS
