require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/doaction"

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 20
local MAX_CHASE_TIME = 40

local SnowMongBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)


local FOOD_SEEK_RANGE_SQ = 20 * 20
local GEM_EAT_CAP = 10

local abominamole_wants = {"um_gemologybluegem1","um_gemologybluegem2","bluegem","ice","snowball_item"}
local GEM_PREFABS = { um_gemologybluegem1 = true, um_gemologybluegem2 = true }
local function IsAbominaMoleBait(inst)
	for i,v in ipairs(abominamole_wants) do
		if inst.prefab == v then
			return true
		end
	end
end

local TAKEBAIT_MUST_TAGS = { "_inventoryitem" }
local TAKEBAIT_CANT_TAGS = { "outofreach", "INLIMBO", "fire" }

local function SelectedTargetTimeout(target)
    target.selectedasmoletarget = nil
end

local function TakeBaitAction(inst)
    -- Don't look for bait if just spawned, busy making a new home, or has full inventory
    if inst:GetTimeAlive() < 3 or inst.sg:HasStateTag("busy") then
        return
    end
    -- Target is close and snowmong is healthy: keep fighting, skip food
    local target = inst.components.combat.target
    if target and target:IsValid()
        and inst:GetDistanceSqToInst(target) <= FOOD_SEEK_RANGE_SQ
        and inst.components.health:GetPercent() > 0.3 then
        return
    end

    local gem_cap_reached = (inst.gems_eaten or 0) >= GEM_EAT_CAP
    local target = FindEntity(inst, 32, function(item)
        if GEM_PREFABS[item.prefab] then
            return not gem_cap_reached
        end
        return IsAbominaMoleBait(item)
    end, TAKEBAIT_MUST_TAGS, TAKEBAIT_CANT_TAGS)
    if target ~= nil and not target.selectedasmoletarget and target:IsOnValidGround() then
        target.selectedasmoletarget = true
        target:DoTaskInTime(5, SelectedTargetTimeout)
        local act = BufferedAction(inst, target, ACTIONS.STEALMOLEBAIT)
        act.validfn = function()
            return not (target.components.inventoryitem ~= nil and target.components.inventoryitem:IsHeld())
                and not (target.components.burnable ~= nil and target.components.burnable:IsBurning())
        end
        return act
    end
end

function SnowMongBrain:OnStart()
	local root = PriorityNode(
	{
		BrainCommon.PanicTrigger(self.inst),
		BrainCommon.ElectricFencePanicTrigger(self.inst),
		DoAction(self.inst, TakeBaitAction, "Take Bait", false),
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
	}, 0.25)
	self.bt = BT(self.inst, root)
end

return SnowMongBrain