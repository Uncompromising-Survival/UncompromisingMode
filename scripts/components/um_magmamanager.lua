local MagmaManager = Class(function(self, inst)
    self.inst = inst
    self.init_comlete = false

    self.cooled_down_tiles = {}

    self.magma_tiles= {}

    self.inst:StartUpdatingComponent(self)
end)

function MagmaManager:Init(tiles)
    if self.init_complete then
        return
    end

    self.magma_tiles = tiles

    for _, pos in pairs(tiles) do
        --set to real tile
        local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(pos.x, 0, pos.z)
        TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.UM_MAGMA_LAVAMOLTEN)

        --spawn temperature/light/etc
        if #TheSim:FindEntities(pos.x, 0, pos.z, 1, { "magma_tile" }, {}) == 0 then
            local prefab = SpawnPrefab("magma_tile")
            prefab.Transform:SetPosition(pos.x, 0, pos.z)
        end

        --spawn magmatile borders

        for px = -16, 16, 4 do
            for pz = -16, 16, 4 do
                if TheWorld.Map:IsPassableAtPoint(pos.x + px, 0, pos.z + pz) then
                    local chance = math.abs(((math.abs(px) / 16 + math.abs(pz) / 16) / 2) - 1)
                    if (math.random() <= chance) then
                        tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(pos.x + px, 0, pos.z + pz)

                        TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.UM_MAGMA_LAVABORDER)
                    end
                end
            end
        end
    end

    self.init_complete = true
end

function MagmaManager:OnSave()
    local data = {
        init_complete = self.init_complete,
        cooled_down_tiles = self.cooled_down_tiles,
        magma_tiles = self.magma_tiles
    }

    return data
end

function MagmaManager:OnLoad(data)
    self.init_complete = data.init_complete
    self.cooled_down_tiles = data.cooled_down_tiles
    self.magma_tiles = data.magma_tiles
end

function MagmaManager:CoolDownMagmaTile(x, z, duration)
    for k, v in pairs(self.cooled_down_tiles) do
        if v.x == x and v.z == z then
            v.duration = duration --refresh duration
            return
        end
    end



    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    if not TheWorld.Map:GetTile(tile_x, tile_z) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
        return
    end

    TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.UM_MAGMA_LAVABORDER) --TODO? Custom tile

    for _, v in ipairs(TheSim:FindEntities(x, 0, z, 6)) do
        v:PushEvent("check_magma_cooled")
    end

    table.insert(self.cooled_down_tiles, { x = x, z = z, duration = duration })
end

function MagmaManager:MeltMagmaTile(x, z, tile_index)
    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.UM_MAGMA_LAVAMOLTEN)
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, 6)) do
        v:PushEvent("check_magma_melt")
    end
    SpawnPrefab("rock_break_fx").Transform:SetPosition(x, 0, z)

    table.remove(self.cooled_down_tiles, tile_index)
end

function MagmaManager:OnUpdate(dt)
    for k, v in pairs(self.cooled_down_tiles) do
        v.duration = v.duration - 1
        if v.duration <= 100 and math.random() > 0.5 then
            local fx1 = SpawnPrefab("fossilizing_fx_" .. math.random(1, 2))
            fx1.Transform:SetPosition(v.x + (math.random(-4, 4) * math.random()), 0, v.z + (math.random(-4, 4) * math.random()))

            local fx2 = SpawnPrefab("deer_fire_burst")
            fx2.Transform:SetPosition(v.x + (math.random(-4, 4) * math.random()), 0, v.z + (math.random(-4, 4) * math.random()))
        end

        if v.duration <= 0 then
            self:MeltMagmaTile(v.x, v.z, k)
        end
    end
end

return MagmaManager
