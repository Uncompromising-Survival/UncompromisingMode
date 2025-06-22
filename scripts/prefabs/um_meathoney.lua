local assets =
{
    Asset("ANIM", "anim/um_meathoney.zip"),
}

local prefabs =
{
    "spoiled_food",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("um_meathoney")
    inst.AnimState:SetBank("um_meathoney")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("honeyed")

    MakeInventoryFloatable(inst, "med", nil, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 9.8
	inst.components.edible.sanityvalue = -5

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERSLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("um_meathoney", fn, assets, prefabs)