require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/panic"
require "behaviours/doaction"
require "behaviours/jukeandjive"

local BrainCommon = require("brains/braincommon")
local WobyBrainCommon = require "brains/wobycommon"

local MIN_FOLLOW_DIST = 0
local TARGET_FOLLOW_DIST = 7
local MAX_FOLLOW_DIST = 12

local SIT_DOWN_DISTANCE = 10

local PLATFORM_WANDER_DIST = 4
local WANDER_DIST = 12

local function GetOwner(inst)
    return inst.components.follower.leader
end

local function KeepFaceOwnerFn(inst, target)
    return inst.components.follower.leader == target
end

local function IsTryingToPerformAction(inst, performer, action)
    local act = performer.components.locomotor.bufferedaction--performer:GetBufferedAction()
    return act ~= nil and act.target == inst and act.action == action
end

local function TryingToInteractWithWoby(inst, performer)
    local interactions = { ACTIONS.FEED, ACTIONS.RUMMAGE, ACTIONS.STORE }
    for _, action in ipairs(interactions) do
        if IsTryingToPerformAction(inst, performer, action) then
            return true
        end
    end

    if inst.components.container:IsOpenedBy(performer) then
        return true
    end

    return false
end

local function GetRiderFn(inst)
    local leader = inst.components.follower ~= nil and inst.components.follower.leader
    if leader ~= nil and WobyBrainCommon.IsTryingToPerformAction(inst, leader, ACTIONS.MOUNT) then
        return leader
    end

    return nil
end

local function KeepRiderFn(inst, target)
    return WobyBrainCommon.IsTryingToPerformAction(inst, target, ACTIONS.MOUNT)
end

local function GetWalterInteractionFn(inst)
   local leader = inst.components.follower ~= nil and inst.components.follower.leader
    if leader ~= nil and TryingToInteractWithWoby(inst, leader) then
        return leader
    end

    return nil
end

local function GetGenericInteractionFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, SIT_DOWN_DISTANCE, true)
    for k,player in pairs(players) do
        if WobyBrainCommon.TryingToInteractWithWoby(inst, player) then
            return player
        end
    end

    return nil
end

local function KeepGenericInteractionFn(inst, target)
    return TryingToInteractWithWoby(inst, target)
end

local function GetHomePos(inst)
    local platform = inst:GetCurrentPlatform()
    if platform then
        return platform:GetPosition()
    else
        local owner = GetOwner(inst)
        if owner then
            return owner:GetPosition()
        end
    end

    return nil
end

local function GetWanderDist(inst)
   local platform = inst:GetCurrentPlatform()
    if platform then
        return platform.components.walkableplatform and platform.components.walkableplatform.platform_radius or PLATFORM_WANDER_DIST
    else
        return WANDER_DIST
    end
end

-------------------------------------------------------------------------------
--  Combat Avoidance, transplanted from crittersbrain

local COMBAT_TOO_CLOSE_DIST = 10                 -- distance for find enitities check
local COMBAT_TOO_CLOSE_DIST_SQ = COMBAT_TOO_CLOSE_DIST * COMBAT_TOO_CLOSE_DIST
local COMBAT_SAFE_TO_WATCH_FROM_DIST = 12        -- will run to this distance and watch if was too close
local COMBAT_SAFE_TO_WATCH_FROM_MAX_DIST = 14   -- combat is quite far away now, better catch up
local COMBAT_SAFE_TO_WATCH_FROM_MAX_DIST_SQ = COMBAT_SAFE_TO_WATCH_FROM_MAX_DIST * COMBAT_SAFE_TO_WATCH_FROM_MAX_DIST
local COMBAT_TIMEOUT = 8

local function _avoidtargetfn(self, target)
    if target == nil or not target:IsValid() then
        return false
    end

    local owner = self.inst.components.follower.leader
    local owner_combat = owner ~= nil and owner.components.combat or nil
    local target_combat = target.components.combat
    if owner_combat == nil or target_combat == nil or not self.inst:IsNear(owner, 20) then
        return false
    elseif target_combat:TargetIs(owner)
        or (target.components.grouptargeter ~= nil and target.components.grouptargeter:IsTargeting(owner))
		or target_combat:TargetIs(self.inst)
        or (target.components.grouptargeter ~= nil and target.components.grouptargeter:IsTargeting(self.inst)) then
        return true
    end

    local distsq = owner:GetDistanceSqToInst(target)
    if distsq >= COMBAT_SAFE_TO_WATCH_FROM_MAX_DIST_SQ then
        -- Too far
        return false
    elseif distsq < COMBAT_TOO_CLOSE_DIST_SQ and target_combat:HasTarget() then
        -- Too close to any combat
        return true
    end

    -- Is owner in combat with target?
    -- Are owner and target both in any combat?
    local t = GetTime()
    return  (   (owner_combat:IsRecentTarget(target) or target_combat:HasTarget()) and
                math.max(owner_combat.laststartattacktime or 0, owner_combat.lastdoattacktime or 0) + COMBAT_TIMEOUT > t
            ) or
            (   owner_combat.lastattacker == target and
                owner_combat:GetLastAttackedTime() + COMBAT_TIMEOUT > t
            )
