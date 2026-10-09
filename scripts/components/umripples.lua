local function onxscale(self, scale)
    self.inst.replica.umripples:SetXScale(scale)
end

local function onyscale(self, scale)
    self.inst.replica.umripples:SetYScale(scale)
end

local function onzscale(self, scale)
    self.inst.replica.umripples:SetZScale(scale)
end

local function onvertoffset(self, offset)
    if offset then
        self.inst.replica.umripples:SetVerticalOffset(offset)
    end
end

local function onbobpercent(self, bobpercent)
    self.inst.replica.umripples.bob_percent:set(bobpercent)
end

local function onsize(self, sizetype)
    self.inst.replica.umripples.size:set(sizetype)
end

local function onshouldparenteffect(self, parenteffect)
    self.inst.replica.umripples.should_parent_effect:set(parenteffect)
end

local function onlanded(self, landed)
    self.inst.replica.umripples:IsLanded(landed)
end

local function OnMountedDismounted(inst, data)
    inst.components.umripples:ShouldChangeToRiding(inst.components.rider:IsRiding())
end

---------------------------
-- [ Flooded Tile Handling] -- AXE
---------------------------

--local flood_equipment_verylow = { "trunkvest_summer", "reflectivevest" }
--local flood_equipment_low = { "armor_reed_um", "armor_windbreaker", "armor_snakeskin" }
--local flood_equipment_med = { "raincoat", "blubbersuit", "tarsuit" }
--local flood_equipment_high = { "armor_sharksuit_um" }

--local function CheckClothing(inst, table_check)
    --local body
    --if inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) then
        --body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab
    --end
    --return (body and table.contains(table_check, body))
--end

local um_flood_speed_immune_no_turfrunner_TAGS = {"swampbro", "playermerm", "woosegoose", "weregoose"}
local um_flood_speed_immune_TAGS = ConcatArrays({"turfrunner_279", "turfrunner_280", "turfrunner_281"}, um_flood_speed_immune_no_turfrunner_TAGS)

local function IsSpeedImmune(inst, noturfrunner)
    return inst:HasAnyTag(noturfrunner and um_flood_speed_immune_no_turfrunner_TAGS or um_flood_speed_immune_TAGS) or inst:HasTag("merm") and not inst:HasTag("mermdisguise")
        or inst.components.moistureimmunity ~= nil or inst.components.umripples.speed_immune ~= nil
end

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

local function GetBodyItem(inst)
    return inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
end

local function GetBodyWetnessProtection(inst)
    local body = GetBodyItem(inst)
    local waterproofer = body and body.components.waterproofer
    return waterproofer and waterproofed:GetEffectiveness() or 0
end

local function AdjustSpeed(inst)
    local body = GetBodyItem(inst)

    if body and body.prefab == "armor_sharksuit_um" then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "um_floodedwater", 1.2)
        return
    end
    
    local waterproofness = GetBodyWetnessProtection(inst)

    local mod = .5
    if waterproofness >= .7 then
        mod = .9
    elseif waterproofness >= .35 then
        mod = .75
    elseif waterproofness > 0 then
        mod = .6
    end
    
    if inst.components.rider and inst.components.rider:IsRiding() and mod < 1 then
        mod = (mod + 1) / 2
    end

    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "um_floodedwater", mod)
end

local no_water = { "flying", "shadow", "worm", "playerghost", "brightmare", "brightmare_gestalt" }

local function IsFloodWater(inst)
    local current_tile = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition())
    return current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO
end

local function FloodMoistureRamp(inst)
    local moisture = inst.components.moisture
    if moisture then
        local burnable = inst.components.burnable
        if burnable and burnable:IsBurning() then
            burnable:Extinguish()
        end

        local body = GetBodyItem(inst)
        local mod = body and body.prefab == "armor_sharksuit_um" and 1 or GetBodyWetnessProtection(inst)
        local wetness_gain = 3 * (1 - mod) * (inst.components.rider and inst.components.rider:IsRiding() and .5 or 1)

        moisture:DoDelta(wetness_gain, true)
        --DoDeltaMoistureToEntity(inst, wetness_gain, nil, nil, true)
    end
