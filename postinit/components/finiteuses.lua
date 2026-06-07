local env = env
GLOBAL.setfenv(1, GLOBAL)

--potential support for finite uses overcharging.

env.AddComponentPostInit("finiteuses", function(self)
    local _IgnoresCombatDurabilityLoss = self.IgnoresCombatDurabilityLoss
    function self:IgnoresCombatDurabilityLoss(...)
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
        local buffaction = owner and owner:GetBufferedAction()
        if buffaction and buffaction.mockattack then return true end
        return _IgnoresCombatDurabilityLoss(self, ...)
    end
end)