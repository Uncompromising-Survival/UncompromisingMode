local tile_radius_plus_overhang = ((TILE_SCALE / 2) + 1.0) * 1.4142 -- from componentutil
local CRACK_MUST_TAGS = { "lava_crack_fx" }


local MagmaManager = Class(function(self, inst)
    self.inst = inst
    self.init_comlete = false
    self.temp_tiles = {}
    self.magma_tiles = {}

    self.flingos = {}
    self.crystaleyezers = {}

    self.inst:StartUpdatingComponent(self)
end)


function MagmaManager:Init(tiles)
    if self.init_complete then
        return
    end

    for k, pos in pairs(tiles) do
        local node, index = TheWorld.Map:FindVisualNodeAtPoint(pos.x, 0, pos.z)
        if node and node.tags and table.contains(node.tags, "UM_ActiveLavaZone") then
            table.insert(self.magma_tiles, { x = pos.x, z = pos.z }) --we really don't need to be saving this. Its used once.
        end
    end

    self:CreateMoltenLavaTiles()

    self.init_complete = true
end

local function BuildLavaTile(self, x, y, z)
    local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, y, z)

    --set tile
    --double checking...
    if TheWorld.Map:GetTile(tx, tz) == WORLD_TILES.UM_MAGMA then
        TheWorld.Map:SetTile(tx, tz, WORLD_TILES.UM_MAGMA_LAVAMOLTEN)

        --remove all prefabs on top of the lava.
        local ents = TheSim:FindEntities(tcx, y, tcz, tile_radius_plus_overhang, nil, { "FX", "INLIMBO", "CLASSIFIED", "DECOR", "NOCLICK", "magma_tile" })
        for k, ent in pairs(ents) do
            local etx, etz = TheWorld.Map:GetTileCoordsAtPoint(ent.Transform:GetWorldPosition())
            if etx == tx and etz == tz then
                ent:Remove()
            end
        end

        --spawn light
        if #TheSim:FindEntities(tcx, 0, tcz, 1, { "magma_tile" }) == 0 then
            local prefab = SpawnPrefab("magma_tile")
            prefab.Transform:SetPosition(tcx, 0, tcz)
        end
    end
end

local function CreateLavaRiverTiles(self, point, thickness)
    local x, y, z = point.x, 0, point.z
    local angle = math.random(0, 360)
    local angle_range = 10
    for i = 0, 200, 4 do
        local angle_change = math.random(-angle_range, angle_range)

        local x1 = x + i * math.cos(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)
        local z1 = z + i * math.sin(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)

        local is_nearby_tiles_valid = false

        for w = -thickness, thickness do
            for h = -thickness, thickness do
                if TheWorld.Map:GetTileAtPoint(x1 + w, y, z1 + h) == WORLD_TILES.UM_MAGMA then
                    is_nearby_tiles_valid = true
                end
            end
        end


        if is_nearby_tiles_valid then
            --set lava tile
            for w = -thickness, thickness do
                for h = -thickness, thickness do
                    BuildLavaTile(self, x1 + w, y, z1 + h)
                end
            end
        else
            break
        end

        angle = angle + angle_change
    end

    for i = 0, 200, 4 do
        local angle_change = math.random(-angle_range, angle_range)

        local x1 = x - i * math.cos(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)
        local z1 = z - i * math.sin(angle * DEGREES) + math.random(-1, 1) / math.random(2, 4)

        local is_nearby_tiles_valid = i == 0 and true or false --skip first iteration because it'll always fail otherwise.

        for w = -thickness, thickness do
            for h = -thickness, thickness do
                if TheWorld.Map:GetTileAtPoint(x1 + w, y, z1 + h) == WORLD_TILES.UM_MAGMA then
                    is_nearby_tiles_valid = true
                end
            end
        end


        if is_nearby_tiles_valid then
            --set lava tile
            for w = -thickness, thickness do
                for h = -thickness, thickness do
                    BuildLavaTile(self, x1 + w, y, z1 + h)
                end
            end
        else
            break
        end

        angle = angle + angle_change
    end
end

local function removecrackedicefx(dx, dz)
    local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(dx, 0, dz)

    local cracks = TheSim:FindEntities(dx, 0, dz, 4.5, CRACK_MUST_TAGS)
    for i = #cracks, 1, -1 do
        local itx, itz = TheWorld.Map:GetTileCoordsAtPoint(cracks[i].Transform:GetWorldPosition())
        if tx == itx and tz == itz then
            cracks[i]:Remove()
        end
    end
end

