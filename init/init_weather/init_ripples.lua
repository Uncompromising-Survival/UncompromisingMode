local env = env
GLOBAL.setfenv(1, GLOBAL)

local function RobustFloodCheck(inst) -- For players, check to see if they're on the edge of a tile, you can walk on the "Void" to avoid the effects of the tile you're standing on, similar to spider webbings
    --IsVisualGroundAtPoint(x,y,z)... not sure how this can help?
    local x, y, z = inst.Transform:GetWorldPosition()
    local md = 1.5 --maxdist
    for i = -md, md, 3 do
        for j = -md, md, 3 do
            local current_tile = TheWorld.Map:GetTileAtPoint(x + i, y, z + j)
            if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO or current_tile == WORLD_TILES.UM_FLOODWATER_BROILING then
                return true
            end
        end
    end
end

env.AddReplicableComponent("umripples")

env.AddComponentPostInit("floater", function(self)
    local _ShouldShowEffect = self.ShouldShowEffect
    function self:ShouldShowEffect(...)
        local pos_x, pos_y, pos_z = self.inst.Transform:GetWorldPosition()
        if TheWorld.Map:GetTileAtPoint(pos_x, 0, pos_z) == WORLD_TILES.UM_FLOODWATER_GROTTO and not (self.inst.sg and self.inst.sg:HasStateTag("flying")) then return true end
        return _ShouldShowEffect(self, ...)
    end
end)

for _, prefab in ipairs(TUNING.DSTU.RIPPLE_BLACKLIST_PREFABS) do
    env.AddPrefabPostInit(prefab, function(inst)
        inst.um_ripple_blacklist = true
    end)
end

-- AXE Add ripples to plants, structures, and items
env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst:HasAnyTag(TUNING.DSTU.RIPPLE_BLACKLIST_TAGS) then
        inst.um_ripple_blacklist = true
    end

    if (inst:HasAnyTag("structure", "boulder", "plant") or inst.components.inventoryitem) and not inst.components.floater and not inst.um_ripple_blacklist then
        local umripples = inst.components.umripples or inst:AddComponent("umripples")
        if inst.components.inventoryitem and not inst.components.floater then
            umripples.vert_offset = .1
        end
    end
end)

local function AddRipples(prefab, xscale, yscale, zscale, vert_offset) --AXE These calls need to be both on client and server
    env.AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then return end
        local umripples = inst.components.umripples or inst:AddComponent("umripples")
        umripples.xscale = xscale or 1
        umripples.yscale = yscale or 1
        umripples.zscale = zscale or 1
        umripples.vert_offset = vert_offset or 0
    end)
end

-- AXE TODO convert the many function calls to a table and a loop... would that even be cleaner though? It's already about as complex as a table...? What do you think?

-- Tuned Ripples on Prefabs
AddRipples("molebathill", 2, 1, 2)
AddRipples("moonspider_spike", .5, 1, .5)
AddRipples("driftwood_small1", 3, 1, 3)
AddRipples("driftwood_small2", 3, 1, 3)
AddRipples("driftwood_tall", 1.5)
AddRipples("rock1", 3.5, 1.5, 3.5)
AddRipples("rock2", 3.5, 1.5, 3.5)
AddRipples("skeleton", 2.25, 2, 2.25, .2)

-- Tuned Ripples on Creatures
AddRipples("hound", 2, 1, 2)
AddRipples("icehound", 2, 1, 2)
AddRipples("firehound", 2, 1, 2)
AddRipples("um_tentacle_moon", 1.5, 1.5, 1.5, .2)
AddRipples("um_tentacle_moon_mine", .5, 1, .5)
AddRipples("boulder_crab", 3, 1, 3)
AddRipples("molebat", 1.1, 1.1, 1.1)
AddRipples("frog", 1.1, 1.1, 1.1)
AddRipples("uncompromising_toad", 1.1, 1.1, 1.1)
AddRipples("lunarfrog", 1.1, 1.1, 1.1)
AddRipples("worm", 1.4, 1.4, 1.4)
AddRipples("viperworm", 1.4, 1.4, 1.4)
AddRipples("shockworm", 1.4, 1.4, 1.4)
AddRipples("carrat", 1.1, 1.1, 1.1, .2)
AddRipples("mushgnome", .8, .8, .8, .2)
local pigmanlike_minions = {"pigman", "bunnyman", "merm", "mermguard", "merm_lunar", "mermguard_lunar"}
for _, v in ipairs(pigmanlike_minions) do
    AddRipples(v, 1.2, 1.2, 1.2, .2)
