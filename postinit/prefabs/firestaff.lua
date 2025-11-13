local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------------------------

env.AddPrefabPostInit("firestaff", function(inst)
    if not TheWorld.ismastersim then
		return
	end

    local oldonequipfn = inst.components.equippable.onequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
        oldonequipfn(inst, owner)
        if not owner.components.skilltreeupdater:IsActivated("willow_controlled_burn_1") then
            owner:AddTag("controlled_burner")
        end
    end)

    local oldonunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        oldonunequipfn(inst, owner)
        if not owner.components.skilltreeupdater:IsActivated("willow_controlled_burn_1") then
            owner:RemoveTag("controlled_burner")
        end
    end)
end)