local env = env
GLOBAL.setfenv(1, GLOBAL)

local function GetClosestLavaTileDist(x, y, z)
    local map = TheWorld.Map
    if map.GetClosestTileDist ~= nil then
        return map:GetClosestTileDist(x, y, z, WORLD_TILES.UM_MAGMA_LAVAMOLTEN, 8)
    end
    local tx, ty = map:GetTileXYAtPoint(x, y, z)
    local tile = WORLD_TILES.UM_MAGMA_LAVAMOLTEN
    for r = 1, TUNING.DSTU.MAGMATILE_HEAT_RADIUS do
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
        if lava_dist <= TUNING.DSTU.MAGMATILE_HEAT_RADIUS then
            self:SetModifier("um_magma_heat", TUNING.MAGMATILE_HEAT)
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
            --have to check tile itself because IMPASSABLE tiles do not work for areaaware.
            local biome = (TheWorld.Map:GetTileAtPoint(self.inst.Transform:GetWorldPosition()) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN or self.inst.components.areaaware:CurrentlyInTag("UM_ActiveLavaZone")) and "ocean"
                or self.inst.components.areaaware:CurrentlyInTag("magmacaves") and "cave"
                or nil

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


local function DoMagmaCoolProjectile(inst)
    inst:AddTag("allow_action_on_impassable")

    if not TheWorld.ismastersim then
        return
    end

    if inst.components.complexprojectile ~= nil then
        local _OnHit = inst.components.complexprojectile.onhitfn

        inst.components.complexprojectile:SetOnHit(function(inst, attacker, target)
            _OnHit(inst, attacker, target)
            local x, y, z = inst.Transform:GetWorldPosition()
            if TheWorld.components.um_magmamanager ~= nil then
                local cooled = TheWorld.components.um_magmamanager:CoolDownMagmaTile(x, z, TUNING.DSTU.MAGMATILE_DEFAULT_COOL_TIME)
                if cooled then
                    for i = 0, math.random(4, 8) do
                        SpawnPrefab("slow_steam_fx" .. math.random(1, 5)).Transform:SetPosition(x + math.random(-2, 2), 0, z + math.random(-2, 2))
                    end
                end
            end
        end)
    end
end

--chilling down tiles
env.AddPrefabPostInit("waterballoon", DoMagmaCoolProjectile)
env.AddPrefabPostInit("snowball", DoMagmaCoolProjectile)

local ice_staves = {
    ["icestaff"] = 0.25,
    ["icestaff2"] = 0.25,
    ["icestaff3"] = 0.125
}

for staff, uses in pairs(ice_staves) do
    env.AddPrefabPostInit(staff, function(inst)
        inst:AddTag("magma_cooler")
        inst:AddTag("allow_action_on_impassable")

        if not TheWorld.ismastersim then
            return
        end

        if inst.components.finiteuses ~= nil and uses ~= nil then
            inst.components.finiteuses:SetConsumption(ACTIONS.UM_COOL_MAGMA, uses)
        end


        inst:AddComponent("magma_cooler")
    end)
end


env.AddPrefabPostInitAny(function(inst)
    if inst:HasTag("wateringcan") then
        inst:AddTag("magma_cooler")
        inst:AddTag("allow_action_on_impassable")

        if not TheWorld.ismastersim then
            return
        end

        inst:AddComponent("magma_cooler")
    end
end)



--sinking stuff
SINKENTITY_PREFABS.LAVA = { "deer_fire_burst", "slow_steam_fx1" }

local _ShouldEntitySink = ShouldEntitySink

function ShouldEntitySink(entity, entity_sinks_in_water, ...)
    if entity:IsValid() and entity.components.complexprojectile ~= nil and entity.components.complexprojectile.owningweapon ~= nil then
        return false
    end
    return _ShouldEntitySink(entity, entity_sinks_in_water, ...)
end

local _GetSinkEntityFXPrefabs = GetSinkEntityFXPrefabs
function GetSinkEntityFXPrefabs(entity, px, py, pz, ...)
    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(px, py, pz)
    if TheWorld.Map:GetTile(tile_x, tile_z) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
        return SINKENTITY_PREFABS.LAVA
    end
    return _GetSinkEntityFXPrefabs(entity, px, py, pz, ...)
