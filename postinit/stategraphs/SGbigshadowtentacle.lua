local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("bigshadowtentacle", function(inst)
    local attackstate = inst.states["attack"]
    if attackstate and attackstate.events["animqueueover"] then
        attackstate.events["animqueueover"].fn = function(inst, ...)
            inst.sg:GoToState("attack_post")
        end
    end
end)