local env = env
GLOBAL.setfenv(1, GLOBAL)

local updatecoef = .001 -- Coefficient for tuning the lost durability for onupdate, a majority of temperature handling is done through onupdate instead of dodelta
env.AddComponentPostInit("temperature", function(self)
    local _DoDelta = self.DoDelta
    function self:DoDelta(delta, ...)
        local hat = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if hat and hat.prefab == "um_hat_pepperdragon" then
            if hat.components.fueled then
                hat.components.fueled:DoDelta(-math.abs(delta), self.inst)
            end
            delta = -delta
        end
        return _DoDelta(self, delta, ...)
    end

    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local inst = self.inst
        local hat = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        local ret
        if hat and hat.prefab == "um_hat_pepperdragon" then
            local old_current = self.current
            ret = {_OnUpdate(self, dt, ...)}

            -- Whatever we just did, do it backwards
            local new_current = self.current
            local diff = new_current - old_current
            local mintemp = self.mintemp
            local maxtemp = self.maxtemp

            local delta = math.clamp(old_current - diff, mintemp, maxtemp)
            self:SetTemperature(delta)
            if hat.components.fueled then
                hat.components.fueled:DoDelta(-math.abs(delta) * updatecoef, self.inst)
            end
        else
            ret = {_OnUpdate(self, dt, ...)}
        end
        return unpack(ret)
    end
end)