end

require("stategraphs/commonstates")

local upvaluehacker = require("tools/um_upvaluehacker")

local _DoVoidFall = upvaluehacker.TryGetUpvalue(CommonStates.AddVoidFallStates, "DoVoidFall")

local function DoVoidAndLavaFall(inst, skip_vfx)
    local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(inst.Transform:GetWorldPosition())
    if TheWorld.Map:GetTile(tx, tz) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
        if not skip_vfx then
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("deer_fire_burst").Transform:SetPosition(x, y, z)
            SpawnPrefab("slow_steam_fx1").Transform:SetPosition(x, y, z)
        end
        inst.sg.statemem.isteleporting = true
        inst:Hide()
        if inst.components.health ~= nil then
            inst.components.health:SetPercent(inst.components.health:GetPercent() - 0.25, false, "fire")
            inst.components.health:SetInvincible(true)
        end
        if inst.components.drownable ~= nil then
            inst.components.drownable:VoidArrive()
        else
            inst:PutBackOnGround()
        end
    else
        _DoVoidFall(inst, skip_vfx)
    end
end

upvaluehacker.SetUpvalue(CommonStates.AddVoidFallStates, DoVoidAndLavaFall, "DoVoidFall")


--for players...
local states = {
    State {
        name = "washed_ashore_lava",
        tags = { "busy", "canrotate", "nopredict", "nomorph", "drowning", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wakeup")

            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("deer_fire_burst").Transform:SetPosition(x, y, z)
            SpawnPrefab("slow_steam_fx1").Transform:SetPosition(x, y, z)

            if inst.components.health ~= nil then
                inst.components.health:SetPercent(inst.components.health:GetPercent() - 0.25, false, "fire")
                inst.components.health:DeltaPenalty(0.25)
            end

            if inst.components.burnable ~= nil then
                inst.components.burnable:Ignite()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
}

env.AddStategraphPostInit("wilson", function(inst)
    local abyss_fall = inst.states.abyss_fall

    local _onenter = abyss_fall.onenter

    abyss_fall.onenter = function(inst, teleport_pt, ...)
        if TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
            inst.sg.statemem.lavafall = true
        end

        _onenter(inst, teleport_pt, ...)
    end

    local timelinefn = abyss_fall.timeline[3].fn

    abyss_fall.timeline[3].fn = function(inst, ...)
        if inst.sg.statemem then
            if inst.components.drownable ~= nil then
                inst.components.drownable:Teleport()
            else
                inst:PutBackOnGround()
            end
            inst:SnapCamera()
            inst.sg:GoToState("washed_ashore_lava")
        else
            timelinefn(inst, ...)
        end
    end

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end
end)

--bridges...
require("components/map")
local _CanDeployBridgeAtPointWithFilter = Map.CanDeployBridgeAtPointWithFilter

function Map:CanDeployBridgeAtPointWithFilter(pt, inst, mouseover, tilefilterfn, ...)
    if self:GetTileAtPoint(pt:Get()) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
        return false
    end
    return _CanDeployBridgeAtPointWithFilter(self, pt, inst, mouseover, tilefilterfn, ...)
end

--caching flingos and crystaleyezers
local firefighters = {
    ["firesuppressor"] = "flingos",
    ["deerclopseyeball_sentryward"] = "crystaleyezers"
}

for name, type in pairs(firefighters) do
    env.AddPrefabPostInit(name, function(inst)
        if not TheWorld.ismastersim then return end
        local um_magmamanager = TheWorld.components.um_magmamanager
        if um_magmamanager then
            um_magmamanager:RegisterFireFighter(inst, type)
            inst:ListenForEvent("onremove", function(_inst)
                local um_magmamanager = TheWorld.components.um_magmamanager
                if um_magmamanager then um_magmamanager:UnregisterFireFighter(_inst, type) end
            end)
        end
    end)
end
