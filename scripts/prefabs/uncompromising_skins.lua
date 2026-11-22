local um_upvaluehacker = require "tools/um_upvaluehacker"
local prefs = {}
require("skinsutils")

--kill whitelisting
print("killing whitelisting")
local function IsWhiteListedMod(...)
    return true -- Whitelist is no longer used nowadays, but you never know !
end

print(Sim)
print(Sim.ReskinEntity)
um_upvaluehacker.SetUpvalue(Sim.ReskinEntity, IsWhiteListedMod, "IsWhiteListedMod")

--require("uncompprefabskin")

table.insert(prefs, CreatePrefabSkin("ms_hat_plaguemask_formal",
    {
        assets = {
            Asset("ANIM", "anim/hat_plaguemask_formal.zip"),
        },
        base_prefab = "plaguemask",
        build_name_override = "hat_plaguemask_formal",
        type = "item",
        rarity = "ModMade",
        skin_tags = { "CRAFTABLE" },
    }))

table.insert(prefs, CreatePrefabSkin("ms_feather_frock_fancy",
    {
        assets = {
            Asset("ANIM", "anim/featherfrock_fancy_ground.zip"),
        },
        base_prefab = "feather_frock",
        build_name_override = "featherfrock_fancy_ground",
        type = "item",
        rarity = "ModMade",
        skin_tags = {},
    }))

table.insert(prefs, CreatePrefabSkin("ms_twisted_antler",
    {
        assets = {
            Asset("ANIM", "anim/twisted_antler.zip"),
        },
        base_prefab = "cursed_antler",
        build_name_override = "twisted_antler",
        type = "item",
        rarity = "ModMade",
        skin_tags = {},
    }))

table.insert(prefs, CreatePrefabSkin("ms_ancient_amulet_red_demoneye",
    {
        assets = {
            Asset("ANIM", "anim/ancient_amulet_red_demoneye.zip"),
        },
        base_prefab = "ancient_amulet_red",
        build_name_override = "ancient_amulet_red_demoneye",
        type = "item",
        rarity = "ModMade",
        skin_tags = { "CRAFTABLE" },
    }))

table.insert(prefs, CreatePrefabSkin("ms_um_trans_bomb_moon",
    {
        assets = {
            Asset("ANIM", "anim/um_trans_bomb_moon.zip"),
        },
        base_prefab = "um_bomb_moon",
        build_name_override = "um_trans_bomb_moon",
        type = "item",
        rarity = "ModLocked",
        condition = {
            no_gift = true
        },
        skin_tags = { "CRAFTABLE" },
    }))

--records...
local record_defs = {
    hooded_widow = "UMMusic/gramaphone_record/hoodedforest_efs",
    menu = "UMMusic/gramaphone_record/uncomp_main_menu",
    moonmaw = "UMMusic2/gramaphone_record/um_epicfight_moonmaw",
    shadow_wixie = "UMMusic/gramaphone_record/shadow_boxing",
    stranger = "UMMusic/gramaphone_record/tiddlestranger",
    tot = "UMMusic2/gramaphone_record/um_epicfight_tot",
    walter = "UMMusic/gramaphone_record/follow_me_woby_flat",
    wathom = "UMMusic/gramaphone_record/wathom_amped",
    winky = "UMMusic2/gramaphone_record/winky2",
    wixie = "UMMusic/gramaphone_record/wixie_the_delinquent"
}

local unlockable = {
    "shadow_wixie",
    "moonmaw",
    "hooded_widow",
    "tot"
}

for name, _ in pairs(record_defs) do
    local is_unlock = table.contains(unlockable, name)
    local data = {
        assets = {
            Asset("DYNAMIC_ANIM", "anim/dynamic/um_record_" .. name .. ".zip"),
            Asset("PKGREF", "anim/dynamic/um_record_" .. name .. ".dyn"),
        },
        base_prefab = "record",
        type = "item",
        build_name_override = "um_record_" .. name,
        rarity = is_unlock and "ModLocked" or "ModMade",
        skin_tags = { "CRAFTABLE" },
    }

    if is_unlock then
        data.condition = {
            --no_gift = true
        }
    end

    table.insert(prefs, CreatePrefabSkin("ms_um_record_" .. name, data))
end

--I'll do this here as well just to keep it on one place.
--Credits goes to ADM the GOAT.


local old_record_init_fn = record_init_fn

record_init_fn = function(inst, build_name, trackname)
    local name = string.gsub(build_name, "um_record_", "")

    local um_track = record_defs[name]

    trackname = um_track and um_track or trackname

    old_record_init_fn(inst, build_name, trackname)
end



return unpack(prefs)
