local assets =
{
    Asset("ANIM", "anim/um_hat_leafwing.zip"),
    Asset("ATLAS", "images/inventoryimages/widowshead.xml"),
    Asset("IMAGE", "images/inventoryimages/widowshead.tex"),
}

local function Poof(inst,owner)
	if owner and owner.sg and owner.sg:HasStateTag("moving") then
		SpawnPrefab("oceantree_leaf_fx_chop").Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "um_hat_leafwing", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
	inst.pooftask = inst:DoPeriodicTask(3.66,function(inst) Poof(inst,owner) end)
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
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
	if inst.pooftask then
		inst.pooftask:Cancel()
		inst.pooftask = nil
	end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("catcoonhat")
    inst.AnimState:SetBuild("um_hat_leafwing")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("donotautopick")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
	
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
	inst.components.equippable.walkspeedmult = 1.15

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime((2 * TUNING.PERISH_TWO_DAY))
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    MakeHauntableLaunch(inst)
    --------------------------------------------------------------

    return inst
end


return Prefab("um_hat_leafwing", fn, assets)
