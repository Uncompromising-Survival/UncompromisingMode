local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
require "behaviours/runaway"

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 12

local function ShouldDodge(inst)
    return inst.components.combat:HasTarget() and inst.components.combat:InCooldown() and not inst.attacked_run_cd
end

local function FindNode(self, fn)
    for id, node in pairs(self) do
        if fn(node) then
            return node
        end
    end
end

local function WerepigIgnoreFood(self)
    local dodge = WhileNode(function() return ShouldDodge(self.inst) end, "Dodge",
        RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST))
    local ParallelNode = FindNode(self.bt.root.children, function(node) return node.name == "Parallel" end)
    local PriorityNode = ParallelNode and FindNode(ParallelNode.children, function(node) return node.name == "Priority" end)
    local PriorityNode_children = PriorityNode and PriorityNode.children
    if PriorityNode_children then
        for i = #PriorityNode_children, 1, -1 do
            local node = PriorityNode_children[i]
            if node.name == "ChaseAndAttack" then
                table.remove(PriorityNode_children, i)
                table.insert(PriorityNode_children, i - 1, node)
                table.insert(PriorityNode_children, i - 1, dodge)
                break
            end
        end
    end
end

env.AddBrainPostInit("werepigbrain", WerepigIgnoreFood)