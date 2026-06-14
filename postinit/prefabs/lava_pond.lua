local env = env
GLOBAL.setfenv(1, GLOBAL)

local PF_DIMS = 6 --equal to 4x4 grid of walls

local function UnregisterPathFinding(inst)
    --didn't register wall but got removed.
    if inst._pfpos == nil then return end

    local x = inst._pfpos.x - (PF_DIMS - 1) / 2
    local z = inst._pfpos.z - (PF_DIMS - 1) / 2
    local pathfinder = TheWorld.Pathfinder
    for i = 0, PF_DIMS - 1 do
        for j = 0, PF_DIMS - 1 do
            pathfinder:RemoveWall(x + i, 0, z + j)
        end
    end
end

local function RegisterPathFinding(inst)
    inst._pfpos = inst:GetPosition()
    local x = inst._pfpos.x - (PF_DIMS - 1) / 2
    local z = inst._pfpos.z - (PF_DIMS - 1) / 2
    local pathfinder = TheWorld.Pathfinder
    for i = 0, PF_DIMS - 1 do
        for j = 0, PF_DIMS - 1 do
            pathfinder:AddWall(x + i, 0, z + j)
        end
    end
end


env.AddPrefabPostInit("lava_pond", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, RegisterPathFinding)
    inst:ListenForEvent("onremove", UnregisterPathFinding)

    inst:AddComponent("watersource")
end)
