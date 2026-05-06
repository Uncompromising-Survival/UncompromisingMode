local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddComponentPostInit("unwrappable", function(self)
    local _Unwrap = self.Unwrap
    function self:Unwrap(doer, ...)
        if self.inst.timebundled then
            local time_since_bundled = (TheWorld.state.time + TheWorld.state.cycles) * 8 * 60 - self.inst.timebundled
            if self.itemdata then
                for i, v in ipairs(self.itemdata) do
                    if v.data and v.data.perishable then
                        local self = v.data.perishable
                        -- If the amount of time that has passed is too much for perishable to handle, go ahead and make the item rot.
                        self.time = self.time - time_since_bundled > 0 and self.time - time_since_bundled or 0
                    end
                end
            end
        end
        return _Unwrap(self, doer, ...)
    end
end)