local env = env
GLOBAL.setfenv(1, GLOBAL)

local UMUpvalueHacker = require("tools/um_upvaluehacker")

env.AddComponentPostInit("coach", function(self)
    if not TheWorld.ismastersim then return end

    UMUpvalueHacker.SetUpvalue(self.StartInspiring, 0, "inspire", "SANITY_BUFF")
end)
