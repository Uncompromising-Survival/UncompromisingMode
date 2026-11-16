local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMShove = require("tools/um_shoveutility")

local AOE_RANGE_PADDING = 3
local GHOSTPUSH_MUST_TAGS = {"inspectable","locomotor"}
local GHOSTPUSH_CANT_TAGS = {"notarget", "invisible", "noattack", "flight", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}
local KNOCKBACK_RADIUS_PADDING = .8
local function DoGhostPush(inst, target)
    --inst:PerformBufferedAction()
    local combat = inst.components.combat
    combat.ignorehitrange = true
    local range = combat:GetHitRange()
    local x, y, z = target.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, range + AOE_RANGE_PADDING, GHOSTPUSH_MUST_TAGS, GHOSTPUSH_CANT_TAGS)) do
        if v:IsValid() and v ~= inst and not (v.components.health and v.components.health:IsDead())
            and target:IsNear(v, range + v:GetPhysicsRadius(0)) then
            local combat = v.components.combat
            if combat then
                combat:SetShouldAvoidAggro(inst)
                v:PushEvent("attacked", {attacker = inst, damage = 0, redirected = v})
                combat:RemoveShouldAvoidAggro(inst)
            end
            UMShove.DoShove(v, {knocker = inst, radius = range + KNOCKBACK_RADIUS_PADDING})
            if v.SoundEmitter then v.SoundEmitter:PlaySound("dontstarve/movement/slip_fall_whoop") end
        end
    end
    combat.ignorehitrange = false
end

local function CanPushTarget(target, doer, client)
    return target ~= doer and not IsEntityDeadOrGhost(target) and (client and inst:HasTag("locomotor") or target.components.locomotor) and not target:HasAnyTags(GHOSTPUSH_CANT_TAGS)
end

local UM_GHOSTPUSH = Action({priority = 10, rmb = true, mindistance = 2, ghost_valid = true, ghost_exclusive = true, canforce = true, rangecheckfn = ACTIONS.HAUNT.rangecheckfn})
UM_GHOSTPUSH.id = "UM_GHOSTPUSH"
UM_GHOSTPUSH.str = "Push"
UM_GHOSTPUSH.fn = function(act)
    local target, doer = act.target, act.doer
    if target and CanPushTarget(target, doer) then
        DoGhostPush(doer, target)
        return true
    end
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
                    if right and CanPushTarget(inst, doer, true) then
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

    for _, act in pairs(actionhandlers) do
        inst.actionhandlers[act.action] = act
    end
end)