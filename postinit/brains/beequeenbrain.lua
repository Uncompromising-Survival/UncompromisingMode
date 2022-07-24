local env = env
GLOBAL.setfenv(1, GLOBAL)
require "behaviours/chaseandattack"

local function ShouldChase_UM(self)
    local target = self.inst.components.combat.target
    if self.inst.focustarget_cd <= 0 and self.inst.ShouldChase(self.inst) then
        return not (self.inst.components.combat:InCooldown() and
                    target ~= nil and
                    target:IsValid() and
                    target:IsNear(self.inst, TUNING.BEEQUEEN_ATTACK_RANGE + target:GetPhysicsRadius(0)))
    elseif target == nil or not target:IsValid() then
        self._shouldchase = false
        return false
    end
    local distsq = self.inst:GetDistanceSqToInst(target)
    local range = TUNING.BEEQUEEN_CHASE_TO_RANGE + (self._shouldchase and 0 or 3)+4
    self._shouldchase = distsq >= range * range
    if self._shouldchase and not self.inst.ShouldChase(self.inst) then
        return true
    elseif self.inst.components.combat:InCooldown() then
        return false
    end
    range = TUNING.BEEQUEEN_ATTACK_RANGE + target:GetPhysicsRadius(0) + 1
    return distsq <= range * range
end

local function WhyAreYouStopping(self)
					
	local ChaseMe = WhileNode(function() return ShouldChase_UM(self) end, "Chase",
            ChaseAndAttack(self.inst))
	table.remove(self.bt.root.children, 3)
    table.insert(self.bt.root.children, 3, ChaseMe)
end


env.AddBrainPostInit("beequeenbrain", WhyAreYouStopping)