local function LargeFernCheck(x, y, z, thickness)
    local plants = #TheSim:FindEntities(x, y, z, thickness, { "plant" })
    local sculpture = #TheSim:FindEntities(x, y, z, 7, { "heavy" }) -- The spacing for the sculpture is larger so it doesn't cover them up
    local sinkhole_bockers = #TheSim:FindEntities(x, y, z, 3, { "antlion_sinkhole_blocker" })
    if plants > 0 or sculpture > 0 or sinkhole_bockers > 0 then
        return true
    end
end

local function Populate(inst, tile, plant, thickness)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i = -15, 15, 0.5 do
        for j = -15, 15, 0.5 do
            local to_spawn
            if plant == "um_pyre_nettles_stage_" then -- There is variance for pyre nettles
                to_spawn = plant .. math.random(1, 5)
            else
                to_spawn = plant
            end
            local x1 = x + i + math.random(-1, 1) / math.random(2, 4)
            local z1 = z + j + math.random(-1, 1) / math.random(2, 4)
            if TheWorld.Map:GetTileAtPoint(x1, y, z1) == tile and not LargeFernCheck(x1, y, z1, thickness) then
                SpawnPrefab(to_spawn).Transform:SetPosition(x1, y, z1)
            end
        end
    end
    inst:Remove()
end

--[[
generates thickets in squigly lines instead of filling in a square
from the starting position, it picks a random angle to start spreading to, and starts spreading towards a direction
with some degrees of varaition.
]]
local function PopulateIAThicket(inst, tile, plant, thickness)
    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = math.random(0, 360)
    local angle_range = 5
    for i = 0, 50, 0.5 do
        local angle_change = math.random(-angle_range, angle_range)

        local x1 = x + i * math.cos(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)
        local z1 = z + i * math.sin(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)

        if TheWorld.Map:GetTileAtPoint(x1, y, z1) == tile and TheWorld.Map:IsVisualGroundAtPoint(x1, y, z1) then
            if not LargeFernCheck(x1, y, z1, thickness) then
                SpawnPrefab(plant).Transform:SetPosition(x1, y, z1)
            end
        else
            break
        end
        angle = angle + angle_change
    end
    --spread in both directions.
    for i = 0, 50, 0.5 do
        local angle_change = math.random(-angle_range, angle_range)

        local x1 = x - i * math.cos(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)
        local z1 = z - i * math.sin(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)

        if TheWorld.Map:GetTileAtPoint(x1, y, z1) == tile and TheWorld.Map:IsVisualGroundAtPoint(x1, y, z1) then
            if not LargeFernCheck(x1, y, z1, thickness) then
                SpawnPrefab(plant).Transform:SetPosition(x1, y, z1)
            end
        else
            break
        end
        angle = angle + angle_change
    end
    inst:Remove()
end

local function fnthicket()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function(inst)
        Populate(inst, WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK, "hooded_fern", 2.4)
    end)

    return inst
end

local function fnpyrethicket()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function(inst)
        Populate(inst, WORLD_TILES.UM_GRASSMAGMA, "um_pyre_nettles_stage_", 4)
    end)

    return inst
end

local function fniathicket()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function(inst)
        if IsIslandWorld() and WORLD_TILES.JUNGLE ~= nil then
            PopulateIAThicket(inst, WORLD_TILES.JUNGLE, "hooded_fern", 2.4)
        end
    end)

    return inst
end

return Prefab("thicket_builder", fnthicket),
    Prefab("pyrethicket_builder", fnpyrethicket),
    Prefab("iathicket_builder", fniathicket)
