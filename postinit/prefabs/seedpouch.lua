local env = env
GLOBAL.setfenv(1, GLOBAL)

-- Leaving this here for clarity
TUNING.SEEDPOUCH_PRESERVER_RATE = 0

env.AddPrefabPostInit("seedpouch", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.container:EnableInfiniteStackSize(true)
end)
