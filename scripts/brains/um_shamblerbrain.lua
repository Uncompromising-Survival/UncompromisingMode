require "behaviours/follow"
require "behaviours/wander"

local UM_ShamblerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
	local leader = inst.components.follower.leader
	
	if leader ~= nil and not leader.components.health:IsDead() and
		leader:IsValid() then
			return leader
	end
	
	return nil
end

function UM_ShamblerBrain:OnStart()
    local root = PriorityNode(
    {
        
        WhileNode(function() return GetLeader(self.inst) ~= nil and
			(self.inst:GetDistanceSqToInst(GetLeader(self.inst)) > 300 or
				self.inst:GetDistanceSqToInst(GetLeader(self.inst)) < 5)			
			end, "FollowTarget",
				ChaseAndAttack(self.inst)
				--Follow(self.inst, function() return GetLeader(self.inst) end, TUNING.GHOST_RADIUS*.25, TUNING.GHOST_RADIUS*.5, TUNING.GHOST_RADIUS, false)
        ),
        WhileNode(function() return GetLeader(self.inst) ~= nil end, "FollowTarget",
				Follow(self.inst, function() return GetLeader(self.inst) end, TUNING.GHOST_RADIUS*.25, TUNING.GHOST_RADIUS*.5, TUNING.GHOST_RADIUS, true)
        ),
		WhileNode(function() return self.inst:GetTimeAlive() > 3 end, "Begone",
			ActionNode(function() self.inst.sg:GoToState("dissipate") end)
		),
    }, 1)

    self.bt = BT(self.inst, root)
end

return UM_ShamblerBrain