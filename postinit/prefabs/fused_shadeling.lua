local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("fused_shadeling", function(inst)
    inst:AddTag("fused_shadeling")
end)