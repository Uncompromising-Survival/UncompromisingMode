local assets =
{
    Asset("ANIM", "anim/meat_rack_food.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("meat_human")
    inst.AnimState:SetBuild("meat_human")
    inst.AnimState:PlayAnimation("raw")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()
	
    inst:AddTag("show_spoilage")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/skeletonmeat.xml"

    inst:AddComponent("perishable")
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("skeletonmeat", fn, assets)
