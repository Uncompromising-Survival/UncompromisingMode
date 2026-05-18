local prefabs =
{
    "crow",
}
local function MapCheck(x, y, z)
    if GLOBAL.TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
        local node = GLOBAL.TheWorld.Map:FindNodeAtPoint(x, y, z)
        return node ~= nil and node.tags ~= nil and table.contains(node.tags, "hoodedcanopy")
    end
    return false
end
local function UMBirdSwap(inst) --Fix is a slightly different version of ADM's fix to bird spawning on the cherry island, credits to ADM.
    local cage = inst.components.occupier ~= nil and inst.components.occupier:GetOwner()
    if cage == nil and
        not inst.components.inventoryitem:IsHeld() and
        inst.sg.currentstate.name == "glide" then
        local x, y, z = inst.Transform:GetWorldPosition()
        if MapCheck(x, y, z) then
            if math.random() > 0.5 then
                local birb = GLOBAL.SpawnPrefab("woodpecker")
                birb.Transform:SetPosition(x, y, z)
                birb.sg:HasStateTag("glide")
                inst:Remove()
            else
                local birb = (GLOBAL.TheWorld.state.iswinter and GLOBAL.SpawnPrefab("robin_winter")) or GLOBAL.SpawnPrefab("robin")
                birb.Transform:SetPosition(x, y, z)
                birb.sg:HasStateTag("glide")
                inst:Remove()
            end
        end
    end
end

for k, v in pairs(prefabs) do
    AddPrefabPostInit(v, function(inst)
        inst:DoTaskInTime(0, UMBirdSwap)
    end)
end

local function FeatherCheck(prefab)
    return type(prefab) == "string" and string.find(prefab, "feather") ~= nil
end

local function AddFeather(candidates, prefab)
    if FeatherCheck(prefab) then
        candidates[prefab] = true
    end
end

local function BirdLoot(lootdropper)
    local candidates = {}

    if lootdropper.loot ~= nil then
        for _, prefab in ipairs(lootdropper.loot) do
            AddFeather(candidates, prefab)
        end
    end

    if lootdropper.chanceloot ~= nil then
        for _, data in ipairs(lootdropper.chanceloot) do
            AddFeather(candidates, data.prefab or data[1])
        end
    end

    if lootdropper.randomloot ~= nil then
        for _, data in ipairs(lootdropper.randomloot) do
            AddFeather(candidates, data.prefab or data[1])
        end
    end

    local result = {}

    for prefab in pairs(candidates) do
        table.insert(result, prefab)
    end

    if #result > 0 then
        return result[math.random(#result)]
    end
end

local function RemoveMorsel(inst)
    if not inst:HasTag("bird") then
        return
    end

    if inst.components.lootdropper == nil then
        return
    end

    local old_GenerateLoot = inst.components.lootdropper.GenerateLoot

    inst.components.lootdropper.GenerateLoot = function(self, ...)
        local loot = old_GenerateLoot(self, ...)
        local feather = BirdLoot(self)

        if loot ~= nil then
            for i = #loot, 1, -1 do
                if loot[i] == "smallmeat" then
                    if feather ~= nil then
                        loot[i] = feather
                    else
                        table.remove(loot, i)
                    end
                end
            end
        end

        return loot
    end
end

AddPrefabPostInitAny(function(inst)
    if GLOBAL.TheWorld.ismastersim and inst:HasTag("bird") then
        inst:DoTaskInTime(0, RemoveMorsel)
    end
end)
