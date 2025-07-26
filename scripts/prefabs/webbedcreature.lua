local function AddChanceLoot(inst, prefab, chance, amount)
    for i = 1, (amount or 1) do
        inst.components.lootdropper:AddChanceLoot(prefab, chance or 1)
    end
end

local function AddDurabilityLoot(inst, prefab, chance, amount)
    local chance = chance or 1
    for i = 1, (amount or 1) do
        if chance >= 1 or math.random() < chance then
            local item = inst.components.lootdropper:SpawnLootPrefab(prefab, inst:GetPosition())
            local itemcomponent = item.components.finiteuses or item.components.fueled or item.components.perishable or item.components.armor
            if itemcomponent then
                itemcomponent:SetPercent(math.random(25, 100) / 100)
            else
                print(prefab.." has no durability-esque component in webbedcreature.lua!")
            end
        end
    end
end

local function AddLootOnDropFn(inst, prefab, onDropFn)
    -- When this loot prefab is dropped, onDropFn is called! -- Thanks Summerrr :) -Carlos
    -- I love you, Summerrr! You're the best, and I wouldn't be here without you! -Max
    if onDropFn then onDropFn(inst.components.lootdropper:SpawnLootPrefab(prefab, inst:GetPosition()), inst) end
end

local char_cocoon_list = {
    "wilson",
    "willow",
    "wolfgang",
    "wendy",
    "wx78",
    "wickerbottom",
    "woodie",
    "waxwell",
    "wathgrithr",
    "webber",
    "winona",
    "warly",
    "wortox",
    "wormwood",
    "wurt",
    "walter",
    "wanda",
    --"wonkey", --Wilbur stole your loot idk what to do with you. :^) -Carlos
    "winky",
    "wathom",
    "wixie",
    "wes",
}

--[[if GetModConfigData("funny rat") then
    table.insert(char_cocoon_list, "winky")
end
if GetModConfigData("holy fucking shit it's wathom") then
    table.insert(char_cocoon_list, "wathom")
end
if GetModConfigData("wixie_walter") then
    table.insert(char_cocoon_list, "wixie")
end]]
if KnownModIndex:IsModEnabled("workshop-3484995444") then
    table.insert(char_cocoon_list, "wieneke")
end
if KnownModIndex:IsModEnabled("workshop-2496686961") then
    table.insert(char_cocoon_list, "flaire")
end
if KnownModIndex:IsModEnabled("workshop-2010472942") then
    table.insert(char_cocoon_list, "weerclops")
    table.insert(char_cocoon_list, "woose")
    table.insert(char_cocoon_list, "wragonfly")
    table.insert(char_cocoon_list, "wearger")
end
if KnownModIndex:IsModEnabled("workshop-3435352667") then
    table.insert(char_cocoon_list, "wilbur")
    table.insert(char_cocoon_list, "walani")
    table.insert(char_cocoon_list, "woodlegs")
    --table.insert(char_cocoon_list, "wilba")
    --table.insert(char_cocoon_list, "wheeler")
    --table.insert(char_cocoon_list, "wagstaff")
end
if KnownModIndex:IsModEnabled("workshop-1289779251") then
    table.insert(char_cocoon_list, "wirlywings")
end
if KnownModIndex:IsModEnabled("workshop-1982562290") then
    table.insert(char_cocoon_list, "wade")
end
if KnownModIndex:IsModEnabled("workshop-2879092392") then
    table.insert(char_cocoon_list, "wonderwhy")
end
if KnownModIndex:IsModEnabled("workshop-1836542884") then
    table.insert(char_cocoon_list, "zeta") --wuzzy the buzzy
end
if KnownModIndex:IsModEnabled("workshop-2618885209") then
    table.insert(char_cocoon_list, "whimsy")
end

