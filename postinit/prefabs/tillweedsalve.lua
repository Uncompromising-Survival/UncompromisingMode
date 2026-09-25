local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------
env.AddPrefabPostInit("tillweedsalve", function(inst)
    if not TheWorld.ismastersim then return end
    local healer = inst.components.healer
    if healer then
        local _OnHeal = healer.onhealfn
        local function OnHeal(_inst, target)
            local ret = _OnHeal(_inst, target)
            if target.components.health then target.components.health:DeltaPenalty(-.125) end
            return ret
        end
        healer:SetOnHealFn(OnHeal)
    end
end)
