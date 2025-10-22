local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("glasscutter", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local weapon = inst.components.weapon
    if weapon then
        local _OnAttack = weapon.onattack
        weapon:SetOnAttack(function(inst, attacker, target, ...)
            inst.components.weapon.attackwear = target and target:IsValid() and target:HasTag("shadow_aligned") and TUNING.GLASSCUTTER.SHADOW_WEAR or 1
            if _OnAttack then _OnAttack(inst, attacker, target, ...) end
        end)
    end

    local damagetypebonus = inst.components.damagetypebonus or inst:AddComponent("damagetypebonus")
    if damagetypebonus then damagetypebonus:AddBonus("shadow_aligned", inst, 1+17 / 68) end
end)