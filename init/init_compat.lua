--General inter-mod compatbility/integration features here.
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("woose", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local WOOSE_PATHFINDER_TILES_UM = {
        WORLD_TILES.UM_FLOODWATER,
        WORLD_TILES.UM_FLOODWATER_GROTTO,
        WORLD_TILES.UM_FLOODWATER_BROILING,
    }
    local function UMWooseSkillCheck(inst, data)
        if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("woose_ocean_2") then
            for _, tile in ipairs(WOOSE_PATHFINDER_TILES_UM) do
                inst.components.locomotor:SetFasterOnGroundTile(tile, true)
            end
        end
    end

    inst:ListenForEvent("onactivateskill_server", UMWooseSkillCheck)
    inst:ListenForEvent("ms_skilltreeinitialized", UMWooseSkillCheck)
end)

env.AddPrefabPostInit("wonderwhy", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("ignores_healthregen")
end)

env.AddPrefabPostInit("kris_m", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.eater:SetCanEatMoss()

    if inst.components.foodaffinity then
        inst.components.foodaffinity.favorite_foods = {
            ["um_moss"] = 4,
        }
    end
end)

env.AddPrefabPostInit("susie_m", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.eater:SetCanEatVeggieHorrible()
end)

env.AddPrefabPostInit("aphid", function(inst)
    if IsIslandOrVolcanoWorld() then
        inst:AddComponent("appeasement")
        inst.components.appeasement.appeasementvalue = TUNING.TOTAL_DAY_TIME
    end
end)

env.AddPrefabPostInit("shipwrecked", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if TUNING.DSTU.HEATWAVES then
        inst:AddComponent("um_heatwaves")
    end

    if env.GetModConfigData("rat_raids") then
        inst:AddComponent("ratcheck")
    end

    if TUNING.DSTU.STORMS then
        inst:AddComponent("um_stormspawner")
    end
end)

env.AddPrefabPostInit("volcanoworld", function(inst)
    if not TheWorld.ismastersim then
        return
    end
end)

--Scythe hacking. CBA to actually do this on the prefab, I'm just copying this from IA.
local HARVEST_AFTERFINDINGONEOFTAGS = { "pickable", "HACK_workable" }
local HARVEST_CANTTAGS              = { "INLIMBO", "FX" }
local HARVEST_ONEOFTAGS             = { "plant", "lichen", "oceanvine", "kelp" }

local function hacked(inst, data)
    for k, v in pairs(data.loot) do
        Launch(v, data.hacker, 1.5)
    end
    inst:RemoveEventCallback("hacked", hacked)
end

local function ScytheFunctions(inst)
    if not inst.DoScythe then return end
    local DoScythe_old = inst.DoScythe
    local function DoScythe(inst, target, doer, ...)
        if target.components.pickable or target.components.hackable then
            local harvested = nil
            local doer_pos = doer:GetPosition()
            local x, y, z = doer_pos:Get()

            local doer_rotation = doer.Transform:GetRotation()

            local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS * 1.2, nil, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
            for _, ent in pairs(ents) do
                if ent:IsValid() and ent:HasOneOfTags(HARVEST_AFTERFINDINGONEOFTAGS) and inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
                    if ent.components.pickable ~= nil then
                        inst:HarvestPickable(ent, doer)
                        harvested = true
                    elseif ent.components.hackable ~= nil then
                        local workamount = 3 * doer.components.workmultiplier:GetMultiplier(ACTIONS.HACK)
                        if ent.components.hackable.hacksleft <= workamount then
                            ent:ListenForEvent("hacked", hacked)
                        end
                        ent.components.hackable:Hack(doer, workamount, nil, nil, true)
                        harvested = true
                    end
                end
            end
            if harvested then
                inst:PushEvent("um_scythed", { doer = doer })
            end
        end

        return DoScythe_old(inst, target, doer, ...)
    end
    inst.DoScythe = DoScythe
end

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    ScytheFunctions(inst)
end)

local _makeemptyfn
local function makeemptyfn(inst, ...)
    inst.components.hackable.canbehacked = false
    return _makeemptyfn and _makeemptyfn(inst, ...)
end

local function makeemptyfn_hackable(inst)
    inst.components.pickable:MakeEmpty() -- This does everything for us
end

local _makebarrenfn
local function makebarrenfn(inst, ...)
    inst.components.hackable.canbehacked = false
    return _makebarrenfn and _makebarrenfn(inst, ...)
end

local function makebarrenfn_hackable(inst)
    inst.components.pickable:MakeBarren() -- This does everything for us
end

local _onpickedfn
local function onpickedfn(inst, ...)
    inst.components.hackable.canbehacked = false
    return _onpickedfn and _onpickedfn(inst, ...)
