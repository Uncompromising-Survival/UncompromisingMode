local assets =
{
    Asset("ANIM", "anim/um_meatcomb.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("um_meatcomb")
    inst.AnimState:SetBank("um_meatcomb")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("honeyed")

    MakeInventoryFloatable(inst, "med", nil, 0.78)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("um_meatcomb", fn, assets)