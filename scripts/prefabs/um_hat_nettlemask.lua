local assets =
{
    Asset("ANIM", "anim/hat_nettlemask.zip"),
    Asset("ATLAS", "images/inventoryimages/um_hat_nettlemask.xml"),
    Asset("IMAGE", "images/inventoryimages/um_hat_nettlemask.tex"),
}

local DebuffDurationWearer = 10

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_nettlemask", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")
    owner.AnimState:Show("HAIRFRONT")
	
    if not owner:HasTag("scp049") then
        owner:AddTag("has_gasmask")
        owner:AddTag("tiddlevirusmask")
    end

	
	--AXE Nettle harming the Player... similar to mantle.
    owner:AddTag("PyreToxinImmune")
    owner:AddTag("SmolderSporeAvoid")
    owner:AddTag("MagmaCaveFriend")
    if inst.fx ~= nil then
        inst.fx:Remove()
    end

    -- Debuff wearer when equipped.
    if owner:IsValid() and not owner:HasAnyTag("INLIMBO", "noattack") then
        inst.components.perishable:ReducePercent(0.05) -- 20 equips to fully spoil, to stop winter cheese, I think. -C
        owner:AddDebuff("umdebuff_pyre_toxin_armor_wearer", "umdebuff_pyre_toxin", DebuffDurationWearer)
    end -- I am okay with discussing on how to nerf the mantle if it's truly overpowered. But I am unsure if overheating the player is the right move.
	if owner:IsValid() and owner.components.health and not owner.components.health:IsDead() and owner.prefab ~= "wormwood" and owner.prefab ~= "willow" then
		owner.components.health:DoDelta(-10)
	end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:ClearOverrideSymbol("face")
    owner.AnimState:Hide("HAT")

    if not owner:HasTag("scp049") then
        owner:RemoveTag("has_gasmask")
        owner:RemoveTag("tiddlevirusmask")
    end


	
	--AXE Removal of Nettle properties
    owner:RemoveTag("PyreToxinImmune")
    owner:RemoveTag("SmolderSporeAvoid")
    owner:RemoveTag("MagmaCaveFriend")
	
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("catcoonhat")
    inst.AnimState:SetBuild("hat_nettlemask")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("has_gasmask")
    inst:AddTag("goggles")
    inst:AddTag("hat")
    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL -- It is not comfortable.

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.HORRIBLE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(4 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "goldnugget"

    MakeHauntableLaunch(inst)
    --------------------------------------------------------------
    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL / 2)


    return inst
end

return Prefab("um_hat_nettlemask", fn, assets)