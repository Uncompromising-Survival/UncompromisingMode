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

local function WerepigIgnoreFood(self)
    local attack_instead_eat = ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME),SpringCombatMod(MAX_CHASE_DIST))
    local dodge = WhileNode(function() return ShouldDodge(self.inst) end, "Dodge",
        RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST))
    table.insert(self.bt.root.children, 4, dodge)
    table.insert(self.bt.root.children, 5, attack_instead_eat)
end

env.AddBrainPostInit("werepigbrain", WerepigIgnoreFood)