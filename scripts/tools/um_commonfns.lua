local UMCommonFns = {}

UMCommonFns.VetcurseUnequip = function(inst, owner, slot)
    if not owner:HasTag("vetcurse") and owner:HasTag("player") then
        inst:DoTaskInTime(0, function(inst)
            --local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
            local tool = owner and owner.components.inventory:GetEquippedItem(slot)
            if tool and owner then
                owner.components.inventory:Unequip(slot)
                owner.components.inventory:DropItem(tool)
                owner.components.inventory:GiveItem(inst)
                if owner.components.talker then
                    owner.components.talker:Say(GetString(owner, "CURSED_ITEM_EQUIP"))
                end
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")
                if owner.sg then owner.sg:GoToState("hit") end
            end
        end)
		return true
	end
end

return UMCommonFns