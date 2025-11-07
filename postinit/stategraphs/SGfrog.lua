local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("frog", function(inst)
    local actionhandlers =
    {
        ActionHandler(ACTIONS.EAT, "eat_loop"),
        ActionHandler(ACTIONS.PICKUP, "eat")
    }

    local states = {
        State{
            name = "eat",
            tags = {"busy"},

            onenter = function(inst, forced)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("eat_pre")
                inst.SoundEmitter:PlaySound("dontstarve/frog/attack_voice")
                inst.sg.statemem.forced = forced
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    inst:PerformBufferedAction()
                    inst.sg:GoToState("idle")
                end),
            },
        },
        State{
            name = "eat_loop",
            tags = {"busy"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("eat_pre")
                inst.AnimState:SetFrame(15)
                inst.AnimState:PushAnimation("eat_loop", true)
                inst.SoundEmitter:PlaySound("dontstarve/frog/grunt")
                inst.sg:SetTimeout(1 + math.random() * 2)
            end,

            ontimeout = function(inst)
                inst:PerformBufferedAction()
                inst.sg:GoToState("eat_pst", "idle")
            end,

            events =
            {
                EventHandler("attacked", function(inst) --drop food
                    if inst.components.inventory then
                        inst.components.inventory:DropEverything()
                    end
                    inst.sg:GoToState("idle")
                end)
            },
        },
        State{
            name = "eat_pst",
            tags = {"busy"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("eat_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },
        }
    }

    for k, v in pairs(actionhandlers) do
        assert(v:is_a(ActionHandler), "Non-action added in mod state table!")
        inst.actionhandlers[v.action] = v
    end

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end
end)