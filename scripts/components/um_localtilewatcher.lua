return Class(function(self, inst)
--------------------------------------------------------------------------
--[[ LocalTileWatcher class definition ]]
--------------------------------------------------------------------------

local distsq = distsq
local next = next

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

local GRID_RADIUS = ((PLAYER_CAMERA_SEE_DISTANCE) / TILE_SCALE) + 10 -- expand for zoom
local CULL_RADIUS = GRID_RADIUS + 3

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _world = TheWorld
local _map = _world.Map
local _ismastersim = _world.ismastersim

local _changes_grid
local _tile_grid = nil
local prev_tx, prev_tz = nil, nil

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function PushEvents()
    if next(_changes_grid.grid) == nil then return end
    for index, data in pairs(_changes_grid.grid) do
        _world:PushEvent("um_local_onterraform", data)
    end
    _world:PushEvent("um_local_onanyterraform", _changes_grid.grid)
    _changes_grid:Load({})
end

local function UpdateTile(index, x, y, original_tile, tile)
    _tile_grid:SetDataAtIndex(index, tile)
    _changes_grid:SetDataAtIndex(index, {index = index, x = x, y = y, original_tile = original_tile, tile = tile})
end

local function InitializeDataGrid()
    if _tile_grid ~= nil then return end --only check one since the rest will all be in the same state

    local w, h = _map:GetSize()
    _changes_grid = DataGrid(w, h)
    _tile_grid = DataGrid(w, h)

    self.inst:StartUpdatingComponent(self)
end
inst:ListenForEvent("worldmapsetsize", InitializeDataGrid, _world)

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:OnTerraform(data)
    local index = _tile_grid:GetIndex(data.x, data.y)
    if _tile_grid:GetDataAtIndex(index) ~= nil then
        if not _ismastersim then
            _map:SetTile(data.x, data.y, data.tile)
        end
        UpdateTile(index, data.x, data.y, data.original_tile, data.tile)
        PushEvents()
    end
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    local player = ThePlayer
    if player == nil then return end

    local px, py, pz = player.Transform:GetWorldPosition()

    local tx, tz = _map:GetTileCoordsAtPoint(px, py, pz)

    if prev_tx ~= nil and prev_tz ~= nil and math.abs(tx - prev_tx) < 4 and math.abs(tz - prev_tz) < 4 then
        -- Don't update if we have not moved far enough
        return
    end
    prev_tx, prev_tz = tx, tz

    -- cull tiles
    for index, data in pairs(_tile_grid.grid) do
        local _tx, _tz = _tile_grid:GetXYFromIndex(index)
        if math.abs(tx - _tx) > CULL_RADIUS or math.abs(tz - _tz) > CULL_RADIUS then
            UpdateTile(index, _tx, _tz, _tile_grid:GetDataAtIndex(index), nil)
        end
    end

    -- set tiles
    for x = -GRID_RADIUS, GRID_RADIUS do
        local newtx = tx + x
        for z = -GRID_RADIUS, GRID_RADIUS do
            local newtz = tz + z
            local index = _tile_grid:GetIndex(newtx, newtz)

            local original_tile = _tile_grid:GetDataAtIndex(index)
            local tile = _map:GetTile(newtx, newtz)
            if original_tile ~= tile then
                UpdateTile(index, newtx, newtz, original_tile, tile)
            end
        end
    end

    -- push events
    PushEvents()
end

end)
