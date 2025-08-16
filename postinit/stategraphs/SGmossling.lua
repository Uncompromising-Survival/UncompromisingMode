local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("mossling", function(inst)
    local spinloopstate = inst.states["spin_loop"]
    if spinloopstate then
        local spinloopstate_onenter = spinloopstate.onenter
        spinloopstate.onenter = function(inst, target, ...)
            local ret = spinloopstate_onenter(inst, target, ...)
            if inst:HasTag("mothermossling") then inst.AnimState:SetBuild(IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and "mossling_angry_build" or "mossling_yule_angry_build") end
            return ret
        end
    end
end)