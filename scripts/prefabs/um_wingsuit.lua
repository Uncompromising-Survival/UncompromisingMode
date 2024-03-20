local function onequip(inst, owner)
	if not owner:HasTag("vetcurse") then
		inst:DoTaskInTime(0, function(inst, owner)
			local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner
			local tool = owner ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
			if tool ~= nil and owner ~= nil then
				owner.components.inventory:Unequip(EQUIPSLOTS.BODY)
				owner.components.inventory:DropItem(tool)
				owner.components.inventory:GiveItem(inst)
				owner.components.talker:Say(GetString(owner, "CURSED_ITEM_EQUIP"))
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")

				if owner.sg ~= nil then
					owner.sg:GoToState("hit")
				end
			end
		end)
	else
		owner:AddTag("allow_action_on_impassable")
		owner.AnimState:OverrideSymbol("swap_body", "featherfrock", "swap_body")
		
		owner.um_wingsuit = inst
		 
		--inst:Hide()
	end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
	owner.um_wingsuit = nil

    owner:RemoveTag("allow_action_on_impassable")
	
	--inst:Show()
end

local function frockfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("featherfrock_ground")
	inst.AnimState:SetBuild("featherfrock_ground")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("um_wingsuit")
	--inst:AddTag("backpack")
	inst:AddTag("vetcurse_item")

    inst:AddTag("allow_action_on_impassable")

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("tradable")
	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_wingsuit.xml"

	inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)
	
	inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(30)
    inst.components.finiteuses:SetUses(30)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("um_wingsuit", frockfn)