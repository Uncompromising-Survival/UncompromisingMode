local env = env
GLOBAL.setfenv(1, GLOBAL)
local easing = require("easing")

env.AddComponentPostInit("moisture", function(self)
    function self:UM_GetMoistureRateAssumingTornadoOrWaterFall(multlimit, ratebonus, usebonusonmultlimit)
        if self.inst.components.rainimmunity ~= nil then
            return 0
        end

        local waterproofmult =
            (   self.inst.components.sheltered ~= nil and
                self.inst.components.sheltered.sheltered and
                self.inst.components.sheltered.waterproofness or 0
            ) +
            (   self.inst.components.inventory ~= nil and
                self.inst.components.inventory:GetWaterproofness() or 0
            ) +
            (   self.inherentWaterproofness or 0
            ) +
            (
                self.waterproofnessmodifiers:Get() or 0
            )
        if waterproofmult >= (multlimit or 1) then
            return 0
        end

        local rate = easing.inSine(TheWorld.state.precipitationrate, self.minMoistureRate, self.maxMoistureRate, 1)
        return (rate + (ratebonus or 0)) * (((multlimit or 1) + (usebonusonmultlimit and ratebonus or 0)) - waterproofmult)
    end

    local _GetMoistureRate = self.GetMoistureRate
    function self:GetMoistureRate(...)
        if not (self.inst.components.inventory and self.inst.components.inventory:IsFloaterHeld() or self:IsInBathingPool()) then
            if self.inst:HasTag("under_the_weather") then
                return self:UM_GetMoistureRateAssumingTornadoOrWaterFall(1.5, .2)
            elseif self.inst:HasTag("um_waterfall_moisture_override") then
                local waterfall_bonus = self.inst:HasTag("um_waterfall_bonus") and .5 or 0
                return self:UM_GetMoistureRateAssumingTornadoOrWaterFall(1 + waterfall_bonus, .2 + waterfall_bonus)
            end
        end
        return _GetMoistureRate(self, ...)
    end

    local _DoDelta = self.DoDelta
    function self:DoDelta(num, no_announce, ...)
        return _DoDelta(self, self.inst:HasTag("wetness_affinity") and num * 1.5 or num, no_announce, ...)
    end

    local _GetDryingRate = self.GetDryingRate
    function self:GetDryingRate(moisturerate, ...)
        return self.inst:HasTag("wetness_affinity") and 0 or _GetDryingRate(self, moisturerate, ...)
    end
end)