end

local function onfinishfn_hackable(inst, doer, loot)
    doer.SoundEmitter:PlaySound(inst.components.pickable.picksound or "dontstarve/wilson/harvest_sticks")

    inst.components.pickable:Pick(nil) -- Purposefully no valid doer given to avoid damage & double loot
end

local _onregenfn
local function onregenfn(inst, ...)
    inst.components.hackable:Regen()
    return _onregenfn and _onregenfn(inst, ...)
end

env.AddPrefabPostInit("hooded_fern", function(inst)
    if not TheWorld.ismastersim or not (IsSWEnabled() or IsHAMEnabled()) then return end

    if not inst.components.lootdropper then
        inst:AddComponent("lootdropper")
    end

    inst:AddComponent("hackable")
    inst.components.hackable:SetUp(nil)
    inst.components.hackable.max_cycles = 127 -- dirty, but realistically speaking, never reached anyways
    inst.components.hackable.cycles_left = 127
    inst.components.hackable.hacksleft = 1
    inst.components.hackable.maxhacks = 1

    if not _makeemptyfn then
        _makeemptyfn = inst.components.pickable.makeemptyfn
    end
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.hackable.makeemptyfn = makeemptyfn_hackable

    if not _makebarrenfn then
        _makebarrenfn = inst.components.pickable.makebarrenfn
    end
    inst.components.pickable.makebarrenfn = makebarrenfn
    inst.components.hackable.makebarrenfn = makebarrenfn_hackable

    if not _onpickedfn then
        _onpickedfn = inst.components.pickable.onpickedfn
    end
    inst.components.pickable.onpickedfn = onpickedfn

    inst.components.hackable.onfinishfn = onfinishfn_hackable

    if not _onregenfn then
        _onregenfn = inst.components.pickable.onregenfn
    end
    inst.components.pickable.onregenfn = onregenfn
end)

if IsSWEnabled() or IsHAMEnabled() then
    ACTIONS.HACK.mindistance = 2
end

env.AddPrefabPostInit("dragoon", function(inst)
    inst:AddTag("pyre_toxin_immune")
end)


--VERY WIP NO GOOD.
--WE HAVE PLANS FOR PROPER INTEGRATION, BUT THIS'LL DO FOR NOW
--These would run before its set on the prefabs, so we'll just do it on the respective prefabs

env.AddPrefabPostInit("rock_obsidian", function(inst)
    SetSharedLootTable("rock_obsidian", {
        { "obsidian",              1.0 },
        { "obsidian",              1.0 },
        { "obsidian",              0.5 },
        { "obsidian",              0.25 },
        { "obsidian",              0.25 },
        { "um_gemologyredgem1",    0.005 },
        { "um_gemologyredgem2",    0.005 },
        { "um_gemologybluegem1",   0.005 },
        { "um_gemologybluegem2",   0.005 },
        { "um_gemologygreengem1",  0.005 },
        { "um_gemologygreengem2",  0.005 },
        { "um_gemologyorangegem1", 0.005 },
        { "um_gemologyorangegem2", 0.005 },
        { "um_gemologypalegem1",   0.005 },
        { "um_gemologypalegem2",   0.005 },
    })
end)

env.AddPrefabPostInit("rock_charcoal", function(inst)
    SetSharedLootTable("rock_charcoal", {
        { "charcoal",              1.0 },
        { "charcoal",              1.0 },
        { "charcoal",              0.5 },
        { "charcoal",              0.25 },
        { "charcoal",              0.25 },
        { "flint",                 0.5 },
        { "um_gemologyredgem1",    0.005 },
        { "um_gemologyredgem2",    0.005 },
        { "um_gemologybluegem1",   0.005 },
        { "um_gemologybluegem2",   0.005 },
        { "um_gemologypurplegem1", 0.005 },
        { "um_gemologypurplegem2", 0.005 },
        { "um_gemologygreengem1",  0.005 },
        { "um_gemologygreengem2",  0.005 },
        { "um_gemologyorangegem1", 0.005 },
        { "um_gemologyorangegem2", 0.005 },
        { "um_gemologyyellowgem1", 0.005 },
        { "um_gemologyyellowgem2", 0.005 },
        { "um_gemologypalegem1",   0.005 },
        { "um_gemologypalegem2",   0.005 },
    })
end)


