local env = env
GLOBAL.setfenv(1, GLOBAL)
local easing = require("easing")
local GEM_DEFS = require("gemology_defs").GEM_DEFS

------------------------Fire spread is less efficient in winter-----------------------------------------
env.AddComponentPostInit("weapon", function(self)
    function self:RemoveElectric()
        self.stimuli = nil
    end

    local _OnAttack = self.OnAttack
    function self:OnAttack(attacker, target, projectile, ...)
        if TUNING.DSTU.BUTTERFLYWINGS_NERF == "slippery" and target and target.UMSlipAway and target:UMSlipAway({attacker = attacker, weapon = self.inst}) then return end
        if self.inst.components.gem_enchantable then
            for enchant, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                if GEM_DEFS[enchant].fns.onattack ~= nil then
                    GEM_DEFS[enchant].fns.onattack(self.inst, attacker, target, tier)
                end
            end
        end
        return _OnAttack(self, attacker, target, projectile, ...)
    end

    local _CanRangedAttack = self.CanRangedAttack
    function self:CanRangedAttack(...)
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
        if TUNING.DSTU.WIXIE and owner and owner.sg and owner.sg.mem.um_dontuseweaponinstate then return false end
        return _CanRangedAttack(self, ...)
    end

    function self:OnAttack_NoDurabilityLoss(attacker, target, projectile)
        if self.onattack ~= nil then
            self.onattack(self.inst, attacker, target, 2)
        end

        --[[if self.inst.components.finiteuses ~= nil then
            local uses = (self.attackwear or 1) * self.attackwearmultipliers:Get()
            if attacker ~= nil and attacker:IsValid() and attacker.components.efficientuser ~= nil then
                uses = uses * (attacker.components.efficientuser:GetMultiplier(ACTIONS.ATTACK) or 1)
            end

            self.inst.components.finiteuses:Use(uses)
        end]]
    end
end)