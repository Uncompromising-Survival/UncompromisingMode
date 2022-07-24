local assets =
{
    Asset("ANIM", "anim/charcoal.zip"),
}

local function ontaken(inst, taker)
    print("ontaken")--THIS ISNT EVEN PRINTING, WHAT.
    local bottle = SpawnPrefab("messagebottleempty")

    local owner = taker ~= nil and 
					taker.components.inventoryitem and 
					taker.components.inventoryitem:GetGrandOwner() or nil
	
	if owner ~= nil and owner.components.inventory ~= nil then
		local x,y,z = owner.Transform:GetWorldPosition()
		bottle.Transform:SetPosition(x,y,z)
        owner.components.inventory:GiveItem(bottle)
	else
		Launch2(bottle, taker, 1.5, 1, 3, .75)
	end

    --inst:Remove()
end

local function sludge_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("charcoal")
    inst.AnimState:SetBuild("charcoal")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("boat_patch")

    MakeInventoryFloatable(inst, "med", 0.05, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    --inst.components.fuel:SetOnTakenFn(ontaken)-- :)

    inst:AddComponent("boatpatch")
    inst.components.boatpatch.patch_type = "sludge"

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = MATERIALS.WOOD
    inst.components.repairer.healthrepairvalue = TUNING.REPAIR_TREEGROWTH_HEALTH
    inst.components.repairer.boatrepairsound = "waterlogged1/common/use_figjam"

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    return inst
end

local function onactiveitem(item, inst)
    item.components.inventoryitem:SetOwner(inst)
end

local function oil_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bottle")
    inst.AnimState:SetBuild("bottle")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.05, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    inst.components.fuel.fueltype = FUELTYPE.CAVE
    inst.components.fuel:SetOnTakenFn(ontaken)-- :)

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/sludge.xml"
    inst.components.inventoryitem.onactiveitemfn = onactiveitem

    return inst
end

local function bucket_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("driftwood_log")
    inst.AnimState:SetBuild("driftwood_log")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("allow_action_on_impassable")

    MakeInventoryFloatable(inst, "med", 0.05, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/sludge_cork.xml"

    inst:AddComponent("tradable")
    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = UPGRADETYPES.SLUDGE_CORK
    inst.components.upgrader.upgradevalue = 2--hm

    return inst
end

return Prefab("sludge", sludge_fn, assets), Prefab("sludge_oil", oil_fn, assets), Prefab("sludge_cork", bucket_fn, assets)
