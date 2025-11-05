GLOBAL.setfenv(1, GLOBAL)

local UM_LAVA_TILES = UM_LAVA_TILES

local RenderTileOrder = nil

local _AddRenderLayer = Map.AddRenderLayer
function Map:AddRenderLayer(...)
    if RenderTileOrder == nil then
        RenderTileOrder = {}
        local tiles = require("worldtiledefs")
        for i, v in ipairs(tiles.ground) do
            RenderTileOrder[v[1]] = i
        end
    end
    _AddRenderLayer(self, ...)
end

local function TileRendersOver(tile1, tile2)
    return (RenderTileOrder[tile1] or 0) > (RenderTileOrder[tile2] or 0)
end


function Map:TileRendersOver(tile1, tile2)
    return TileRendersOver(tile1, tile2)
end

local _IsDeployPointClear = Map.IsDeployPointClear
Map.IsDeployPointClear = function(Map, pt, inst, min_spacing, min_spacing_sq_fn, near_other_fn, check_player, custom_ignore_tags)
    
    if pt ~= nil and pt.x ~= nil then
        local x = pt.x
        local z = pt.z
        
        local portaboat = TheSim:FindEntities(x, 0, z, 4, {"portableraft"})
        if portaboat ~= nil and #portaboat > 0 then
            return false
        end
    end

    return _IsDeployPointClear(Map, pt, inst, min_spacing, min_spacing_sq_fn, near_other_fn, check_player, custom_ignore_tags)
end

function Map:IsUMLavaTile(tile)
    return UM_LAVA_TILES[tile] ~= nil
end

--graciously obtained from IA.
function Map:GetClosestTileDist(x, y, z, tile, radius)
    x, y = self:GetTileXYAtPoint(x, y, z)
    for r = 1, radius do
        if tile == self:GetTile(x - r, y) or tile == self:GetTile(x + r, y) or tile == self:GetTile(x, y - r) or tile == self:GetTile(x, y + r) then
            return r
        end

        for i = 1, r - 1 do
            if tile == self:GetTile(x + r, y + i) or tile == self:GetTile(x + r, y - i) or tile == self:GetTile(x - r, y + i) or tile == self:GetTile(x - r, y - i)
                or tile == self:GetTile(x + i, y + r) or tile == self:GetTile(x + i, y - r) or tile == self:GetTile(x - i, y + r) or tile == self:GetTile(x - i, y - r)
            then
                return math.sqrt(r * r + i * i)
            end
        end

        if tile == self:GetTile(x + r, y + r) or tile == self:GetTile(x + r, y - r) or tile == self:GetTile(x - r, y + r) or tile == self:GetTile(x - r, y - r) then
            return math.sqrt(2) * r
        end
    end

    return math.huge
end
