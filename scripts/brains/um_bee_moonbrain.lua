require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/chaseandattack"
require "behaviours/standstill"

local BrainCommon = require("brains/braincommon")

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local MAX_WANDER_DIST = 20
local SEE_TARGET_DIST = 6

local MAX_CHASE_DIST = 7
local MAX_CHASE_TIME = 8

local MIN_FOLLOW_LEADER = 2
local MAX_FOLLOW_LEADER = 6
local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER + MIN_FOLLOW_LEADER) / 2

local function GetLeader(inst)
	return inst.components.follower ~= nil and inst.components.follower.leader or nil
end
	

local Um_Bee_MoonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Um_Bee_MoonBrain:OnStart()
    local root = PriorityNode(
    {
		BrainCommon.PanicTrigger(self.inst),
    BrainCommon.ElectricFencePanicTrigger(self.inst),

		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		WhileNode(function() return GetLeader(self.inst) end, "HasLeader",
            Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER)),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
		StandStill(self.inst, function() return self.inst.sg:HasStateTag("idle") end, nil),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Um_Bee_MoonBrain
