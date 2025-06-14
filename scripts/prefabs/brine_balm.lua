local assets =
{
    Asset("ANIM", "anim/brine_balm.zip"),
}

local function OnUse(inst, target)
    local health = target.components.health
    if not (health and health:IsDead()) then
        health:DoDelta(math.max(-TUNING.HEALING_MED, (health.currenthealth <= 20 and -health.currenthealth + 1 or -TUNING.HEALING_MED)), false, inst.prefab, nil, nil, true)
        health:DeltaPenalty(-.125)
        target:AddDebuff("confighealbuff", "confighealbuff", {amount = 70})
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("brine_balm")
    inst.AnimState:SetBuild("brine_balm")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", 0.05, 0.95)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(0)
    inst.components.healer.onhealfn = OnUse

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("brine_balm", fn, assets)