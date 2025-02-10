local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("placer", function(self)
    local _OnUpdate = self.OnUpdate

    function self:OnUpdate(dt, ...)
        local ret = _OnUpdate(self, dt, ...)

        if self.invobject ~= nil and self.invobject:HasTag("boatbottle") and not self.invobject:HasTag("filled_boat_bottle") then
            self.inst:Hide()
        end

        return ret
    end
end)
