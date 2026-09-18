local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local easing = require("easing")
local GEM_DEFS = require("gemology_defs").GEM_DEFS

------------------------Fire spread is less efficient in winter-----------------------------------------
env.AddComponentPostInit("weapon", function(self)
    function self:RemoveElectric()
        self.stimuli = nil
    end

    function self:UMGetEnchantsAndDoFn(fn, ...)
        local weapon = self.inst.um_projectile_owner or self.inst
        local gem_enchantable = weapon.components.gem_enchantable
        if gem_enchantable then
            for enchant, tier in pairs(gem_enchantable.enchants) do
                fn(enchant, tier, self, ...)
            end
        end
    end

    local _OnAttack = self.OnAttack
    function self:OnAttack(attacker, target, projectile, ...)
        if TUNING.DSTU.BUTTERFLYWINGS_NERF == "slippery" and target and target.UMSlipAway and target:UMSlipAway({attacker = attacker, weapon = self.inst}) then return end
        self:UMGetEnchantsAndDoFn(function(enchant, tier, _self, _attacker, _target)
            if GEM_DEFS[enchant].fns.onattack then
                GEM_DEFS[enchant].fns.onattack(_self.inst, _attacker, _target, tier)
            end
        end, attacker, target)
        return _OnAttack(self, attacker, target, projectile, ...)
    end

    local _GetDamage = self.GetDamage
    function self:GetDamage(attacker, target, ...)
        local _damage
        self:UMGetEnchantsAndDoFn(function(enchant, tier, _self)
            if GEM_DEFS[enchant].fns.onadjustdamage then
                if not _damage then _damage = _self.damage end
                local _damagechanged = _self.damage
                _self.damage = function(inst, _attacker, _target, ...)
                    return GEM_DEFS[enchant].fns.onadjustdamage(inst, FunctionOrValue(_damagechanged, inst, _attacker, _target, ...), _attacker, _target, tier, 1)
                end
            end
        end)
        local ret = {_GetDamage(self, attacker, target, ...)}
        if _damage then self.damage = _damage end
        self:UMGetEnchantsAndDoFn(function(enchant, tier, _self, _attacker, _target)
            if GEM_DEFS[enchant].fns.onadjustdamage then
                ret[1] = GEM_DEFS[enchant].fns.onadjustdamage(_self.inst, ret[1], _attacker, _target, tier, 2)
            end
        end, attacker, target)
        return unpack(ret)
    end

    local _CanRangedAttack = self.CanRangedAttack
    function self:CanRangedAttack(...)
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
        if owner and owner.UMShouldNotRangeAttack and owner:UMShouldNotRangeAttack({weapon = self.inst}) then return false end
        return _CanRangedAttack(self, ...)
    end
end)