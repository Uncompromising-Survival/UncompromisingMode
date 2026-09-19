local env = env
GLOBAL.setfenv(1, GLOBAL)
local UMUpvalueHacker = require("tools/um_upvaluehacker")

env.AddPrefabPostInit("lightning_rod", function(inst)
    if not TheWorld.ismastersim then return end

    -- Expose function to allow other sources to charge it
    local onlightning = UMUpvalueHacker.GetUpvalue(Prefabs.lightning_rod.fn, "onlightning")
    inst.onlightningfn = onlightning
end)