function MagmaManager:CreateMoltenLavaTiles()
    --get a random point inside the biome
    if not next(self.magma_tiles) then return end
    local num_points = 12
    local points = {}
    for i = 1, num_points do
        local valid = true
        local point = self.magma_tiles[math.random(#self.magma_tiles)]
        for k, other_point in pairs(points) do
            if DistXZSq(point, other_point) < 16 * 16 then --putting a min dist between these
                valid = false
            end
        end

        if valid then
            table.insert(points, point)
        else
            i = i - 1
        end
    end

    --generate magma tiles
    for k, v in pairs(points) do
        CreateLavaRiverTiles(self, v, math.random(4, 8))
    end
end

function MagmaManager:OnSave()
    local data = { init_complete = self.init_complete, temp_tiles = self.temp_tiles, magma_tiles = self.magma_tiles }

    return data
end

function MagmaManager:OnLoad(data)
    self.init_complete = data.init_complete or {}
    self.temp_tiles = data.temp_tiles or {}
    self.magma_tiles = data.magma_tiles or {}
end

function MagmaManager:CoolDownMagmaTile(x, z, duration)
    --normalize coords to tile center coords
    local x, y, z = TheWorld.Map:GetTileCenterPoint(x, 0, z)

    removecrackedicefx(x, z)

    for k, v in pairs(self.temp_tiles) do
        if v.x == x and v.z == z then
            v.duration = duration -- refresh duration
            return true
        end
    end

    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    if TheWorld.Map:GetTile(tile_x, tile_z) ~= WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
        return
    end

    TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.UM_MAGMA_LAVACOOLED)

    for _, v in ipairs(TheSim:FindEntities(x, 0, z, tile_radius_plus_overhang)) do
        local vtx, vtz = TheWorld.Map:GetTileCoordsAtPoint(v.Transform:GetWorldPosition())
        if vtx == tile_x and vtz == tile_z then
            v:PushEvent("onmagmacooled")
        end
    end

    table.insert(self.temp_tiles, { x = x, z = z, duration = duration })

    return true
end

function MagmaManager:MeltMagmaTile(x, z)
    --normalize coords to tile center coords
    local x, y, z = TheWorld.Map:GetTileCenterPoint(x, 0, z)
    removecrackedicefx(x, z)
    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)

    TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.UM_MAGMA_LAVAMOLTEN)
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, tile_radius_plus_overhang, nil, { "FX", "INLIMBO", "CLASSIFIED", "DECOR", "NOCLICK" })) do
        local vtx, vtz = TheWorld.Map:GetTileCoordsAtPoint(v.Transform:GetWorldPosition())
        --we check  visual ground because structures can technically be placed inside this tile and not actually be on it and vice versa.
        if v:IsValid() and (vtx == tile_x and vtz == tile_z or not TheWorld.Map:IsVisualGroundAtPoint(v.Transform:GetWorldPosition())) then
            v:PushEvent("onmagmamelted")
            if ShouldEntitySink(v) and v.components.inventoryitem then
                SinkEntity(v)
            end

            --redundant?
            if v.components.burnable ~= nil then
                v.components.burnable:Ignite(true)
            end
            if v.components.drownable ~= nil then
                v.components.drownable:CheckDrownable()
            end

            if v.components.workable ~= nil then
                v.components.workable:Destroy(TheSim:FindFirstEntityWithTag("magma_tile"))
            end
            --health dmg handled by sg

            local fx = SpawnPrefab("deer_fire_burst")
            fx.Transform:SetPosition(v.Transform:GetWorldPosition())
        end
    end

    local fx = SpawnPrefab("fx_boat_pop")
    fx.Transform:SetPosition(x, 0, z)

    SpawnPrefab("rock_break_fx").Transform:SetPosition(x, 0, z)

    local new_tiles = {}

    for k, v in pairs(self.temp_tiles) do
        if not (v.x == x and v.z == z) then
            table.insert(new_tiles, { x = v.x, z = v.z, duration = v.duration })
        end
    end

    self.temp_tiles = new_tiles
end

local function DoMagmaBreakFx(x, z)
    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(tx, ty)

    local S = TheWorld.Map:IsLandTileAtPoint(cx + 4, cy, cz)
    local N = TheWorld.Map:IsLandTileAtPoint(cx - 4, cy, cz)
    local E = TheWorld.Map:IsLandTileAtPoint(cx, cy, cz + 4)
    local W = TheWorld.Map:IsLandTileAtPoint(cx, cy, cz - 4)
    local function spawnfx(lx, lz, rot)
        if #TheSim:FindEntities(lx, 0, lz, 1, CRACK_MUST_TAGS) < 1 then
            local fx = SpawnPrefab("magma_tile_crack_grid_fx")

            fx.Transform:SetPosition(lx, 0, lz)
            fx.Transform:SetRotation(rot)
        end
    end

    --Slightly inside the previous tile so we can precisely remove the FX
    --on top of the relevant tile.
    if N then
        spawnfx(cx - 1.95, cz, 0)
    end
    if S then
        spawnfx(cx + 1.95, cz, 180)
    end
    if E then
        spawnfx(cx, cz + 1.95, 90)
    end
    if W then
        spawnfx(cx, cz - 1.95, 270)
    end