end

local function WormBubble(inst)
    SpawnPrefab("crab_king_bubble"..math.random(1, 3)).Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function ToggleSlowdown(inst, toggle)
    if toggle and inst.um_floodslowdown or not toggle and not inst.um_floodslowdown then return end
    if toggle then
        inst:ListenForEvent("equip", AdjustSpeed)
        inst:ListenForEvent("unequip", AdjustSpeed) -- may fire twice, but that shouldn't matter, it's not doing a huge amount of computational work
        if not (inst.prefab == "mole" or inst:HasTag("worm")) then
            AdjustSpeed(inst)
        end
        inst:PushEvent("carefulwalking", {careful = true})
        inst.um_floodslowdown = true
    else
        inst:RemoveEventCallback("equip", AdjustSpeed)
        inst:RemoveEventCallback("unequip", AdjustSpeed)
        if inst.components.locomotor then
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "um_floodedwater")
        end
        inst:PushEvent("carefulwalking", {careful = false})
        inst.um_floodslowdown = nil
    end
end

local function ToggleFloodCheck(inst, toggle)
    local wormormole = inst:HasTag("worm") or inst.prefab == "mole"
    if toggle then
        if not inst.um_floodchecked then
            if inst.components.umripples and not wormormole then --AXE check if should update ripples
                inst.components.umripples:OnLandedServer(true)
            elseif wormormole then
                inst:Hide()
                SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                inst.um_worm_bubble_task = inst:DoPeriodicTask(.5, WormBubble)
            end
            FloodMoistureRamp(inst)
            inst.um_flood_moisture_ramp = inst:DoPeriodicTask(1, FloodMoistureRamp)
            inst.um_floodchecked = true
        end
        ToggleSlowdown(inst, not IsSpeedImmune(inst))
    else
        if inst.um_floodchecked then
            if inst.um_flood_moisture_ramp then
                inst.um_flood_moisture_ramp:Cancel()
                inst.um_flood_moisture_ramp = nil
            end
            if inst.components.umripples and not wormormole then --AXE check if should update ripples
                inst.components.umripples:OnNoLongerLandedServer()
            elseif wormormole then
                inst:Show()
                if inst.um_worm_bubble_task then
                    inst.um_worm_bubble_task:Cancel()
                    inst.um_worm_bubble_task = nil
                end
            end
            inst.um_floodchecked = nil
        end
        ToggleSlowdown(inst)
    end
end

local function ToggleFloodCheckUpdating(inst, toggle)
    local umripples = inst.components.umripples
    if toggle then
        inst:StartUpdatingComponent(umripples)
    else
        inst:StopUpdatingComponent(umripples)
        ToggleFloodCheck(inst)
    end
end

local function RemoveFloodCheck(inst)
    ToggleFloodCheckUpdating(inst)
end

local function OnRespawnedFromGhost(inst)
    ToggleFloodCheckUpdating(inst, true)
end

