local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------------------------
env.AddPrefabPostInit("ruins_bat", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    -- Note to random buff - does more damage vs lunar aligned, similar to glass cutter
    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, 1 + 17 / 59)
end)
