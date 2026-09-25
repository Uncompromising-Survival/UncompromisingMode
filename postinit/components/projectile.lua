local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("projectile", function(self)
    local _Hit = self.Hit
    function self:Hit(target, ...)
        self.inst.um_projectile_owner = self.owner and self.owner.components.inventoryitem and self.owner or self.inst
        local ret = _Hit(self, target, ...)
        self.inst.um_projectile_owner = nil
        return ret
    end
end)