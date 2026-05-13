local UMENV = env
GLOBAL.setfenv(1, GLOBAL)

local IsTableEmpty = IsTableEmpty

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local DEBUG_MODE = false

local COLOUR_ENVELOPE_NAME = "ParticleWorldTileState[COLOUR_ENVELOPE]"
local SCALE_ENVELOPE_NAME = "ParticleWorldTileState[SCALE_ENVELOPE]"

local WORLDTILE_PARTICLE_STATES = {}
local WORLDTILE_PROXY = {}
local OVERHANG_PROXY = {}

local ASSETS = {}

local BOUNDS_OFFSET_X = 0
local BOUNDS_OFFSET_Z = 0

local ANIM_SCALE = 1/150
local function PixelsToCoords(pixel_count)
    return ANIM_SCALE*pixel_count
end

local ATLAS_X_TEX_COUNT = 15.0;
local ATLAS_Y_TEX_COUNT = 5.0;

local TEXTURE_WIDTH = 2048.0;
local TEXTURE_HEIGHT = 2048.0;

local MASK_OFFSET = 4.0;
local MASK_X_OFFSET = MASK_OFFSET;
local MASK_Y_OFFSET = 1368.0+MASK_OFFSET;
local F_MASK_SIZE = 128.0;
local F_MASK_INDEX_SIZE = F_MASK_SIZE+MASK_OFFSET*2.0;

local MASK_START_X = MASK_X_OFFSET/TEXTURE_WIDTH;
local MASK_SIZE_X = F_MASK_SIZE/TEXTURE_WIDTH;
local MASK_INDEX_SIZE_X = F_MASK_INDEX_SIZE/TEXTURE_WIDTH;

local MASK_START_Y = MASK_Y_OFFSET/TEXTURE_HEIGHT;
local MASK_SIZE_Y = F_MASK_SIZE/TEXTURE_HEIGHT;
local MASK_INDEX_SIZE_Y = F_MASK_INDEX_SIZE/TEXTURE_HEIGHT;

local LIFETIME_OFFSET = 10
local MAX_LIFETIME = 2000000000
--our lifetime system ensures that if the time alive of a particle stays between -10000 and -9900 it will evaluate correctly, stay between -9990 and -9910 just to be safe
local LIFETIME_RANGE = MAX_LIFETIME-(2.0*LIFETIME_OFFSET)

local TILE_SCALE = TILE_SCALE
local GROUND_INVISIBLETILES = GROUND_INVISIBLETILES

local TEXTURE_INDEX_WIDTH = 15
local TEXTURE_INDEX_HEIGHT = 5

local builder = UM_ParticleTileTextureBuilder(TEXTURE_INDEX_WIDTH, TEXTURE_INDEX_HEIGHT)

local PRIMARY_INDEX = builder:GetPrimaryIndex()

local TILE_WEST  = builder:GetNextMask()
local TILE_NORTH = builder:GetNextMask()
local TILE_EAST  = builder:GetNextMask()
local TILE_SOUTH = builder:GetNextMask()

local TILE_NORTHWEST = builder:GetNextMask()
local TILE_NORTHEAST = builder:GetNextMask()
local TILE_SOUTHEAST = builder:GetNextMask()
local TILE_SOUTHWEST = builder:GetNextMask()

local VARIANT = builder:GetNextMask()

local NEIGHBOR_TILES = {
    [TILE_EAST]       = {x = 1, y =  0},
    [TILE_SOUTHEAST] = {x = 1, y =  -1},
    [TILE_SOUTH]      = {x =  0, y =  -1},
    [TILE_SOUTHWEST] = {x =  -1, y =  -1},
    [TILE_WEST]       = {x =  -1, y =  0},
    [TILE_NORTHWEST] = {x =  -1, y = 1},
    [TILE_NORTH]      = {x =  0, y = 1},
    [TILE_NORTHEAST] = {x = 1, y = 1},
}

