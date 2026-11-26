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
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    return home and home:IsValid() and home.components.childspawner
        and (home.components.health == nil or not home.components.health:IsDead())
        and BufferedAction(inst, home, ACTIONS.GOHOME)
        or nil
end

local function JumpHomeAction(inst)
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    return home and home:IsValid() and home.components.childspawner
        and (home.components.health == nil or not home.components.health:IsDead())
        and inst.sg:GoToState("jumphome") --Instead we should be just jumping back into the canopy
        or nil
end

local function CanMeleeNow(inst)
    local target = inst.components.combat.target
    if not target or inst.components.combat:InCooldown() then
        return false
    end
    if target.components.pinnable then
        return not target.components.pinnable:IsValidPinTarget()
    end
    return inst:IsNear(target, FORCE_MELEE_DIST)
end

local function TargetLeavingArena(inst)
    if inst.components.combat and inst.components.combat.target and not inst.prey then
        local target = inst.components.combat.target
        local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
        if (target and home) then
            local dx, dy, dz = target.Transform:GetWorldPosition()
            local spx, spy, spz = home.Transform:GetWorldPosition()
            return target and home and math.sqrt(distsq(spx, spz, dx, dz)) >= (24)
        end
    end
    return false
end


local function ShouldLeave(inst)
    if inst.investigated and not inst.components.combat.target and inst.components.health and inst.components.health:GetPercent() >= 1 then
        return true
    end
end

local function ReadyToLeapOrStick(inst)
    if inst.components.timer and not inst.components.timer:TimerExists("special") then
        return true
    end
end

local function DistancedFromTarget(inst)
    if inst.components.combat and inst.components.combat.target then
        return inst:GetDistanceSqToInst(inst.components.combat.target) > 5 ^ 2
    end
end

local function NearPoint(inst)
    if inst._dodgedest then
        return (inst:GetDistanceSqToPoint(inst._dodgedest) < 2 or inst._dodgetimeout)
    end
end

local function DoSpecial(inst)
    if inst.components.health and not inst.components.health:IsDead() then
        if inst.repositionlimittask then
            inst.repositionlimittask:Cancel()
            inst.repositionlimittask = nil
        end

        if not inst.sg:HasStateTag("busy") and inst.components.combat and inst.components.combat.target then -- If we don't have a target, don't try it
            -- Reset the timeout
            inst:CancelDodgeTimeOut()
            
            if (inst.recent_special and inst.recent_special == "charge_or_leap") then --If both are done from counter, first pounce THEN lob
                inst.AnimState:SetBank("widow")
                inst.recent_special = "mortar"
                return inst.sg:GoToState("lobprojectile")
            else
                inst.recent_special = "charge_or_leap"
                inst.AnimState:SetBank("widow")
                if inst.components.health:GetPercent() < 0.4 then
                    inst.treetarget = nil
                    return inst.sg:GoToState("prechargeattack")
                end
                return inst.sg:GoToState("preleapattack") --inst.sg:GoToState("prechargeattack")
            end
        else
            UMCommonFns.RestartTimer(inst, {name = "special", time = 15}) -- Restart Pounce
        end
    end
end

local function Eat(inst)
    local webbedcreature = FindEntity(inst, 2, nil, {"webbedcreature"})
    if webbedcreature then -- Food's here! Time to dine
        inst.prey = webbedcreature
        --TheNet:Announce("told to eat")
        return inst.sg:GoToState("eat_pre")
    else -- The prey was fake or was removed before we could eat it. Bummer.
        inst.prey = nil
    end
end

local function NearPrey(inst) --Are we near the webbed creature we're interested in eating? (If we are not already eating)
    if inst.prey and 8 ^ 2 > inst:GetDistanceSqToInst(inst.prey) and not inst.sg:HasStateTag("eating") then
        return true
    end
end


local function DefinePrey(inst)
    if inst.components.health:GetPercent() >= 1 and inst.components.combat and inst.components.combat.target then --We're already healed, whoever is attacking us is just running away after starting the fight I guess
        inst.components.combat:DropTarget()
        if inst.prey then inst.prey = nil end
        inst.investigated = true
    else
        if not (inst.components.health and inst.components.health:IsDead()) and inst.components.knownlocations:GetLocation("home") then
            local home = inst.components.knownlocations:GetLocation("home")
            local ents = TheSim:FindEntities(home.x, home.y, home.z, 16)
            local preys = {}
            for i,v in ipairs(ents) do
                if v.prefab == "webbedcreature" then -- AXE did this when trying to fix a bug... this isn't what the fix was but we may as well get ready to not have as many tags.
                    table.insert(preys,v)
                end
            end
            local mindist = 9999
            local xnew,ynew,znew = inst.Transform:GetWorldPosition()
            for i,prey in ipairs(preys) do
                local xtest,y,ztest = prey.Transform:GetWorldPosition()
                if mindist > inst:GetDistanceSqToPoint(xtest, y, ztest) and TheWorld.Map:IsAboveGroundAtPoint(xtest, y, ztest) then --We're looking for the dodge position closest to widow
                    mindist = inst:GetDistanceSqToPoint(xtest, y, ztest)
                    inst.prey = prey
                end
            end
            return inst.sg:GoToState("leaptoprey_pre")
        end
    end
end

local function CanHitTarget(inst)
    local combat = inst.components.combat
    if combat then
        local target = combat.target
        if target and target:GetDistanceSqToInst(inst) < combat.attackrange^2 then
            return true
        end
    end
end

function HoodedWidowBrain:OnStart()
    local root = PriorityNode(
    {
        -- Someone's trying to attack me while I'm returning, give them a piece of my mind.
        --WhileNode(function() return self.inst.prey and CanHitTarget(self.inst) end, "DefendMyself", ChaseAndAttack(self.inst,30)),
        
        --Prey but it's Widow vs Wilson
        WhileNode(function() return TargetLeavingArena(self.inst) and not self.inst.prey end, "DefinePrey", DoAction(self.inst, DefinePrey)),
        
        -- I'm in position, time to do a special
        WhileNode(function() return ReadyToLeapOrStick(self.inst) and NearPoint(self.inst) end, "DoSpecial", DoAction(self.inst, DoSpecial)),
        
        -- Gotta reposition for the special
        WhileNode(function() return ReadyToLeapOrStick(self.inst) and not self.inst.prey end, "GetDistanceToSpecial", Leash(self.inst, function() 
            return self.inst._dodgedest end, 
        1, 1)), --Ready to pounce or Web, get some distance first
        
        --I've got no special tricks ready, all I can do is attack.
        WhileNode(function() return not (ReadyToLeapOrStick(self.inst) and (self.inst.components.combat.target and self.inst.components.combat:InCooldown())) end, "ChaseAndAttack", ChaseAndAttack(self.inst,30)), --Chase and attack for 30 seconds, if the player stops after that then quit and go home
        
        --Somehow there's noone willing to challenge Hooded Widow? Probably best to go home... though we'll wait a second just incase
        WhileNode(function() return ShouldLeave(self.inst) end,"NoTarget", DoAction(self.inst, GoHomeAction)), --No target and done investigating? we should probably go home then.
        
    }, 2)

    self.bt = BT(self.inst, root)
end

return HoodedWidowBrain