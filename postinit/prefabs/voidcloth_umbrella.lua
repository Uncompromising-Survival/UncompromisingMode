local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("voidcloth_umbrella", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    -- For tornado
    inst.components.waterproofer.effectiveness = 1.5

    -- Don't do anything when it's acid raining.
    -- This is much less intrusive than removing all the acid rain checks from every function 
    inst.OnIsAcidRaining = function (inst, isacidraining) end
end)