local TileMaskToTextureIndex = {}

--------------------------------------------------------------------------
--[[ Mask initialization ]]
--------------------------------------------------------------------------

local function BuildMask(data, variant)
    local _optional = {}
    local required = 0
    for i, mask in ipairs(data) do
        required = required + mask
        if mask == TILE_WEST then
            _optional[TILE_NORTHWEST] = true
            _optional[TILE_SOUTHWEST] = true
        end
        if mask == TILE_NORTH then
            _optional[TILE_NORTHWEST] = true
            _optional[TILE_NORTHEAST] = true
        end
        if mask == TILE_EAST then
            _optional[TILE_NORTHEAST] = true
            _optional[TILE_SOUTHEAST] = true
        end
        if mask == TILE_SOUTH then
            _optional[TILE_SOUTHWEST] = true
            _optional[TILE_SOUTHEAST] = true
        end
    end

    local optional = {}
    for k, v in pairs(_optional) do
        table.insert(optional, k)
    end

    if variant ~= nil then
        if variant then
            required = required + VARIANT
        end
    else
        table.insert(optional, VARIANT)
    end

    builder:BuildTextureIndexForMask(required, unpack(optional))
end

BuildMask({TILE_WEST}, true)
BuildMask({TILE_NORTH}, false)
BuildMask({TILE_NORTH, TILE_WEST}, false)
BuildMask({TILE_EAST}, true)
BuildMask({TILE_EAST, TILE_WEST}, true)
BuildMask({TILE_EAST, TILE_NORTH}, false)
BuildMask({TILE_EAST, TILE_NORTH, TILE_WEST}, false)
BuildMask({TILE_SOUTH}, false)
BuildMask({TILE_SOUTH, TILE_WEST}, true)
BuildMask({TILE_SOUTH, TILE_NORTH}, false)
BuildMask({TILE_SOUTH, TILE_NORTH, TILE_WEST}, true)
BuildMask({TILE_SOUTH, TILE_EAST}, false)
BuildMask({TILE_SOUTH, TILE_EAST, TILE_WEST}, true)
BuildMask({TILE_SOUTH, TILE_EAST, TILE_NORTH}, true)
BuildMask({TILE_SOUTH, TILE_EAST, TILE_NORTH, TILE_WEST}, false)

builder.SkipIndex()

BuildMask({TILE_NORTHWEST})
BuildMask({TILE_NORTHEAST})
BuildMask({TILE_NORTHEAST, TILE_NORTHWEST})
BuildMask({TILE_SOUTHEAST})
BuildMask({TILE_SOUTHEAST, TILE_NORTHWEST})
BuildMask({TILE_SOUTHEAST, TILE_NORTHEAST})
BuildMask({TILE_SOUTHEAST, TILE_NORTHEAST, TILE_NORTHWEST})
BuildMask({TILE_SOUTHWEST})
BuildMask({TILE_SOUTHWEST, TILE_NORTHWEST})
BuildMask({TILE_SOUTHWEST, TILE_NORTHEAST})
BuildMask({TILE_SOUTHWEST, TILE_NORTHEAST, TILE_NORTHWEST})
BuildMask({TILE_SOUTHWEST, TILE_SOUTHEAST})
BuildMask({TILE_SOUTHWEST, TILE_SOUTHEAST, TILE_NORTHWEST})
BuildMask({TILE_SOUTHWEST, TILE_SOUTHEAST, TILE_NORTHEAST})
BuildMask({TILE_SOUTHWEST, TILE_SOUTHEAST, TILE_NORTHEAST, TILE_NORTHWEST})

