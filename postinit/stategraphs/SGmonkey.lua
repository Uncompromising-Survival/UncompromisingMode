local env = env
GLOBAL.setfenv(1, GLOBAL)

local function IsThrowerEquipped(inst)
    local thrower = inst.HasAmmo and inst:HasAmmo() and inst.weaponitems and inst.weaponitems.thrower
    local inventory = inst.components.inventory
    return thrower and thrower:IsValid() and inventory and inventory:IsItemEquipped(thrower)
end

env.AddStategraphPostInit("monkey", function(inst)
    local doattack_eventhandler = inst.events["doattack"]
    if doattack_eventhandler then
        --local doattack_eventhandler_fn = doattack_eventhandler.fn
        doattack_eventhandler.fn = function(inst, data, ...)
            if inst.components.health and not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
                -- Fixes a bug where Monkeys want to throw instead of attack when they shouldn't.
                inst.sg:GoToState(IsThrowerEquipped(inst) and "throw" or "attack")
                --return
            end
            --return doattack_eventhandler_fn(inst, data, ...)
        end
    end
end)