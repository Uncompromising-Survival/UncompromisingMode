local function spawnshadow(inst, range, no_lightrays)
    if not TheWorld.hooded_forest_shadetiles then
        TheWorld.hooded_forest_shadetiles = {}
    end
    if not TheWorld.shadetile_key_to_hooded_forest_canopy_id then
        TheWorld.shadetile_key_to_hooded_forest_canopy_id = {}
    end

    local data = { lightrays = {}, shadetile_keys = {} }

    local x, y, z = inst.Transform:GetWorldPosition()
    for i = -range, range do
        for t = -range, range do
            if ((t * t) + (i * i)) <= range * range then
                local newx = (math.floor((x + (i * 4)) / 4) * 4) + 2
                local newz = (math.floor((z + (t * 4)) / 4) * 4) + 2

                local shadetile_key = newx .. "-" .. newz
                table.insert(data.shadetile_keys, shadetile_key)

                if not TheWorld.hooded_forest_shadetiles[shadetile_key] or TheWorld.hooded_forest_shadetiles[shadetile_key] <= 0 then
                    if math.random() < 0.8 then
                        TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key] = SpawnHoodedforestCanopy(newx, newz)
                    elseif not no_lightrays then
                        if math.random() < 0.5 then
                            local rays = SpawnPrefab("lightrays_canopy")
                            rays.Transform:SetPosition(newx, 0, newz)
                            table.insert(data.lightrays, rays)
                        end
                    end
                    TheWorld.hooded_forest_shadetiles[shadetile_key] = 1
                else
                    TheWorld.hooded_forest_shadetiles[shadetile_key] = TheWorld.hooded_forest_shadetiles[shadetile_key] + 1
                end
            end
        end
    end

    return data
end

return { spawnshadow = spawnshadow }
