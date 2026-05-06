local env = env
GLOBAL.setfenv(1, GLOBAL)

local function GetWaveBearing(map, ex, ey, ez)
    local radius = 3.5
    local tx, tz = ex % TILE_SCALE, ez % TILE_SCALE
    local left = tx - radius < 0
    local right = tx + radius > TILE_SCALE
    local up = tz - radius < 0
    local down = tz + radius > TILE_SCALE


    local offs_1 =
    {
        { -1, -1, left and up }, { 0, -1, up }, { 1, -1, right and up },
        { -1, 0,  left }, { 1, 0, right },
        { -1, 1, left and down }, { 0, 1, down }, { 1, 1, right and down },
    }

    local width, height = map:GetSize()
    local halfw, halfh = 0.5 * width, 0.5 * height
    local x, y = map:GetTileXYAtPoint(ex, ey, ez)
    local xtotal, ztotal, n = 0, 0, 0

    local is_nearby_land_tile = false

    for i = 1, #offs_1, 1 do
        local curoff = offs_1[i]
        local offx, offy = curoff[1], curoff[2]

        local ground = map:GetTile(x + offx, y + offy)
        if IsLandTile(ground) and ground ~= WORLD_TILES.UM_FLOODWATER_GROTTO then --have to explicity check if the tile is not the floodwater
            if curoff[3] then                                               --because technically itself is a land tile.
                return false
            else
                is_nearby_land_tile = true
            end
            xtotal = xtotal + ((x + offx - halfw) * TILE_SCALE)
            ztotal = ztotal + ((y + offy - halfh) * TILE_SCALE)
            n = n + 1
        end
    end

    radius = 4.5
    local minoffx, maxoffx, minoffy, maxoffy
    if not is_nearby_land_tile then
        minoffx = math.floor((tx - radius) / TILE_SCALE)
        maxoffx = math.floor((tx + radius) / TILE_SCALE)
        minoffy = math.floor((tz - radius) / TILE_SCALE)
        maxoffy = math.floor((tz + radius) / TILE_SCALE)
    end

    local offs_2 =
    {
        { -2, -2 }, { -1, -2 }, { 0, -2 }, { 1, -2 }, { 2, -2 },
        { -2, -1 }, { 2, -1 },
        { -2, 0 }, { 2, 0 },
        { -2, 1 }, { 2, 1 },
        { -2, 2 }, { -1, 2 }, { 0, 2 }, { 1, 2 }, { 2, 2 }
    }
    for i = 1, #offs_2, 1 do
        local curoff = offs_2[i]
        local offx, offy = curoff[1], curoff[2]

        local ground = map:GetTile(x + offx, y + offy)
        if IsLandTile(ground) and ground ~= WORLD_TILES.UM_FLOODWATER_GROTTO then
            if not is_nearby_land_tile then
                is_nearby_land_tile = offx >= minoffx and offx <= maxoffx and offy >= minoffy and offy <= maxoffy
            end
            xtotal = xtotal + ((x + offx - halfw) * TILE_SCALE)
            ztotal = ztotal + ((y + offy - halfh) * TILE_SCALE)
            n = n + 1
        end
    end

    if n == 0 then return true end
    if not is_nearby_land_tile then return false end
    return -math.atan2(ztotal / n - ez, xtotal / n - ex) / DEGREES - 90
end

local function TrySpawnWavesOrShore(self, map, x, y, z)
    local bearing = GetWaveBearing(map, x, y, z)
    if bearing == false then return end

    --always spawn shimmer
    SpawnPrefab("wave_shimmer").Transform:SetPosition(x, y, z)

    if bearing ~= true then
        local wave = SpawnPrefab("wave_shore")
        wave.Transform:SetPosition(x, y, z)
        wave.Transform:SetRotation(bearing)
        wave:SetAnim()
    end
end


env.AddComponentPostInit("wavemanager", function(self)
    self.shimmer[WORLD_TILES.UM_FLOODWATER_GROTTO] = { per_sec = 80, spawn_rate = 0, tryspawn = TrySpawnWavesOrShore }
end)