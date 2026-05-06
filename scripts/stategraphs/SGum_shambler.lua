require("stategraphs/commonstates")

local function startaura(inst)
    inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_attack_LP", "angry")
end

local function stopaura(inst)
    inst.SoundEmitter:KillSound("angry")
end

local events =
{
    CommonHandlers.OnLocomote(true, true),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("attack", data.target)
        end
    end),
    EventHandler("death", function(inst)
        inst.sg:GoToState("dissipate")
    end),
}

local function getidleanim(inst)
	local leader = inst.components.follower.leader

    return leader ~= nil and (inst:GetDistanceSqToInst(leader) < 20 and "aggroidle"
        or inst:GetDistanceSqToInst(leader) > 300 and "groanidle")
        or "groanidle"
end

local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate", "canslide" },

        onenter = function(inst)
			--inst.AnimState:PlayAnimation("idleloop", true)
            local hastarget = inst.components.combat ~= nil and inst.components.combat:HasTarget()
            inst.AnimState:PlayAnimation(hastarget and "aggroidle" or "groanidle")
        end,
    },

    State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("eat_90s")
        end,

        timeline =
        {

            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.attack) end),
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },

    State{
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            --inst.components.locomotor:RunForward()
            local hastarget = inst.components.combat ~= nil and inst.components.combat:HasTarget()
            inst.AnimState:PlayAnimation(hastarget and "aggrowalk_pre" or "groanwalk_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("run")
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            --inst.components.locomotor:RunForward()
            local hastarget = inst.components.combat ~= nil and inst.components.combat:HasTarget()
            inst.AnimState:PlayAnimation(hastarget and "aggrowalk_loop" or "groanwalk_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "idle" },

        onenter = function(inst)
            --inst.components.locomotor:StopMoving()
            local hastarget = inst.components.combat ~= nil and inst.components.combat:HasTarget()
            inst.AnimState:PlayAnimation(hastarget and "aggrowalk_pst" or "groanwalk_pst")
        end,

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State{
        name = "appear",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.aura:Enable(true)
        end,
    },

    State{
        name = "dissipate",
        tags = { "busy", "noattack", "nointerrupt" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("disappear")
            inst.SoundEmitter:PlaySound(inst:HasTag("girl") and "dontstarve/ghost/ghost_girl_howl" or "dontstarve/ghost/ghost_howl")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.components.lootdropper ~= nil then
                        inst.components.lootdropper:DropLoot()
                    end
                    inst:PushEvent("detachchild")
                    inst:Remove()
                end
            end)
        },
    },
}

CommonStates.AddSimpleWalkStates(states, getidleanim)
CommonStates.AddSimpleRunStates(states, getidleanim)

return StateGraph("um_shambler", states, events, "appear")
