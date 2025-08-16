local env = env
GLOBAL.setfenv(1, GLOBAL)

--potential support for finite uses overcharging.

env.AddComponentPostInit("finiteuses", function(self)
    local _SetUses = self.SetUses
    function self:SetUses(val)
        _SetUses(self, val)
        if self.inst:HasTag("overchargeable") then
            if self.current > self.total then
                self.inst:PushEvent("overcharged", true)
            else
                self.inst:PushEvent("overcharged", false)
            end
        end
    end
    local _IgnoresCombatDurabilityLoss = self.IgnoresCombatDurabilityLoss
    function self:IgnoresCombatDurabilityLoss(...)
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
        if owner and owner.sg and owner.sg.mem.mockattack then return true end
        return _IgnoresCombatDurabilityLoss(self, ...)
    end
end)