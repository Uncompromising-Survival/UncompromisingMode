local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("explosiveresist", function(self)
    self.decay = nil

    local _SetResistance = self.SetResistance
    function self:SetResistance(resistance, ...)
        self.resistance = math.clamp(resistance, 0, 1)
        if self.resistance > 0 and not self.decay then
            return _SetResistance(self, resistance, ...)
        else
            self.inst:StopUpdatingComponent(self)
            self.delayremaining = 0
        end
    end
end)