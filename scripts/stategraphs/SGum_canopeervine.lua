local easing = require("easing")
require("stategraphs/commonstates")

local events=
{
	EventHandler("attacked", function(inst, data)
		if inst.components.health and not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			elseif not inst.sg:HasAnyStateTag("hit", "attack") then
                inst.sg:GoToState("land_hit")
			end
		end
	end),
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),

    EventHandler("death", function(inst,data)
        inst.sg:GoToState("death")
    end),
    EventHandler("freeze", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.sg:GoToState("frozen")
        end
    end),
}

local states=
{
    State{
        name = "appear",
		tags = { "idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear_pre",false)
            inst.AnimState:PlayAnimation("appear_loop",true)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/vine_emerge")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_central_idle", "loop")
        end,
		onupdate = function(inst)
			inst.ShuffleToTarget(inst)
		end,
    },

    State{
        name = "leave_up",
		tags = { "busy","idle"},
        onenter = function(inst)
            inst.AnimState:PushAnimation("appear_pst",false)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst:Remove()
            end),
        },
    },

    State{
        name = "attack",
		tags = { "busy","hit"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_pre",false)
            inst.AnimState:PushAnimation("attack",false)
            inst.AnimState:PushAnimation("attack_pst",false)

            if inst.decide_to_attack then
                inst.decide_to_attack:Cancel()
                inst.decide_to_attack = nil
            end
        end,
        timeline=
        {
            TimeEvent(1*FRAMES,function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_emerge")
            end), -- sound - preparing
            TimeEvent(10*FRAMES,function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/frog/attack_spit") -- WOOSH
            end), -- sound -- launching
            TimeEvent(15*FRAMES,function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_bite")
                inst.DoVineAreaAttack(inst)
                if inst.components.locomotor then
                    inst.components.locomotor:StopMoving()
                end
            end), -- sound --- hit, attack
        },
        events=
        {
            EventHandler("animqueueover", function(inst)

                -- Vine is vulnerable now
                inst:RemoveTag("INLIMBO") 
                inst.components.health.invincible = false
                inst.struggle_count = math.random(2,4)
                inst.sg:GoToState("land_idle")
            end),
        },

    },

    State{
        name = "land_idle",
		tags = { "idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("land_idle",false)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst.struggle_count = inst.struggle_count - 1
                if inst.struggle_count < 1 then
                    inst.sg:GoToState("land_leave")
                else
                    inst.sg:GoToState("land_idle")
                end
            end),
        },
    },

    State{
        name = "land_hit",
		tags = { "busy","hit"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("land_hit",false)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("land_idle")
            end),
        },
    },

    State{
        name = "land_leave",
		tags = { "busy","idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("land_leave_pre",false)
            inst.AnimState:PlayAnimation("land_leave_pst",false)
            inst:AddTag("INLIMBO") 
            inst.components.health.invincible = true
        end,
        events=
        {
            EventHandler("animqueueover", function(inst)
                inst:Remove()
            end),
        },
    },


	State{
        name = "death",
        tags = {"busy","raised"},

        onenter = function(inst)
            inst.components.lootdropper:DropLoot()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_retract")
            inst.AnimState:PlayAnimation("death",false)
            RemovePhysicsColliders(inst)
            inst.SendHealthLossToCanopeer(inst)
        end,
        events = 
        {
            EventHandler("animover",function(inst) inst:Remove() end)

        }
    },
}

local anims =
{
    loop = "shock_loop",
    pst = "shock_loop_pst",
}

CommonStates.AddFrozenStates(states) --AXE Not using common states because of the way the animations were named.
CommonStates.AddElectrocuteStates(states, nil, anims, {
	onanimover = function(inst)
		if inst.AnimState:AnimDone() then
			inst.sg:GoToState("land_idle")
		end
	end,
}) -- AXE Missing electrocute animations

CommonStates.AddInitState(states, "appear")
--CommonStates.AddCorpseStates(states)

return StateGraph("um_canopeervine", states, events, "init")
