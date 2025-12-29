local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
require "behaviours/runaway"

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 12

local function WerepigIgnoreFood(self)
    local attack_instead_eat = ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME),SpringCombatMod(MAX_CHASE_DIST))
	local dodge = WhileNode( function() return self.inst.components.combat.target and self.inst.components.combat:InCooldown() and not self.inst.attacked_run_cd end, "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST) )
	table.insert(self.bt.root.children, 1, dodge)
	table.insert(self.bt.root.children, 2, attack_instead_eat)
end

env.AddBrainPostInit("werepigbrain", WerepigIgnoreFood)