local function SurvivorCocoon(inst)
    local random_char_cocoon = char_cocoon_list[math.random(#char_cocoon_list)]
    if random_char_cocoon == "wilson" then
        AddChanceLoot(inst, "blueprint", nil, 3)
        AddChanceLoot(inst, "blueprint", .5, 2)
        AddChanceLoot(inst, "beardhair", nil, 4)
        AddChanceLoot(inst, "beardhair", .5, 2)
        AddChanceLoot(inst, math.random() > .5 and "bluegem" or math.random() > .5 and "redgem" or "purplegem", nil, 2)
    elseif random_char_cocoon == "willow" then
        AddDurabilityLoot(inst, "firestaff")
        AddDurabilityLoot(inst, "sludge_oil")
        AddDurabilityLoot(inst, "lighter")
        AddChanceLoot(inst, "snapalm", .5, 4)
        AddChanceLoot(inst, "slurtleslime", .5, 4)
    elseif random_char_cocoon == "wolfgang" then
        AddDurabilityLoot(inst, "armormarble")
        AddChanceLoot(inst, "marble", nil, 6)
        AddChanceLoot(inst, "marble", .5, 2)
        AddChanceLoot(inst, "pigskin")
        AddDurabilityLoot(inst, "potato_cooked", nil, 3)
        AddDurabilityLoot(inst, "potato_cooked", .3, 3)
        AddDurabilityLoot(inst, "armorslurper", .2)
        AddDurabilityLoot(inst, "bonestew", .3)
    elseif random_char_cocoon == "wendy" then
        AddDurabilityLoot(inst, "ghostflowerhat")
        AddDurabilityLoot(inst, "moon_tree_blossom", .5, 6)
        AddDurabilityLoot(inst, "petals_evil", nil, 4)
        AddChanceLoot(inst, math.random() > .5 and "ghostlyelixir_fastregen" or "ghostlyelixir_slowregen", nil, 2)
        AddChanceLoot(inst, math.random() > .5 and "ghostlyelixir_retaliation" or "ghostlyelixir_shield", .5, 2)
        AddChanceLoot(inst, math.random() > .5 and "ghostlyelixir_attack" or "ghostlyelixir_speed", .5, 2)
        AddChanceLoot(inst, "ghostlyelixir_revive", .5, 2)
        AddChanceLoot(inst, math.random() > .5 and "halloweenpotion_sanity_large" or "halloweenpotion_sanity_small", nil, 2)
        AddChanceLoot(inst, math.random() > .5 and "halloweenpotion_health_large" or "halloweenpotion_health_small", nil, 2)
        AddChanceLoot(inst, "butterfly", .5, 4)
    elseif random_char_cocoon == "wx78" then
        AddChanceLoot(inst, "gears", nil, 2)
        AddChanceLoot(inst, "gears", .5)
        AddChanceLoot(inst, "transistor", nil, 2)
        AddChanceLoot(inst, "transistor", .5)
        AddDurabilityLoot(inst, "goatmilk", nil, 2)
        AddDurabilityLoot(inst, "goatmilk", .5)
        AddDurabilityLoot(inst, "zaspberry_lesser", nil, 2)
        AddDurabilityLoot(inst, "zaspberry_lesser", .5, 2)
        AddDurabilityLoot(inst, "zaspberry", .5)
        if TheWorld.state.isspring then
            AddDurabilityLoot(inst, math.random() > .75 and "raincoat" or "rainhat", .1)
        end
    elseif random_char_cocoon == "wickerbottom" then
        AddChanceLoot(inst, "papyrus", nil, 4)
        AddChanceLoot(inst, "papyrus", .5, 2)
        AddChanceLoot(inst, "featherpencil")
        AddChanceLoot(inst, "featherpencil", .5, 3)
        AddChanceLoot(inst, "tentaclespots", .2, 2)
        AddDurabilityLoot(inst, "featherhat")
        AddDurabilityLoot(inst, "green_cap", nil, 2)
        AddDurabilityLoot(inst, "green_cap", .5, 4)
        AddLootOnDropFn(inst, "fx_book_birds", function(loot, cocoon)
            local birdspawner = TheWorld.components.birdspawner
            if not birdspawner then return false end
            local pt = loot:GetPosition()
            local BIRDSMAXCHECK_MUST_TAGS = {"magicalbird"}
            local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 10, BIRDSMAXCHECK_MUST_TAGS)
            if #ents > 30 then return false end
            local num = math.random(10, 20)
            if #ents <= 10 then num = num + 10 end
            local success = false
            local delay = 0
            for k = 1, num do
                local pos = birdspawner:GetSpawnPoint(pt)
                if pos then
                    local bird = birdspawner:SpawnBird(pos, true)
                    if bird then
                        bird:AddTag("magicalbird")
                        bird.sg:GoToState("delay_glide", delay)
                        delay = delay + .034 + .033 * math.random()
                        success = true
                    end
                end
            end
        end)
    elseif random_char_cocoon == "woodie" then
        AddDurabilityLoot(inst, "walking_stick")
        AddChanceLoot(inst, "boards", .5, 10)
        AddChanceLoot(inst, "log", nil, 10)
        AddChanceLoot(inst, "log", .75, 20)
        AddChanceLoot(inst, math.random() > .5 and "wereitem_beaver" or math.random() > .5 and "wereitem_moose" or "wereitem_goose")
    elseif random_char_cocoon == "waxwell" then
        AddChanceLoot(inst, "nightmarefuel", nil, 4)
        AddChanceLoot(inst, "nightmarefuel", .5, 6)
        AddDurabilityLoot(inst, "tophat")
        AddChanceLoot(inst, "rabbit")
        AddDurabilityLoot(inst, "purpleamulet", .2)
        AddChanceLoot(inst, "nightsword")
        AddDurabilityLoot(inst, math.random() > .75 and "armor_sanity" or "nightsword")
    elseif random_char_cocoon == "wathgrithr" then
        AddDurabilityLoot(inst, TheWorld.state.iswinter and "trunk_winter" or "trunk_summer")
        AddDurabilityLoot(inst, "meat", nil, 6)
        AddDurabilityLoot(inst, "meat", .5, 2)
        AddChanceLoot(inst, "wathgrithrhat")
        AddDurabilityLoot(inst, "wathgrithrhat", .5)
        AddDurabilityLoot(inst, "spear_wathgrithr")
        AddDurabilityLoot(inst, "spear_wathgrithr", .5)
    elseif random_char_cocoon == "webber" then
        AddChanceLoot(inst, "silk", nil, 2)
        AddChanceLoot(inst, "silk", .5, 6)
        AddChanceLoot(inst, "spidereggsack")
        AddChanceLoot(inst, "healingsalve", nil, 3)
        AddChanceLoot(inst, "healingsalve", .5, 3)
        AddDurabilityLoot(inst, math.random() > .5 and "monstermeat" or "monstersmallmeat", .5, 6)
        AddDurabilityLoot(inst, "sewing_kit")
    elseif random_char_cocoon == "winona" then
        AddChanceLoot(inst, "sewing_tape", nil, 2)
        AddChanceLoot(inst, "sewing_tape", .5, 3)
        AddChanceLoot(inst, "nitre", nil, 4)
        AddChanceLoot(inst, "nitre", .5, 4)
        AddChanceLoot(inst, "rocks", nil, 6)
        AddChanceLoot(inst, "rocks", .5, 8)
        AddChanceLoot(inst, "wagpunk_bits", .5, 4)
        AddChanceLoot(inst, "powercell", .5, 2)
        AddDurabilityLoot(inst, math.random() > .5 and "nightstick" or "bugzapper", .1)
    elseif random_char_cocoon == "warly" then
        AddChanceLoot(inst, "yotc_seedpacket_rare", nil, 3)
        AddChanceLoot(inst, "saltrock")
        AddChanceLoot(inst, "saltrock", .5, 5)
        AddDurabilityLoot(inst, math.random() > .5 and "pepper" or "garlic", nil, 3)
        AddDurabilityLoot(inst, math.random() > .5 and "pepper" or "garlic", .5, 3)
        AddDurabilityLoot(inst, "honey", nil, 3)
        AddDurabilityLoot(inst, "honey", .5, 3)
        --AddDurabilityLoot(inst, "onion", .3, 3)
        AddDurabilityLoot(inst, "monstertartare")
        AddDurabilityLoot(inst, TheWorld.state.iswinter and "dragonchilisalad" or TheWorld.state.issummer and "gazpacho" or "frogfishbowl")
        AddDurabilityLoot(inst, "voltgoatjelly", .1)
        AddDurabilityLoot(inst, math.random() > .5 and "glowberrymousse_spice_sugar" or math.random() > .5 and "nightmarepie" or "potatosouffle_spice_chili", .3)
        AddDurabilityLoot(inst, math.random() > .5 and "moqueca_spice_salt" or math.random() > .5 and "bonesoup_spice_garlic" or "freshfruitcrepes", .3)
        AddDurabilityLoot(inst, math.random() > .5 and "theatercorn_spice_salt" or math.random() > .5 and "beefalowings_spice_garlic" or "stuffed_peeper_poppers", .3)
        AddDurabilityLoot(inst, math.random() > .5 and "zaspberryparfait_spice_sugar" or math.random() > .5 and "snotroast_spice_chili" or "viperjam_spice_sugar", .3)
        AddDurabilityLoot(inst, math.random() > .5 and "um_rimeweed_spagett" or "um_rimeweed_tequila", .3)
    elseif random_char_cocoon == "wortox" then
        AddChanceLoot(inst, "wortox_soul", nil, 4)
        AddChanceLoot(inst, "wortox_soul", .3, 16)
        AddChanceLoot(inst, "redgem")
        AddChanceLoot(inst, "redgem", .5, 2)
        AddDurabilityLoot(inst, "pomegranate", nil, 2)
        AddDurabilityLoot(inst, "pomegranate", .5, 3)
        AddDurabilityLoot(inst, "devilsfruitcake")
        AddDurabilityLoot(inst, "beemine")
        AddChanceLoot(inst, "cotl_trinket", .3)
        AddDurabilityLoot(inst, "panflute", .1)
        AddChanceLoot(inst, "krampus_sack", .01)
    elseif random_char_cocoon == "wormwood" then
        AddChanceLoot(inst, "yotc_seedpacket_rare", nil, 5)
        AddChanceLoot(inst, "livinglog", nil, 2)
        AddChanceLoot(inst, "livinglog", .5, 4)
        AddChanceLoot(inst, math.random() > .5 and "compostwrap" or "tillweedsalve", nil, 4)
		AddChanceLoot(inst, math.random() > .5 and "gloomcap" or "moon_cap", .5, 6)
        AddDurabilityLoot(inst, TheWorld.state.issummer and "cactus_flower" or "dragonfruit", .5, 4)
        --AddDurabilityLoot(inst, "cactus_meat", nil, 2)
		--AddDurabilityLoot(inst, "cactus_meat", .5, 4)
        AddChanceLoot(inst, "lightflier", .3, 6)
        AddDurabilityLoot(inst, math.random() > .75 and TheWorld.state.iswinter and "um_armor_bramble_rimeweed" or "armor_bramble")
        AddDurabilityLoot(inst, "trap_bramble", .5, 3)
        AddChanceLoot(inst, "lureplantbulb", .2)
    elseif random_char_cocoon == "wurt" then
        AddChanceLoot(inst, "cutreeds", nil, 4)
        AddChanceLoot(inst, "cutreeds", .5, 8)
        AddChanceLoot(inst, "tentaclespots", .5, 2)
        AddChanceLoot(inst, "mosquito", .1, 4)
        AddChanceLoot(inst, "mosquitobomb", .5, 3)
        AddChanceLoot(inst, "mosquitofertilizer", .5, 4)
        AddDurabilityLoot(inst, "mosquitomusk")
        AddChanceLoot(inst, "mosquitosack", .5, 6)
        AddChanceLoot(inst, "pondfish", .5, 4)
        AddDurabilityLoot(inst, "tentaclespike", .75, 3)
        AddDurabilityLoot(inst, "mermhat", .2)
    elseif random_char_cocoon == "walter" then
        AddDurabilityLoot(inst, math.random() > .5 and "fishmeat_dried" or "meat_dried", nil, 4)
        AddDurabilityLoot(inst, math.random() > .5 and "smallfishmeat_dried" or "smallmeat_dried", .5, 5)
        AddDurabilityLoot(inst, math.random() > .5 and "monstermeat_dried" or "monstersmallmeat_dried", .5, 6)
        AddDurabilityLoot(inst, "kelp_dried", nil, 4)
        AddDurabilityLoot(inst, "kelp_dried", .5, 2)
        AddChanceLoot(inst, math.random() > .5 and "healingsalve" or "bandage_butterflywings", .5, 5)
        AddChanceLoot(inst, math.random() > .9 and "floral_bandage" or "bandage", .5, 2)
        AddChanceLoot(inst, "brine_balm", .2, 2)
        AddDurabilityLoot(inst, math.random() > .75 and "portabletent_item" or "bedroll_furry", .3)
        AddChanceLoot(inst, math.random() > .5 and "meatrack_hat" or math.random() > .5 and "walterhat" or "bushhat")
        AddChanceLoot(inst, "um_record_walter", .05)
    elseif random_char_cocoon == "wanda" then
        AddChanceLoot(inst, "thulecite_pieces", nil, 4)
        AddChanceLoot(inst, "thulecite_pieces", .5, 8)
        AddChanceLoot(inst, "nightmarefuel", nil, 2)
        AddChanceLoot(inst, "nightmarefuel", .5, 6)
        AddChanceLoot(inst, "marble", .5, 6)
        AddDurabilityLoot(inst, "armor_sanity", .5)
        AddChanceLoot(inst, "walrus_tusk", .5)
        AddChanceLoot(inst, "purplegem", .5)
        AddChanceLoot(inst, "oldager_become_younger_front_fx")
    elseif random_char_cocoon == "winky" then
        AddChanceLoot(inst, "trinket_20")
        AddChanceLoot(inst, "spoiled_food", nil, 6)
        AddChanceLoot(inst, "spoiled_food", .5, 12)
        --AddDurabilityLoot(inst, "um_cheese")
        AddChanceLoot(inst, "rat_tail", nil, 2)
        AddChanceLoot(inst, "rat_tail", .5, 4)
        AddDurabilityLoot(inst, "monstersmallmeat", .5, 8)
        AddChanceLoot(inst, math.random() > .5 and "trinket_1" or "trinket_2", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_3" or "trinket_4", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_5" or "trinket_6", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_7" or "trinket_8", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_9" or "trinket_10", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_11" or "trinket_12", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_13" or "trinket_14", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_17" or "trinket_18", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_19" or "trinket_21", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_22" or "trinket_23", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_24" or "trinket_25", .15)
        AddChanceLoot(inst, math.random() > .5 and "trinket_26" or "trinket_27", .2)
        AddChanceLoot(inst, math.random() > .5 and "cctrinket_don" or "cctrinket_freddo", .2)
        AddChanceLoot(inst, math.random() > .5 and "cctrinket_names" or "trinket_jazzy", .2)
        AddChanceLoot(inst, "corncan", .2)
        AddChanceLoot(inst, "um_record_winky", .05)
    elseif random_char_cocoon == "wathom" then
		AddChanceLoot(inst, "purplegem")
        AddChanceLoot(inst, "meat", nil, 2)
        AddChanceLoot(inst, "meat", .5, 2)
        AddChanceLoot(inst, "nightmarefuel", nil, 4)
        AddChanceLoot(inst, "nightmarefuel", .5, 4)
        AddDurabilityLoot(inst, math.random() > .9 and "ancient_amulet_red" or "amulet")
        AddDurabilityLoot(inst, math.random() > .9 and "ruins_bat" or "hambat")
        AddChanceLoot(inst, "thulecite")
        AddChanceLoot(inst, "thulecite", .3, 5)
        AddChanceLoot(inst, "um_record_wathom", .05)
    elseif random_char_cocoon == "wixie" then
        AddChanceLoot(inst, "bagofmarbles")
        AddChanceLoot(inst, "bagofmarbles", .5, 3)
        AddChanceLoot(inst, math.random() > .5 and "um_blowdart_pyre" or "um_blowdart_rime", .5, 3)
        AddChanceLoot(inst, math.random() > .5 and "slingshotammo_honey" or "slingshotammo_goop", .75, 20)
        AddChanceLoot(inst, "nitre", nil, 3)
        AddChanceLoot(inst, "nitre", .5, 5)
		AddChanceLoot(inst, "mosquitosack", nil, 2)
        AddChanceLoot(inst, "mosquitosack", .5, 4)
		AddChanceLoot(inst,  math.random() > .5 and "livinglog" or "driftwood_log", .5, 2)
        AddChanceLoot(inst,  math.random() > .5 and "sludge" or "saltrock", .5, 4)
		AddChanceLoot(inst,  math.random() > .5 and "moonrocknugget" or "moonglass", nil, 6)
		AddChanceLoot(inst, "townportaltalisman", .1, 3)
        AddChanceLoot(inst, "um_record_wixie", .05)
    elseif random_char_cocoon == "wes" then
        AddChanceLoot(inst, "balloonparty_confetti_cloud", nil, 5)
        AddChanceLoot(inst, "balloonspeed", .1, 50)
		AddChanceLoot(inst, "balloon", .01)
        AddChanceLoot(inst, "freshfruitcrepes")
        AddChanceLoot(inst, "balloonhat")
        AddChanceLoot(inst, "balloonvest")
        AddChanceLoot(inst, "waterballoon", .3, 10)
    elseif random_char_cocoon == "wieneke" then
        AddLootOnDropFn(inst, "koalefant_carcass", function(loot, cocoon)
            if not loot.SetMeatPct then return end
            loot:SetMeatPct(.25) -- Not sure if 25% is the right amount to have the second-to-last decay stage, might need to fiddle to get it right!
        end)
        AddChanceLoot(inst, "glommerfuel", nil, 2)
        AddChanceLoot(inst, "glommerfuel", .5, 2)
        AddChanceLoot(inst, "trinket_9")
        AddChanceLoot(inst, "snotroast")
        AddChanceLoot(inst, "halloweencandy_8")
    elseif random_char_cocoon == "flaire" then
        AddChanceLoot(inst, "nightsword")
        AddDurabilityLoot(inst, "familiarsword")
        AddChanceLoot(inst, "pureaspectgem")
        AddChanceLoot(inst, "pureaspectgem", .5, 2)
        AddChanceLoot(inst, "bluegem")
        AddChanceLoot(inst, "redgem")
        AddChanceLoot(inst, "goldnugget", nil, 2)
        AddChanceLoot(inst, "goldnugget", .5, 4)
        AddLootOnDropFn(inst, "spellprint", function(loot, cocoon)
            if not loot.TryRevealSpell then return end
            local flaire = FindClosestEntity(loot, 40, true, {"flaire"})
            if flaire then
                loot:TryRevealSpell(flaire)
            else
                loot:Remove()
            end
        end)
    elseif random_char_cocoon == "weerclops" then
        AddChanceLoot(inst, "ice", nil, 12)
        AddChanceLoot(inst, "ice", .5, 12)
        AddDurabilityLoot(inst, "snowball_item", nil, 4)
        AddDurabilityLoot(inst, "snowball_item", .5, 8)
        AddChanceLoot(inst, "um_rimeweed_itemvine", nil, 3)
        AddChanceLoot(inst, "um_rimeweed_itemvine", .5, 3)
        AddChanceLoot(inst, "um_rimeweed_itemflower", .5)
        AddChanceLoot(inst, "um_rimeweed_icepack")
        AddChanceLoot(inst, "um_rimeweed_icepack", .5, 2)
        AddDurabilityLoot(inst, math.random() > .5 and "um_hat_rime" or "rimeweed_whip", .5)
        AddDurabilityLoot(inst, math.random() > .9 and "beakbasher" or "hammer")
    elseif random_char_cocoon == "woose" then
        AddChanceLoot(inst, "tallbirdegg")
        AddChanceLoot(inst, "dug_sapling")
        AddChanceLoot(inst, "twigs", nil, 6)
        AddChanceLoot(inst, "twigs", .5, 8)
        AddChanceLoot(inst, "cutgrass", nil, 6)
        AddChanceLoot(inst, "cutgrass", .5, 8)
        AddChanceLoot(inst, "goose_feather", nil, 3)
        AddChanceLoot(inst, "goose_feather", .3, 3)
        AddChanceLoot(inst, "feather_crow", .5, 3)
        AddChanceLoot(inst, "feather_robin", .5, 3)
        AddChanceLoot(inst, "feather_robin_winter", .5, 3)
        AddChanceLoot(inst, "feather_canary", .5, 3)
        AddChanceLoot(inst, "malbatross_feather", .3, 6)
        AddDurabilityLoot(inst, "featherfan", .3)
    elseif random_char_cocoon == "wearger" then
        AddDurabilityLoot(inst, "honey", nil, 4)
        AddDurabilityLoot(inst, "honey", .5, 6)
        AddChanceLoot(inst, "honeycomb")
        AddChanceLoot(inst, "honeycomb", .5, 2)
        AddDurabilityLoot(inst, "royal_jelly", .1, 2)
		AddDurabilityLoot(inst, "honeyham")
        AddChanceLoot(inst, "bedroll_furry")
        AddChanceLoot(inst, "furtuft", nil, 12)
        AddChanceLoot(inst, "furtuft", .5, 30)
    elseif random_char_cocoon == "wragonfly" then
        AddChanceLoot(inst, "ash", nil, 6)
        AddChanceLoot(inst, "ash", .5, 14)
        AddChanceLoot(inst, "charcoal", nil, 6)
        AddChanceLoot(inst, "charcoal", .5, 14)
        AddChanceLoot(inst, "goldnugget", nil, 4)
        AddChanceLoot(inst, "goldnugget", .5, 4)
        AddChanceLoot(inst, "redgem")
        AddChanceLoot(inst, "redgem", .5)
        AddChanceLoot(inst, "bluegem")
        AddChanceLoot(inst, "bluegem", .5)
        AddChanceLoot(inst, "purplegem", .5, 2)
        AddChanceLoot(inst, "orangegem", .1, 2)
        AddChanceLoot(inst, "yellowgem", .1, 2)
        AddChanceLoot(inst, "greengem", .1, 2)
        AddChanceLoot(inst, "lavae_cocoon")
    elseif random_char_cocoon == "wilbur" then
        AddChanceLoot(inst, "dug_monkeytail", nil, 2)
        AddChanceLoot(inst, "dug_monkeytail", .5, 2)
        AddChanceLoot(inst, "dug_bananabush", .1, 2)
        AddDurabilityLoot(inst, "cave_banana", nil, 3)
        AddDurabilityLoot(inst, "cave_banana", .5, 5)
        AddDurabilityLoot(inst, math.random() > .5 and "frozenbananadaiquiri" or "bananapop")
        AddDurabilityLoot(inst, "monkeyball")
        AddDurabilityLoot(inst, math.random() > .5 and "monkey_smallhat" or "oar_monkey")
        AddChanceLoot(inst, "poop", .5, 6)
        AddChanceLoot(inst, "blackflag")
        AddDurabilityLoot(inst, math.random() > .9 and "cutlass" or "cutless")
    elseif random_char_cocoon == "walani" then
        AddChanceLoot(inst, "seashell", nil, 4)
        AddChanceLoot(inst, "seashell", .5, 2)
        AddChanceLoot(inst, "boards", nil, 2)
        AddDurabilityLoot(inst, "sunglasses")
        AddDurabilityLoot(inst, math.random() > .5 and "bananajuice" or "vegstinger")
        AddChanceLoot(inst, "palmleaf", nil, 2)
        AddChanceLoot(inst, "palmleaf", .5, 4)
        AddDurabilityLoot(inst, "coconut", nil, 3)
        AddDurabilityLoot(inst, "coconut", .5, 5)
        AddChanceLoot(inst, "coconade", .3, 2)
        AddDurabilityLoot(inst, math.random() > .9 and "cutlass" or "spear_launcher")
    elseif random_char_cocoon == "woodlegs" then
        AddDurabilityLoot(inst, "woodlegshat")
        AddDurabilityLoot(inst, math.random() > .9 and "supertelescope" or "telescope")
        AddChanceLoot(inst, "dubloon", nil, 10)
        AddChanceLoot(inst, "dubloon", .5, 20)
        AddChanceLoot(inst, "boneshard", .5, 6)
        AddChanceLoot(inst, math.random() > .5 and "boatpatch_sludge" or "boatrepairkit")
        AddDurabilityLoot(inst, "boatrepairkit", .5, 2)
        AddChanceLoot(inst, math.random() > .5 and "boat_cannon_kit" or "boatcannon")
        AddChanceLoot(inst, "stash_map")
        AddDurabilityLoot(inst, "cutlass", .1)
    elseif random_char_cocoon == "wirlywings" then
        AddChanceLoot(inst, "cherrytrinket_1")
        AddChanceLoot(inst, "cherrytrinket_2")
        AddChanceLoot(inst, "cherrygem", nil, 2)
        AddDurabilityLoot(inst, "cherryscepter")
        AddDurabilityLoot(inst, "cherryhat", .75)
        AddDurabilityLoot(inst, "cherry_cake", .5, 2)
        AddDurabilityLoot(inst, "cherry", nil, 2)
        AddDurabilityLoot(inst, "cherry", .75, 3)
        AddDurabilityLoot(inst, "cherry_double", .3, 3)
        AddChanceLoot(inst, "wirlycandy_regen", .75, 2)
        AddChanceLoot(inst, "wirlycandy_oblivious", .5, 2)
        AddChanceLoot(inst, "wirlycandy_blackhole", .3)
        AddChanceLoot(inst, "wirlycandy_goop", .3, 3)
    elseif random_char_cocoon == "wade" then
        AddDurabilityLoot(inst, "tiddlestick")
        AddDurabilityLoot(inst, "tiddle_detector")
        AddChanceLoot(inst, "tiddle_sponge", nil, 3)
        AddChanceLoot(inst, "tiddle_sponge", .5)
        AddDurabilityLoot(inst, math.random() > .5 and "hat_tiddlevirus" or "armor_tiddlesapron")
        AddDurabilityLoot(inst, "tiddlebungus_cap")
        AddDurabilityLoot(inst, "tiddlebungus_cap", .5, 2)
        AddChanceLoot(inst, "tiddlelog", .3)
        AddChanceLoot(inst, "spoiled_food", nil, 4)
        AddChanceLoot(inst, "spoiled_food", .5, 4)
    elseif random_char_cocoon == "wonderwhy" then
        AddChanceLoot(inst, "thulecite_pieces", nil, 6)
        AddChanceLoot(inst, "thulecite_pieces", .5, 6)
		AddChanceLoot(inst, "nitre", nil, 3)
        AddChanceLoot(inst, "nitre", .5, 3)
		AddChanceLoot(inst, "boneshard", nil, 4)
        AddChanceLoot(inst, "boneshard", .5, 2)
        AddChanceLoot(inst, "ancientdreams_gemshard", nil, 3)
        AddChanceLoot(inst, "ancientdreams_gemshard", .5, 3)
        AddChanceLoot(inst, math.random() > .75 and "moonglass" or math.random() > .5 and "moonrocknugget" or "goldnugget", nil, 4)
		AddDurabilityLoot(inst, math.random() > .75 and "why_refined_butterfly_moon" or math.random() > .5 and "why_refined_butterfly" or "why_refined_lightbulb")
        AddChanceLoot(inst, math.random() > .5 and "redgem" or "bluegem")
        AddChanceLoot(inst, math.random() > .75 and "orangegem" or "purplegem")
        AddChanceLoot(inst, math.random() > .75 and "greengem" or "yellowgem", .5)
    elseif random_char_cocoon == "zeta" then --wuzzy the buzzy
		AddChanceLoot(inst, "honey_splash")
        AddDurabilityLoot(inst, "honey", nil, 8)
        AddDurabilityLoot(inst, "honey", .5, 6)
		AddDurabilityLoot(inst, "royal_jelly")
        AddDurabilityLoot(inst, math.random() > .75 and "royal_jelly" or "zetapollen", nil, 3)
		AddDurabilityLoot(inst, "zetapollen", .5, 9)
		AddChanceLoot(inst, "honeycomb", nil, 2)
		AddChanceLoot(inst, "honeycomb", .5)
        AddDurabilityLoot(inst, math.random() > .5 and "armor_honey" or "melissa")
		AddChanceLoot(inst, math.random() > .9 and "um_beemine_moon_item" or "beemine", .5)
    elseif random_char_cocoon == "whimsy" then
		AddChanceLoot(inst, "purplegem")
		AddChanceLoot(inst, math.random() > .5 and "redgem" or "bluegem", .75, 3)
		AddChanceLoot(inst, math.random() > .5 and "yellowgem" or "orangegem", .15, 3)
        AddChanceLoot(inst, "marble", nil, 4)
        AddChanceLoot(inst, "marble", .5, 2)
		AddChanceLoot(inst, "brainrock")
		AddChanceLoot(inst, "brainrock", .5, 2)
		AddDurabilityLoot(inst, "wobster_sheller_land")
		AddDurabilityLoot(inst, "purpletool")
    else
        AddChanceLoot(inst, "skeleton")
        AddChanceLoot(inst, "boneshard", nil, 2)
        AddChanceLoot(inst, "boneshard", .5, 2)
        AddChanceLoot(inst, "cutgrass", nil, 6)
        AddChanceLoot(inst, "cutgrass", .5, 6)
        AddChanceLoot(inst, "twigs", nil, 6)
        AddChanceLoot(inst, "twigs", .5, 6)
        AddDurabilityLoot(inst, "armorwood")
        AddDurabilityLoot(inst, "footballhat")
        AddDurabilityLoot(inst, "tentaclespike")
    end
end

local cocoontable = {
    [1] = {
        creature = "beeguard",
        lootfn = function(inst)
            AddChanceLoot(inst, "honeycomb", nil, 2)
            AddChanceLoot(inst, "honey", nil, 5)
            AddChanceLoot(inst, "honey", .5)
            AddChanceLoot(inst, "stinger", .1)
            AddChanceLoot(inst, "royal_jelly")
        end,
        cocoonsize = "small",
        cocoonname = "Buggy",
    },
    [2] = {
        creature = "pied_rat",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat", nil, 2)
            AddChanceLoot(inst, "monstermeat", .5)
            AddChanceLoot(inst, "rat_tail", nil, 2)
        end,
        cocoonsize = "small",
        cocoonname = "Grotesque",
    },
    [3] = {
        creature = "eyeofterror_mini",
        lootfn = function(inst)
            AddChanceLoot(inst, "milkywhites", nil, 2)
            AddChanceLoot(inst, "monstermeat")
            AddChanceLoot(inst, "monstermeat", .5)
        end,
        cocoonsize = "small",
        cocoonname = "Grotesque",
    },
    [4] = {
        creature = "catcoon",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "coontail", nil, 4)
        end,
        cocoonsize = "small",
        cocoonname = "Hairy",
    },
    [5] = {
        creature = "alpha_lightninggoat",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "lightninggoathorn")
        end,
        cocoonsize = "small",
        cocoonname = "Hairy",
    },
    [6] = {
        creature = "bishop",
        lootfn = function(inst)
            AddChanceLoot(inst, "trinket_6", nil, 2)
        end,
        cocoonsize = "small",
        cocoonname = "Hardened",
    },
    [7] = {
        creature = "merm",
        lootfn = function(inst)
            AddChanceLoot(inst, "froglegs", .5)
            AddChanceLoot(inst, "tentaclespots", nil, 2)
        end,
        cocoonsize = "small",
        cocoonname = "Scaly",
    },
    [8] = {
        creature = "pigman",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "pigskin")
            AddChanceLoot(inst, "tophat")
            AddChanceLoot(inst, "pig_token", .1)
        end,
        cocoonsize = "small",
        cocoonname = "Leathery",
    },
    [9] = {
        creature = "mossling",
        cocoonsize = "medium",
        cocoonname = "Feathery",
    },
    [10] = {
        creature = "tallbird",
        lootfn = function(inst)
            AddChanceLoot(inst, "tallbirdegg")
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "feather_crow", nil, 2)
            AddChanceLoot(inst, "feather_crow", .25)
            AddChanceLoot(inst, "feather_robin", nil, 2)
            AddChanceLoot(inst, "feather_robin", .25)
            AddChanceLoot(inst, "feather_robin_winter", nil, 2)
            AddChanceLoot(inst, "feather_robin_winter", .25)
            AddChanceLoot(inst, "feather_canary", nil, 2)
            AddChanceLoot(inst, "feather_canary", .25)
        end,
        cocoonsize = "medium",
        cocoonname = "Feathery",
    },
    [11] = {
        creature = "deer",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "deer_antler")
            AddChanceLoot(inst, "bluegem")
            AddChanceLoot(inst, "redgem")
        end,
        cocoonsize = "medium",
        cocoonname = "Hairy",
    },
    [12] = {
        creature = "krampus",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat", .5)
            AddChanceLoot(inst, "charcoal", nil, 2)
            AddChanceLoot(inst, "boneshard")
            AddChanceLoot(inst, "krampus_sack", .05)
            AddChanceLoot(inst, "bluegem")
            AddChanceLoot(inst, "redgem")
        end,
        cocoonsize = "medium",
        cocoonname = "Grotesque",
    },
    [13] = {
        creature = "otter",
        lootfn = function(inst)
            AddChanceLoot(inst, "smallmeat")
            AddChanceLoot(inst, "kelp", nil, 2)
            AddChanceLoot(inst, "kelp", .75, 2)
            AddChanceLoot(inst, "kelp", .5)
            AddChanceLoot(inst, "barnacle", .5)
            AddChanceLoot(inst, "barnacle", .25)
            AddChanceLoot(inst, "messagebottle")
            AddChanceLoot(inst, "bullkelp_root")
            AddChanceLoot(inst, "oceanfish_small_4_inv", .75)
            AddChanceLoot(inst, "oceanfish_medium_1_inv", .2)
            AddChanceLoot(inst, "oceanfish_small_3_inv", .1)
            if TheWorld.state.isautumn then
                AddChanceLoot(inst, "oceanfish_small_6_inv", .5)
            elseif TheWorld.state.iswinter then
                AddChanceLoot(inst, "oceanfish_medium_8_inv", .2)
            elseif TheWorld.state.isspring then
                AddChanceLoot(inst, "oceanfish_small_7_inv")
            elseif TheWorld.state.issummer then
                AddChanceLoot(inst, "oceanfish_small_8_inv", .2)
            else
                AddChanceLoot(inst, "wobster_sheller_land")
            end
        end,
        cocoonsize = "medium",
        cocoonname = "Scaly",
    },
    [14] = {
        creature = "walrus",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "walrus_tusk")
            AddChanceLoot(inst, "um_bear_trap_equippable_tooth", .5)
        end,
        cocoonsize = "medium",
        cocoonname = "Leathery",
    },
    [15] = {
        creature = "lordfruitfly",
        lootfn = function(inst)
            AddChanceLoot(inst, "plantmeat", .5)
            AddChanceLoot(inst, "seeds", nil, 4)
            AddChanceLoot(inst, "seeds", .25, 4)
        end,
        cocoonsize = "large",
        cocoonname = "Buggy",
    },
    [16] = {
        creature = "spiderqueen",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat")
            AddChanceLoot(inst, "monstermeat", .5)
            AddChanceLoot(inst, "silk")
            AddChanceLoot(inst, "silk", .5)
        end,
        cocoonsize = "large",
        cocoonname = "Buggy",
    },
    [17] = {
        creature = "beefalo",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "beefalowool")
            AddChanceLoot(inst, "beefalowool", .5)
            AddChanceLoot(inst, "horn")
            AddChanceLoot(inst, "poop", .5)
        end,
        cocoonsize = "large",
        cocoonname = "Hairy",
    },
    [18] = {
        creature = "warg",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat")
            AddChanceLoot(inst, "houndstooth", nil, 2)
            AddChanceLoot(inst, "houndstooth", .5)
            AddChanceLoot(inst, "boneshard")
            AddChanceLoot(inst, "boneshard", .5)
            AddChanceLoot(inst, "bluegem")
            AddChanceLoot(inst, "redgem")
        end,
        cocoonsize = "large",
        cocoonname = "Hairy",
    },
    [19] = {
        creature = "spat",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "steelwool", nil, 2)
            AddChanceLoot(inst, "steelwool", .5)
            AddChanceLoot(inst, "phlegm", nil, 2)
        end,
        cocoonsize = "large",
        cocoonname = "Hardened",
    },
    [20] = {
        creature = "koalefant_summer",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", nil, 3)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "poop", .5)
        end,
        cocoonsize = "large",
        cocoonname = "Leathery",
    },
    [21] = {
        creature = "shark",
        lootfn = function(inst) -- 1 Rocky Hide, 3-6 fishmeat, 4-6 barnacle, 2-3 flint, 6-8 rocks, 2-4 nitre, 15% Deep Bass.
            AddChanceLoot(inst, "fishmeat", .5)
            AddChanceLoot(inst, "barnacle", nil, 3)
            AddChanceLoot(inst, "rocks", nil, 3)
            AddChanceLoot(inst, "nitre", nil, 2)
            AddChanceLoot(inst, "nitre", .5, 2)
            
        end,
        cocoonsize = "large",
        cocoonname = "Scaly",
    },
    [23] = {
        creature = "grassgator", -- 7-8 plantmeat, 4 cutgrass, 4 twigs, 3-4 cactus_flower.
        lootfn = function(inst)
            AddChanceLoot(inst, "plantmeat", .5)
            AddChanceLoot(inst, "cutgrass", nil, 2)
            AddChanceLoot(inst, "twigs", nil, 2)
            AddChanceLoot(inst, "cactus_flower", nil, 3)
            AddChanceLoot(inst, "cactus_flower", .5)
        end,
        cocoonsize = "large",
        cocoonname = "Leafy",
    },
    [22] = {
        creature = "leif_sparse", -- 2 plantmeat, 6-8 livinglog, 10-20 logs.
        lootfn = function(inst)
            AddChanceLoot(inst, "plantmeat")
            AddChanceLoot(inst, "livinglog", .5, 2)
            AddChanceLoot(inst, "log", nil, 10)
            AddChanceLoot(inst, "log", .75, 10)
        end,
        cocoonsize = "large",
        cocoonname = "Leafy",
    },
    [23] = {
        creature = "stalker_minion1", -- Do the funny stuff here
        lootfn = SurvivorCocoon,
        cocoonsize = "medium",
        cocoonname = "Shrouded",
    },
    [24] = {
        creature = "stalker_minion2", -- Do the funny stuff here
        lootfn = function(inst)
            for i = 1, 2 do
                SurvivorCocoon(inst)
            end
        end,
        cocoonsize = "large",
        cocoonname = "Shrouded",
    },
}

