local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
if UM_CONFIG.WENDY then
    -- Wendy now only gets the 10% bonus from Abigail, not 40%
    --[[local function CustomCombatDamage(inst, target)
        return (target == inst.components.ghostlybond.ghost and target:HasTag("abigail")) and 0
            or nil
    end

    AddPrefabPostInit("wendy", function (inst)
        if inst.components.combat ~= nil then
            inst.components.combat.customdamagemultfn = CustomCombatDamage
        end
    end)]]

    local petals = {"petals", "petals_evil", "moon_tree_blossom"}
    for _, prefab in ipairs(petals) do
        env.AddPrefabPostInit(prefab, function(inst)
            if not TheWorld.ismastersim then return end

            local perishable = inst.components.perishable
            if perishable then
                local _OnPerish = perishable.perishfn
                perishable:SetOnPerishFn(function(_inst, ...)
                    local owner = _inst.components.inventoryitem.owner
                    if owner and owner.prefab == "sisturn" then
                        _inst.components.perishable.onperishreplacement = "ghostflower"
                    end
                    return _OnPerish and _OnPerish(_inst, ...)
                end)
            end
        end)
    end
end