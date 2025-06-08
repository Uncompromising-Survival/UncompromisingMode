local assets =
{
    Asset("ANIM", "anim/slurtle_slime.zip"),
}

local prefabs =
{
    "explode_small",
}

TUNING.SNAILDRAKE_EXPLODE_DAMAGE = 50

SetSharedLootTable('snaildrake_explosion',
{
    {'houndfire',   1.0},
    {'houndfire',   1.0},
    {'houndfire',   1.0},
})

-- Spawn an explosion and spew fire around the Snaildrake.
local function InitExplode(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("explode_small").Transform:SetPosition(x, y, z)
    inst.components.lootdropper:DropLoot(Vector3(x, y, z))
    inst.components.explosive:OnBurnt()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("explosive")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeSmallBurnable(inst, 0)
	MakeSmallPropagator(inst)
    --V2C: Remove default OnBurnt handler, as it conflicts with
    --explosive component's OnBurnt handler for removing itself
    inst.components.burnable:SetOnBurntFn(nil)

    inst:AddComponent("explosive")
    inst.components.explosive.explosivedamage = TUNING.SNAILDRAKE_EXPLODE_DAMAGE
    inst.components.explosive.buildingdamage = 1
    inst.components.explosive.lightonexplode = false

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('snaildrake_explosion')
    inst.components.lootdropper.min_speed = 2
    inst.components.lootdropper.max_speed = 4

    inst.snaildrake = nil

    inst:DoTaskInTime(0, InitExplode)

    return inst
end

return Prefab("snaildrake_explosion", fn, assets, prefabs)
