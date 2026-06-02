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
        notes = {cursed_item = true}
    }

    if extra_data ~= nil then
        for k, v in pairs(extra_data) do
            data[k] = v

            if k == "deps" then
                --table.insert(data.deps, "veteranshrine")
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
    -- cursed items & related
    cursed_antler = CreateCursedItemData("cursed_antler", nil, nil, nil, {weapondamage = "34-66", areadamage = 34, deps = {"boneshard", "deerclops"}}),
    beargerclaw = CreateCursedItemData("beargerclaw", nil, nil, nil, {areadamage = "20-60", weaponrange = 20, deps = {"boneshard", "bearger", "furtuft"} }), --toolactions = {"DIG"} toolactions looks wierd without  finiteuses
    slobberlobber = CreateCursedItemData("slobberlobber", nil, nil, nil, {weapondamage = "20/0.6s", weaponrange = 15, deps = {"meat", "dragon_scales", "dragonfly"} --[[mock_dragonfly]] }),
    feather_frock = CreateCursedItemData("feather_frock", "featherfrock_ground", "featherfrock_ground", "anim", {weapondamage = "10-50", deps = {"goose_feather", "moose", "feather_robin", "feather_robin_winter", "feather_crow", "feather_canary", "malbatross_feather"}}),
    gore_horn_hat = CreateCursedItemData("gore_horn_hat", "hat_gore_horn", "hat_gore_horn", nil, {weapondamage = 200, deps = {"minotaur", "nightmarefuel"}}),
    klaus_amulet = CreateCursedItemData("klaus_amulet", "amulet_klaus", "amulet_klaus", "klausamulet", {deps = {"klaus", "goldnugget", "nightmarefuel"}, absorb_percent=0.3,}),
    crabclaw = CreateCursedItemData("crabclaw", "cursedcrabclaw", "cursedcrabclaw", nil, {weapondamage = "40-60", deps = {"meat", "rocks", "crabking", "redgem", "bluegem", "purplegem", "yellowgem", "greengem", "orangegem", "opalpreciousgem"}}),
    um_beegun = CreateCursedItemData("um_beegun", nil, nil, nil, {weapondamage = 10, weaponrange = 14, deps = {"beequeen", "honeycomb", "royal_jelly"}}),
    bulletbee = {name="bulletbee", tex="bulletbee.tex", subcat="insect", type="creature", prefab="bulletbee", health=10, damage=10, stacksize=20, build="bulletbee_build", bank="bee", anim="idle", animoffsety=150, perishable=960, workable="NET", deps={"beemine", "um_beegun"}},
    
    
    -- lunar/grotto
    um_bee_moon = {name = "um_bee_moon", tex = "um_bee_moon.tex", subcat = "insect", type = "creature", prefab = "um_bee_moon", health = 250, damage = 34, stacksize = 20, build = "um_bee_moon", bank = "um_bee_moon", anim = "idle", animoffsety = 150, perishable = 960, workable = "NET", deps = {"um_meathoney", "houndstooth"}, notes = {lunar_aligned = true}},
    um_astral_projector = {name = "um_astral_projector", tex = "um_astral_projector.tex", subcat = "structure", type = "thing", prefab = "um_astral_projector", build = "um_archives_projectinator", bank = "um_archives_projectinator", anim = "idle", workable = "HAMMER", deps = {"um_astral_projector_target", "purplemooneye", "thulecite", "moonrocknugget"}},
    um_astral_projector_target = {name = "um_astral_projector_target", tex = "um_astral_projector_target.tex", subcat = "structure", type = "thing", prefab = "um_astral_projector_target", build = "um_archives_receptionator", bank = "um_archives_receptionator", anim = "idle", workable = "HAMMER", deps = {"moonglass", "thulecite", "moonrocknugget"}}
}

local crabclaw_gem_colours = {
    red = 1,
    blue = 1,
    purple = 1.25,
    yellow = 2,
    green = 2,
    orange = 2,
    opalprecious = 2
}

for k,v in pairs(crabclaw_gem_colours) do
    data[k.."gem_cracked"] = {
        name = k.."gem_cracked",
        tex = k.."gem_cracked.tex",
        type = "item",
        prefab = k.."gem_cracked",
        finiteuses = v * 200,
        subcat = "veteranscurse", 
        build = "gems",
        bank = "gems",
        anim = (k == "opalprecious" and "opal" or k).."gem_idle",
        hungervalue=2.5, 
        healthvalue=0, 
        sanityvalue=0, 
        foodtype="ELEMENTAL",
        deps = {k.."gem", "crabclaw"}
    }
end

return data
 