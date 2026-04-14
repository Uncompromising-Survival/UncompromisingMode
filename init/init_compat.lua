--General inter-mod compatbility/integration features here.
local env = env
GLOBAL.setfenv(1, GLOBAL)

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

-- I don't know where else to put this
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

local DoScythe_old

local function DoScythe(inst, target, doer, ...)
    if target.components.pickable or target.components.hackable then
        local doer_pos = doer:GetPosition()
        local x, y, z = doer_pos:Get()

        local doer_rotation = doer.Transform:GetRotation()

        local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS * 1.2, nil, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
        for _, ent in pairs(ents) do
            if ent:IsValid() and ent:HasOneOfTags(HARVEST_AFTERFINDINGONEOFTAGS) and inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
                if ent.components.pickable ~= nil then
                    inst:HarvestPickable(ent, doer)
                elseif ent.components.hackable ~= nil then
                    local workamount = 3 * doer.components.workmultiplier:GetMultiplier(ACTIONS.HACK)
                    if ent.components.hackable.hacksleft <= workamount then
                        ent:ListenForEvent("hacked", hacked)
                    end
                    ent.components.hackable:Hack(doer, workamount, nil, nil, true)
                end
            end
        end
    end

    return DoScythe_old(inst, target, doer, ...)
end

env.AddPrefabPostInit("jawed_scythe", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    if not DoScythe_old then
        DoScythe_old = inst.DoScythe
    end
    inst.DoScythe = DoScythe
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
    inst:AddTag("PyreToxinImmune")
end)
