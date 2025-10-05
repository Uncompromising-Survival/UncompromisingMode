--General inter-mod compatbility/integration features here.
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("wonderwhy", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("ignores_healthregen")
end)

-- I don't know where else to put this
env.AddPrefabPostInit("aphid", function(inst)
    if IsIslandOrVolcanoWorld() then
        inst:AddComponent("appeasement")
        inst.components.appeasement.appeasementvalue = TUNING.TOTAL_DAY_TIME
    end
end)

env.AddPrefabPostInit("shipwrecked", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if TUNING.DSTU.HEATWAVES then
        inst:AddComponent("um_heatwaves")
    end

    if env.GetModConfigData("rat_raids") then
        inst:AddComponent("ratcheck")
    end

    if TUNING.DSTU.STORMS then
        inst:AddComponent("um_stormspawner")
    end
end)

env.AddPrefabPostInit("volcanoworld", function(inst)
    if not TheWorld.ismastersim then
        return
    end
end)
