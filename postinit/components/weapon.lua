local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local easing = require("easing")

------------------------Fire spread is less efficient in winter-----------------------------------------
env.AddComponentPostInit("weapon", function(self)
    function self:RemoveElectric()
        self.stimuli = nil
    end

    local _OnAttack = self.OnAttack
    function self:OnAttack(attacker, target, projectile, ...)
        if TUNING.DSTU.BUTTERFLYWINGS_NERF == "slippery" and target and target.UMSlipAway and target:UMSlipAway({attacker = attacker, weapon = self.inst}) then return end
        UMGemologyFns.GetEnchantsAndDoFn(self.inst, "onattack", function(enchant, tier, gemfn, _self, _attacker, _target)
            gemfn(_self, _attacker, _target, tier)
        end, attacker, target)
        return _OnAttack(self, attacker, target, projectile, ...)
    end

    local _GetDamage = self.GetDamage
    function self:GetDamage(attacker, target, ...)
        local _damage
        UMGemologyFns.GetEnchantsAndDoFn(self, "onadjustdamage", function(enchant, tier, gemfn, _self)
            if not _damage then _damage = _self.damage end
            local _damagechanged = _self.damage
            _self.damage = function(inst, _attacker, _target, ...)
                return gemfn(inst, FunctionOrValue(_damagechanged, inst, _attacker, _target, ...), _attacker, _target, tier, 1)
            end
        end)
        local ret = {_GetDamage(self, attacker, target, ...)}
        if _damage then self.damage = _damage end
        UMGemologyFns.GetEnchantsAndDoFn(self.inst, "onadjustdamage", function(enchant, tier, gemfn, _self, _attacker, _target)
            ret[1] = gemfn(_self, ret[1], _attacker, _target, tier, 2)
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