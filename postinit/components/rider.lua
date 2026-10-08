local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("rider", function(self)
    local _Mount = self.Mount
    function self:Mount(target, instant, ...)
        local hadredirectdamagefn = self.inst.components.combat.redirectdamagefn ~= nil
        local ret = _Mount(self, target, instant, ...)
        local _redirectdamagefn = self.inst.components.combat.redirectdamagefn
        if not hadredirectdamagefn and _redirectdamagefn then
            self.inst.components.combat.redirectdamagefn = function(inst, attacker, damage, weapon, stimuli, ...)
                return stimuli ~= "beefalo_half_damage" and _redirectdamagefn(inst, attacker, damage, weapon, stimuli, ...) or nil
            end
        end
        return ret
    end
end)