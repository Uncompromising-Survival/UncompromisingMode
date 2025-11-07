local env = env
GLOBAL.setfenv(1, GLOBAL)
require "behaviours/runaway"
-----------------------------------------------------------------
local SEE_DIST = 12

local AVOID_PLAYER_DIST = 7
local AVOID_PLAYER_STOP = 12

local AVOID_DIST = 10
local AVOID_STOP = 12

local FINDFOOD_CANT_TAGS = { "outofreach", "INLIMBO" }
local DONTEAT_TAGS = {"bee", "mosquito"}
local function IsFoodValid(item, inst)
    return item.prefab ~= "mandrake"
        and not (item.components.burnable and item.components.burnable:IsBurning())
        --and item:IsOnPassablePoint()
        and item:IsOnValidGround()
        and not item:HasAnyTag(DONTEAT_TAGS)
        and inst.components.eater and inst.components.eater:CanEat(item)
end

local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return nil
    elseif inst.components.inventory and inst.components.eater then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end
    --[[local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnPassablePoint(true) end)
    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
    ]]
    local target = FindEntity(inst, SEE_DIST, IsFoodValid, nil, FINDFOOD_CANT_TAGS, inst.components.eater and inst.components.eater:GetEdibleTags() or nil)
    return target and BufferedAction(inst, target, ACTIONS.PICKUP) or nil
end

local function FearfulOfEpics(inst)
    local target = inst.components.combat and inst.components.combat.target or nil
    if target and target:HasTag("epic") then
        inst.components.combat:DropTarget()
    end
    return true
end

local function FrogFindFood(self)
    local avoidthenoid = RunAway(self.inst, "epic", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP, FearfulOfEpics)
    if TUNING.DSTU.COWARDFROGS then
        table.insert(self.bt.root.children, 2, avoidthenoid)
    end
    local findfood = DoAction(self.inst, EatFoodAction, "eat food", true)
    if TUNING.DSTU.HUNGRYFROGS then
        table.insert(self.bt.root.children, 5, findfood)
    end
end

env.AddBrainPostInit("frogbrain", FrogFindFood)

local function ToadFindFood(self)
    local avoidthenoid = RunAway(self.inst, "epic", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP, FearfulOfEpics)
    if TUNING.DSTU.COWARDFROGS then
        table.insert(self.bt.root.children, 2, avoidthenoid)
    end
    local findfood = DoAction(self.inst, EatFoodAction, "eat food", true)
    if TUNING.DSTU.HUNGRYFROGS then
        table.insert(self.bt.root.children, 4, findfood)
    end
end

env.AddBrainPostInit("uncompromising_toadbrain", ToadFindFood)