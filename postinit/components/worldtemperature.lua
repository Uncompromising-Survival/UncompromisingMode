local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
env.AddComponentPostInit("worldtemperature", function(self)
    local _CalculateTemperature = UMUpvalueHacker.TryGetUpvalue(self.GetDebugString, "CalculateTemperature") -- This is an old copy of the function, right? This would cause a stackoverflow when it gets set again, right???
    if _CalculateTemperature then
        local function new_CalculateTemperature()
            return _CalculateTemperature() * (TheWorld:HasTag("heatwavestart") and 1.2 or 1) -- Is 2 too much?
        end
        UMUpvalueHacker.SetUpvalue(self.GetDebugString, new_CalculateTemperature, "CalculateTemperature")
    end
end)
