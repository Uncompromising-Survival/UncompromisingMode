require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/doaction"
require "behaviours/minperiod"
require "behaviours/panic"
require "behaviours/runaway"

local HoodedWidowBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

-----------------------------------------------------------------
local FORCE_MELEE_DIST = 4
local MAX_WANDER_DIST = 7


local function GoHomeAction(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    return home ~= nil
        and home:IsValid()
        and home.components.childspawner ~= nil
        and (home.components.health == nil or not home.components.health:IsDead())
        and BufferedAction(inst, home, ACTIONS.GOHOME)
        or nil
end

local function WebSlingerAction(inst)
	if not inst.sg:HasStateTag("busy") then
		return inst.sg:GoToState("launchprojectile")
	end
end

local function JumpHomeAction(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    return home ~= nil
        and home:IsValid()
        and home.components.childspawner ~= nil
        and (home.components.health == nil or not home.components.health:IsDead())
        and inst.sg:GoToState("jumphome") --Instead we should be just jumping back into the canopy
        or nil
end

local function CanMeleeNow(inst)
    local target = inst.components.combat.target
    if target == nil or inst.components.combat:InCooldown() then
        return false
    end
    if target.components.pinnable ~= nil then
        return not target.components.pinnable:IsValidPinTarget()
    end
    return inst:IsNear(target, FORCE_MELEE_DIST)
end

local function TargetLeavingArena(inst)
	if inst.components.combat~= nil and inst.components.combat.target ~= nil and not inst.prey then
		local target = inst.components.combat.target
		local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
		if (target ~= nil and home ~= nil) then
			local dx, dy, dz = target.Transform:GetWorldPosition()
			local spx, spy, spz = home.Transform:GetWorldPosition()
			
			return target ~= nil and home ~= nil and distsq(spx, spz, dx, dz) >= (TUNING.DRAGONFLY_RESET_DIST*7)
		else
			return false
		end
	else
		return false
	end
end


local function ShouldLeave(inst)
	if inst.investigated and inst.components.combat.target == nil then
		return true
	end
end

local function ReadyToLeapOrStick(inst)
	if inst.components.timer and (not inst.components.timer:TimerExists("mortar") or not inst.components.timer:TimerExists("pounce")) then
		return true
	end
end

local function RepositionLimitation(inst)
	if not inst.repositionlimit and ReadyToLeapOrStick(inst) then
		inst.repositionlimittask = inst:DoTaskInTime(math.random(2,3),function(inst)
			inst.repositionlimit = true
			inst.repositionlimittask = nil
		end)
	else
		inst.repositionlimit = nil
		return true
	end
end

local function DistancedFromTarget(inst)
	if inst.components.combat and inst.components.combat.target then
		return inst:GetDistanceSqToInst(inst.components.combat.target) > 5^2
	end
end

local function NearPoint(inst)
	if inst._dodgedest then
		return inst:GetDistanceSqToPoint(inst._dodgedest) < 2
	end
end

local function DoSpecial(inst)
	if inst.components.health and not inst.components.health:IsDead() then
		if inst.repositionlimittask then
			inst.repositionlimittask:Cancel()
			inst.repositionlimittask = nil
		end
		--TheNet:Announce("Told to special")
		if not inst.sg:HasStateTag("busy") and inst.components.combat and inst.components.combat.target then -- If we don't have a target, don't try it
			if not inst.components.timer:TimerExists("pounce") then --If both are done from counter, first pounce THEN lob
				--return inst.sg:GoToState("preleapattack")
				inst.AnimState:SetBank("widow")
				return inst.sg:GoToState("preleapattack") --inst.sg:GoToState("prechargeattack")
			elseif not inst.components.timer:TimerExists("mortar") then
				inst.AnimState:SetBank("widow")
				return inst.sg:GoToState("lobprojectile")
			end
		else
			inst.components.timer:StartTimer("pounce",math.random(15,20)) --Restart Pounce
			inst.components.timer:StartTimer("mortar",math.random(20,30)) --Restart Mortar	
		end
	end
end

local function Eat(inst)
	local webbedcreature = FindEntity(inst,2,nil,{"webbedcreature"})
	if webbedcreature then -- Food's here! Time to dine
		inst.prey = webbedcreature
		--TheNet:Announce("told to eat")
		return inst.sg:GoToState("eat_pre")
	else	-- The prey was fake or was removed before we could eat it. Bummer.
		inst.prey = nil
	end
end

local function NearPrey(inst) --Are we near the webbed creature we're interested in eating? (If we are not already eating)
	if inst.prey and 8^2 > inst:GetDistanceSqToInst(inst.prey) and not inst.sg:HasStateTag("eating") then
		return true
	end
end


local function DefinePrey(inst)
	--[[local player = FindEntity(inst.components.homeseeker.home,math.sqrt(TUNING.DRAGONFLY_RESET_DIST*7),nil,{"player"},{"playerghost"}) --Try to find additional players near our prey
	if player then --There's another player close to our prey, let's get them
		TheNet:Announce("found new target")
		inst.components.combat:SetTarget(player)
		return inst.sg:GoToState("taunt")
	else]]
	if inst.components.health:GetPercent() >= 1 and inst.components.combat and inst.components.combat.target then --We're already healed, whoever is attacking us is just running away after starting the fight I guess
		inst.components.combat:DropTarget()
		if inst.prey then
			inst.prey = nil
		end
		inst.investigated = true
		--return inst.sg:GoToState("taunt")
	else
		if inst.components.knownlocations:GetLocation("home") then
			local home = inst.components.knownlocations:GetLocation("home")
			local preys = TheSim:FindEntities(home.x,home.y,home.z,16,{"webbedcreature"})
			local mindist = 9999
			local xnew,ynew,znew = inst.Transform:GetWorldPosition()
			for i,prey in ipairs(preys) do
				local xtest,y,ztest = prey.Transform:GetWorldPosition()
				if mindist > inst:GetDistanceSqToPoint(xtest,y,ztest) and TheWorld.Map:IsAboveGroundAtPoint(xtest,y,ztest) then --We're looking for the dodge position closest to widow
					mindist = inst:GetDistanceSqToPoint(xtest,y,ztest)
					inst.prey = prey
				end
			end
			--TheNet:Announce("we did a prey")
			return inst.sg:GoToState("leaptoprey_pre")
		end
	end
end

function HoodedWidowBrain:OnStart()
    local root = PriorityNode(
    {	
		
		WhileNode(function() return self.inst.bullier end,"BeingBullied", DoAction(self.inst, JumpHomeAction)), -- Under any circumstances where an epic is nearby, leave the fight.
		
		--WhileNode(function() return TargetLeavingArena(self.inst) end, "PullThemBack", DoAction(self.inst, WebSlingerAction)), -- Swap for eating...
		
		--Prey but it's Widow vs Wilson
		--WhileNode(function() return NearPrey(self.inst) end, "EatPrey", DoAction(self.inst, Eat)),
		--WhileNode(function() return self.inst.prey end, "PursuePrey",  Leash(self.inst, function() return self.inst.prey:GetPosition() end, 1, 1)),
		WhileNode(function() return TargetLeavingArena(self.inst) and not self.inst.prey end, "DefinePrey", DoAction(self.inst, DefinePrey)),
		
		--Get Ready to be special... (I need to position myself near a good spot to do a special)
		WhileNode(function() return ReadyToLeapOrStick(self.inst) and NearPoint(self.inst) end, "DoSpecial", DoAction(self.inst, DoSpecial)),
		WhileNode(function() return ReadyToLeapOrStick(self.inst) and not self.inst.prey end, "GetDistanceToSpecial", Leash(self.inst, function() 
			return self.inst._dodgedest end, 
		1, 1)), --Ready to pounce or Web, get some distance first
		
		--I've got no special tricks ready, all I can do is attack.
		WhileNode(function() return not (ReadyToLeapOrStick(self.inst) and (self.inst.components.combat.target and self.inst.components.combat:InCooldown())) end, "ChaseAndAttack", ChaseAndAttack(self.inst,30)), --Chase and attack for 30 seconds, if the player stops after that then quit and go home
		
		--Somehow there's noone willing to challenge Hooded Widow? Probably best to go home... though we'll wait a second just incase
		WhileNode(function() return ShouldLeave(self.inst) end,"NoTarget", DoAction(self.inst, GoHomeAction)), --No target and done investigating? we should probably go home then.
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
    }, 2)
    
    self.bt = BT(self.inst, root)
    
end

return HoodedWidowBrain