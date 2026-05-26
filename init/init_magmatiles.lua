local env = env
GLOBAL.setfenv(1, GLOBAL)

local function GetClosestLavaTileDist(x, y, z)
    local map = TheWorld.Map
    if map.GetClosestTileDist ~= nil then
        return map:GetClosestTileDist(x, y, z, WORLD_TILES.UM_MAGMA_LAVAMOLTEN, 8)
    end
    local tx, ty = map:GetTileXYAtPoint(x, y, z)
    local tile = WORLD_TILES.UM_MAGMA_LAVAMOLTEN
    for r = 1, 8 do
        if tile == map:GetTile(tx - r, ty) or tile == map:GetTile(tx + r, ty) or tile == map:GetTile(tx, ty - r) or tile == map:GetTile(tx, ty + r) then
            return r
        end
        for i = 1, r - 1 do
            if tile == map:GetTile(tx + r, ty + i) or tile == map:GetTile(tx + r, ty - i) or tile == map:GetTile(tx - r, ty + i) or tile == map:GetTile(tx - r, ty - i)
                or tile == map:GetTile(tx + i, ty + r) or tile == map:GetTile(tx + i, ty - r) or tile == map:GetTile(tx - i, ty + r) or tile == map:GetTile(tx - i, ty - r)
            then
                return math.sqrt(r * r + i * i)
            end
        end
        if tile == map:GetTile(tx + r, ty + r) or tile == map:GetTile(tx + r, ty - r) or tile == map:GetTile(tx - r, ty + r) or tile == map:GetTile(tx - r, ty - r) then
            return math.sqrt(2) * r
        end
    end
    return math.huge
end

env.AddComponentPostInit("temperature", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local lava_dist = GetClosestLavaTileDist(x, y, z)
        if lava_dist <= 8 then
            self:SetModifier("um_magma_heat", 240)
        else
            self:RemoveModifier("um_magma_heat")
        end

        return _OnUpdate(self, dt, ...)
    end
end)

--idfc i'm putting this here rn. TODO: move it.
local magmacave_cc = {
    ["cave"] = {
        night = "images/colour_cubes/dusk03_cc.tex",
    },
    ["ocean"] = {
        night = "images/colour_cubes/summer_dusk_cc.tex",
    }
}

env.AddComponentPostInit("playervision", function(self)
    local _UpdateCCTable = self.UpdateCCTable

    function self:UpdateCCTable()
        _UpdateCCTable(self)
        if self.inst.components.areaaware then
            local biome = self.inst.components.areaaware:CurrentlyInTag("magmacaves") and "cave"
                --have to check tile itself because IMPASSABLE tiles do not work for areaaware.
                or TheWorld.Map:GetTileAtPoint(self.inst.Transform:GetWorldPosition()) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN and "ocean" or nil

            if biome ~= nil and magmacave_cc[biome] ~= self.currentcctable then
                self.currentcctable = magmacave_cc[biome]
                self.currentccphasefn = nil

                self.inst:PushEvent("ccoverrides", magmacave_cc[biome])
                self.inst:PushEvent("ccphasefn", nil)
            end
        end
    end
end)

env.AddPlayerPostInit(function(inst)
    if inst.components.playervision ~= nil and inst.components.areaaware ~= nil then
        inst:ListenForEvent("changearea", function(inst)
            inst.components.playervision:UpdateCCTable()
        end)

        inst.components.areaaware:StartWatchingTile(WORLD_TILES.UM_MAGMA_LAVAMOLTEN)
        inst:ListenForEvent("on_UM_MAGMA_LAVAMOLTEN", function(inst)
            inst.components.playervision:UpdateCCTable()
        end)
    end
end)