BuildMask({TILE_NORTH, TILE_SOUTHEAST})
BuildMask({TILE_EAST, TILE_SOUTHWEST})
BuildMask({TILE_SOUTH, TILE_NORTHWEST})
BuildMask({TILE_WEST, TILE_NORTHEAST})
BuildMask({TILE_NORTH, TILE_SOUTHEAST, TILE_SOUTHWEST})
BuildMask({TILE_EAST, TILE_SOUTHWEST, TILE_NORTHWEST})
BuildMask({TILE_SOUTH, TILE_NORTHWEST, TILE_NORTHEAST})
BuildMask({TILE_WEST, TILE_NORTHEAST, TILE_SOUTHEAST})
BuildMask({TILE_NORTH, TILE_SOUTHWEST})
BuildMask({TILE_EAST, TILE_NORTHWEST})
BuildMask({TILE_SOUTH, TILE_NORTHEAST})
BuildMask({TILE_WEST, TILE_SOUTHEAST})

BuildMask({TILE_WEST, TILE_NORTH, TILE_SOUTHEAST})
BuildMask({TILE_NORTH, TILE_EAST, TILE_SOUTHWEST})
BuildMask({TILE_WEST, TILE_SOUTH, TILE_NORTHEAST})
BuildMask({TILE_SOUTH, TILE_EAST, TILE_NORTHWEST})

builder.SkipIndex()

BuildMask({TILE_WEST}, false)
BuildMask({TILE_NORTH}, true)
BuildMask({TILE_NORTH, TILE_WEST}, true)
BuildMask({TILE_EAST}, false)
BuildMask({TILE_EAST, TILE_WEST}, false)
BuildMask({TILE_EAST, TILE_NORTH}, true)
BuildMask({TILE_EAST, TILE_NORTH, TILE_WEST}, true)
BuildMask({TILE_SOUTH}, true)
BuildMask({TILE_SOUTH, TILE_WEST}, false)
BuildMask({TILE_SOUTH, TILE_NORTH}, true)
BuildMask({TILE_SOUTH, TILE_NORTH, TILE_WEST}, false)
BuildMask({TILE_SOUTH, TILE_EAST}, true)
BuildMask({TILE_SOUTH, TILE_EAST, TILE_WEST}, false)
BuildMask({TILE_SOUTH, TILE_EAST, TILE_NORTH}, false)
BuildMask({TILE_SOUTH, TILE_EAST, TILE_NORTH, TILE_WEST}, true)

for mask, index in pairs(builder:Finish()) do
	TileMaskToTextureIndex[mask] = index
end

builder = nil

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _map
local _manager
local _tile_grid = {}
local _particletile_grids = {}
local _id_to_tile = {}
local _tile_to_id = {}
local _id_to_state = {}
local _centre_x, _, _centre_y
local tile_w, tile_h
local _debug_grid

--------------------------------------------------------------------------
--[[ Private Member Functions ]]
--------------------------------------------------------------------------

local function UpdateDebugData(index)
    if DEBUG_MODE then
        local debug = _debug_grid:GetDataAtIndex(index)
        if debug ~= nil then
            debug:Remove()
            _debug_grid:SetDataAtIndex(index, nil)
        end
        for id, tile in pairs(_id_to_tile) do
            local data = _particletile_grids[id]:GetDataAtIndex(index)
            if data ~= nil then
                local debug = _debug_grid:GetDataAtIndex(index)
                if debug == nil then
                    debug = SpawnAt("um_debug_label", Vector3(data.x, 0, data.y))
                    local tile = _tile_grid:GetDataAtIndex(index)
                    debug:SetUMDebugLabel("TILE", string.format("CACHED TILE[%s]", tile and INVERTED_WORLD_TILES[tile] or "N/A"))
                end
                local debug_str = string.format("TILE[%s](%i)", INVERTED_WORLD_TILES[_id_to_tile[id]], data.state)
                debug:SetUMDebugLabel(tostring(id), debug_str)
                _debug_grid:SetDataAtIndex(index, debug)
            end
        end
    end
end

local function GetMaskForNeighbors(data)
    local mask = 0
    for i, _mask in ipairs(data) do
        mask = mask + _mask
    end

    return mask
end

