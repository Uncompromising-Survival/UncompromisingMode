local env = env
GLOBAL.setfenv(1, GLOBAL)
require "behaviours/runaway"
-----------------------------------------------------------------
local SEE_DIST = 12

local AVOID_DIST = 7 --10
local AVOID_STOP = 12

local FINDFOOD_MUST_TAGS = {"_inventoryitem"}
local FINDFOOD_CANT_TAGS = {"INLIMBO", "outofreach", "bee", "mosquito"}
local function IsFoodValid(item, inst)
    return inst.components.eater and inst.components.eater:CanEat(item) and item:IsOnPassablePoint() and item:GetTimeAlive() >= 1.5
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
    local target = FindEntity(inst, SEE_DIST, IsFoodValid, FINDFOOD_MUST_TAGS, FINDFOOD_CANT_TAGS, inst.components.eater and inst.components.eater:GetEdibleTags() or nil)
    return target and BufferedAction(inst, target, ACTIONS.PICKUP) or nil
end

local function FearfulOfEpics(inst)
    local target = inst.components.combat and inst.components.combat.target or nil
    if target and target:HasTag("epic") then
        inst.components.combat:DropTarget()
    end
    return true
end

local function FrogFindFood(self, pos)
    if UM_CONFIG.COWARDFROGS then
        local avoidthenoid = RunAway(self.inst, "epic", AVOID_DIST, AVOID_STOP, FearfulOfEpics)
        table.insert(self.bt.root.children, 2, avoidthenoid)
    end
    if UM_CONFIG.HUNGRYFROGS then
        local findfood = DoAction(self.inst, EatFoodAction, "eat food", true)
        table.insert(self.bt.root.children, pos, findfood)
    end
end

env.AddBrainPostInit("frogbrain", function(self)
    FrogFindFood(self, 5)
end)

env.AddBrainPostInit("uncompromising_toadbrain", function(self)
    FrogFindFood(self, 4)
end)