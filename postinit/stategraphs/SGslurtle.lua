local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("slurtle", function(inst)

local events=
{
    EventHandler("rangedattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("rangedattack")
        end
    end),
}

local states = {

    State{
        name = "rangedattack", -- AXE This state is reused for trading too...
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spit")
            
        end,

        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
            TimeEvent(26*FRAMES, function(inst) 
                if not inst.trader and inst.DoRangedAttack then
                    inst:DoRangedAttack()
                else
                    inst.GemologyEatFn(inst) 
                end 
            end),
        },

        events=
        {
            EventHandler("animover", function(inst) 
                if inst.trader then
                    inst.trader = nil
                end
                inst.sg:GoToState("idle") 
            end),
        },
    },
}

for k, v in pairs(events) do
    assert(v:is_a(EventHandler), "Non-event added in mod events table!")
    inst.events[v.name] = v
end

for k, v in pairs(states) do
    assert(v:is_a(State), "Non-state added in mod state table!")
    inst.states[v.name] = v
end

end)