local function GetTileVariant(x, z)
    local seed = x * 127.1 + z * 311.7

    local random = math.sin(seed) * 43758.5453
    random = random - math.floor(random)

    if random < 0.5 then
        return 0
    else
        return 1
    end
end

local function ClearParticleTileData(index)
    local changed = false
    for id, tile in pairs(_id_to_tile) do
        if _particletile_grids[id]:GetDataAtIndex(index) ~= nil then
            changed = true
        end
        _particletile_grids[id]:SetDataAtIndex(index, nil)
    end
    return changed
end

local function DespawnTiles()
    _manager:ResetParticles()
end

local function SpawnTiles()
    for id, tile in pairs(_id_to_tile) do
        for _, data in pairs(_particletile_grids[id].grid) do
            _manager:SpawnTile(data.x, data.y, data.state, id)
        end
    end
    _manager:SpawnFastForward()
end

local function IsInMapBounds(tx, tz)
    if tx < -BOUNDS_OFFSET_X or tz < -BOUNDS_OFFSET_Z then
        return false
    end

    if tx > tile_w - 1 + BOUNDS_OFFSET_X or tz > tile_h - 1 + BOUNDS_OFFSET_Z then
        return false
    end

    return true
end

--------------------------------------------------------------------------
--[[ VFX Manager ]]
--------------------------------------------------------------------------

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(COLOUR_ENVELOPE_NAME, 
        {{2, {1, 1, 1, 1}}
    })

    EnvelopeManager:AddVector2Envelope(SCALE_ENVELOPE_NAME, {
        {2, {(4/PixelsToCoords(TEXTURE_WIDTH)) / MASK_SIZE_X, (4/PixelsToCoords(TEXTURE_HEIGHT)) / MASK_SIZE_Y}}
    })
end

local function get_overhang_uv(texture_index)
    local index_x, index_y = (texture_index % ATLAS_X_TEX_COUNT), math.floor(texture_index / ATLAS_X_TEX_COUNT)
    return MASK_START_X + (index_x * MASK_INDEX_SIZE_X), MASK_START_Y + (index_y * MASK_INDEX_SIZE_Y)
end

local function SpawnTile(inst, x, y, state, index)
    local uv_x, uv_y = get_overhang_uv(state - 1)
    inst.Transform:SetPosition(x, 0, y)
    inst.VFXEffect:AddParticleUV(index - 1, MAX_LIFETIME, 0, 0, 0, 0, 0, 0, uv_x, uv_y)
end

local function ConstructWorldParticleStateManager()    
    local inst = CreateEntity()
    inst.entity:AddTransform()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(GetTableSize(WORLDTILE_PARTICLE_STATES))
    for tile, data in pairs(WORLDTILE_PARTICLE_STATES) do
        local index = _tile_to_id[tile] - 1
        effect:SetRenderResources(index, resolvefilepath(data.texture), resolvefilepath(data.shader))
        effect:SetMaxNumParticles(index, 10000)
        effect:SetMaxLifetime(index, MAX_LIFETIME)
        effect:SetScaleEnvelope(index, SCALE_ENVELOPE_NAME)
        effect:SetColourEnvelope(index, COLOUR_ENVELOPE_NAME)
        effect:SetUVFrameSize(index, MASK_SIZE_X, MASK_SIZE_Y)
        effect:SetLayer(index, data.layer or LAYER_BACKGROUND)
        effect:SetSortOrder(index, data.sort or -3)
        effect:SetSortOffset(index, -7)

        effect:SetKillOnEntityDeath(index, true)
        effect:SetSpawnVectors(index,
            1, 0, 0,
            0, 0, 1
        )
    end

    inst.SpawnTile = SpawnTile

    local ticktime = 0

    function inst:UpdateParticles(dt)
		ticktime = ticktime + dt
		if ticktime >= LIFETIME_RANGE then
            for id, tile in pairs(_id_to_tile) do
                local index = id - 1
                effect:FastForward(index, -LIFETIME_RANGE)
            end
            ticktime = ticktime - LIFETIME_RANGE
		end
    end

    function inst:ResetParticles()
		ticktime = 0
        for id, tile in pairs(_id_to_tile) do
            local index = id - 1
            effect:ClearAllParticles(index)
        end
    end

    function inst:SpawnFastForward()
        local delta = LIFETIME_OFFSET+(GetTime() % LIFETIME_RANGE)
        for id, tile in pairs(_id_to_tile) do
            local index = id - 1
            effect:FastForward(index, delta)
        end
    end

    inst.entity:SetPristine()

    inst.persists = false

	inst:SetPrefabName("particle_world_tile_state")

	inst.entity:CallPrefabConstructionComplete()

	return inst
