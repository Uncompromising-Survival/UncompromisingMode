local env = env
GLOBAL.setfenv(1, GLOBAL)

------------------------------------------------



env.AddPrefabPostInit("tillweedsalve", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnHeal = inst.components.healer.onhealfn

    local function OnHeal(inst, target)
        _OnHeal(inst, target)
        if target.components.health ~= nil then
            target.components.health:DeltaPenalty(-.125)
        end
    end


    inst.components.healer:SetOnHealFn(OnHeal)
end)
