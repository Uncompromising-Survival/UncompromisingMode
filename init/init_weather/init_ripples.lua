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


for i, v in ipairs(TUNING.DSTU.RIPPLE_BLACKLIST_PREFABS) do
    env.AddPrefabPostInit(v, function(inst)
        inst.um_ripple_blacklist = true
    end)
end


-- AXE Add ripples to plants, structures, and items
env.AddPrefabPostInitAny(function(inst)
    for i,v in ipairs(TUNING.DSTU.RIPPLE_BLACKLIST_TAGS) do
        if inst:HasTag(v) then
            inst.um_ripple_blacklist = true
        end
    end

    if (inst:HasAnyTag("structure", "boulder", "plant") or inst.components.inventoryitem) and not inst.um_ripple_blacklist then
        if not inst.components.umripples then
            inst:AddComponent("umripples")
        end
        if inst.components.floater then
            local floater = inst.components.floater
            local umripples = inst.components.umripples
            umripples.size = floater.size
            umripples.vert_offset = floater.vert_offset
            umripples.xscale = floater.xscale
            umripples.yscale = floater.yscale
            umripples.zscale = floater.zscale
            umripples.should_parent_effect = floater.should_parent_effect
            umripples.do_bank_swap = floater.do_bank_swap
            umripples.float_index = floater.float_index
            umripples.swap_data = floater.swap_data
            umripples.showing_effect = floater.showing_effect
            umripples.bob_percent = floater.bob_percent
            umripples.splash = floater.splash
        end
        if inst.components.inventoryitem and not inst.components.floatable then
            local umripples = inst.components.umripples
            umripples.vert_offset = 0.1
        end
    end
end)


env.AddClassPostConstruct("components/inventoryitem_replica", function(self) --AXE Add the ripples to the client side of items
    if not self.inst.components.umripples then
        self.inst:AddComponent("umripples")
        if not self.inst.components.floatable then
            local umripples = self.inst.components.umripples
            umripples.vert_offset = 0.1
        end
    end
end)

local function AddRipples(prefab, xscale, yscale, zscale, vert_offset) --AXE These calls need to be both on client and server
    env.AddPrefabPostInit(prefab, function(inst)
        if not inst.components.umripples then
            inst:AddComponent("umripples")
        end
        local umripples = inst.components.umripples
        umripples.vert_offset = vert_offset and vert_offset or 0
        umripples.xscale = xscale and xscale or 1
        umripples.yscale = yscale and yscale or 1
        umripples.zscale = zscale and zscale or 1
    end)
end

-- Tuned Ripples on Prefabs
AddRipples("molebathill", 2)
AddRipples("moonspider_spike", 0.5)
AddRipples("driftwood_small1", 3)
AddRipples("driftwood_small2", 3)
AddRipples("driftwood_tall", 1.5)
AddRipples("rock1", 3.5, 1.5, 3.5)
AddRipples("rock2", 3.5, 1.5, 3.5)
AddRipples("skeleton", 2.25, 2, 2.25, 0.2)

-- Tuned Ripples on Creatures
AddRipples("hound", 2)
AddRipples("icehound", 2)
AddRipples("firehound", 2)
AddRipples("um_tentacle_moon", 1.5, 1.5, 1.5,0.2)
AddRipples("um_tentacle_moon_mine", 0.5)
AddRipples("boulder_crab", 3)
AddRipples("molebat", 1.1, 1.1, 1.1)
AddRipples("frog", 1.1, 1.1, 1.1)
AddRipples("worm", 1.4, 1.4, 1.4)
AddRipples("viperworm", 1.4, 1.4, 1.4)
AddRipples("shockworm", 1.4, 1.4, 1.4)
AddRipples("pigman", 1.2, 1.2, 1.2, 0.2)
AddRipples("bunnyman", 1.2, 1.2, 1.2, 0.2)
AddRipples("merm", 1.2, 1.2, 1.2, 0.2)
AddRipples("carrat", 1.1, 1.1, 1.1, 0.2)
AddRipples("mushgnome", 0.8, 0.8, 0.8, 0.2)
--


env.AddPlayerPostInit(function(inst)
    if not inst.components.umripples then
        inst:AddComponent("umripples")
    end
    inst.components.umripples.xscale = 0.75
    inst.components.umripples.zscale = 0.75
    inst.components.umripples.vert_offset = 0.2
end)

