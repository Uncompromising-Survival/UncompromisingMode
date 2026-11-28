local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")

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
    if isautumn and TheWorld.state.cycles >= UM_CONFIG.WEATHERHAZARD_AUTUMN and UM_CONFIG.TOADS then
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

local RETARGET_CANT_TAGS = {"frog","toadstool","toad", "bird", "invisible", "wall", "structure"}
env.AddSimPostInit(function()
    local _retargetfn = UMUpvalueHacker.TryGetUpvalue(Prefabs.frog.fn, "commonfn", "retargetfn")
    if _retargetfn then
        local _RETARGET_CANT_TAGS = UMUpvalueHacker.GetUpvalue(_retargetfn, "RETARGET_CANT_TAGS")
        local _LUNAR_RETARGET_CANT_TAGS = UMUpvalueHacker.GetUpvalue(_retargetfn, "LUNAR_RETARGET_CANT_TAGS")

        for i, TAG in ipairs(RETARGET_CANT_TAGS) do
            table.insert(_RETARGET_CANT_TAGS, TAG)
            table.insert(_LUNAR_RETARGET_CANT_TAGS, TAG)
        end
    end
end)

local DIET = {FOODGROUP.OMNI, FOODTYPE.HORRIBLE, FOODTYPE.RAW}
local function FrogFunctions(inst)
    inst:AddTag("frogimmunity")

    if not TheWorld.ismastersim then return end

    local eater = inst.components.eater or inst:AddComponent("eater")
    if eater then
        eater:SetDiet(DIET, DIET)
        eater:SetStrongStomach(true) -- can eat monster meat!
    end

    if not inst.components.inventory then
        inst:AddComponent("inventory")
    end

    --[[local um_dynamic_digester = inst.components.um_dynamic_digester or inst:AddComponent("um_dynamic_digester")
    if um_dynamic_digester then
        um_dynamic_digester.digesttime = 5
        um_dynamic_digester.digest_per = 20
    end]]
end

env.AddPrefabPostInit("frog", function(inst)
    FrogFunctions(inst)

    if not TheWorld.ismastersim then return end

    inst.TurnIntoToad = OnIsAutumn
    inst:WatchWorldState("isautumn", inst.TurnIntoToad)
    if TheWorld.state.isautumn then
        inst:TurnIntoToad(true)
    end
end)

env.AddPrefabPostInit("lunarfrog", FrogFunctions)
env.AddPrefabPostInit("uncompromising_toad", FrogFunctions)