end

local function GetParticleTileID(tile)
    if tile == nil then return nil, nil end

    local id = _tile_to_id[tile] or nil
    local overhang_id = id

    if id == nil then
        tile = OVERHANG_PROXY[tile] or tile
        overhang_id = _tile_to_id[tile] or id
    end

    return id, overhang_id
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function UM_InitializeParticleWorldTileState()
    assert(_map == nil, "[ParticleWorldTileState]: Already initialized")

    local sim_tick_time = TheSim:GetTickTime()
    -- Round to the tick time
    LIFETIME_RANGE = math.ceil(LIFETIME_RANGE/sim_tick_time)*sim_tick_time

    _map = TheWorld.Map

    tile_w, tile_h = _map:GetSize()
    _tile_grid = DataGrid(tile_w, tile_h)

    _id_to_state = {}
    _id_to_tile = {}
    for tile, data in pairs(WORLDTILE_PARTICLE_STATES) do
        table.insert(_id_to_state, data)
        table.insert(_id_to_tile, tile)
    end
    table.sort(_id_to_tile, function(a,b) return _map:TileRendersOver(b, a) end)

    _tile_to_id = {}
    for id, tile in pairs(_id_to_tile) do
        _tile_to_id[tile] = id
        _particletile_grids[id] = DataGrid(tile_w, tile_h)
    end

    if DEBUG_MODE then
        _debug_grid = DataGrid(tile_w, tile_h)
    end

    _centre_x, _, _centre_y = _map:GetTileCenterPoint(0, 0)

    --these don't produce the exact size, but its close enough that we can round it to perfect numbers in the shader
    InitEnvelope()
    _manager = ConstructWorldParticleStateManager()

    local _Update = Update
    function Update(dt, ...)
        _Update(dt, ...)
        _manager:UpdateParticles(dt)
    end
    UpdateLuaRegistry(_Update, Update)
end

function UM_RegisterParticleWorldTileState(tile, texture, shader, config)
    assert(_map == nil, "[ParticleWorldTileState]: Cannot register tiles post initialization")

    config = config or {}

    WORLDTILE_PARTICLE_STATES[tile] =
    {
        texture = texture,
        shader = shader,
        has_variant = config.has_variant or false,
        layer = config.layer,
        sort = config.sort,
    }

    table.insert(ASSETS, Asset("IMAGE", texture))
    table.insert(ASSETS, Asset("SHADER", shader))
end