end

local function CombatAvoidanceFindEntityCheck(self)
    return function(ent)
            if _avoidtargetfn(self, ent) then
                self.inst:PushEvent("critter_avoidcombat", {avoid=true})
                self.runawayfrom = ent
                return true
            end
            return false
        end
end

local function ValidateCombatAvoidance(self)
    if self.runawayfrom == nil or 
		self.inst:GetCurrentPlatform() ~= nil or 
		self.inst.components.follower.leader ~= nil and not 
		self.inst:IsNear(self.inst.components.follower.leader, 20) then
        return false
    end

    if not self.runawayfrom:IsValid() then
        self.inst:PushEvent("critter_avoidcombat", {avoid=false})
        self.runawayfrom = nil
        return false
    end

    if not self.inst:IsNear(self.runawayfrom, COMBAT_SAFE_TO_WATCH_FROM_MAX_DIST) then
        return false
    end

    if not _avoidtargetfn(self, self.runawayfrom) then
        self.inst:PushEvent("critter_avoidcombat", {avoid=false})
        self.runawayfrom = nil
        return false
    end

    return true
end

local COMBAT_AVOIDANCE_MUST_TAGS = { "_combat", "_health" }
local COMBAT_AVOIDANCE_CANT_TAGS = { "wall", "INLIMBO" }

local function HasAvoidCombatTarget(self)
    local shouldavoid = ValidateCombatAvoidance(self)

    if not shouldavoid then
        self.runawayfrom = nil
    end

    return shouldavoid or FindEntity(self.inst, COMBAT_TOO_CLOSE_DIST, CombatAvoidanceFindEntityCheck(self), COMBAT_AVOIDANCE_MUST_TAGS, COMBAT_AVOIDANCE_CANT_TAGS) ~= nil
end

-------------------------------------------------------------------------------

local function IsAllowedToWorkThings(inst)
    return inst.woby_commands_classified ~= nil and inst.woby_commands_classified:ShouldWork()
end

local function HasTaskAidBehavior(inst)
    local skilltreeupdater = inst._playerlink ~= nil and inst._playerlink.components.skilltreeupdater or nil

    return skilltreeupdater ~= nil and skilltreeupdater:IsActivated("walter_woby_taskaid")
end

local WORK_MIN_DISTANCE = 3

-- Adding a min distance to work actions.

local function FindNew_MINE(inst, leaderdist, finddist, ...)
    local act = BrainCommon.AssistLeaderDefaults.MINE.FindNew(inst, leaderdist, finddist, ...)

    if act == nil then
        return
    end

    act.distance = WORK_MIN_DISTANCE + act.target:GetPhysicsRadius(0)

    if inst._playerlink ~= nil then
        inst._playerlink:PushEvent("tellwobywork", inst)
    end

    return act
end

local function FindNew_CHOP(inst, leaderdist, finddist, ...)
    local act = BrainCommon.AssistLeaderDefaults.CHOP.FindNew(inst, leaderdist, finddist, ...)

    if act == nil then
        return
    end

    act.distance = WORK_MIN_DISTANCE + act.target:GetPhysicsRadius(0)

    if inst._playerlink ~= nil then
        inst._playerlink:PushEvent("tellwobywork", inst)
    end

    return act
end

-------------------------------------------------------------------------------
-- CUSTOM FUNCTIONS FOR WOBY ACTIONS

