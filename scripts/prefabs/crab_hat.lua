local assets =
{
    Asset("ANIM", "anim/hat_snowgoggles.zip"),
    Asset("ATLAS", "images/inventoryimages/gasmask.xml"),
    Asset("IMAGE", "images/inventoryimages/gasmask.tex"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_gore_horn_swap_off", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    owner.AnimState:Hide("HEAD")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner:AddTag("expert_repairer")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner:RemoveTag("expert_repairer")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hat_gore_horn")
    inst.AnimState:SetBuild("hat_gore_horn")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hat")
    inst:AddTag("gore_horn")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    inst.components.floater:SetSize("med")
    inst.components.floater:SetVerticalOffset(0.1)
    inst.components.floater:SetScale(0.63)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/gore_horn_hat.xml"

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("crab_hat", fn, assets)