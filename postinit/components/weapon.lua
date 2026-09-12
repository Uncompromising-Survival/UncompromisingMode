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

    --[[local _GetDamage = self.GetDamage
    function self:GetDamage(attacker, target, ...) -- Unused/untested right now, purpose is to apply enchants that change damage always without having to worry about the damage function changing.
        local _damage
        if self.inst.components.gem_enchantable then
            for enchant, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                if GEM_DEFS[enchant].fns.adjustdamage then
                    if not _damage then _damage = self.damage end
                    local _damagechanged = self.damage
                    self.damage = function(inst, attacker, target, ...)
                        local ret = _damagechanged(inst, attacker target, ...)
                        ret = GEM_DEFS[enchant].fns.adjustdamage(ret, inst, attacker, target, tier)
                        return ret
                    end
                end
            end
        end
        local ret = {_GetDamage(self, attacker, target, ...)}
        if _damage then self.damage = _damage end
    	return unpack(ret)
    end]]

    local _CanRangedAttack = self.CanRangedAttack
    function self:CanRangedAttack(...)
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
        if owner and owner.UMShouldNotRangeAttack and owner:UMShouldNotRangeAttack({weapon = self.inst}) then return false end
        return _CanRangedAttack(self, ...)
    end
end)