local function HasWobyTarget(inst)
    return inst.wobytarget ~= nil and
			inst.wobytarget:IsValid() and not
			inst.wobytarget:HasTag("outofreach") and not
			inst.wobytarget:HasTag("INLIMBO") and
			inst.wobytarget:IsOnPassablePoint() ~= nil and inst.wobytarget:IsOnPassablePoint() and
			(
			-- Check for Picking (plants)
			(inst.wobytarget.components.pickable ~= nil and inst.wobytarget.components.pickable.canbepicked and inst.wobytarget.components.pickable.caninteractwith and not inst.wobytarget:HasTag("snowpile_basic")) or
			-- Check for item to pick up		
			(inst.wobytarget.components.inventoryitem ~= nil and inst.wobytarget.components.inventoryitem.canbepickedup and not inst.wobytarget.components.combat) or
			-- Check for harvestable target	
			(inst.wobytarget.components.harvestable ~= nil and inst.wobytarget.components.harvestable:CanBeHarvested()) or 
			-- I'm big AF and I can dig things
			(inst.wobytarget.components.workable ~= nil and inst.wobytarget.components.workable:GetWorkAction() == ACTIONS.DIG and (inst.wobytarget:HasTag("snowpile_basic") or (inst.wobytarget.components.pickable ~= nil and (not inst.wobytarget.components.pickable.canbepicked or not inst.wobytarget.components.pickable.caninteractwith)) or inst.wobytarget.components.pickable == nil)) or 
			-- Bark Bark! Attack me you dink!
			(inst.wobytarget.components.combat ~= nil and 
			-- is my pal walter near?
			(inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, 20)) and
			inst.wobytarget.components.combat:CanTarget(inst) and not
			(inst.wobytarget.components.combat:TargetIs(inst) or inst.wobytarget.components.grouptargeter ~= nil and inst.wobytarget.components.grouptargeter:IsTargeting(inst)) and not
			(inst.wobytarget.sg ~= nil and inst.wobytarget.sg:HasStateTag("attack")))
			
			) or false
end

local function DoTargetAction(inst)
    return inst.wobytarget ~= nil and
			inst.wobytarget:IsValid() and not
			inst.wobytarget:HasTag("outofreach") and not
			inst.wobytarget:HasTag("INLIMBO") and
			inst.wobytarget:IsOnPassablePoint() ~= nil and inst.wobytarget:IsOnPassablePoint() and
			(
			-- Check for Picking (plants)
			(inst.wobytarget.components.pickable ~= nil and inst.wobytarget.components.pickable.canbepicked and inst.wobytarget.components.pickable.caninteractwith and not inst.wobytarget:HasTag("snowpile_basic") and
			BufferedAction(inst, inst.wobytarget, ACTIONS.PICK)) or
			-- Check for item to pick up		
			(inst.wobytarget.components.inventoryitem ~= nil and inst.wobytarget.components.inventoryitem.canbepickedup and not inst.wobytarget.components.combat and
			BufferedAction(inst, inst.wobytarget, ACTIONS.PICKUP)) or
			-- Check for harvestable target	
			(inst.wobytarget.components.harvestable ~= nil and inst.wobytarget.components.harvestable:CanBeHarvested() and
			BufferedAction(inst, inst.wobytarget, ACTIONS.HARVEST)) or 
			-- I'm big AF and I can dig things
			((inst.wobytarget.components.workable ~= nil and inst.wobytarget.components.workable:GetWorkAction() == ACTIONS.DIG and (inst.wobytarget:HasTag("snowpile_basic") or (inst.wobytarget.components.pickable ~= nil and (not inst.wobytarget.components.pickable.canbepicked or not inst.wobytarget.components.pickable.caninteractwith)) or inst.wobytarget.components.pickable == nil)) and 
			BufferedAction(inst, inst.wobytarget, ACTIONS.DIG)) or 
			-- Bark Bark! Attack me you dink!
			(inst.wobytarget.components.combat ~= nil and 
			-- is my pal walter near?
			(inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, 20)) and
			inst.wobytarget.components.combat:CanTarget(inst) and not
			(inst.wobytarget.components.combat:TargetIs(inst) or inst.wobytarget.components.grouptargeter ~= nil and inst.wobytarget.components.grouptargeter:IsTargeting(inst)) and not
			(inst.wobytarget.sg ~= nil and inst.wobytarget.sg:HasStateTag("attack")) and
			BufferedAction(inst, inst.wobytarget, ACTIONS.WOBY_BARK))
			
			) or nil
end

local function HasSitTarget(inst)
    return inst.wobytarget ~= nil and inst.wobytarget:HasTag("wobysittarget") and inst.wobytarget:IsOnPassablePoint() or nil
end

