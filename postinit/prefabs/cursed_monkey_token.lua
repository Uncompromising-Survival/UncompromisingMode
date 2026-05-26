local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("cursed_monkey_token", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME )
    MakeSmallPropagator(inst)
end)