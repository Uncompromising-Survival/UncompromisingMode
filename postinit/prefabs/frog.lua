local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
--[[SetSharedLootTable('toad',
{
    {'sporecloud_toad', .5},
})

SetSharedLootTable('frog',
{
})
]]

local function DoSporeExplosion(inst)
    if math.random() <= .5 then
        local sporecloud = SpawnPrefab("sporecloud_toad")
        sporecloud.Transform:SetPosition(inst.Transform:GetWorldPosition())
        sporecloud.owner = inst
    end
end

local function OnIsAutumn(inst, isautumn)
    if isautumn and TheWorld.state.cycles >= TUNING.DSTU.WEATHERHAZARD_START_DATE_AUTUMN and TUNING.DSTU.TOADS then
        if not inst.um_toad then
            inst.AnimState:SetBuild("frog_yellow_build")
            inst:SetPrefabNameOverride("uncompromising_toad")
            inst:ListenForEvent("death", DoSporeExplosion)
            inst.um_toad = true
        end
    else
        inst.AnimState:SetBuild("frog")
        inst:SetPrefabNameOverride("frog")
        inst:RemoveEventCallback("death", DoSporeExplosion)
        inst.um_toad = nil
    end
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "frog","toadstool","toad", "merm", "bird", "invisible", "wall", "structure" }
local LUNAR_RETARGET_CANT_TAGS = { "merm", "lunar_aligned", "frog","toadstool", "toad", "bird", "invisible", "wall", "structure" }

local function NewRetargetfn(inst)
    if not inst.components.health:IsDead() and (inst.components.sleeper == nil or inst.components.sleeper ~= nil and not inst.components.sleeper:IsAsleep()) then
        local target_dist = inst.islunar and TUNING.LUNARFROG_TARGET_DIST or TUNING.FROG_TARGET_DIST
        local cant_tags   = inst.islunar and LUNAR_RETARGET_CANT_TAGS or RETARGET_CANT_TAGS
        
        return FindEntity(inst, target_dist, function(guy) 
            if not guy.components.health:IsDead() then
                return guy.components.inventory ~= nil and inst._um_oldretarget
            end
        end,
        RETARGET_MUST_TAGS, -- see entityreplica.lua
        cant_tags -- see entityreplica.lua
        )
    end
end

env.AddPrefabPostInit("frog", function (inst)
    inst:AddTag("frogimmunity")

    if not TheWorld.ismastersim then return end

    inst.TurnIntoToad = OnIsAutumn
    inst:WatchWorldState("isautumn", inst.TurnIntoToad)
    if TheWorld.state.isautumn then
        inst:TurnIntoToad(true)
    end

    if inst.components.combat ~= nil then
        if inst.components.combat.targetfn ~= nil then
            inst._um_oldretarget = inst.components.combat.targetfn
        
            inst.components.combat:SetRetargetFunction(2, NewRetargetfn)
        end
    end

    local eater = inst.components.eater or inst:AddComponent("eater")
    if eater then
        eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
        eater:SetCanEatHorrible()
        eater:SetCanEatRaw()
        eater.strongstomach = true -- can eat monster meat!
    end

    if not inst.components.inventory then
        inst:AddComponent("inventory")
    end

    --[[local um_dynamic_digester = inst.components.um_dynamic_digester or inst:AddComponent("um_dynamic_digester")
    if um_dynamic_digester then
        um_dynamic_digester.digesttime = 5
        um_dynamic_digester.digest_per = 20
    end]]
end)

env.AddPrefabPostInit("uncompromising_toad", function (inst)
    inst:AddTag("frogimmunity")

    if not TheWorld.ismastersim then return end

    local eater = inst.components.eater or inst:AddComponent("eater")
    if eater then
        eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
        eater:SetCanEatHorrible()
        eater:SetCanEatRaw()
        eater.strongstomach = true -- can eat monster meat!
    end

    if not inst.components.inventory then
        inst:AddComponent("inventory")
    end

    --[[local um_dynamic_digester = inst.components.um_dynamic_digester or inst:AddComponent("um_dynamic_digester")
    if um_dynamic_digester then
        um_dynamic_digester.digesttime = 5
        um_dynamic_digester.digest_per = 20
    end]]
end)

env.AddPrefabPostInit("lunarfrog", function (inst)
    inst:AddTag("frogimmunity")

    if not TheWorld.ismastersim then return end

    if inst.components.combat ~= nil then
        if inst.components.combat.targetfn ~= nil then
            inst._um_oldretarget = inst.components.combat.targetfn
        
            inst.components.combat:SetRetargetFunction(2, NewRetargetfn)
        end
    end

    local eater = inst.components.eater or inst:AddComponent("eater")
    if eater then
        eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
        eater:SetCanEatHorrible()
        eater:SetCanEatRaw()
        eater.strongstomach = true -- can eat monster meat!
    end

    if not inst.components.inventory then
        inst:AddComponent("inventory")
    end

    --[[local um_dynamic_digester = inst.components.um_dynamic_digester or inst:AddComponent("um_dynamic_digester")
    if um_dynamic_digester then
        um_dynamic_digester.digesttime = 5
        um_dynamic_digester.digest_per = 20
    end]]
end)