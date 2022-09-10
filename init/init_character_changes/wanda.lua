local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
if TUNING.DSTU.WANDA_NERF then
    env.AddPrefabPostInit("wanda", function(inst)
        if inst.components.combat ~= nil then
            local _CustomCombatDamage = inst.components.combat.customdamagemultfn

            local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
                if mount == nil then
                    if weapon ~= nil and weapon.prefab == "pocketwatch_weapon" and target:HasTag("shadow") then
                        return inst.age_state == "old" and (127.5 / 51) * 0.8 or
                            inst.age_state == "normal" and (68 / 51) * 0.8 or 0.8 --should probably make these tuning values.
                    elseif weapon ~= nil and weapon.prefab == "pocketwatch_weapon" then
                        return inst.age_state == "old" and 127.5 / 51 or
                            inst.age_state == "normal" and 68 / 51 or 1
                    elseif weapon ~= nil and weapon:HasTag("shadow_item") and target:HasTag("shadow") then
                        return inst.age_state == "old" and TUNING.WANDA_SHADOW_DAMAGE_OLD * 0.8
                            or inst.age_state == "normal" and TUNING.WANDA_SHADOW_DAMAGE_NORMAL * 0.8
                            or TUNING.WANDA_SHADOW_DAMAGE_YOUNG * 0.75
                    elseif target:HasTag("shadow") then
                        return inst.age_state == "old" and TUNING.WANDA_REGULAR_DAMAGE_OLD * 0.8
                            or inst.age_state == "normal" and TUNING.WANDA_REGULAR_DAMAGE_NORMAL * 0.8
                            or TUNING.WANDA_REGULAR_DAMAGE_YOUNG * 0.8
                    end
                    return _CustomCombatDamage(inst, target, weapon, multiplier, mount)
                end
            end

            inst.components.combat.customdamagemultfn = CustomCombatDamage
        end
    end)
end
