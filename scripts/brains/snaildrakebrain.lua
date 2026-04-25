require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/useshield"
require "behaviours/wander"
require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

TUNING.SNAILDRAKE_RANGED_ATTACK_MIN_RANGE = 8
TUNING.SNAILDRAKE_RANGED_ATTACK_MAX_RANGE = 16
TUNING.SNAILDRAKE_DAMAGE_UNTIL_SHIELD = 300

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40
local DAMAGE_UNTIL_SHIELD = TUNING.SNAILDRAKE_DAMAGE_UNTIL_SHIELD
local AVOID_PROJECTILE_ATTACKS = true
local HIDE_WHEN_SCARED = true
local SHIELD_TIME = 1
local SEE_FOOD_DIST = 13
local HUNGER_TOLERANCE = 70

local SnaildrakeBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

-- The Snaildrake will return to its hole.
local function GoHomeAction(inst)
    local homeseeker = inst.components.homeseeker
    if (homeseeker
        and homeseeker.home
        and homeseeker.home:IsValid()
        -- "Eventually you'll be able to plug the hole with something you can craft in a hotspring (quick-set cement)" -- Axe
        -- Need to check if the home is not plugged once quick-set cement is added -- KW
        -- and (not homeseeker.home.components.burnable or not homeseeker.home.components.burnable:IsBurning())
    ) then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

-- Snaildrakes are active during daytime and dusk, and will sleep at night.
local function ShouldGoHomeAtNight(inst)
    return TheWorld.state.isnight
end

local EATFOOD_CANT_TAGS = { "outofreach" }
-- Same function that Slurtles use to eat food.
local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    elseif inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end

    local target = FindEntity(inst,
        30,
        function(item)
            return item:GetTimeAlive() >= 8
                and item:IsOnValidGround()
                and inst.components.eater:CanEat(item)
        end,
        nil,
        EATFOOD_CANT_TAGS
    )
    if target ~= nil then
        local ba = BufferedAction(inst, target, ACTIONS.PICKUP)
        ba.distance = 1.5
        return ba
    end
end

-- A Snaildrake will use its ranged attack if the ability is off cooldown
-- and the target is 2-4 tiles away from it.
local function ShouldUseRangedAttack(self)
    local inst = self.inst
    local target = inst.components.combat:HasTarget() and inst.components.combat.target or nil
    if not target then
        return false
    end
    local MIN_RANGE = TUNING.SNAILDRAKE_RANGED_ATTACK_MIN_RANGE -- 8
    local MAX_RANGE = TUNING.SNAILDRAKE_RANGED_ATTACK_MAX_RANGE -- 16
    local distance = inst:GetDistanceSqToInst(target)
    return not inst.components.timer:TimerExists("rangedattack_cd") and
        distance >= MIN_RANGE and distance <= MAX_RANGE
end
 
function SnaildrakeBrain:OnStart()
    local root = PriorityNode(
    {
        UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS, HIDE_WHEN_SCARED, {dontshieldforfire = true}),
        --BrainCommon.PanicTrigger(self.inst),
        BrainCommon.ElectricFencePanicTrigger(self.inst),
        WhileNode(function()
            return ShouldUseRangedAttack(self)
        end, "RangedAttack", ActionNode(function(inst)
            self.inst:PushEvent("rangedattack")
        end)),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        WhileNode(function()
            return ShouldGoHomeAtNight(self.inst)
        end, "GoHomeNight", DoAction(self.inst, GoHomeAction, "GoHomeNight")),
        DoAction(self.inst, EatFoodAction),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, 40),
    }, .25)

    self.bt = BT(self.inst, root)
end

return SnaildrakeBrain
