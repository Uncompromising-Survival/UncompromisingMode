local assets = {
    Asset("ANIM", "anim/um_magnifier.zip"),
}

local function OnScanned(inst, target, doer)
    inst.components.finiteuses:Use(1)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("um_magnifier")
    inst.AnimState:SetBank("um_magnifier")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("gemologyscanner")
    inst:AddTag("tradeable")

    MakeInventoryFloatable(inst, "med", nil, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("gemologyscanner")
    inst.components.gemologyscanner:SetOnScannedFn(OnScanned)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(20)
    inst.components.finiteuses:SetUses(20)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("um_magnifier", fn, assets)