--AXE Mobs
env.AddPrefabPostInitAny(function(inst)
    if (inst:HasAnyTag("_health", "animal", "EPIC", "monster") and not inst:HasAnyTag("shadow", "flying", "gestalt", "ghost")) and not inst.prefab == "webbedcreature" then
        if not inst.components.umripples then
            inst:AddComponent("umripples")
        end
        inst.components.umripples.vert_offset = 0.2
    end
    if inst:HasTag("spider") and not inst:HasTag("player") then
        if not inst.components.umripples then
            inst:AddComponent("umripples")
        end
        inst.components.umripples.xscale = 2
        inst.components.umripples.zscale = 2
        inst.components.umripples.yscale = 1.4
        inst.components.umripples.vert_offset = 0.35
    end
    if inst:HasTag("largecreature") and not inst:HasTag("flying") then
        if not inst.components.umripples then
            inst:AddComponent("umripples")
        end
        inst.components.umripples.xscale = 3
        inst.components.umripples.zscale = 3
        inst.components.umripples.yscale = 3
        inst.components.umripples.vert_offset = 0.5
    end
end)

local statenames = { "bedroll", "knockout" }
local state_time_ent = { 1.2, 1.2 }
local state_time_ext = { 1, 1.5 }
env.AddStategraphPostInit("wilson", function(inst)
    for iname = 1, #statenames do
        local state = inst.states[statenames[iname]]

        local _onenter = state.onenter
        state.onenter = function(inst, ...)
            inst:DoTaskInTime(state_time_ent[iname], function(inst)
                if RobustFloodCheck(inst) and inst.sg.currentstate.name == statenames[iname] then
                    inst.components.umripples._resize_target:set({ 250, 250, 250 })
                end
            end)
            _onenter(inst, ...)
        end

        local _onexit = state.onexit
        state.onexit = function(inst, ...)
            inst:DoTaskInTime(state_time_ext[iname], function(inst)
                if RobustFloodCheck(inst) then
                    inst.components.umripples._resize_target:set({ 75, 100, 75 })
                end
            end)
            _onexit(inst, ...)
        end
    end
end)

-- AXE Add mobs that don't fly but still shouldn't be penalized
local um_flood_speed_immune = { "frog", "molebat" }

for i, v in ipairs(um_flood_speed_immune) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
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

local statenames = { "aggressivehop", "hop" }
env.AddStategraphPostInit("frog", function(inst)
    for iname = 1, #statenames do
        local state = inst.states[statenames[iname]]
        local _fn = state.timeline[1].fn
        state.timeline[1].fn = function(inst)
            inst.components.umripples:OnNoLongerLandedServer()
            _fn(inst)
        end
        local _fn = state.timeline[2].fn
        state.timeline[2].fn = function(inst)
            if RobustFloodCheck(inst) then
                inst.components.umripples:OnLandedServer(true)
            end
            _fn(inst)
        end
        state.onexit = function(inst)
            if RobustFloodCheck(inst) and not inst.components.umripples.showing_effect then
                inst.components.umripples:OnLandedServer(true)
            end
        end
    end
end)


env.AddStategraphPostInit("molebat", function(inst)
    local state = inst.states["walk"]
    local _fn = state.timeline[2].fn
    state.timeline[2].fn = function(inst)
        inst.components.umripples:OnNoLongerLandedServer()
        _fn(inst)
    end
    local _fn = state.timeline[3].fn
    state.timeline[3].fn = function(inst)
        if RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
        end
        _fn(inst)
    end
    state.onexit = function(inst)
        if RobustFloodCheck(inst) and not inst.components.umripples.showing_effect then
            inst.components.umripples:OnLandedServer(true)
        end
    end

    local state = inst.states["attack"]
    local _fn = state.timeline[1].fn
    state.timeline[1].fn = function(inst)
        inst.components.umripples:OnNoLongerLandedServer()
        _fn(inst)
    end
    local _fn = state.timeline[3].fn
    state.timeline[3].fn = function(inst)
        if RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
        end
        _fn(inst)
    end
    state.onexit = function(inst)
        if RobustFloodCheck(inst) and not inst.components.umripples.showing_effect then
            inst.components.umripples:OnLandedServer(true)
        end
    end

    local state = inst.states["fall"]
    local _onenter = state.onenter
    state.onenter = function(inst, ...)
        if RobustFloodCheck(inst) then
            inst.components.umripples:OnNoLongerLandedServer()
            inst:DoTaskInTime(30 * FRAMES, function(inst)
                inst.components.umripples:OnLandedServer(true)
            end)
        end
        _onenter(inst, ...)
    end
end)

