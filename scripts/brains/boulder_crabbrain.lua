require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/avoidlight"
require "behaviours/panic"
require "behaviours/attackwall"

local BrainCommon = require "brains/braincommon"

local AVOID_PLAYER_DIST = 6
local AVOID_PLAYER_STOP = 9

local SEE_FOOD_DIST = 10

local MAX_WANDER_DIST = 16
local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8

local Boulder_crabBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local EATFOOD_CANT_TAGS = { "INLIMBO", "outofreach" }
local function IsFoodValid(item, inst)
    return inst.components.eater:CanEat(item)
        and item:IsOnValidGround()
        and item:GetTimeAlive() > TUNING.SPIDER_EAT_DELAY
end

local function EatFoodAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, IsFoodValid, nil, EATFOOD_CANT_TAGS, inst.components.eater:GetEdibleTags())
    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

--[[local function InvestigateAction(inst)
    local investigatePos = inst.components.knownlocations ~= nil and inst.components.knownlocations:GetLocation("investigate") or nil
    return investigatePos ~= nil and BufferedAction(inst, nil, ACTIONS.INVESTIGATE, nil, investigatePos, nil, 1) or nil
end]]

local function ShouldHideUnderRock(inst)
    local rock = inst.myrock
    return GetTime() - inst.lasthidetime > 10 and TheWorld.state.isday and not inst.hiding and not (inst.components.combat and inst.components.combat:HasTarget())
        and rock and rock:IsValid() and rock.AnimState:IsCurrentAnimation("full")
end

local function HideUnderRock(inst)
    inst:PushEvent("hideunderrock")
end

local function ShouldComeOutFromUnderRock(inst)
    return not TheWorld.state.isday and inst.hiding
end

local function ComeOutFromUnderRock(inst)
    inst:PushEvent("comeoutfromunderrock")
end

function Boulder_crabBrain:OnStart()
    local pre_nodes = PriorityNode({
        BrainCommon.PanicWhenScared(self.inst, .3),
        WhileNode(function() return not (self.inst.myrock and self.inst.myrock.components.workable) end, "Rockless", RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP)),
        WhileNode(function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        WhileNode(function() return ShouldHideUnderRock(self.inst) end, "ShouldHideUnderRock", ActionNode(function() HideUnderRock(self.inst) end)),
        WhileNode(function() return ShouldComeOutFromUnderRock(self.inst) end, "ShouldComeOutFromUnderRock", ActionNode(function() ComeOutFromUnderRock(self.inst) end)),
        WhileNode(function() return self.inst.hiding end, "Hiding", StandStill(self.inst)),
    })

    local post_nodes = PriorityNode({
		DoAction(self.inst, function() return EatFoodAction(self.inst) end),
		FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn, 0.25),
        --DoAction(self.inst, function() return InvestigateAction(self.inst) end ),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
    })


    local attack_nodes = PriorityNode({
        WhileNode(function() return (self.inst.myrock and self.inst.myrock.components.workable) end, "Rockhard", ChaseAndAttack(self.inst, SpringCombatMod(TUNING.SPIDER_AGGRESSIVE_MAX_CHASE_TIME))),
    })

    local root =
        PriorityNode(
        {
            pre_nodes,
            attack_nodes,
            post_nodes,

        }, 1)
        
    self.bt = BT(self.inst, root)
end

function Boulder_crabBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return Boulder_crabBrain