end
--

env.AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    local umripples = inst.components.umripples or inst:AddComponent("umripples")
    umripples.xscale = .75
    umripples.zscale = .75
    umripples.vert_offset = .2
end)

--AXE Mobs
env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst:HasAnyTag("_health", "animal", "epic", "monster") and not inst:HasAnyTag("shadow", "flying", "gestalt", "ghost") and not inst.prefab == "webbedcreature" then
        local umripples = inst.components.umripples or inst:AddComponent("umripples")
        umripples.vert_offset = .2
    end
    if inst:HasTag("spider") and not inst:HasTag("player") then
        local umripples = inst.components.umripples or inst:AddComponent("umripples")
        umripples.xscale = 2
        umripples.yscale = 1.4
        umripples.zscale = 2
        umripples.vert_offset = .35
    end
    if inst:HasTag("largecreature") and not inst:HasTag("flying") then
        local umripples = inst.components.umripples or inst:AddComponent("umripples")
        umripples.xscale = 3
        umripples.yscale = 3
        umripples.zscale = 3
        umripples.vert_offset = .5
    end
end)

local statenames = {"bedroll", "knockout"}
local state_time_ent = {1.2, 1.2}
local state_time_ext = {1, 1.5}
env.AddStategraphPostInit("wilson", function(inst)
    for iname = 1, #statenames do
        local state = inst.states[statenames[iname]]

        local _onenter = state.onenter
        state.onenter = function(inst, ...)
            inst:DoTaskInTime(state_time_ent[iname], function(inst)
                if RobustFloodCheck(inst) and inst.sg.currentstate.name == statenames[iname] then
                    inst.components.umripples:ResizeTarget({250, 250, 250})
                end
            end)
            _onenter(inst, ...)
        end

        local _onexit = state.onexit
        state.onexit = function(inst, ...)
            inst:DoTaskInTime(state_time_ext[iname], function(inst)
                if RobustFloodCheck(inst) then
                    inst.components.umripples:ResizeTarget({75, 100, 75})
                end
            end)
            _onexit(inst, ...)
        end
    end
end)

-- AXE Add mobs that don't fly but still shouldn't be penalized
local um_flood_speed_immune = {"frog", "molebat", "lunarfrog"}
for i, v in ipairs(um_flood_speed_immune) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.umripples.speed_immune = true
    end)
end

env.AddPrefabPostInit("mole_move_fx", function(inst)
    inst:DoTaskInTime(0, function(inst)
        if RobustFloodCheck(inst) then
            inst:Remove()
        end
    end)
end)

local statenames = {"aggressivehop", "hop"}
env.AddStategraphPostInit("frog", function(inst)
    for iname = 1, #statenames do
        local state = inst.states[statenames[iname]]
        local state_timeline1_fn = state.timeline[1].fn
        state.timeline[1].fn = function(inst, ...)
            if inst.components.umripples then
                inst.components.umripples:OnNoLongerLandedServer()
            end
            state_timeline1_fn(inst, ...)
        end
        local state_timeline2_fn = state.timeline[2].fn
        state.timeline[2].fn = function(inst, ...)
            if inst.components.umripples and RobustFloodCheck(inst) then
                inst.components.umripples:OnLandedServer(true)
            end
            state_timeline2_fn(inst, ...)
        end
        state.onexit = function(inst)
            if inst.components.umripples and RobustFloodCheck(inst) then
                inst.components.umripples:OnLandedServer(true)
            end
        end
    end
end)

