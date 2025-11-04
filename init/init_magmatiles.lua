local env = env
GLOBAL.setfenv(1, GLOBAL)



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

    return radius + 1
end

env.AddComponentPostInit("temperature", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local lava_dist = TheWorld.Map:GetClosestTileDist(x, y, z, WORLD_TILES.UM_MAGMA_LAVAMOLTEN, 8)
        if lava_dist <= 8 then
            self:SetModifier("um_magma_heat", 800)
        else
            self:RemoveModifier("volcano_heat")
        end

        return _OnUpdate(self, dt, ...)
    end
end)