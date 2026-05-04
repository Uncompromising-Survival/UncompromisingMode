local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("ancientfruit_gem", function(inst)
    if not TheWorld.ismastersim then
        return
    end


    for k, v in pairs(inst.GEMS_WEIGHTS) do
        local color = string.gsub(k, "gem", "")

        if PrefabExists("um_gemology" .. string.lower(color) .. "gem1") then --just to prevent crashes if any mod tries anything funny.
            inst.GEMS_WEIGHTS["um_gemology" .. string.lower(color) .. "gem1"] = v / 8
            inst.GEMS_WEIGHTS["um_gemology" .. string.lower(color) .. "gem2"] = v / 8
        end
    end

    inst.GEMS_WEIGHTS["um_gemologypalegem1"] = 1 / 8
    inst.GEMS_WEIGHTS["um_gemologypalegem2"] = 1 / 8

    --they make the weight list accessible but not this, which causes a crash.
    local GEMS = {}

    for gem, _ in pairs(inst.GEMS_WEIGHTS) do
        GEMS[gem] = 0
    end

    --I really don't care about it at this point.
    local function GemFruit_SpawnAndLaunchGems(inst)
        if inst.components.stackable == nil or not inst.components.stackable:IsStack() then
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()

        -- Generate a list of prefabs to create first and optimize the loop by having every type here.
        local spawned_prefabs = shallowcopy(GEMS)

        local gem
        for _ = 1, inst.components.stackable:StackSize() do
            gem = weighted_random_choice(inst.GEMS_WEIGHTS)

            spawned_prefabs[gem] = spawned_prefabs[gem] + 1
        end

        -- Then create these prefabs while stacking them up as much as they are able to.
        local i, loot, room, stacksize
        for prefab, count in pairs(spawned_prefabs) do
            i = 1

            while i <= count do
                loot = inst:SpawnGem(x, z, prefab)
                room = loot.components.stackable ~= nil and loot.components.stackable:RoomLeft() or 0

                if room > 0 then
                    stacksize = math.min(count - i, room) + 1
                    loot.components.stackable:SetStackSize(stacksize)

                    i = i + stacksize
                else
                    i = i + 1
                end

                Launch2(loot, inst, 1.5, 1.25, 0.3, 0, 2)
            end
        end

        return spawned_prefabs -- Mods.
    end

    inst.SpawnAndLaunchGems = GemFruit_SpawnAndLaunchGems
end)
