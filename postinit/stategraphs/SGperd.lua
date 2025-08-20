local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("perd", function(inst)
    local _OldAttackedEvent = inst.events["attacked"].fn
    inst.events["attacked"].fn = function(inst, data, ...)
        if not (inst.components.health and inst.components.health:IsDead()) then
            if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
                return
            elseif not inst.sg:HasStateTag("busy", "electrocute") then
                if inst.attacked then
                    inst.sg:GoToState("hitshort")
                else
                    _OldAttackedEvent(inst, data, ...)
                end
            end
        end
    end

    local states =
    {
        State{
            name = "hitshort",
            tags = {"busy"},

            onenter = function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/perd/hurt")
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("hit")
                local timeouttime = inst.AnimState:GetCurrentAnimationLength() / 1.2
                inst.sg:SetTimeout(timeouttime)
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("idle")
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        }
    }

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end
end)