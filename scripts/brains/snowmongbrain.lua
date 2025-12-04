require "behaviours/wander"
require "behaviours/chaseandattack"

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 20
local MAX_CHASE_TIME = 40

local SnowMongBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function SnowMongBrain:OnStart()
	local root = PriorityNode(
	{
		BrainCommon.PanicTrigger(self.inst),
		BrainCommon.ElectricFencePanicTrigger(self.inst),
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
	}, 0.25)
	self.bt = BT(self.inst, root)
end

return SnowMongBrain