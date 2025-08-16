local assets =
{
    Asset("ANIM", "anim/um_moss.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_moss")
    inst.AnimState:SetBuild("um_moss")
    inst.AnimState:PlayAnimation("idle")
    MakeInventoryFloatable(inst)
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 4.9
    inst.components.edible.sanityvalue = -5
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
	inst.components.edible:SetOnEatenFn(oneatenfn)
    inst:AddComponent("perishable")
	inst:AddComponent("tradable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST*2) -- 6 days
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    return inst
end

return Prefab("um_moss", fn, assets)