local function OnKilled(inst)
    inst.AnimState:PlayAnimation(inst.anims.kill)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
    local creature
    if inst.size and inst.cocoontable then
        for num, mob in ipairs(inst.cocoontable) do
            if inst.size == num then
                creature = mob.creature
                if mob.lootfn then
                    mob.lootfn(inst)
                end
            end
        end
        inst.components.lootdropper:DropLoot()
        --[[if creature and not creature == "spiderqueen" then
            inst.components.lootdropper:SetChanceLootTable('webbedcreature_'..creature)
        end]]
        local deadcreature = SpawnPrefab(creature)
        deadcreature.Transform:SetPosition(x, y, z)
        if creature == "spiderqueen" then
            deadcreature:AddTag("nodecomposepls")
        end
        deadcreature:DoTaskInTime(0, function()
            if deadcreature.brain then deadcreature.brain:Stop() end
            deadcreature.components.health:Kill()
        end)
    else
        local deadcreature = SpawnPrefab("pigman")
        deadcreature.Transform:SetPosition(x, y, z)
        deadcreature.components.health:Kill()
    end
    local spawner = SpawnPrefab("webbedcreaturespawner")
    spawner.Transform:SetPosition(x, y, z)
end

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spidernest_LP", "loop")
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function onsave(inst, data)
    if inst.size then
        data.size = inst.size
    end