env.AddStategraphPostInit("bird", function(inst)
    local state = inst.states["flyaway"]
    local _onenter = state.onenter
    state.onenter = function(inst, ...)
        inst.components.umripples:OnNoLongerLandedServer()
        _onenter(inst, ...)
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
    local state = inst.states["attack_pre"]
    local _onenter = state.onenter
    state.onenter = function(inst, ...)
        if RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
            inst:Show()
        end

        _onenter(inst, ...)
    end

    local state = inst.states["attack"]
    local _onenter = state.onenter
    state.onenter = function(inst, ...)
        if RobustFloodCheck(inst) then
            inst.components.umripples:OnLandedServer(true)
            inst:Show()
            ToggleWormMoveSymbols(inst, false)
        end
        _onenter(inst, ...)
    end
    state.onexit = function(inst, ...)
        if RobustFloodCheck(inst) then
            inst.components.umripples:OnNoLongerLandedServer()
            inst:Hide()
            ToggleWormMoveSymbols(inst, true)
        end
    end
end)

-- Flying Creatures
local _RaiseFlyingCreature = RaiseFlyingCreature
function RaiseFlyingCreature(inst)
    _RaiseFlyingCreature(inst)
    if inst.components.umripples then
        inst.components.umripples.showing_effect = false
        inst.components.umripples:OnNoLongerLandedServer()
    end
end

local _LandFlyingCreature = LandFlyingCreature
function LandFlyingCreature(inst)
    _LandFlyingCreature(inst)
    if inst.components.umripples and RobustFloodCheck(inst) and not inst.components.umripples.showing_effect then
        inst.components.umripples.showing_effect = true
        inst.components.umripples:OnLandedServer(true)
    end
end

-- Player actions that may be a bit odd to account for --AXE

-- orange staff
env.AddComponentPostInit("blinkstaff", function(self)
    local _Blink = self.Blink
    function self:Blink(pt, caster, ...)
        local ret = _Blink(self, pt, caster, ...)
        caster.blinktask_ripples = caster:DoTaskInTime(.26, function(caster)
            if caster.components.locomotor then
                caster.components.locomotor:OnUpdate(0) --AXE call an update... get flooded tiles to work after teleporting
            end
        end)
        return ret
    end
end)

-- wortox
env.AddStategraphPostInit("wilson", function(inst)
    local state = inst.states["portal_jumpout"]
    local _onexit = state.onexit
    state.onexit = function(inst, ...)
        if inst.components.locomotor then
            inst.components.locomotor:OnUpdate(0) --AXE call an update... get flooded tiles to work after teleporting
        end
        _onexit(inst, ...)
    end
end)

---------------------------
-- [ Flooded Tile Handling] -- AXE
---------------------------

--(Atoba): This should really just do something with the waterproofness of the body slot + exception for shark vest for mod compat...
--TODO: That ^
local flood_equipment_verylow = { "trunkvest_summer", "reflectivevest" }
local flood_equipment_low = { "armor_reed_um", "armor_windbreaker", "armor_snakeskin" }
local flood_equipment_med = { "raincoat", "blubbersuit", "tarsuit" }
local flood_equipment_high = { "armor_sharksuit_um" }

local function CheckClothing(inst, table_check)
    local body
    if inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) then
        body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab
    end
    return (body and table.contains(table_check, body))
end

local function AdjustSpeed(inst)
    local mod = 0.5 -- Nothing
    if CheckClothing(inst, flood_equipment_high) then
        mod = 1.2 -- Shark Vest
    elseif CheckClothing(inst, flood_equipment_med) then
        mod = 0.9 -- Rain Coat
    elseif CheckClothing(inst, flood_equipment_low) then
        mod = 0.75 -- Reed Suit
    elseif CheckClothing(inst, flood_equipment_verylow) then
        mod = 0.6 -- Oddballs, like summer vest
    end
    if inst.prefab == "wurt" and mod < 1 then
        mod = 1
    end

    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "um_floodedwater", mod)
end


local no_water = { "flying", "shadow", "worm", "playerghost", "brightmare", "brightmare_gestalt" }

local function IsFloodWater(inst)
    local current_tile = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())
    return current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO
end

