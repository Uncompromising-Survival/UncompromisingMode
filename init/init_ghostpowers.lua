local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMShove = require("tools/um_shoveutility")

local ATTACK_PROP_MUST_TAGS = {"inspectable","locomotor"}
local ATTACK_PROP_CANT_TAGS = {"notarget", "invisible", "noattack", "flight", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}
local function DoGhostPush(inst)
    --inst:PerformBufferedAction()
    local combat = inst.components.combat
    combat.ignorehitrange = true
    local radius = combat:GetHitRange() + .8
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + 3, ATTACK_PROP_MUST_TAGS, ATTACK_PROP_CANT_TAGS)) do
        if v:IsValid() and not (v.components.health and v.components.health:IsDead()) then
            local range = radius + v:GetPhysicsRadius(0)
            if inst:IsNear(v, range) then
                --dummy redirected so that players don't get red blood flash
                local combat = v.components.combat
                if combat then
                    combat:SetShouldAvoidAggro(inst)
                    v:PushEvent("attacked", {attacker = inst, damage = 0, redirected = v})
                    combat:RemoveShouldAvoidAggro(inst)
                end
                UMShove.DoShove(v, {knocker = inst, radius = radius})
                if v.SoundEmitter then v.SoundEmitter:PlaySound("dontstarve/movement/slip_fall_whoop") end
            end
        end
    end
    combat.ignorehitrange = false
end

local UM_GHOSTPUSH = Action({priority = 10, rmb = true, mindistance = 2, ghost_valid = true, ghost_exclusive = true, canforce = true, rangecheckfn = ACTIONS.HAUNT.rangecheckfn})
UM_GHOSTPUSH.id = "UM_GHOSTPUSH"
UM_GHOSTPUSH.str = "Push"
UM_GHOSTPUSH.fn = function(act)
    DoGhostPush(act.doer)
    return true
end

env.AddAction(UM_GHOSTPUSH)

local UMUpvalueHacker = require("tools/um_upvaluehacker")
env.AddSimPostInit(function()
    local COMPONENT_ACTIONS = UMUpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local SCENE = COMPONENT_ACTIONS.SCENE
        if SCENE then
            local _SCENE_inspectable_fn = SCENE["inspectable"]
            if _SCENE_inspectable_fn then
                SCENE["inspectable"] = function(inst, doer, actions, right, ...)
                    if right and doer:HasTag("playerghost") and inst ~= doer and inst:HasTag("locomotor") then
                        table.insert(actions, ACTIONS.UM_GHOSTPUSH)
                        return
                    end
                    return _SCENE_inspectable_fn(inst, doer, actions, right, ...)
                end
            end
        end
    end
end)

--[[env.AddComponentAction("SCENE", "combat", function(inst, doer, actions, right)
    if right and doer:HasTag("playerghost") then
        table.insert(actions, ACTIONS.UM_GHOSTPUSH)
    end
end)]]

env.AddStategraphPostInit("wilsonghost", function(inst)
    local actionhandlers = {
        ActionHandler(ACTIONS.UM_GHOSTPUSH, "haunt_pre")
    }

    local states = {
        State{
            name = "um_ghostpush",
            tags = {"doing", "busy"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("dissipate")
                inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_haunt", nil, nil, true)
            end,

            timeline =
            {
                TimeEvent(15 * FRAMES, DoGhostPush)
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("haunt")
                    end
                end),
            },
        },
    }

    for _, act in pairs(actionhandlers) do
        inst.actionhandlers[act.action] = act
    end

    for _, state in pairs(states) do
        inst.states[state.name] = state
    end
end)