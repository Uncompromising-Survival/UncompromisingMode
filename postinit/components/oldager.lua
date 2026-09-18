local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("oldager", function(self)
    local _OnTakeDamage = self.OnTakeDamage
    function self:OnTakeDamage(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
        if self.inst.vetcurse_shadowdeath and afflicter and afflicter:HasAnyTag("shadowcreature", "nightmarecreature") then
            amount = TUNING.OLDAGE_HEALTH_SCALE * -400
        end
        return _OnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    end
end)