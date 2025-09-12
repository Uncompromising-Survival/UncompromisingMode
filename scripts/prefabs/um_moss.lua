local assets =
{
    Asset("ANIM", "anim/um_moss.zip"),
}
local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
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

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL / 2
    inst.components.edible.sanityvalue = TUNING.SANITY_SUPERTINY
    inst.components.edible.foodtype = FOODTYPE.UM_GROSS_VEGGIE

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

	inst:AddComponent("tradable")
	
	
	local fertilizer = inst:AddComponent("fertilizer")
	fertilizer.fertilizervalue = TUNING.SOILAMENDER_FERTILIZE_MED
	fertilizer.soil_cycles = TUNING.SOILAMENDER_SOILCYCLES_MED
	fertilizer.withered_cycles = TUNING.SOILAMENDER_WITHEREDCYCLES_MED
	fertilizer:SetNutrients(FERTILIZER_DEFS.soil_amender_med.nutrients)
			
    MakeHauntableLaunchAndPerish(inst)
    return inst
end

return Prefab("um_moss", fn, assets)