function UM_OnAnyTerraformParticleWorldTileState(tiles_data)
    if tiles_data == nil then return end

    local changed_tiles = {}

    local changed = true

    for index, data in pairs(tiles_data) do
        local tile = data.tile
        tile = WORLDTILE_PROXY[tile] or tile

        local old_tile = _tile_grid:GetDataAtIndex(index)
        local old_id, old_overhang_id = GetParticleTileID(old_tile)
        local id, overhang_id = GetParticleTileID(tile)

        if id ~= old_id or overhang_id ~= old_overhang_id then
            if overhang_id ~= nil then
                _tile_grid:SetDataAtIndex(index, tile)
            else
                _tile_grid:SetDataAtIndex(index, nil)
            end
            changed_tiles[index] = {
                tx = data.x, 
                ty = data.y,
                tile = tile,
                id = id,
                overhang_id = overhang_id,
            }
            for dir, off in pairs(NEIGHBOR_TILES) do
                local _tx, _ty = data.x + off.x, data.y + off.y
                if IsInMapBounds(_tx, _ty) then
                    local _index = _tile_grid:GetIndex(_tx, _ty)
                    if changed_tiles[_index] == nil then
                        local _tile = _tile_grid:GetDataAtIndex(_index)
                        local _id, _overhang_id = GetParticleTileID(_tile)
                        changed_tiles[_index] = {
                            tx = _tx, 
                            ty = _ty,
                            tile = _tile,
                            id = _id,
                            overhang_id = _overhang_id,
                        }
                    end
                end
            end
            changed = true
        end
    end

    if not changed then
        return
    end

    local tiles_dirty = true

    local overhang_data = {}
    for index, data in pairs(changed_tiles) do
        local tx, ty, tile, id, overhang_id = data.tx, data.ty, data.tile, data.id, data.overhang_id
        local x, y = _centre_x + tx * TILE_SCALE, _centre_y + ty * TILE_SCALE

        if ClearParticleTileData(index) then
            tiles_dirty = true
            UpdateDebugData(index)
        end

        if id ~= nil then
            _particletile_grids[id]:SetDataAtIndex(index, {
                x = x,
                y = y,
                state = PRIMARY_INDEX,
            })
            tiles_dirty = true
            UpdateDebugData(index)
        end

        for dir, off in pairs(NEIGHBOR_TILES) do
            local _tx, _ty = tx + off.x, ty + off.y
            local _index = _tile_grid:GetIndex(_tx, _ty)

            local _tile = _tile_grid:GetDataAtIndex(_index)
            local _id, _overhang_id = GetParticleTileID(_tile)

            if _id ~= id and _overhang_id ~= nil and overhang_id ~= _overhang_id and _map:TileRendersOver(_tile, tile) then
                if overhang_data[_overhang_id] == nil then
                    overhang_data[_overhang_id] = {}
                end
                if overhang_data[_overhang_id][index] == nil then
                    overhang_data[_overhang_id][index] = {
                        x = x,
                        y = y,
                        neighbours = {}
                    }
                end
                table.insert(overhang_data[_overhang_id][index].neighbours, dir)
            end
        end
    end

    for id, tile_overhang_data in pairs(overhang_data) do
        local particle_state = _id_to_state[id]
        for index, data in pairs(tile_overhang_data) do
            local key = GetMaskForNeighbors(data.neighbours)
            if key > 0 then
                if particle_state.has_variant then
                    key = key + VARIANT * GetTileVariant(data.x, data.y)
                end
                _particletile_grids[id]:SetDataAtIndex(index, {
                    x = data.x,
                    y = data.y,
                    state = TileMaskToTextureIndex[key],
                })
                tiles_dirty = true
                UpdateDebugData(index)
            end
        end
    end

    if tiles_dirty then
        DespawnTiles()
        SpawnTiles()
    end
end

function UM_OnTerraformParticleWorldTileState(tile_data)
    UM_OnAnyTerraformParticleWorldTileState({[_tile_grid:GetIndex(tile_data.x, tile_data.y)] = tile_data})
end

function UM_SetProxyParticleWorldTileState(tile, proxy_tile)
    WORLDTILE_PROXY[proxy_tile] = tile
end

function UM_SetOverhangProxyParticleWorldTileState(tile, proxy_tile)
    OVERHANG_PROXY[proxy_tile] = tile
end

function UM_SetMapBoundsOffsetParticleWorldTileState(x_off, z_off)
    BOUNDS_OFFSET_X, BOUNDS_OFFSET_Z = x_off, z_off
end

function UM_AddAssetsParticleWorldTileState(assets) 
    for i, asset in ipairs(ASSETS) do
        table.insert(assets, asset)
    end
end
