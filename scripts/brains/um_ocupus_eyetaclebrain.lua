require "behaviours/follow"
require "behaviours/wander"

local um_ocupus_eyetaclebrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)

    return inst.components.combat.target
end

local function findtargetcheck(target)
	local x, y, z = target.Transform:GetWorldPosition()
	return TheWorld.Map:IsOceanAtPoint(x, y, z, target:HasTag("boat"))
end

local FINDEDIBLE_CANT_TAGS = { "INLIMBO", "fire", "smolder" }
local FINDEDIBLE_ONEOF_TAGS = { "boat"}
local function CheckForBoats(inst)
	inst.target_wood = FindEntity(inst, TUNING.COOKIECUTTER.BOAT_DETECTION_DIST, findtargetcheck, nil, FINDEDIBLE_CANT_TAGS, FINDEDIBLE_ONEOF_TAGS)
end

local function FindBoat(inst)
	if inst.target_wood then
		return inst.target_wood
	else
		CheckForBoats(inst)
		if inst.target_wood then
			return inst.target_wood
		end
	end
end
local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, 20)
end

function um_ocupus_eyetaclebrain:OnStart()
    local root = PriorityNode(
		{	
			Leash(self.inst, function() return self.inst.investigationspot end, 2, 2),
			FaceEntity(self.inst, FindBoat,KeepFaceTargetFn),
			
		}, 
	1)


    self.bt = BT(self.inst, root)
end

function um_ocupus_eyetaclebrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition(), true)
end
return um_ocupus_eyetaclebrain