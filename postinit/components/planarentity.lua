local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------Fixing A Vanilla Bug-----------------------------------------

env.AddComponentPostInit("planarentity", function(self, inst)
    local _OnResistNonPlanarAttack = self.OnResistNonPlanarAttack
    function self:OnResistNonPlanarAttack(attacker, ...)
        return _OnResistNonPlanarAttack(self, attacker and attacker:IsValid() and attacker or nil)
    end
end)