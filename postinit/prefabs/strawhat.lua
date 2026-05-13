local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("strawhat", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALLMED)
end)