local Umripples = Class(function(self, inst)
    self.inst = inst

    self.ismastersim = TheNet:GetIsMasterSimulation()
    if self.ismastersim then
        -- Calls from elsewhere
        self.inst:ListenForEvent("onremove", function() self:OnNoLongerLandedServer() end)
        if self.inst:HasTag("player") then
            self.inst:ListenForEvent("mounted", OnMountedDismounted)
            self.inst:ListenForEvent("dismounted", OnMountedDismounted)
            self.inst:ListenForEvent("ms_becameghost", RemoveFloodCheck)
            self.inst:ListenForEvent("ms_respawnedfromghost", OnRespawnedFromGhost)
        end

        local locomotor = self.inst.components.locomotor
        if not locomotor then
            if not self.inst.components.inventoryitem then
                -- On server load, check to see if I should be showing effect
                self.inst:DoTaskInTime(0, function() if self:ShouldShowEffect() then self:OnLandedServer() end end)
            else
                self.inst:ListenForEvent("on_landed", function() self:OnLandedServer() end)
                self.inst:ListenForEvent("on_no_longer_landed", function() self:OnNoLongerLandedServer() end)
                --self.inst:ListenForEvent("ondropped", function() self:OnLandedServer() end)
            end
        else
            self.inst:StartUpdatingComponent(self)
        end
    end

    self.size = "small"
    self.vert_offset = nil
    self.xscale = 1
    self.yscale = 1
    self.zscale = 1
    self.should_parent_effect = true
    self.do_bank_swap = false
    self.float_index = 1
    self.swap_data = nil
    self.showing_effect = false
    self.bob_percent = 0
    self.splash = true
    self.is_landed = false
end,
nil,
{
    xscale = onxscale,
    yscale = onyscale,
    zscale = onzscale,
    vert_offset = onvertoffset,
    bob_percent = onbobpercent,
    size = onsize,
    should_parent_effect = onshouldparenteffect,
    is_landed = onlanded,
})

function Umripples:ShouldChangeToRiding(riding)
    if riding == true then --AXE Player gets beefalo FX
        self.xscale = 3
        self.yscale = 3
        self.zscale = 3
        self.vert_offset = .5
    else -- Player gets player FX
        self.vert_offset = .2
        self.xscale = .75
        self.zscale = .75
        self.yscale = 1
    end
end

function Umripples:ResizeTarget(resize_target)
    local resize = resize_target
    if not (resize[1] and resize[2] and resize[3]) then return end
    self.xscale = resize[1]/100
    self.yscale = resize[2]/100
    self.zscale = resize[3]/100
    if self.vert_offset and resize[4] then
        self.vert_offset = resize[4]
    end
end

function Umripples:SetIsObstacle(bool)
    self.is_obstable = bool ~= false
end

--small/med/large
function Umripples:SetSize(size)
    self.size = size
end

function Umripples:SetVerticalOffset(offset)
    self.vert_offset = offset
end

function Umripples:SetScale(scale)
    if scale then
        if type(scale) == "table" then
            self.xscale = scale[1]
            self.yscale = scale[2]
            self.zscale = scale[3]
        else
            self.xscale = scale
            self.yscale = scale
            self.zscale = scale
        end
    end
end

function Umripples:SetBankSwapOnFloat(should_bank_swap, float_index, swap_data)
    self.do_bank_swap = should_bank_swap
    self.float_index = float_index or 1
    self.swap_data = swap_data
end

function Umripples:SetSwapData(swap_data)
    self.swap_data = swap_data
end