end

local function onload(inst, data)
    if data and data.size then
        inst.size = data.size
    end
end

local function SetStage(inst, stage)
    if stage <= 3 then
        inst.AnimState:PlayAnimation(inst.anims.init)
        inst.AnimState:PushAnimation(inst.anims.idle, true)
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationNumFrames() * FRAMES, function(inst) inst.AnimState:SetTime(math.random() * 2) end)
    end
end

local function GetCocoonFeatures(size)
    local shadowx, shadowy, silk, stage = 5, 4, 6, 3
    if size == "small" then
        shadowx, shadowy, silk, stage = 3.5, 2.5, 2, 1
    elseif size == "medium" then
        shadowx, shadowy, silk, stage = 4, 3.5, 4, 2
    end
    return shadowx, shadowy, silk, stage
end

local function SetCocoonSize(inst, size)
    if size ~= "small" and inst:HasTag("smallcocoon") then
        inst:RemoveTag("smallcocoon")
    end
    if size ~= "medium" and inst:HasTag("mediumcocoon") then
        inst:RemoveTag("mediumcocoon")
    end
    if size ~= "large" and inst:HasTag("largecocoon") then
        inst:RemoveTag("largecocoon")
    end
    local shadowx, shadowy, silk, stage = GetCocoonFeatures(size)
    inst:AddTag(size.."cocoon")
    inst.MiniMapEntity:SetIcon("webbedcreature_"..size.."_minimap.tex")
    inst.DynamicShadow:SetSize(shadowx, shadowy)
    for i = 1, silk do
        inst.components.lootdropper:AddChanceLoot("silk", 1)
    end
    inst.anims = {
        hit = "hit_"..size,
        idle = "idle_"..size,
        kill = "break_"..size,
        init = "appear_"..size,
    }
    SetStage(inst, stage)
