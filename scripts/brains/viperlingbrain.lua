require "behaviours/standstill"
require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/leash"
local BrainCommon = require("brains/braincommon")

local ViperlingBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local MIN_FOLLOW_LEADER = 2
local MAX_FOLLOW_LEADER = 6
local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER + MIN_FOLLOW_LEADER) / 2

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader()
end

function ViperlingBrain:OnStart()
    local root = PriorityNode(
        {
            BrainCommon.PanicTriggerShadowCreature(self.inst),
            Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER),
            ChaseAndAttack(self.inst, TUNING.WORM_CHASE_TIME, TUNING.WORM_CHASE_DIST),
            Wander(self.inst, function() return self.inst:GetPosition() end, TUNING.WORM_WANDER_DIST),
            StandStill(self.inst),
        }, .25)

    if UPDATE_CHECK then
        table.insert(root.children, 2, BrainCommon.RunAwayFromQueenTorch(self))
    end
    self.bt = BT(self.inst, root)
end

return ViperlingBrain