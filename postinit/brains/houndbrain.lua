local env = env
GLOBAL.setfenv(1, GLOBAL)

local MAX_JUMP_ATTACK_RANGE = 9
local function shouldjumpattack(inst)
    if inst.sg:HasStateTag("leapattack") then return true end
    if inst.components.combat.target and inst.lightningshot then
        local target = inst.components.combat.target
        if target then
            if target:IsValid() then
                local combatrange = inst.components.combat:CalcAttackRangeSq(target)
                local distsq = inst:GetDistanceSqToInst(target)
                if distsq > combatrange and distsq < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE then
                    return true
                end
            else
                inst.components.combat.target = nil
            end
        end
    end
    return false
end

local function dojumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        inst:PushEvent("doleapattack", {target = target})
        inst:FacePoint(target.Transform:GetWorldPosition())
    end
end

local function HoundBrainFunctions(self)
    local JumpAttack = WhileNode(function() return shouldjumpattack(self.inst) end, "ShouldJumpAttack",
        DoAction(self.inst, function() return dojumpAttack(self.inst) end, "JumpAttack", true))
    if self.inst:HasTag("sporehound") then table.insert(self.bt.root.children[1].children[2].children, 3, JumpAttack) end
end

env.AddBrainPostInit("houndbrain", HoundBrainFunctions)