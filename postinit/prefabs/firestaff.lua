local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------------------------


local function IsValid(owner)
    if owner.components.skilltreeupdater then
        return not owner.components.skilltreeupdater:IsActivated("willow_controlled_burn_1")
    end

    return false
end

env.AddPrefabPostInit("firestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _onequipfn = inst.components.equippable.onequipfn
    inst.components.equippable:SetOnEquip(function(_inst, owner, ...)
        _onequipfn(_inst, owner, ...)
        if IsValid(owner) then
            owner:AddTag("controlled_burner")
        end
    end)

    local _onunequipfn = inst.components.equippable.onunequipfn
    inst.components.equippable:SetOnUnequip(function(_inst, owner, ...)
        _onunequipfn(_inst, owner, ...)
        if IsValid(owner) then
            owner:RemoveTag("controlled_burner")
        end
    end)
end)