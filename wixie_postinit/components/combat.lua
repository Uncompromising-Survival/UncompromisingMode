local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("combat", function(self)
    local _CalcDamage = self.CalcDamage
    function self:CalcDamage(target, weapon, multiplier, ...)
        if self.inst.sg and self.inst.sg:HasStateTag("dontuseweaponinstate") then weapon = nil end
        return _CalcDamage(self, target, weapon, multiplier, ...)
    end
end)