env.AddPrefabPostInit("dragoonegg", function(inst)
    SetSharedLootTable('dragoonegg',
        {
            { 'flint',                 1.0 },
            { 'flint',                 0.5 },
            { 'rocks',                 1.0 },
            { 'rocks',                 0.5 },
            { 'rocks',                 0.3 },
            { 'obsidian',              0.5 },
            { 'obsidian',              0.5 },
            { "um_gemologyredgem1",    0.005 },
            { "um_gemologyredgem2",    0.005 },
            { "um_gemologybluegem1",   0.005 },
            { "um_gemologybluegem2",   0.005 },
            { "um_gemologygreengem1",  0.005 },
            { "um_gemologygreengem2",  0.005 },
            { "um_gemologyorangegem1", 0.005 },
            { "um_gemologyorangegem2", 0.005 },
            { "um_gemologypurplegem1", 0.005 },
            { "um_gemologypurplegem2", 0.005 },
            { "um_gemologyyellowgem1", 0.005 },
            { "um_gemologyyellowgem2", 0.005 },
            { "um_gemologypalegem1",   0.005 },
            { "um_gemologypalegem2",   0.005 },
        })
end)

local magma_gem_loot = {
    ["um_gemologyredgem1"] = 0.005,
    ["um_gemologyredgem2"] = 0.005,

    ["um_gemologybluegem1"] = 0.005,
    ["um_gemologybluegem2"] = 0.005,

    ["um_gemologypurplegem1"] = 0.005,
    ["um_gemologypurplegem2"] = 0.005,

    ["um_gemologyorangegem1"] = 0.005,
    ["um_gemologyorangegem2"] = 0.005,

    ["um_gemologygreengem1"] = 0.005,
    ["um_gemologygreengem2"] = 0.005,

    ["um_gemologyyellowgem1"] = 0.005,
    ["um_gemologyyellowgem2"] = 0.005,

    ["um_gemologypalegem1"] = 0.005,
    ["um_gemologypalegem2"] = 0.005,
}

local magma_rocks = {
    "magmarock_gold",
    "magmarock"
}

for k, v in pairs(magma_rocks) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst.loot = MergeMaps(inst.loot, magma_gem_loot)
    end)
end

if IsSWEnabled() or IsHAMEnabled() then
    local TreasureLootList = GetTreasureLootDefinitionTable()
    --respect IA's config
    if IA_CONFIG ~= nil and IA_CONFIG.slotmachineloot and SLOTMACHINE_LOOT ~= nil and TreasureLootList ~= nil then
        SLOTMACHINE_LOOT.goodspawns["slot_gemology_mushroom"] = 1
        SLOTMACHINE_LOOT.actions["slot_gemology_mushroom"] = { treasure = "slot_gemology_mushroom", }
        TreasureLootList["slot_gemology_mushroom"] =
        {
            slot_loot_quality = "good",
            loot =
            {
                um_gemology_geode_red = 1,
                um_gemology_geode_green = 1,
                um_gemology_geode_blue = 1,
            },
            num_random_loot = 3,
            random_loot =
            {
                blue_cap = 1,
                red_cap = 1,
                green_cap = 1,
                spore_small = 1,
                spore_medium = 1,
                spore_tall = 1,
            },
        }

        TreasureLootList["slot_mooncaps"].loot.um_gemology_geode_glass = 2

        SLOTMACHINE_LOOT.goodspawns["slot_gemology_lobster"] = 1
        SLOTMACHINE_LOOT.actions["slot_gemology_lobster"] = { treasure = "slot_gemology_lobster", }
        TreasureLootList["slot_gemology_lobster"] =
        {
            slot_loot_quality = "good",
            loot =
            {
                um_gemology_geode_lobster = 2,
                rocks = 5,
                goldnugget = 3,
            },
            num_random_loot = 3,
            random_loot =
            {
                rocks = 1,
                flint = 1,
                goldnugget = 1,
                guano = 1,
                slurtle_shellpieces = 1,
                um_gemology_geode_lobster = 0.5,
            },
        }

        SLOTMACHINE_LOOT.goodspawns["slot_gemology_guano"] = 1
        SLOTMACHINE_LOOT.actions["slot_gemology_guano"] = { treasure = "slot_gemology_guano", }
        TreasureLootList["slot_gemology_guano"] =
        {
            slot_loot_quality = "good",
            loot =
            {
                rocks = 2,
                flint = 2,
                goldnugget = 1,
                guano = 3,
                um_gemology_geode_guano = 2
            },
            num_random_loot = 3,
            random_loot =
            {
                rocks = 1,
                flint = 1,
                goldnugget = 1,
                guano = 1,
                um_gemology_geode_guano = 0.5,
            },
        }

        TreasureLootList["gears"].loot.um_gemology_geode_ruins = 2

        TreasureLootList["slot_obsidian"].loot.um_gemology_geode_vent = 1
        TreasureLootList["slot_obsidian"].loot.um_fyrite = 3
    end
end
