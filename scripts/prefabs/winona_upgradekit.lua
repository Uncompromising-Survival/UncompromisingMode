require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/mastupgrade_lightningrod.zip"),
}

local prefabs =
{
    "mastupgrade_lightningrod_top",
    "mastupgrade_lightningrod_fx",
    "collapse_small",
}

local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mastupgrade_lightningrod_item")
    inst.AnimState:SetBuild("mastupgrade_lightningrod")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst:AddTag("toolbox_item")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(false)

    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = UPGRADETYPES.ELECTRICAL
    inst.components.upgrader.upgradevalue = 2--hm

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("winona_upgradekit_electrical", itemfn, assets, prefabs)
