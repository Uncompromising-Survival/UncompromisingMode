--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local TileGroupManager = TileGroupManager

--------------------------------------------------------------------------
--[[ IAShoreTileManager class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ constants ]]
--------------------------------------------------------------------------

local OFFSET_SCALE = 3.5

local DIR = table.invert({
    "N",
    "S",
    "W",
    "E",
    "NW",
    "NE",
    "SW",
    "SE",
})

local ADJACENT_OFFSETS = {
    [DIR.N] = {x = 1, y = 0},
    [DIR.E] = {x = 0, y = 1},
    [DIR.W] = {x = 0, y = -1},
    [DIR.S] = {x = -1, y = 0},
}

local DIAGONAL_OFFSETS = {
    [DIR.NE] = {x = 1, y = 1},
    [DIR.NW] = {x = 1, y = -1},
    [DIR.SE] = {x = -1, y = 1},
    [DIR.SW] = {x = -1, y = -1},
}

local WATERFALL_TILES = {}
local WATERFALL_SCALE = 3

local WATERFALL_SOUND_DIST = 16
local WATERFALL_SOUND_DIST_SQ = WATERFALL_SOUND_DIST * WATERFALL_SOUND_DIST

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _world = TheWorld
local _map = _world.Map
local _waterfall_grid
local _waterfall_w, _waterfall_h
local prev_x, _, prev_z

--------------------------------------------------------------------------
--[[ Private Member Functions ]]
--------------------------------------------------------------------------

local function GetWaterfallCoordsAtTileCoords(tx, ty, offset)
    return tx * WATERFALL_SCALE - offset.x, ty * WATERFALL_SCALE - offset.y
end

local function GetWaterfallCentrePointAtTileCentre(x, y, offset)
    return x + offset.x * OFFSET_SCALE, y + offset.y * OFFSET_SCALE
end

local function UpdateWaterFallSound(waterfall)
    local player = ThePlayer
    if player == nil then
        return
    end

    local is_nearby = player:GetDistanceSqToPoint(waterfall.Transform:GetWorldPosition()) < WATERFALL_SOUND_DIST_SQ
    waterfall:EnableSound(is_nearby)
end

local function SetWaterfall(waterfall_prefab, tx, ty, x, y, dir, offset)
    local waterfall_index = _waterfall_grid:GetIndex(GetWaterfallCoordsAtTileCoords(tx, ty, offset))

    local waterfall = _waterfall_grid:GetDataAtIndex(waterfall_index)
    if waterfall ~= nil and waterfall.prefab ~= waterfall_prefab then
        waterfall:Remove()
        waterfall = nil
    end

    if waterfall_prefab ~= nil then
        waterfall = waterfall or SpawnPrefab(waterfall_prefab)
        waterfall:Init(dir, GetWaterfallCentrePointAtTileCentre(x, y, offset))
        UpdateWaterFallSound(waterfall)
    end
    _waterfall_grid:SetDataAtIndex(waterfall_index, waterfall)
end

local function IsBelowGround(tile)
    return WATERFALL_TILES[tile] == nil and (TileGroupManager:IsOceanTile(tile) or TileGroupManager:IsImpassableTile(tile))
end

--------------------------------------------------------------------------
--[[ Public Member Functions ]]
--------------------------------------------------------------------------

function self:RegisterWaterfallTile(tile, prefab)
    WATERFALL_TILES[tile] = prefab
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    local player = ThePlayer
    if player == nil then
        prev_x, prev_z = nil, nil
        return
    end

    if prev_x ~= nil and prev_z ~= nil and player:GetDistanceSqToPoint(prev_x, 0, prev_z) < 1 then
        return
    end


    prev_x, _, prev_z = player.Transform:GetWorldPosition()

    for index, waterfall in pairs(_waterfall_grid.grid) do
        UpdateWaterFallSound(waterfall)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnTerraform(src, data)
    if not data then return end

    local tx, ty, original_tile, tile = data.x, data.y, data.original_tile, data.tile

    local waterfall_prefab = WATERFALL_TILES[tile]
    local original_waterfall_prefab = WATERFALL_TILES[original_tile]

    local x, _, y = _map:GetTileCenterPoint(tx, ty)

    if waterfall_prefab ~= original_waterfall_prefab then

        local check_diagonal = waterfall_prefab == nil
        for dir, offset in pairs(ADJACENT_OFFSETS) do
            local _tx, _ty = tx + offset.x, ty + offset.y

            local tile = _map:GetTile(_tx, _ty)
            if tile ~= nil and IsBelowGround(tile) then
                SetWaterfall(waterfall_prefab, _tx, _ty, x, y, dir, offset)
                check_diagonal = true
            else
                SetWaterfall(nil, _tx, _ty, x, y, dir, offset)
            end
        end

        if check_diagonal then
            for dir, offset in pairs(DIAGONAL_OFFSETS) do
                local _tx, _ty = tx + offset.x, ty + offset.y

                local tile = _map:GetTile(_tx, _ty)
                local tile_x_off = _map:GetTile(_tx, ty)
                local tile_y_off = _map:GetTile(tx, _ty)
                if tile ~= nil and IsBelowGround(tile)
                    and WATERFALL_TILES[tile_x_off] ~= waterfall_prefab
                    and WATERFALL_TILES[tile_y_off] ~= waterfall_prefab then

                    SetWaterfall(waterfall_prefab, _tx, _ty, x, y, dir, offset)
                else
                    SetWaterfall(nil, _tx, _ty, x, y, dir, offset)
                end
            end
        end
    elseif original_tile ~= nil and IsBelowGround(original_tile) and (tile == nil or not IsBelowGround(tile)) then
        for dir, offset in pairs(DIAGONAL_OFFSETS) do
            local _tx, _ty = tx + offset.x, ty + offset.y

            SetWaterfall(nil, _tx, _ty, x, y, dir, offset)
        end
    end
end

local function InitializeDataGrid()
    if _waterfall_grid ~= nil then return end --only check one since the rest will all be in the same state

    local w, h = _map:GetSize()
    _waterfall_w, _waterfall_h = w * WATERFALL_SCALE, h * WATERFALL_SCALE
    _waterfall_grid = DataGrid(_waterfall_w, _waterfall_h)

    inst:StartUpdatingComponent(self)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Register events
inst:ListenForEvent("um_local_onterraform", OnTerraform, _world)
inst:ListenForEvent("worldmapsetsize", InitializeDataGrid, _world)

end)
