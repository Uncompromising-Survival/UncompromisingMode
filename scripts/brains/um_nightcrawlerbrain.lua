require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/chaseandattack"
require "behaviours/avoidlight"
require "behaviours/findclosest"

local START_FACE_DIST = 15
local KEEP_FACE_DIST = 20

local SEE_DIST = 25

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 7

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30

local UM_NightCrawlerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local NO_TAGS = { "ratimmune", "FX", "NOCLICK", "DECOR", "INLIMBO", "planted", "trap", "raidrat", "spider", "catchable", "fire", "irreplaceable", "heavy", "prey", "bird", "outofreach", "_container" }

local function StealAction(inst)
	local targetpriority = FindEntity(inst, SEE_DIST,
	function(item)
		return item.components.inventoryitem ~= nil
			and item.components.inventoryitem.canbepickedup
			and item:IsOnValidGround()
		end,
	{ "_inventoryitem", "_equippable" },
	NO_TAGS)
	
	local targetpriority_secondary = FindEntity(inst, SEE_DIST,
	
	function(item)
		return item.components.inventoryitem ~= nil
			and item.components.inventoryitem.canbepickedup
			and item:IsOnValidGround()
		end,
	{ "_inventoryitem", "gem" },
	NO_TAGS)
	
	local target = FindEntity(inst, SEE_DIST,
	
	function(item)
		return item.components.inventoryitem ~= nil
			and item.components.inventoryitem.canbepickedup
			and item:IsOnValidGround()
		end,
	{ "_inventoryitem" },
	NO_TAGS)
			
	return targetpriority ~= nil and (inst._item ~= nil and not inst._item:HasTag("_equippable") or inst._item == nil) and BufferedAction(inst, targetpriority, ACTIONS.PICKUP)
		or targetpriority_secondary ~= nil and (inst._item ~= nil and not inst._item:HasTag("_equippable") and not inst._item:HasTag("gem") or inst._item == nil) and BufferedAction(inst, targetpriority_secondary, ACTIONS.PICKUP)
		or target ~= nil and inst._item == nil and BufferedAction(inst, target, ACTIONS.PICKUP) 
		or nil
end

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

function UM_NightCrawlerBrain:OnStart()
    local root = PriorityNode(
			{
			
				ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
				--[[WhileNode( function() return not self.inst.components.inventory:IsFull() end, "Steal",
					DoAction(self.inst, function() return StealAction(self.inst) end, "steal", true ),
					DoAction(self.inst, function() return EmptyChest(self.inst) end, "emptychest", true)),]]
				WhileNode( function() return Um_CustomLightCheck(self.inst, 0.15, .1) end, "OutLight",
					RunAway(self.inst, "player", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
				),
				AvoidLight(self.inst),
				Leash(self.inst, GetTargetPos, 0, 0, true),
			}, .25)

    self.bt = BT(self.inst, root)
end

return UM_NightCrawlerBrain