local function FloodMoistureRamp(inst)
    if inst.components.moisture ~= nil then
        local mod = 0 -- nothing
        if CheckClothing(inst, flood_equipment_high) or CheckClothing(inst, flood_equipment_med) then
            mod = 1 -- Rain coat, shark suit (full immunity)
        elseif CheckClothing(inst, flood_equipment_low) then
            mod = 0.75 -- Reed Suit only gain 5% of 10
        elseif CheckClothing(inst, flood_equipment_verylow) then
            mod = 0.5 -- Summer Vest
        end
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
            inst.components.burnable:Extinguish()
        end

        -- On a beefalo.
        if (inst.components.rider and inst.components.rider:IsRiding()) then
            mod = 1
        end
        inst.components.moisture:DoDelta(3 * (1 - mod), true) -- 10 per second
    end
end

local function RemoveFloodCheck(inst)
    inst:RemoveEventCallback("equip", AdjustSpeed)
    inst:RemoveEventCallback("unequip", AdjustSpeed)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "um_floodedwater")
    end
    if inst.components.umripples then --AXE check if should update ripples
        inst.components.umripples:OnNoLongerLandedServer()
    end
    if inst.prefab ~= "wurt" then
        inst:PushEvent("carefulwalking", { careful = false })
    end
end

local function FloodContinualCheck(inst)
    if not RobustFloodCheck(inst) then
        RemoveFloodCheck(inst)
    end
end

local function WormBubble(inst)
    SpawnPrefab("crab_king_bubble" .. math.random(1, 3)).Transform:SetPosition(inst.Transform:GetWorldPosition())
end

env.AddPlayerPostInit(function(inst)
    inst:ListenForEvent("ms_becameghost", RemoveFloodCheck)
end)

env.AddComponentPostInit("locomotor", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, arrive_check_only)
        local inst = self.inst
        if not inst:HasAnyTag("merm", "flying", "ghost", "playerghost", "shadowcreature", "nightmarecreature", "brightmare_gestalt", "shadowminion", "shadowchesspiece", "turfrunner_279", "turfrunner_280", "turfrunner_281") and not (inst.components.umripples and inst.components.umripples.speed_immune) then
            if RobustFloodCheck(self.inst) and not inst.um_floodcontinualcheck then
                if inst.prefab ~= "wurt" then
                    inst:PushEvent("carefulwalking", { careful = true })
                end
                FloodMoistureRamp(inst)
                if inst.components.umripples and not (inst:HasTag("worm") or inst.prefab == "mole") then --AXE check if should update ripples
                    inst.components.umripples:OnLandedServer(true)
                elseif inst.prefab == "mole" or inst:HasTag("worm") then
                    inst:Hide()
                    SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    inst.um_worm_bubble_task = inst:DoPeriodicTask(0.5, WormBubble)
                end

                inst.um_floodcontinualcheck = inst:DoPeriodicTask(FRAMES, FloodContinualCheck)
                inst.um_flood_moisture_ramp = inst:DoPeriodicTask(1, FloodMoistureRamp)
                inst:ListenForEvent("equip", AdjustSpeed)
                inst:ListenForEvent("unequip", AdjustSpeed) -- may fire twice, but that shouldn't matter, it's not doing a huge amount of computational work        

                if not (inst.prefab == "mole" or inst:HasTag("worm")) then
                    local self = inst.components.locomotor
                    if not (self._externalspeedmultipliers and self._externalspeedmultipliers[inst] and self._externalspeedmultipliers[inst].multipliers["um_floodedwater"]) then
                        AdjustSpeed(inst)
                    end
                end
            elseif inst.um_floodcontinualcheck and not RobustFloodCheck(self.inst) then
                inst.um_floodcontinualcheck:Cancel()
                inst.um_flood_moisture_ramp:Cancel()
                inst.um_floodcontinualcheck = nil
                inst.um_flood_moisture_ramp = nil
                if inst.components.umripples and not (inst:HasTag("worm") or inst.prefab == "mole") then --AXE check if should update ripples
                    inst.components.umripples:OnNoLongerLandedServer()
                elseif inst:HasTag("worm") or inst.prefab == "mole" then
                    inst:Show()
                    if inst.um_worm_bubble_task then
                        inst.um_worm_bubble_task:Cancel()
                        inst.um_worm_bubble_task = nil
                    end
                end
                if self._externalspeedmultipliers and self._externalspeedmultipliers[inst] and self._externalspeedmultipliers[inst].multipliers["um_floodedwater"] then
                    self.inst:RemoveEventCallback("equip", AdjustSpeed)
                    self.inst:RemoveEventCallback("unequip", AdjustSpeed)
                    self:RemoveExternalSpeedMultiplier(inst, "um_floodedwater")
                end
            end
        end
        return _OnUpdate(self, dt, arrive_check_only)
    end
end)
