require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/minperiod"
require "behaviours/follow"

local START_FACE_DIST = 100
local KEEP_FACE_DIST = 10
local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8


local MIN_FOLLOW_DIST = 8
local MAX_FOLLOW_DIST = 20
local TARGET_FOLLOW_DIST = (MAX_FOLLOW_DIST+MIN_FOLLOW_DIST)/2

local Um_Shadow_Warly = Class(Brain, function(self, inst)
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

local function FindLeftovers(inst)
	local targetfood = FindEntity(inst, 25, nil, { "um_shadow_warly_food" })
	
	if targetfood ~= nil then
		return targetfood ~= nil
			and BufferedAction(inst, targetfood, ACTIONS.PICKUP)
			or nil
	end
end

function Um_Shadow_Warly:OnStart()
    local root = PriorityNode(
    {
		WhileNode(function() return not self.inst.sg:HasStateTag("busy") end, "FindLeftovers",
					DoAction(self.inst, function() return FindLeftovers(self.inst) end, "pickup", true )),
		
		IfNode(function() return not self.inst.sg:HasStateTag("busy") end, "Dodge",
			RunAway(self.inst, "player", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST, nil, nil, nil, true)
		),
		
       --[[ WhileNode(function() return self.inst:HasTag("um_shadow_character") end, "FollowFar",
					Follow(self.inst, function() return self.inst.components.combat.target end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true)),
        ]]
		FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        ParallelNode{
            SequenceNode{
                WaitNode(TUNING.SHADOW_CHESSPIECE_DESPAWN_TIME),
                ActionNode(function() self.inst:PushEvent("despawn") end),
            },
            Wander(self.inst),
        },
    }, .25)

    self.bt = BT(self.inst, root)
end

return Um_Shadow_Warly