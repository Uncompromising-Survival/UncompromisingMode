local assets =
{
    Asset("ANIM", "anim/um_moss.zip"),
}
local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS

local function GetFertilizerKey(inst)
    return inst.prefab
end

local function fertilizerresearchfn(inst)
    return inst:GetFertilizerKey()
end

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
	MakeDeployableFertilizerPristine(inst)

    inst:AddTag("fertilizerresearchable")

    inst.GetFertilizerKey = GetFertilizerKey
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL / 2
    inst.components.edible.sanityvalue = TUNING.SANITY_SUPERTINY
    inst.components.edible.foodtype = FOODTYPE.UM_HORRIBLE_VEGGIE
    inst.components.edible.secondaryfoodtype = FOODTYPE.UM_MOSS

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

	inst:AddComponent("tradable")
	
    inst:AddComponent("fertilizerresearchable")
    inst.components.fertilizerresearchable:SetResearchFn(fertilizerresearchfn)
	
	local fertilizer = inst:AddComponent("fertilizer")
	fertilizer.fertilizervalue = TUNING.SOILAMENDER_FERTILIZE_MED
	fertilizer.soil_cycles = TUNING.SOILAMENDER_SOILCYCLES_MED
	fertilizer.withered_cycles = TUNING.SOILAMENDER_WITHEREDCYCLES_MED
	fertilizer:SetNutrients(FERTILIZER_DEFS.soil_amender_med.nutrients)
			
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    MakeDeployableFertilizer(inst)
    MakeHauntableLaunchAndIgnite(inst)
    return inst
end

return Prefab("um_moss", fn, assets)