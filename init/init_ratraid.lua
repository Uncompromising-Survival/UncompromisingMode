local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddPrefabPostInit("forest", function(inst)
    inst:AddComponent("ratcheck")
end)

env.AddPrefabPostInit("cave", function(inst)
    --inst:AddComponent("ratcheck")
end)
--[[
local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

for k, v in pairs(PLANT_DEFS) do
    env.AddPrefabPostInit(v, function (inst)
        if not TheWorld.ismastersim then
            return
        end

        local function OnPicked_Raid(inst, doer)
            if doer ~= nil and not inst.is_oversized and inst:HasTag("farm_plant_killjoy") and math.random() < 0.05 then
                TheWorld:PushEvent("activeraid", {container = inst, doer = doer, amount = 1})
            end
            
            return inst._OldOnPicked(inst, doer)
        end

        if inst.components.pickable ~= nil then
            inst._OldOnPicked = inst.components.pickable.onpickedfn
            inst.components.pickable.onpickedfn = OnPicked_Raid
        end
    end)
end]]

local function PushRatRaidContainer(inst)
    local container = inst.components.container
    if container then
        local _OnClose = container.onclosefn
        local function onclose_raid(inst, doer, ...)
            --Rat Raid
            if not inst:HasTag("burnt") and doer and doer:HasTag("player") then
                --inst:DoTaskInTime(0, ActiveRaid, doer)
                TheWorld:PushEvent("activeraid", {container = inst, doer = doer, amount = 1})
            end
            return _OnClose(inst, doer, ...)
        end
        container.onclosefn = onclose_raid
    end
end

local function PushRatRaidStewer(inst)
    local stewer = inst.components.stewer
    if stewer then
        local _OnHarvest = stewer.onharvest
        local function onharvest_raid(inst, ...)
            if not inst:HasTag("burnt") then
                TheWorld:PushEvent("activeraid", {container = inst, amount = 1})
            end
            return _OnHarvest(inst, ...)
        end
        stewer.onharvest = onharvest_raid
    end
end

local containers = {"treasurechest", "wardrobe", "icebox", "dragonflychest", "saltbox"}
for _, prefab in pairs(containers) do
    env.AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        PushRatRaidContainer(inst)
    end)
end

env.AddPrefabPostInit("dragonflychest", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local function killrat(inst, data)
        data.rat = data.doer or data.worker
        if data.rat and data.rat:HasTag("raidrat") and data.rat.components.health then
            data.rat.components.health:Kill()
        end
    end

    inst:ListenForEvent("worked", killrat)
end)

local stewers = {"cookpot", "portablecookpot", "icebox", "dragonflychest", "saltbox"}
for _, prefab in pairs(stewers) do
    env.AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        PushRatRaidStewer(inst)
    end)
end