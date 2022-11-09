local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then
        return
    end

    --super scuffed but uh, no idea.
    local count1, count2 = 0,0

    for k,v in pairs(Ents) do
        if v.prefab == "skullchest" then
            count1 = count1 + 1
        end
        if v.prefab == "winkyburrow" then
            count2 = count2 + 1
        end
    end

    if count1 == 0 then
        SpawnPrefab("skullchest")
    end
    if count2 == 0 then
        SpawnPrefab("winkyburrow_pocketdim")
    end

    if inst:HasTag("forest") then
        inst:AddComponent("acidmushrooms")
    end
end)