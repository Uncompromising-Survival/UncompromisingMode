local env = env
GLOBAL.setfenv(1, GLOBAL)

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