end

function MagmaManager:OnUpdate(dt)
    --skip the loop if its raining directly.

    --we only update up to 50 tiles per frame for performance.
    --if we have more, we'll update them next frame.
    if not TheWorld.state.israining then
        self.next_batch = self.next_batch or 1
        for i = self.next_batch, #self.temp_tiles do
            local data = self.temp_tiles[i]
            if data == nil then
                print("PANIC! Data invalid!")
                return
            end

            if i == #self.temp_tiles then
                self.next_batch = 1
                break
            end

            if i % 50 == 0 and i ~= self.next_batch then
                self.next_batch = i
                break
            end


            local x, z = data.x, data.z
            --yes these are seperate if statements for clarity's sake.

            --edge case: if there's a fueled flingo, we don't melt the tile offscreen.
            --onscreen it'll re-cool the tile as normal.
            local should_melt = true
            for guid, ent in pairs(self.flingos) do
                if ent:IsValid() and ent:IsAsleep() and ent:GetDistanceSqToPoint(x, 0, z) < TUNING.FIRE_DETECTOR_RANGE * TUNING.FIRE_DETECTOR_RANGE then
                    if ent.components.fueled ~= nil and not ent.components.fueled:IsEmpty() and ent.components.firedetector ~= nil and ent.components.machine ~= nil and ent.components.machine.ison then
                        should_melt = false
                    end
                end
            end

            -- Don't melt tiles near active crystaeyezers.
            for guid, ent in pairs(self.crystaleyezers) do
                if ent:IsValid() and ent.components.temperatureoverrider.enabled then
                    should_melt = false
                end
            end

            --don`t melti if all sides are land
            local S = TheWorld.Map:IsLandTileAtPoint(x + 4, 0, z)
            local N = TheWorld.Map:IsLandTileAtPoint(x - 4, 0, z)
            local E = TheWorld.Map:IsLandTileAtPoint(x, 0, z + 4)
            local W = TheWorld.Map:IsLandTileAtPoint(x, 0, z - 4)


            if (S and N and E and W) then
                should_melt = false
            end

            if should_melt then
                data.duration = data.duration - 1

                if data.duration <= 200 then
                    DoMagmaBreakFx(data.x, data.z)
                end

                if data.duration <= 100 and data.duration % 5 == 0 then
                    local fx1 = SpawnPrefab("fossilizing_fx_" .. math.random(1, 2))
                    fx1.Transform:SetPosition(x + (math.random(-4, 4) * math.random()), 0, z + (math.random(-4, 4) * math.random()))
                elseif data.duration <= 50 and data.duration % 2 == 0 then
                    local fx2 = SpawnPrefab("deer_fire_burst")
                    fx2.Transform:SetPosition(x + (math.random(-4, 4) * math.random()), 0, z + (math.random(-4, 4) * math.random()))
                end

                if data.duration <= 0 then
                    self:MeltMagmaTile(data.x, data.z)
                    --We need to break here as the table gets reconstructed while we're iterating over it.
                    break
                end
            end
        end
    end
end

function MagmaManager:GetTempTileDataAtPoint(x, y, z)
    local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, 0, z)

    for k, v in pairs(self.temp_tiles) do
        if v.x == tcx and v.z == tcz then
            return { valid = true, type = "temp", idx = k, pos = v, duration = v.duration }
        end
    end
end

function MagmaManager:CanCoolDownTileAtPoint(x, y, z)
    local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, 0, z)
    local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(tcx, 0, tcz)

    local data = GetTempTileDataAtPoint(tcx, 0, tcz)
    if data.x == tcx and data.z == tcz then
        return true
    end

    if TheWorld.Map:GetTile(tx, tz) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
        return true
    end
end

function MagmaManager:RegisterFireFighter(ent, type)
    if ent and ent:IsValid() and self[type] and self[type][ent.GUID] == nil then
        self[type][ent.GUID] = ent
    end
end

function MagmaManager:UnregisterFireFighter(ent, type)
    if self[type] and self[type][ent.GUID] ~= nil then
        self[type][ent.GUID] = nil
        local new_ents = {}

        for guid, ent in pairs(self[type]) do
            if ent ~= nil then
                new_ents[guid] = ent
            end
        end

        self[type] = new_ents
    end
end

return MagmaManager
