local env = env
GLOBAL.setfenv(1, GLOBAL)
local UMUpvalueHacker = require("tools/um_upvaluehacker")

env.AddComponentPostInit("worldwind", function(self)
    local MIN_TIME_TO_WIND_CHANGE = 480
    local MAX_TIME_TO_WIND_CHANGE = 480 * 2

    UMUpvalueHacker.SetUpvalue(self.OnUpdate, MIN_TIME_TO_WIND_CHANGE, "MIN_TIME_TO_WIND_CHANGE")
    UMUpvalueHacker.SetUpvalue(self.OnUpdate, MAX_TIME_TO_WIND_CHANGE, "MAX_TIME_TO_WIND_CHANGE")
end)
