require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/minperiod"
require "behaviours/follow"
require "behaviours/standandattack"

local START_FACE_DIST = 100
local KEEP_FACE_DIST = 10
local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 7

local Um_Heckler = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return target.components.health ~= nil
        and not target.components.health:IsDead()
        and not target:HasTag("playerghost")
        and not target:HasTag("notarget")
        and inst:IsNear(target, KEEP_FACE_DIST)
end

function Um_Heckler:OnStart()
    local root = PriorityNode(
    {
		WhileNode( function() return not Um_CustomLightCheck(self.inst, 0.15, .1) and not self.inst.sg:HasStateTag("attack") end, "OutLight",
			RunAway(self.inst, "player", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
			ChaseAndAttack(self.inst, nil, 40)
		),

		WhileNode( function() return Um_CustomLightCheck(self.inst, 0.15, .1) and not self.inst.sg:HasStateTag("attack") end, "InLight",
			RunAway(self.inst, "player", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
			StandAndAttack(self.inst),
			FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)
		),

		RunAway(self.inst, "player", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
        
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
		
		Wander(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Um_Heckler