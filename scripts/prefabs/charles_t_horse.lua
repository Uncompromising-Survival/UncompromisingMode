local assets =
{
    Asset("ANIM", "anim/charles_t_horse.zip"),
    Asset("ANIM", "anim/swap_charles.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_charles", "swap_charles")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
    end
    inst._owner = owner
    inst:ListenForEvent("locomote", inst._onlocomote, owner)
end

local function onunequip(inst, owner)
    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst._onlocomote, inst._owner)
        inst._owner = nil
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("charles_t_horse")
    inst.AnimState:SetBuild("charles_t_horse")
    inst.AnimState:PlayAnimation("idle")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
	inst:AddTag("irreplaceable")

	--inst.foleysound = "dontstarve/creatures/together/deer/bell"

    local swap_data = {sym_build = "charles_t_horse"}
    MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85}, true, 1, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.multiplier = 1
	inst.ringaling = true

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CANE_DAMAGE)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/charles_t_horse.xml"

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1
    inst.components.equippable.dapperness = 0

    MakeHauntableLaunch(inst)

    inst._onlocomote = function(owner)
        if owner.components.locomotor.wantstomoveforward then
			if not inst.SoundEmitter:PlayingSound("ringaling") then
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell", "ringaling")
				inst.multiplier = inst.multiplier + 0.01
				
				if inst.multiplier >= 1.35 then
					inst.multiplier = 1.35
				end
				
				inst:DoTaskInTime(1.6 - inst.multiplier, function(inst) 
					inst.SoundEmitter:KillSound("ringaling")
				end)
				
				if inst._owner ~= nil then
					inst._owner.AnimState:SetDeltaTimeMultiplier(inst.multiplier)
				end
			end
			
			
			inst.components.equippable.dapperness = (inst.multiplier - 1) / 2
			inst.components.equippable.walkspeedmult = inst.multiplier
        else
			inst.multiplier = 1
			inst.components.equippable.dapperness = 0
			inst.components.equippable.walkspeedmult = 1
				
			if inst._owner ~= nil then
				inst._owner.AnimState:SetDeltaTimeMultiplier(inst.multiplier)
			end
        end
    end
	
    return inst
end

return Prefab("charles_t_horse", fn, assets)