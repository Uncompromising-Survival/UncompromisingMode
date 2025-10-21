local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("combat", function(self)
    local _CalcDamage = self.CalcDamage
    function self:CalcDamage(target, weapon, multiplier, ...)
        if self.inst.sg and self.inst.sg.mem.dontuseweaponinstate then weapon = nil end
        return _CalcDamage(self, target, weapon, multiplier, ...)
    end

    local _GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        if attacker and attacker.sg then
            if attacker.sg.mem.wixiefrozentargetshove then return true end
            if attacker.sg.mem.dontuseweaponinstate then weapon = nil end
        end
        return _GetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end
end)