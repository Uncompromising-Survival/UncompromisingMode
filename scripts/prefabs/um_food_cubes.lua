local function onperish(inst)
    inst:Remove()
end

local function fncommon(anim, healthval, hungerval, sanityval)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
	
    inst:AddTag("cattoy")

    inst.AnimState:SetBank("um_food_cube")
    inst.AnimState:SetBuild("um_food_cube")
    inst.AnimState:PlayAnimation(anim)
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = healthval
    inst.components.edible.hungervalue = hungerval
    inst.components.edible.sanityvalue = sanityval
    inst.components.edible.foodtype = FOODTYPE.GENERIC

	inst:AddComponent("tradable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(onperish)

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

local function meatfn()
    local inst = fncommon("um_meat_cube", 0, 2, 0)

    inst.pickupsound = "squidgy"

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.edible.foodtype = FOODTYPE.MEAT

    return inst
end

local function monsterfn()
    local inst = fncommon("um_monster_cube", -1, 1, -1)

    inst.pickupsound = "squidgy"
	
	inst:AddTag("monstermeat")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.secondaryfoodtype = FOODTYPE.MONSTER

    return inst
end

local function veggiefn()
    local inst = fncommon("um_veggie_cube", 1, 1, 0)

    inst.pickupsound = "vegetation_grassy"

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    return inst
end

local function sugarfn()
    local inst = fncommon("um_sugar_cube", 0, 1, 1)

    inst.pickupsound = "rock"

    inst:AddTag("honeyed")
	
    if not TheWorld.ismastersim then
        return inst
    end
	
    --inst.components.edible.foodtype = FOODTYPE.GOODIE

    return inst
end

local function roughagefn()
    local inst = fncommon("um_roughage_cube", 1, 1, 0)
	
	inst.pickupsound = "wood"

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL
	
    inst.components.edible.foodtype = FOODTYPE.ROUGHAGE
	inst.components.edible.secondaryfoodtype = FOODTYPE.WOOD

    return inst
end

local function blandfn()
    local inst = fncommon("um_roughage_cube", 0, 1, 0)

    inst.pickupsound = "vegetation_firm"

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("um_meat_cube", meatfn),
		Prefab("um_monster_cube", monsterfn),
		Prefab("um_veggie_cube", veggiefn),
		Prefab("um_sugar_cube", sugarfn),
		Prefab("um_roughage_cube", roughagefn),
		Prefab("um_bland_cube", blandfn)