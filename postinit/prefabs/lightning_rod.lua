local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")

env.AddPrefabPostInit("lightning_rod", function(inst)
    if not TheWorld.ismastersim then return end

    -- Expose function to allow other sources to charge it
    local onlightning = UpvalueHacker.GetUpvalue(Prefabs.lightning_rod.fn, "onlightning")
    inst.onlightningfn = onlightning
end)