--[[local function CheckForY0(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    if y < 0.6 and inst.components.umripples then
        inst.Transform:SetPosition(x, 0, z)
        if inst.Physics then
            inst.Physics:Stop()
        end
        inst.components.umripples:OnLandedServer()
        if inst.falling then
            inst.falling:Cancel()
            inst.falling = nil
        end
        if inst.umripples_falling then
            inst.umripples_falling:Cancel()
            inst.umripples_falling = nil
        end
    end
end]]

function Umripples:ShouldShowEffect()
    local x,y,z = self.inst.Transform:GetWorldPosition()
    if TheWorld.Map:GetTileAtPoint(x, 0, z) == WORLD_TILES.UM_FLOODWATER_GROTTO and not (self.inst.sg and self.inst.sg:HasStateTag("flying")) then
        --[[if y > 0 and self.inst.components.inventoryitem then
            if not self.inst.umripples_falling then
                self.inst.umripples_falling = self.inst:DoPeriodicTask(FRAMES, CheckForY0)
            end
            return false
        else]]
            return true
        --end
    end
end

function Umripples:IsFloating()
    return self.showing_effect
end

function Umripples:SwitchToFloatAnim()
    if self.do_bank_swap then
        if self.float_index < 0 then
            self.inst.AnimState:SetBankAndPlayAnimation("floating_item", "left")
        else
            self.inst.AnimState:SetBankAndPlayAnimation("floating_item", "right")
        end
        self.inst.AnimState:SetFrame(math.abs(self.float_index))
        self.inst.AnimState:Pause()

        if self.swap_data ~= nil then
            local symbol = self.swap_data.sym_name or self.swap_data.sym_build
            local skin_build = self.inst:GetSkinBuild()
            if skin_build ~= nil then
                self.inst.AnimState:OverrideItemSkinSymbol("swap_spear", skin_build, symbol, self.inst.GUID, self.swap_data.sym_build)
            else
                self.inst.AnimState:OverrideSymbol("swap_spear", self.swap_data.sym_build, symbol)
            end
        end
    end
end

function Umripples:OnLandedServer(forced)
    if not self.showing_effect and (self:ShouldShowEffect() or forced) then
        -- If something lands in a place where the water effect should be shown, and it has an inventory component,
        -- update the inventory component to represent the associated wetness.
        -- Don't apply the wetness to something held by someone, though.
        local hotsplash
        if self.inst.components.inventoryitem and not self.inst.components.inventoryitem:IsHeld() then
            if not self.inst:HasTag("likewateroffducksback") then
                self.inst.components.inventoryitem:MakeMoistureAtLeast(TUNING.OCEAN_WETNESS)
            end
            local oldtemperature = self.inst.components.inventoryitem:GetTemperaturePercent()
            self.inst.components.inventoryitem:SetTemperaturePercentAtMost(TUNING.OCEAN_TEMPERATURE_PENALTY_PERCENT)
            local newtemperature = self.inst.components.inventoryitem:GetTemperaturePercent()
            if oldtemperature and newtemperature and oldtemperature - newtemperature > TUNING.FLOATER_HOT_SIZZLE_THRESHOLD then
                hotsplash = true
            end
        end

        if self.splash and (not self.inst.components.inventoryitem or not self.inst.components.inventoryitem:IsHeld()) then
            local splash = SpawnPrefab(self.inst.components.inventoryitem and (hotsplash and "hot_splash" or "splash") or "splash_green")
            local pos = self.inst:GetPosition()
            splash.Transform:SetPosition(pos.x, splash ~= "splash_green" and pos.y or 0, pos.z)
        end

        self.inst:PushEvent("umripples_startfloating")
        self.is_landed = true
        self.showing_effect = true

        self:SwitchToFloatAnim()
    end
end

function Umripples:SwitchToDefaultAnim(force_switch)
    if self.do_bank_swap or force_switch then
        local bank = self.swap_data ~= nil and self.swap_data.bank or self.inst.prefab
        local anim = self.swap_data ~= nil and self.swap_data.anim or "idle"
        self.inst.AnimState:SetBankAndPlayAnimation(bank, anim)

        if self.swap_data ~= nil then
            self.inst.AnimState:ClearOverrideSymbol("swap_spear")
        end
    end
end

function Umripples:OnNoLongerLandedServer()
    --[[if self.inst.umripples_falling then
        self.inst.umripples_falling:Cancel()
        self.inst.umripples_falling = nil
    end]]
    if self.showing_effect then
        self.is_landed = false
        self.showing_effect = false

        self:SwitchToDefaultAnim()
    end
end

function Umripples:OnEntitySleep()
    if self.inst.components.locomotor then self.inst:StopUpdatingComponent(self) end
end

function Umripples:OnEntityWake()
    if self.inst.components.locomotor then self.inst:StartUpdatingComponent(self) end
end

function Umripples:OnUpdate(dt)
    ToggleFloodCheck(self.inst, not self.inst:IsInLimbo() and RobustFloodCheck(self.inst))
end

return Umripples