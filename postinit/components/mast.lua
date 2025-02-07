local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("mast", function(self)
    local _OnRemoveEntity = self.OnRemoveEntity
    function self:OnRemoveEntity(...)
        if self.inst:HasTag("no_mast_sinking") then
            self:SetBoat(nil)
        else
            _OnRemoveEntity(self, ...)
        end
    end
end)
