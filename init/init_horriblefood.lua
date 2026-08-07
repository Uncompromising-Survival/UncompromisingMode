local foods = { --health/hunger/sanity
    coontail = {9, 9, 7},
    glommerwings = {50, 10, -20},
    hambat = {10, 50, 0},
    manrabbit_tail = {0, 9.4, 15},
    pigskin = {12.5, 5, 0},
    shroom_skin = {25, 37.5, -15},
    slurper_pelt = {0, 15, 0},
    tentaclespots = {15, 15, -10},
}

for prefab, stats in pairs(foods) do
    AddPrefabPostInit(prefab, function(inst)
        if not GLOBAL.TheWorld.ismastersim then return end

        local edible = inst.components.edible or inst:AddComponent("edible")
        edible.healthvalue = stats[1]
        edible.hungervalue = stats[2]
        edible.sanityvalue = stats[3]

        if edible.foodtype ~= GLOBAL.FOODTYPE.HORRIBLE then
            edible.foodtype = GLOBAL.FOODTYPE.HORRIBLE
        end
    end)
end
