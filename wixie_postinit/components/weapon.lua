local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("weapon", function(self)
    local _CanRangedAttack = self.CanRangedAttack
    function self:CanRangedAttack(...)
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
        if owner and owner.sg and owner.sg.mem.dontuseweaponinstate then return false end
        return _CanRangedAttack(self, ...)
    end
end)