local function GoSitAction(inst)
    if inst.wobytarget == nil then
		return
	end
	
    local sitPos = inst.wobytarget:GetPosition()
    return sitPos ~= nil
        and BufferedAction(inst, nil, ACTIONS.WALKTO, nil, sitPos, nil, .3)
        or nil
end

-------------------------------------------------------------------------------

local WobyBigBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)

    self._hasavoidcombattarget = HasAvoidCombatTarget
end)

function WobyBigBrain:OnStart()
    local nodes = PriorityNode(
    {
        WobyBrainCommon.CourierNode(self.inst),
        WobyBrainCommon.SitStillNode(self.inst),
		
		WhileNode( function() return HasWobyTarget(self.inst) end, "Has Target",
			DoAction(self.inst, DoTargetAction, nil, true )
		),
		
		WhileNode(function() return not WobyBrainCommon.IsWheelOpen(self.inst) end, "combat avoidance",
			PriorityNode({
			BrainCommon.PanicTrigger(self.inst),
			JukeAndJive(self.inst, {tags={"_combat", "_health"}, notags={"player", "wall", "INLIMBO", "rabbit", "bird"},
					fn=CombatAvoidanceFindEntityCheck(self)},
					COMBAT_TOO_CLOSE_DIST,
					COMBAT_SAFE_TO_WATCH_FROM_DIST),

				WhileNode(function() return ValidateCombatAvoidance(self) end, "Is Near Combat",
					PriorityNode({
						WobyBrainCommon.PickUpAmmoNode(self.inst),
						FaceEntity(self.inst, GetOwner, KeepFaceOwnerFn, nil, "cower"),
					}, .25)),
			}, 0.25)),

		WhileNode(function() return WobyBrainCommon.IsWheelOpen(self.inst) and HasAvoidCombatTarget(self) end, "wheel open near combat",
			FaceEntity(self.inst, GetOwner, KeepFaceOwnerFn, nil, "cower")),

		WobyBrainCommon.WatchingMinigameNode(self.inst),
				
		WhileNode( function() return HasSitTarget(self.inst) end, "Has Target",
			DoAction(self.inst, GoSitAction, nil, true )
		),

        -- These are kept separatly because we have different animations for mounting vs. opening and feeding vs. paused for wheel open
        FaceEntity(self.inst, GetRiderFn, KeepRiderFn),
        FaceEntity(self.inst, WobyBrainCommon.GetWalterInteractionFn, WobyBrainCommon.KeepGenericInteractionFn, nil, "sit_alert_tailwag"),
		WhileNode(function() return WobyBrainCommon.IsWheelOpen(self.inst) end, "wheel open",
			FaceEntity(self.inst, GetOwner, KeepFaceOwnerFn)),

		--When recalling Woby, temporarily block helper actions until she's fully returned to you.
		WobyBrainCommon.RecallNode(self.inst,
			Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true)),

        WhileNode(function() return HasTaskAidBehavior(self.inst) and IsAllowedToWorkThings(self.inst) end, "HasTaskAidBehavior",
            PriorityNode({
                BrainCommon.NodeAssistLeaderDoAction(self, { action = "CHOP", shouldrun = true, finder = FindNew_CHOP }),
                BrainCommon.NodeAssistLeaderDoAction(self, { action = "MINE", shouldrun = true, finder = FindNew_MINE }),
            }, .25)
        ),

        WobyBrainCommon.ForagerNode(self.inst),
        WobyBrainCommon.RetrieveAmmoNode(self.inst),
        WobyBrainCommon.FetchingActionNode(self.inst),
		
		WhileNode(function() return TheWorld.state.isnight end, "NightFollow",
			Follow(self.inst, function() return self.inst.components.follower.leader end,
                     MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST / 1.5, MAX_FOLLOW_DIST / 1.5, true)
		),
		
        Follow(self.inst, function() return self.inst.components.follower.leader end,
                     MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),

        -- Kept down here because woby should prioritize following walter over storage and food by other players
        FaceEntity(self.inst, GetGenericInteractionFn, KeepGenericInteractionFn, nil, "sit_alert"),


        Wander(self.inst, GetHomePos, GetWanderDist, {minwaittime = 6, randwaittime = 6}),
    }, .25)

    local root = PriorityNode({
		WhileNode(
			function()
				return not self.inst.sg:HasStateTag("jumping") and (self.inst.sg.currentstate == nil or self.inst.sg.currentstate.name ~= "transform")
			end,
			"<busy state guard>",
            nodes
        )
    }, .25)

    self.bt = BT(self.inst, root)
end

return WobyBigBrain
