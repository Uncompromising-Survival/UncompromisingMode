local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------

env.AddComponentPostInit("planardamage", function(self)
    local _GetDamage = self.GetDamage
    function self:GetDamage(...)
        local basedamage
        if self.um_getplanardamagefn then
            basedamage = self.basedamage
            self.basedamage = self.basedamage + self.um_getplanardamagefn(self.inst)
        end
        local ret = {_GetDamage(self, ...)}
        if basedamage then self.basedamage = basedamage end
        return unpack(ret)
    end
end)