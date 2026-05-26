local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
if TUNING.DSTU.BERNIE_BUFF then
    env.AddPrefabPostInit("bernie_inactive", function(inst)
        inst:AddTag("shadowdominance")

        if not TheWorld.ismastersim then return end

        if not inst.components.shadowdominance then
            inst:AddComponent("shadowdominance")
        end
        
        --[[local _OnEquip = inst.components.equippable.onequipfn
        inst.components.equippable.onequipfn = function(inst, owner)
            owner:AddTag("notarget_shadow")
            _OnEquip(inst, owner)
        end

        local _OnUnequip = inst.components.equippable.onunequipfn
        inst.components.equippable.onunequipfn = function(inst, owner)
            owner:RemoveTag("notarget_shadow")
            _OnUnequip(inst, owner)
        end]]
    end)
end
