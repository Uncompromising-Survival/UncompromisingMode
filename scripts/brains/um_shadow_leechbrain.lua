require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/chaseandattack"
require "behaviours/avoidlight"
require "behaviours/findclosest"

local AVOID_PLAYER_DIST = 3
local AVOID_PLAYER_DIST_SQ = AVOID_PLAYER_DIST * AVOID_PLAYER_DIST
local AVOID_PLAYER_STOP = 8

local AVOID_PLAYER_DIST_COMBAT = 12
local AVOID_PLAYER_DIST_SQ_COMBAT  = AVOID_PLAYER_DIST_COMBAT  * AVOID_PLAYER_DIST_COMBAT 
local AVOID_PLAYER_STOP_COMBAT  = 15

local AVOID_RING_DIST = TUNING.FIRE_DETECTOR_RANGE
local AVOID_RING_STOP  = TUNING.FIRE_DETECTOR_RANGE + 2

local MAX_CHASE_TIME = 20
local MAX_CHASE_DIST = 40

local SEE_LIGHT_DIST = 50

local SEE_DIST = 25
local TOOCLOSE = 3

local SEE_BAIT_DIST = 15
local MAX_WANDER_DIST = 5
local Um_Shadow_LeechBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function SafeLightDist(inst, target)
    if target:HasTag("player") or target:HasTag("playerlight") then
        return 5
    end
	
	print(target.Light ~= nil and target.Light:GetCalculatedRadius() or "not light target")
    local owner = target.components.inventoryitem ~= nil and target.components.inventoryitem:GetGrandOwner() or nil
    return (owner ~= nil and owner:HasTag("player") and 5)
        or (target.Light ~= nil and target.Light:GetCalculatedRadius())
        or 5
end

local function GetTargetPos(inst)
	local target = inst:GetNearestPlayer(true)
	return target ~= nil and target:GetPosition() or nil
end

function Um_Shadow_LeechBrain:OnStart()
    local root = PriorityNode(
			{
				JukeAndJive(self.inst, "um_vox_ring", AVOID_RING_DIST, AVOID_RING_STOP),
                WhileNode( function() return (self.inst:IsInLight() or self.inst.components.combat.target and self.inst.components.combat:InCooldown()) and not self.inst.sg:HasStateTag("attack") and not self.inst.sg:HasStateTag("busy") end, "Dodge",
					JukeAndJive(self.inst, "lightsource", AVOID_PLAYER_DIST_COMBAT, AVOID_PLAYER_STOP_COMBAT),
					JukeAndJive(self.inst, "player", AVOID_PLAYER_DIST_COMBAT, AVOID_PLAYER_STOP_COMBAT)),
				JukeAndJiveAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
				WhileNode( function() return self.inst:IsInLight() and not self.inst.sg:HasStateTag("attack") end, "Light",
					FindClosest(self.inst, SEE_LIGHT_DIST, SafeLightDist, { "fire" }, nil, { "campfire", "lighter" })),
				Leash(self.inst, GetTargetPos, 0, 0, true),
			}, .25)

    self.bt = BT(self.inst, root)
end

return Um_Shadow_LeechBrain
