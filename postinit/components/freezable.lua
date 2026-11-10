local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local Freezable = require("components/freezable")
local _OnAttacked = UMUpvalueHacker.TryGetUpvalue(Freezable._ctor, "OnAttacked")
if _OnAttacked then
    local function OnAttacked(inst, data, ...)
        local freezable = inst.components.freezable
        local um_onfreezedata = freezable and freezable.um_onfreezedata
        local weapon = data.weapon
        local gem_enchantable = weapon and weapon.components.gem_enchantable
        if gem_enchantable and gem_enchantable:GetEnchantmentTier("um_gemologybluegem1") and um_onfreezedata then
            um_onfreezedata.weapon, um_onfreezedata.attacker = weapon, data.attacker
        end
        local ret = _OnAttacked(inst, data, ...)
        if um_onfreezedata then freezable.um_onfreezedata.weapon, freezable.um_onfreezedata.attack = nil, nil end
        return ret
    end
    UMUpvalueHacker.SetUpvalue(Freezable._ctor, OnAttacked, "OnAttacked")
end

local __ctor = Freezable._ctor
function Freezable:_ctor(inst, ...)
    local ret = __ctor(self, inst, ...)
    self.um_onfreezedata = {}
    return ret
end

local _Unfreeze = Freezable.Unfreeze
function Freezable:Unfreeze(...)
    local um_onfreezedata = self.um_onfreezedata
    if um_onfreezedata then
        local weapon, attacker = um_onfreezedata.weapon, um_onfreezedata.attacker
        if weapon and weapon:IsValid() and attacker and attacker:IsValid() then
            weapon:PushEvent("um_brokefrozentarget", {attacker = attacker, target = self.inst})
        end
    end
    return _Unfreeze(self, ...)
end