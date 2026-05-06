local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------------------------


local function isValid(owner)
    if owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("willow_controlled_burn_1") then
        return false
    end

    return true
end

env.AddPrefabPostInit("firestaff", function(inst)
    if not TheWorld.ismastersim then
		return
	end

    local _onequipfn = inst.components.equippable.onequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
        _onequipfn(inst, owner)
        if isValid(owner) then
            owner:AddTag("controlled_burner")
        end
    end)

    local _onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        _onunequipfn(inst, owner)
        if isValid(owner) then
            owner:RemoveTag("controlled_burner")
        end
    end)
end)