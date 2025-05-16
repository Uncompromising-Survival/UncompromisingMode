local assets =
{
    Asset("ANIM", "anim/trinket_wathom1.zip"),
}


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("trinket_wathom1")
    inst.AnimState:SetBuild("trinket_wathom1")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	
	MakeHauntableLaunch(inst)

    return inst
end

return Prefab("trinket_wathom1", fn, assets)
