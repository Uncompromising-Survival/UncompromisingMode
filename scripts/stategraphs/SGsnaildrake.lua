require("stategraphs/commonstates")

TUNING.SNAILDRAKE_SHELL_ABSORB = 0.95

local actionhandlers =
{
    ActionHandler(ACTIONS.PICKUP, "eat_pre"),
    ActionHandler(ACTIONS.EAT, "eat_loop"),
    ActionHandler(ACTIONS.GOHOME, "action"),
}

local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    EventHandler("entershield", function(inst) if not (inst.components.health and inst.components.health:IsDead()) then inst.sg:GoToState("shield") end end),
    EventHandler("exitshield", function(inst) if not (inst.components.health and inst.components.health:IsDead()) then inst.sg:GoToState("shield_end") end end),
    --EventHandler("onignite", function(inst) inst:PushEvent("entershield") end), -- Will not hide when ignited
    EventHandler("rangedattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("rangedattack")
        end
    end),
}

local states =
{
     State{

        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,

        timeline =
        {
		    TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/idle") end ),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "taunt",

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
            TimeEvent(33*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/taunt") end ),
        },


        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{

        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
            inst:PerformBufferedAction()
        end,
        events=
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    },


    State{
    	name = "shield",
    	tags = {"busy","hiding"},

    	onenter = function(inst)
            --If taking fire damage, spawn fire effect.

    		inst.components.health:SetAbsorptionAmount(TUNING.SNAILDRAKE_SHELL_ABSORB)
    		inst.Physics:Stop()
    		inst.AnimState:PlayAnimation("hide")
    		inst.AnimState:PushAnimation("hide_loop")
            inst:AddTag("shell")
    	end,

        onexit = function(inst)
            inst:RemoveTag("shell")
            inst.components.health:SetAbsorptionAmount(0)
        end,

        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/hide") end ),
        },
	},

    State{
        name = "shield_end",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("emerge")
        end,

        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) inst:DoExplosion() end ),
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/emerge") end ),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "rangedattack",
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
            TimeEvent(26*FRAMES, function(inst) inst:DoRangedAttack() end ),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat_pre",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre", false)
        end,

        timeline =
        {
            TimeEvent(11*FRAMES, function(inst)
            inst:PerformBufferedAction()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/bite") end ), --take food
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },

    },

    State{
        name = "eat_loop",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(2+math.random()*3)
        end,

        timeline =
        {
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/eat") end ),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/eat") end ),
        },

        events =
        {
            EventHandler("attacked", function(inst) inst.components.inventory:DropItem(inst:GetBufferedAction().target) inst.sg:GoToState("idle") end) --drop food
        },

        ontimeout= function(inst)
            inst.lastmeal = GetTime()
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle", "eat_pst")
        end,
    },
}

CommonStates.AddWalkStates(states,
{
    starttimeline =
    {
	    TimeEvent(0*FRAMES, function(inst) inst.Physics:Stop() end ),
    },
	walktimeline = {
		    TimeEvent(0*FRAMES, function(inst)
		    inst.Physics:Stop()
            if math.random() <= 0.33 then inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/idle") end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/slide_out")
            end ),

            TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/slide_in")
                inst.components.locomotor:WalkForward()
            end ),
            TimeEvent(21*FRAMES, function(inst)
                inst.Physics:Stop()
            end ),
	},
}, nil, true)


local function hitanim(inst)
	local statename = inst.sg.currentstate.name
	if statename == "shield" then
		return "hit_shield"
	else
		return "hit_out"
	end
end

local combatanims =
{
	hit = hitanim,
}

CommonStates.AddCombatStates(states,
{
    attacktimeline =
    {
       TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack()
        inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/bite")
        end),
    },
    deathtimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/death")
        end),
    },
}, combatanims)

CommonStates.AddFrozenStates(states)


return StateGraph("slurtle", states, events, "idle", actionhandlers)
