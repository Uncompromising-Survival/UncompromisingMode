local assets =
{
    Asset("ANIM", "anim/um_thulecite_razor.zip"),
    Asset("ANIM", "anim/razor.zip"),
    Asset("ANIM", "anim/swap_razor.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("razor")
    inst.AnimState:SetBuild("um_thulecite_razor")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", 0.08, {0.9, 0.7, 0.9}, true, -2, {sym_build = "swap_razor"})
    inst:AddTag("donotautopick")
    inst:AddTag("extra_shaver")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("shaver")

    if TUNING.DSTU.SHAVE_MODE then
        local finiteuses = inst:AddComponent("finiteuses")
        finiteuses:SetMaxUses(200)
        finiteuses:SetUses(200)
        finiteuses:SetConsumption(ACTIONS.SHAVE, 1)
        finiteuses:SetOnFinished(inst.Remove)
    end

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("um_thulecite_razor", fn, assets)