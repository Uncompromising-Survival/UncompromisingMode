local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")
local Freezable = require("components/freezable")
local _OnAttacked = UpvalueHacker.GetUpvalue(Freezable._ctor, "OnAttacked")
if _OnAttacked then
    local function OnAttacked(inst, data, ...)
        local weapon = data.weapon
        local gem_enchantable = weapon and weapon.components.gem_enchantable
        if gem_enchantable and gem_enchantable:GetEnchantmentTier("um_gemologybluegem1") then
            inst.um_onfreezedata = {weapon = weapon, attacker = data.attacker}
        end
        local ret = _OnAttacked(inst, data, ...)
        if inst.um_onfreezedata then inst.um_onfreezedata = nil end
        return ret
    end
    UpvalueHacker.SetUpvalue(Freezable._ctor, OnAttacked, "OnAttacked")
end

local _Unfreeze = Freezable.Unfreeze
function Freezable:Unfreeze(...)
    local um_onfreezedata = self.inst.um_onfreezedata
    if um_onfreezedata then
        local weapon, attacker = um_onfreezedata.weapon, um_onfreezedata.attacker
        if weapon and weapon:IsValid() and attacker and attacker:IsValid() then
            weapon:PushEvent("um_brokefrozentarget", {attacker = attacker, target = self.inst})
        end
    end
    return _Unfreeze(self, ...)
end