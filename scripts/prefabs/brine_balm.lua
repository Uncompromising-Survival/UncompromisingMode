local assets =
{
    Asset("ANIM", "anim/brine_balm.zip"),
}

local function OnUse(inst, target)
    local health = target.components.health
    if health and not health:IsDead() then
        local healamount = (TUNING.DSTU.DATES.APRIL_FOOLS or health.currenthealth - TUNING.HEALING_MED > 0) and TUNING.HEALING_MED or health.currenthealth - 1
        if healamount then
            health:DoDelta(-healamount, false, inst.prefab, nil, nil, true)
        end
        health:DeltaPenalty(-.125)
        target:AddDebuff("confighealbuff_"..inst.prefab, "confighealbuff", {time = 70})
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

    MakeInventoryFloatable(inst, "small", .05, .95)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

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