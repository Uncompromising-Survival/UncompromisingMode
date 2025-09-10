require("stategraphs/commonstates")

--------------------------------------------------------------------------


local function DoFootstep(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/footstep", nil, volume)
    PlayFootstep(inst, volume)
end

local function DoFootstepRun(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/footstep_run", nil, volume)
    PlayFootstep(inst, volume)
end

--------------------------------------------------------------------------

local events =
{
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSink(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
    CommonHandlers.OnAttacked(TUNING.DEER_HIT_RECOVERY, TUNING.DEER_MAX_STUN_LOCKS),
    CommonHandlers.OnDeath(),
    -- EventHandler("doattack", function(inst, data) -- never attacks, but leave this here incase we change our mind

    -- end),

}

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, playanim)
            inst.AnimState:PlayAnimation("idle_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0, function(inst)
            DoFootstep(inst)
        end),
        TimeEvent(7 * FRAMES, DoFootstep),
        TimeEvent(9 * FRAMES, DoFootstep),
        TimeEvent(17 * FRAMES, function(inst)
            DoFootstep(inst)
        end),
    },
    endtimeline =
    {
        TimeEvent(3 * FRAMES, function(inst)
            DoFootstep(inst, .5)
        end),
    },
})
CommonStates.AddRunStates(states,
{
    starttimeline =
    {
        TimeEvent(8 * FRAMES, DoFootstepRun),
    },
    runtimeline =
    {
        TimeEvent(0, DoFootstepRun),
        TimeEvent(14 * FRAMES, DoFootstepRun),
    },
    endtimeline =
    {
        TimeEvent(2 * FRAMES, DoFootstep),
        TimeEvent(4 * FRAMES, DoFootstep),
    },
})
CommonStates.AddCombatStates(states,
{
    attacktimeline =
    {
        TimeEvent(3 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/swish")
        end),
        TimeEvent(5 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/taunt")
        end),
        TimeEvent(12 * FRAMES, function(inst)
            inst.components.combat:DoAttack(inst.sg.statemem.target)

        end),
        TimeEvent(23 * FRAMES, DoFootstep),
        TimeEvent(25 * FRAMES, DoFootstepRun),

        TimeEvent(28 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
        end)
    },
    hittimeline =
    {
        TimeEvent(12 * FRAMES, function(inst)
                DoFootstep(inst)

        end),
        TimeEvent(13 * FRAMES, function(inst)
            if inst.gem == nil then
                inst.sg:RemoveStateTag("busy")
            end
        end),
        TimeEvent(22 * FRAMES, function(inst)
            if inst.gem ~= nil then
                inst.sg:RemoveStateTag("busy")
            end
        end),
    },
    deathtimeline =
    {
        TimeEvent(5 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bodyfall_2")
        end),
        TimeEvent(20 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/hit")
        end),
        TimeEvent(23 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bodyfall_2")
        end),
    },
},
{
    hit = function(inst)
        return "hit"
    end,
})

CommonStates.AddFrozenStates(states)
CommonStates.AddElectrocuteStates(states)

CommonStates.AddSleepExStates(states,
{
    starttimeline =
    {
        TimeEvent(9 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bodyfall")
        end),
    },
})
CommonStates.AddSinkAndWashAshoreStates(states)

return StateGraph("fern_fox", states, events, "idle")
