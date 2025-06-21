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


local Um_Bee_MoonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Um_Bee_MoonBrain:OnStart()
    local root = PriorityNode(
    {
		BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
		StandStill(self.inst, function() return self.inst.sg:HasStateTag("idle") end, nil),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Um_Bee_MoonBrain
