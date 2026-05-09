require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/standandattack"

local BrainCommon = require("brains/braincommon")

local MAX_CHASE_TIME = 20
local MAX_WANDER_DIST = 16
local MAX_CHASEAWAY_DIST = 32
local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8
local WARN_BEFORE_ATTACK_TIME = 2


local function GoHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker:HasHome() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME, nil, nil, nil, 0.2)
    end
end

local SEE_FOOD_DIST = 20

local function KeepFaceTargetFn(inst, target)
    return target.components.health and
        not target.components.health:IsDead() and
        inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST
end

local cold_prefabs = 
{
	"ice",
	"blueamulet",
	"icestaff",
	"um_ghost_pepper_item",
	"um_ice_tail",
	"um_ice_sicle",
	"bluegem",
	"um_rimeweed_itemvine",
	"um_rimeweed_itemflower",
	"rimeweed_whip",
	"um_hat_rime",
	"um_rimeweed_tequila",
	"um_rimeweed_spagett",
	"um_ghost_fajita",
}

local function CheckColdTags(ent)
	for i,v in ipairs(cold_prefabs) do
		if ent.prefab == v then
			return ent
		end
	end
end

local EATFOOD_CANT_TAGS = { "INLIMBO", "outofreach" }

local function FindFood(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, CheckColdTags, nil, EATFOOD_CANT_TAGS)
	if target == nil or not target:IsOnValidGround() then
		return nil
	end

	return target
end

local function EatFoodAction(inst, checksafety)
	local target = FindFood(inst)
	if target then
		local act = BufferedAction(inst, target, ACTIONS.EAT)
		act.validfn = function()
			return target.components.inventoryitem == nil
				or target.components.inventoryitem.owner == nil
				or target.components.inventoryitem.owner == inst
		end
		inst._hacky_eat_target = target
		return act
	end 
end

local function HasPepper(item)
    return item.components.pickable ~= nil and (item.components.pickable.product == "um_ghost_pepper_item")
end

local PICKBERRIES_MUST_TAGS = { "pickable" }
local function PickPepperAction(inst)
    local target = FindEntity(inst, SEE_FOOD_DIST, HasPepper, PICKBERRIES_MUST_TAGS)
    return target ~= nil
        and BufferedAction(inst, target, ACTIONS.PICK)
        or nil
end

local function CloseToHome(inst)
    if inst.components.homeseeker and inst.components.homeseeker:HasHome() then
		local home = inst.components.homeseeker.home
		if inst:GetDistanceSqToInst(home) < 4^2 then
			return true
		else
			return false
		end
    end
end

local UM_PepperdragonBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function UM_PepperdragonBrain:OnStart()

    local root =
        PriorityNode(
        {
			-- GOTTA DO WHATEVER KLEI TOLD ME TO
			BrainCommon.PanicTrigger(self.inst),
            BrainCommon.ElectricFencePanicTrigger(self.inst),

			-- OW THAT FUCKIN HURT
			WhileNode(function() return self.inst.components.health and self.inst.components.health:GetPercent() < 0.33 and not CloseToHome(self.inst) end, "Weak", -- if you're angry, don't care about eating.
				DoAction(self.inst, function() return GoHomeAction(self.inst) end, "GoHome", true)
			),

			-- GET OUT OF MY HOUSE
			WhileNode(function() return self.inst.components.health and self.inst.components.health:GetPercent() < 0.33 and CloseToHome(self.inst) end, "Weak", -- if you're angry, don't care about eating.
				StandAndAttack(self.inst)
			),

			-- IM PISSED AND STRONG GO KICK THEIR ASSES
			WhileNode(function() return self.inst.components.timer:TimerExists("pissedoff") end, "Angry", -- if you're angry, don't care about eating.
				ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME))
			),

			-- AWW MY BELLY FULL GOTTA GO NIGHTY NIGHT
            WhileNode(function() return self.inst.components.timer:TimerExists("bellyfull") end, "Full",
				DoAction(self.inst, function() return GoHomeAction(self.inst) end, "GoHome", true)
			),

			-- IM HUNGRY ARGGHHHHH
			WhileNode(function() return not self.inst.components.timer:TimerExists("bellyfull") end, "Full",
				PriorityNode({
					DoAction(self.inst, EatFoodAction, "Eat Food")	,
					DoAction(self.inst, PickPepperAction, "Pick Pepper", true)
				})					
			),

			-- DURR UHHH I DUNNO WHAT I SHOULD DO, CHOOSE VIOLENCE I GUESS
			ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME)),

			-- BRAIN EMPTY, WALK AROUND AND SMELL THE ROSES
			Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST),
      },1)

    self.bt = BT(self.inst, root)

end

function UM_PepperdragonBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
end

return UM_PepperdragonBrain