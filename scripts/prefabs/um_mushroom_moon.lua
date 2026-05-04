local assets =
{
    Asset("ANIM", "anim/grass.zip"),
}


local function onpickedfn(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked")
end

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end


local function onregenfn(inst)
    inst.components.pickable.caninteractwith = false -- Wait for the mushroom to become visible.

    if inst.data.open_time == TheWorld.state.cavephase then
        open(inst)
    else
        inst.AnimState:PushAnimation("inground", false)
        inst:DoTaskInTime(.25, function() inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_down") end )
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("mushrooms")
    inst.AnimState:SetBuild("mushrooms")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.data = data

    inst:AddComponent("inspectable")


    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp(data.pickloot, nil)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    --inst.components.pickable.quickpick = true

    inst.rain = 0

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(function(inst, chopper)
        if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab("moon_cap")
        end

        inst.components.lootdropper:SpawnLootPrefab("moon_cap")
        inst:Remove()
    end)
    inst.components.workable:SetWorkLeft(1)

    --inst:AddComponent("transformer")
    --inst.components.transformer:SetTransformWorldEvent("isfullmoon", true)
    --inst.components.transformer:SetRevertWorldEvent("isfullmoon", false)
    --inst.components.transformer:SetOnLoadCheck(testfortransformonload)
    --inst.components.transformer.transformPrefab = data.transform_prefab

    AddToRegrowthManager(inst)
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)


    --[[
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHauntMush)

    inst:WatchWorldState("iscave"..data.open_time, OnIsOpenPhase)

    inst:DoPeriodicTask(TUNING.SEG_TIME, checkregrow, TUNING.SEG_TIME + math.random()*TUNING.SEG_TIME)

    if data.open_time == TheWorld.state.cavephase then
        inst.AnimState:PlayAnimation(data.animname)
        inst.components.pickable.caninteractwith = true
    else
        inst.AnimState:PlayAnimation("inground")
        inst.components.pickable.caninteractwith = false
    end]]

    inst.OnSave = onsave
    inst.OnLoad = onload
        return inst
    end

    return inst
end

return Prefab(name, fn, assets)