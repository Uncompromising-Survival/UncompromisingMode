local assets =
{
    Asset("ANIM", "anim/um_hat_rime.zip"),
}

local function onperish(inst)
    local owner = inst.components.inventoryitem.owner
    if owner then
        if owner.components.moisture then
            owner.components.moisture:DoDelta(2 * 4)
        elseif owner.components.inventoryitem then
            owner.components.inventoryitem:AddMoisture(4 * 4)
        end
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, y, z, 4 * TUNING.ICE_MELT_GROUND_MOISTURE_AMOUNT)

        inst.persists = false
        inst.components.inventoryitem.canbepickedup = false
    end
    inst:Remove()
end

local function TemperatureChange(owner)
	local hat = owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	if hat and owner.components.temperature then
		local temp = owner.components.temperature.current
		local defense = 0.85 - 0.01*(temp)
		if defense < 0.4 then
			defense = 0.4
		elseif defense > 0.75 then
			defense = 0.75
		end
		hat.components.armor:InitIndestructible(defense)
	end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "um_hat_rime", "swap_hat")

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

	owner:ListenForEvent("temperaturedelta", TemperatureChange)
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
	owner:RemoveEventCallback("temperaturedelta",TemperatureChange)
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("catcoonhat")
    inst.AnimState:SetBuild("um_hat_rime")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("donotautopick")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
	inst:AddTag("hide_percentage")
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

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime((3.5 * TUNING.PERISH_TWO_DAY))
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(onperish)

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

	inst:AddComponent("armor")
	inst.components.armor:InitIndestructible(0.6)
		
    MakeHauntableLaunch(inst)
    --------------------------------------------------------------

    return inst
end

return Prefab("um_hat_rime", fn, assets)