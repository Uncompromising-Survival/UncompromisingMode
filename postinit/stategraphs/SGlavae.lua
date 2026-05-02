local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddStategraphPostInit("lavae", function(inst)
    local deatheventhandler = inst.events["death"]
    if deatheventhandler then
        local deatheventhandler_fn = deatheventhandler.fn
        deatheventhandler.fn = function(inst, data, ...)
            if inst.um_frozendeath then -- Vanilla patch to prevent a lavae's same frame freeze/unfreeze from escaping their frozen death.
                inst.um_frozendeath = nil
                inst.sg:GoToState("thaw_break", data)
                return
            end
            return deatheventhandler_fn(inst, data, ...)
        end
    end
end)