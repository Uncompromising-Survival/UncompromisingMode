require("stategraphs/commonstates")


local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.PICKUP, "eat"),
}


local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then inst.sg:GoToState("attack") end end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnHop(),
	CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),

    EventHandler("locomote",
        function(inst)
            if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end

            if not inst.components.locomotor:WantsToMoveForward() then
                if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("hopping") then
                    inst.sg:GoToState("idle")
                end
            else
                if not inst.sg:HasStateTag("hopping") then
					if inst.components.locomotor:WantsToRun() then
						inst.sg:GoToState("aggressivehop")
					else
						inst.sg:GoToState("hop")
					end
                end
            end
        end),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("attack") and not CommonHandlers.HitRecoveryDelay(inst) then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("trapped", function(inst)
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("trapped")
        end
    end),
}

local function SoundPath(inst, event)
    return inst:SoundPath(event)
end

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()

            local anim = inst.islunar and math.random() <= 0.7 and "idle2" or "idle"

            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation(anim, true)

            elseif inst.AnimState:IsCurrentAnimation("idle") or inst.AnimState:IsCurrentAnimation("idle2") then
                inst.AnimState:PushAnimation(anim, true)
            else
                inst.AnimState:PlayAnimation(anim)
            end

            inst.sg:SetTimeout(1*math.random()+.5)
        end,

        ontimeout= function(inst)
            if inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("hop")
            else
                inst.sg:GoToState("idle")
            end
        end,
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
        name = "aggressivehop",
        tags = {"moving", "canrotate", "hopping", "running"},

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.locomotor:RunForward()
            end ),
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider"))
            end ),
            TimeEvent(20*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider"))
                inst.Physics:Stop()
            end ),
        },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("jump_pre")
            inst.AnimState:PushAnimation("jump_loop")
            inst.AnimState:PushAnimation("jump_pst", false)
        end,

        events=
        {
            EventHandler("animqueueover", function (inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "hop",
        tags = {"moving", "canrotate", "hopping"},

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.components.locomotor:WalkForward()
            end ),
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider"))
            end ),
            TimeEvent(20*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(SoundPath(inst, "walk_spider"))
                inst.Physics:Stop()
            end ),
        },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("jump_pre")
            inst.AnimState:PushAnimation("jump_loop")
            inst.AnimState:PushAnimation("jump_pst", false)
        end,

        events=
        {
            EventHandler("animqueueover", function (inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("attack", false)
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            TimeEvent(12*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "fall",
        tags = {"busy"},
        onenter = function(inst)
			inst.Physics:SetDamping(0)
            inst.Physics:SetMotorVel(0,-20+math.random()*10,0)
            inst.AnimState:PlayAnimation("fall_idle", true)
        end,

        onupdate = function(inst)
            local pt = Point(inst.Transform:GetWorldPosition())
            if pt.y < 2 then
				inst.Physics:SetMotorVel(0,0,0)
            end

            if pt.y <= .1 then
                pt.y = 0

				-- TODO: 20% of the time, they should explode on impact!

                inst.Physics:Stop()
				inst.Physics:SetDamping(5)
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
	            inst.DynamicShadow:Enable(true)
                --inst.SoundEmitter:PlaySound(inst.sounds.splat)
                inst.sg:GoToState("idle", "jump_pst")
            end
        end,
    },

    State{
        name = "hit",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "hit_response"))
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
			CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound(SoundPath(inst, "die"))
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,
    },

    State{
        name = "trapped",
        tags = { "busy", "trapped" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("idle")
            inst.sg:SetTimeout(1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },
	
	State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat", true)
			inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt"))
            --inst.sg:SetTimeout(1+math.random()*1)
        end,

        timeline=
        {
            TimeEvent(6*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
		
        events =
        {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
            end),
		},     
    },

}

CommonStates.AddSleepStates(states,
{
	waketimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.wake) end ),
	},
})
CommonStates.AddFrozenStates(states)
CommonStates.AddHopStates(states, true, {loop = "jump_loop"})--, { pre = "boat_jump_pre", loop = "boat_jump_loop", pst = "boat_jump_pst"})
CommonStates.AddSinkAndWashAshoreStates(states)
CommonStates.AddVoidFallStates(states)

return StateGraph("um_ribopod", states, events, "idle", actionhandlers)
