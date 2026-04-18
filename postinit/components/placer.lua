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

    local _ToggleHideInvIcon = self.ToggleHideInvIcon
    function self:ToggleHideInvIcon(hide, ...)
        if self.invobject:HasTag("boatbottle") and not self.invobject:HasTag("filled_boat_bottle") then
            self.hide_inv_icon = false
            self.builder:PushEvent("onplacerhidden")
            return
        end

        return _ToggleHideInvIcon(self, hide, ...)
    end
end)
