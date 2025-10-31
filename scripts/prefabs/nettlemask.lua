local assets =
{
    Asset("ANIM", "anim/hat_gasmask.zip"),
    Asset("ATLAS", "images/inventoryimages/gasmask.xml"),
    Asset("IMAGE", "images/inventoryimages/gasmask.tex"),
}



local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_gasmask", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner.AnimState:Show("HAIRFRONT")
    --owner:AddTag("toadstool")
    if not owner:HasTag("scp049") then
        owner:AddTag("has_gasmask")
        owner:AddTag("tiddlevirusmask")
    end
    inst.components.fueled:StartConsuming()
	
	if owner:IsValid() and owner.components.health and not owner.componens.health:IsDead() and owner.prefab ~= "wormwood" and owner.prefab ~= "willow" then
		owner.components.health:DoDelta(-10)
	end	
	
	if owner.prefab == "willow" or owner.prefab == "wormwood" then -- dynamically adjust depending on owner, wormwood and willow do not care, likely walter won't care
		inst.components.equippable.dapperness = 0
	else
		inst.components.equippable.dapperness = TUNING.CRAZINESS_MED
	end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:ClearOverrideSymbol("face")
    owner.AnimState:Hide("HAT")

    --owner:RemoveTag("toadstool")
    if not owner:HasTag("scp049") then
        owner:RemoveTag("has_gasmask")
        owner:RemoveTag("tiddlevirusmask")
    end

    inst.components.fueled:StopConsuming()
end


local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gasmaskhat")
    inst.AnimState:SetBuild("hat_gasmask")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("has_gasmask")
    inst:AddTag("goggles")
    inst:AddTag("donotautopick")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED*(2/3))
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
	
    inst.opentop = true

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL / 2)

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)
    return inst
end

return Prefab("nettlemask", fn, assets)
