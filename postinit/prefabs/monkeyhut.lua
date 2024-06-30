local env = env
GLOBAL.setfenv(1, GLOBAL)



local function give_child_gear(child, gear_prefab)
    local gear = SpawnPrefab(gear_prefab)
    gear:AddTag("personal_possession")
    child.components.inventory:GiveItem(gear)
    child.components.inventory:Equip(gear)
end

env.AddPrefabPostInit("monkeyhut", function(inst)
    if not TheWorld.ismastersim then return end

    local _OnSpawned = inst.components.childspawner.onspawned

    inst.components.childspawner.onspawned = function(inst, child)
        _OnSpawned(inst, child)
        if math.random() < 0.5 then
            give_child_gear(child, math.random() > 0.25 and "messagebottle" or "messagebottleempty")
        end
    end
end)