env.AddStategraphPostInit("molebat", function(inst)
    local walkstate = inst.states["walk"]
    local walkstate_timeline2_fn = walkstate.timeline[2].fn
    walkstate.timeline[2].fn = function(inst, ...)
        if inst.components.umripples then
            inst.components.umripples:OnNoLongerLandedServer()
        end
        walkstate_timeline2_fn(inst, ...)
    end
    local walkstate_timeline3_fn = walkstate.timeline[3].fn
    walkstate.timeline[3].fn = function(inst, ...)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
        end
        walkstate_timeline3_fn(inst, ...)
    end
    walkstate.onexit = function(inst)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
        end
    end

    local attackstate = inst.states["attack"]
    local attackstate_timeline1_fn = attackstate.timeline[1].fn
    attackstate.timeline[1].fn = function(inst, ...)
        if inst.components.umripples then
            inst.components.umripples:OnNoLongerLandedServer()
        end
        attackstate_timeline1_fn(inst, ...)
    end
    local attackstate_timeline3_fn = attackstate.timeline[3].fn
    attackstate.timeline[3].fn = function(inst, ...)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
        end
        attackstate_timeline3_fn(inst, ...)
    end
    attackstate.onexit = function(inst)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
        end
    end

    local fallstate = inst.states["fall"]
    local fallstate_onenter = fallstate.onenter
    fallstate.onenter = function(inst, ...)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnNoLongerLandedServer()
            inst:DoTaskInTime(30 * FRAMES, function(inst)
                inst.components.umripples:OnLandedServer(true)
            end)
        end
        fallstate_onenter(inst, ...)
    end
end)

env.AddStategraphPostInit("bird", function(inst)
    local flyawaystate = inst.states["flyaway"]
    local flyawaystate_onenter = flyawaystate.onenter
    flyawaystate.onenter = function(inst, ...)
        if inst.components.umripples then
            inst.components.umripples:OnNoLongerLandedServer()
        end
        flyawaystate_onenter(inst, ...)
    end
end)

local function ToggleWormMoveSymbols(inst, show)
    for i = 0, 8 do
        if show then
            inst.AnimState:ShowSymbol("wormmovefx_" .. i)
        else
            inst.AnimState:HideSymbol("wormmovefx_" .. i)
        end
    end
    if show then
        inst.AnimState:ShowSymbol("wormmovefx")
    else
        inst.AnimState:HideSymbol("wormmovefx")
    end
end

env.AddStategraphPostInit("worm", function(inst)
    local attackprestate = inst.states["attack_pre"]
    local attackprestate_onenter = attackprestate.onenter
    attackprestate.onenter = function(inst, ...)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
            inst:Show()
        end
        attackprestate_onenter(inst, ...)
    end

    local attackstate = inst.states["attack"]
    local attackstate_onenter = attackstate.onenter
    attackstate.onenter = function(inst, ...)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
            inst:Show()
            ToggleWormMoveSymbols(inst, false)
        end
        attackstate_onenter(inst, ...)
    end
    attackstate.onexit = function(inst)
        if inst.components.umripples and RobustFloodCheck(inst) then
            inst.components.umripples:OnNoLongerLandedServer()
            inst:Hide()
            ToggleWormMoveSymbols(inst, true)
        end
    end
end)

-- Flying Creatures
local _RaiseFlyingCreature = RaiseFlyingCreature
function RaiseFlyingCreature(inst, ...)
    _RaiseFlyingCreature(inst, ...)
    if inst.components.umripples then
        inst.components.umripples:OnNoLongerLandedServer()
    end
end

local _LandFlyingCreature = LandFlyingCreature
function LandFlyingCreature(inst, ...)
    _LandFlyingCreature(inst, ...)
    if inst.components.umripples and RobustFloodCheck(inst) then
        inst.components.umripples:OnLandedServer(true)
    end
end