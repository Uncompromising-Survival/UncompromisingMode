local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("oldager", function(self)
    local _OnTakeDamage = self.OnTakeDamage

    function self:OnTakeDamage(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
        print("amount", amount)
        print("overtime", overtime)
        print("cause", cause)
        print("ignore_invincible", ignore_invincible)
        print("afflicter", afflicter)
        print("ignore_absorb", ignore_absorb)
        print("...", ...)
        print("self.inst.vetcurse_shadowdeath", self.inst.vetcurse_shadowdeath)

        if self.inst.vetcurse_shadowdeath and afflicter ~= nil and afflicter:HasAnyTag("shadowcreature", "nightmarecreature") then
            amount = TUNING.OLDAGE_HEALTH_SCALE * -400
        end

        return _OnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
    end
end)
