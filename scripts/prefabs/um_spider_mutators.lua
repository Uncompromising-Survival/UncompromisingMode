local prefabs = {}
local mutator_targets =
{
    { name = "trapdoor", anim = "trapdoor", mutation = "spider_trapdoor" },
    { name = "trapdoor_hooded", anim = "hooded", mutation = "spider_trapdoor_hooded" },
}

local function MakeMutatorFn(mutator_target)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_spider_mutators")
    inst.AnimState:SetBuild("um_spider_mutators")
    inst.AnimState:PlayAnimation(mutator_target.anim)

    MakeInventoryFloatable(inst)

    inst:AddTag("spidermutator")
    inst:AddTag("monstermeat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	
    inst:AddComponent("stackable")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.secondaryfoodtype = FOODTYPE.MONSTER
    inst.components.edible.healthvalue = -TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL

    inst:AddComponent("spidermutator")
    inst.components.spidermutator:SetMutationTarget(mutator_target.mutation)

    MakeHauntableLaunch(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)

    return inst
end

for i, mutator_target in ipairs(mutator_targets) do
    table.insert(prefabs, mutator_target.mutation)
end

local mutator_prefabs = {}
for i, mutator_target in ipairs(mutator_targets) do
    table.insert(mutator_prefabs, Prefab("mutator_" .. mutator_target.name, function() return MakeMutatorFn(mutator_target) end))
end

return unpack(mutator_prefabs)