end

local function SetSize(inst)
    if inst.cocoontable then
        if not inst.size or inst.size < 1 or inst.size > #inst.cocoontable then
            inst.size = math.random(1, #inst.cocoontable)
        end
        for num, mob in ipairs(inst.cocoontable) do
            if inst.size == num then
                SetCocoonSize(inst, mob.cocoonsize or "large")
                inst.components.named:SetName(mob.cocoonname.." Cocoon")
            end
        end
    end
end

local function PlayHitAnimations(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
    inst.AnimState:PlayAnimation(inst.anims.hit)
    inst.AnimState:PushAnimation(inst.anims.idle)
end

local function NoEpics(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheSim:FindEntities(x, y, z, 50, {"epic"}, {"hoodedwidow", "smallepic"})
end

local function Regen(inst, data)
    ---TheNet:Announce("attacked")
    local attacker = data.attacker
    if attacker then
        if not attacker:HasTag("player") and attacker.components.combat and attacker.components.combat.target then
            attacker.components.combat:DropTarget()
        end
        if not inst.components.health:IsDead() and not attacker:HasTag("hoodedwidow") then
            --TheNet:Announce("advancing")
            local widowweb = FindEntity(inst, 50, function(guy) return guy:HasTag("widowweb") end)
            if widowweb and attacker:HasTag("player") and #NoEpics(inst) == 0 then
                --TheNet:Announce("tellingwidow")
                widowweb:SpawnInvestigators(attacker)
            end
            inst:PlayHitAnimations()
            if attacker:HasTag("player") and not attacker:HasTag("mime") and (not attacker:HasTag("widowsgrasp")
                or (attacker.components.rider and attacker.components.rider:IsRiding())) then
                attacker.components.talker:Say(GetString(attacker.prefab, "WEBBEDCREATURE"))
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    --inst.MiniMapEntity:SetIcon("hoodedwidow_map.tex")

    inst.AnimState:SetBank("wackycocoons")
    inst.AnimState:SetBuild("wackycocoons")
    --inst.AnimState:PlayAnimation("idle_small", true)

    inst:AddTag("noepicmusic")
    inst:AddTag("webbedcreature")
    --inst:AddTag("structure")
    --inst:AddTag("noauradamage")
    --inst:AddTag("notarget")
    inst:AddTag("houndfriend")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("queensstuff")
    inst:AddTag("companion")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1000000)
    inst.components.health.absorb = 1
    --inst.components.health.invincible = true

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", Regen)
    inst:ListenForEvent("death", OnKilled)

    inst:AddComponent("lootdropper")
    inst:AddComponent("named")

    MakeLargePropagator(inst)

    inst:AddComponent("inspectable")

    MakeSnowCovered(inst)
    inst.cocoontable = cocoontable
    inst:DoTaskInTime(0, SetSize)
    inst.PlayHitAnimations = PlayHitAnimations
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    return inst
end

local function on_anim_over(inst)
    inst.AnimState:PlayAnimation(inst.category..(math.random() > .95 and "_twitch" or ""))
end

local function decorsave(inst, data)
    if data then
        data.category = inst.category
    end
end

local function decorload(inst, data)
    if data and data.category then
        inst.category = data.category
        inst.AnimState:PlayAnimation(inst.category)
    end
end

local function fndecor()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cocoondecor")
    inst.AnimState:SetBuild("cocoondecor")

    inst:AddTag("webdecor")
    inst:AddTag("antlion_sinkhole_blocker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", on_anim_over)
    inst.OnSave = decorsave
    inst.OnLoad = decorload

    return inst
end

return Prefab("webbedcreature", fn),
    Prefab("widowdecor", fndecor)