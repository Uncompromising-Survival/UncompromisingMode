local function UpdateRippleFXTransform(ripples)
    local front_fx, back_fx = ripples.front_fx, ripples.back_fx
    if front_fx ~= nil then
        front_fx.Transform:SetScale(ripples.xscale, ripples.yscale, ripples.zscale)
    end
    if back_fx ~= nil then
        back_fx.Transform:SetScale(ripples.xscale, ripples.yscale, ripples.zscale)
    end
    if ripples.vert_offset ~= nil then
        if front_fx ~= nil then
            front_fx.Transform:SetPosition(0, ripples.vert_offset, 0)
        end
        if back_fx ~= nil then
            back_fx.Transform:SetPosition(0, ripples.vert_offset, 0)
        end
    end
end

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

local function onresizetarget(self, data)
    self.inst.replica.umripples:ResizeTarget(data)
end

local function OnMountedDismounted(inst, data)
    inst.components.umripples:ShouldChangeToRiding(inst.components.rider:IsRiding())
end

local Umripples = Class(function(self, inst)
    self.inst = inst

    self.ismastersim = TheNet:GetIsMasterSimulation()
    if self.ismastersim then
        -- Calls from elsewhere
        self.inst:ListenForEvent("on_landed", function() self:OnLandedServer() end)
        self.inst:ListenForEvent("on_no_longer_landed", function() self:OnNoLongerLandedServer() end)
        self.inst:ListenForEvent("ondropped", function() self:OnLandedServer() end)
        self.inst:ListenForEvent("onremove", function() self:OnNoLongerLandedServer() end)
        if self.inst:HasTag("player") then
            self.inst:ListenForEvent("mounted", OnMountedDismounted)
            self.inst:ListenForEvent("dismounted", OnMountedDismounted)
        end

        -- On server load, check to see if I should be showing effect
        self.inst:DoTaskInTime(0,function(inst)
            if self:ShouldShowEffect() then
                self:OnLandedServer()
            end
        end)
    end
    
    self.size = "small"
    self.vert_offset = nil
    self.xscale = 1.0
    self.yscale = 1.0
    self.zscale = 1.0
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
    resize_target = onresizetarget,
})

function Umripples:ShouldChangeToRiding(riding)
    if riding == true then --AXE Player gets beefalo FX
        self.xscale = 3
        self.yscale = 3
        self.zscale = 3
        self.vert_offset = 0.5
    else -- Player gets player FX
        self.vert_offset = 0.2
        self.xscale = 0.75
        self.zscale = 0.75
        self.yscale = 1
    end
    --UpdateRippleFXTransform(self)
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
    --UpdateRippleFXTransform(self)
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
    UpdateRippleFXTransform(self)
end

function Umripples:SetScale(scale)
    if scale ~= nil then
        if type(scale) == "table" then
            self.xscale = scale[1]
            self.yscale = scale[2]
            self.zscale = scale[3]
        else
            self.xscale = scale
            self.yscale = scale
            self.zscale = scale
        end

        UpdateRippleFXTransform(self)
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

local function CheckForY0(inst)
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
end

function Umripples:ShouldShowEffect()
    local x,y,z = self.inst.Transform:GetWorldPosition()
    if TheWorld.Map:GetTileAtPoint(x,0,z) == WORLD_TILES.UM_FLOODWATER_GROTTO and not (self.inst.sg and self.inst.sg:HasStateTag("flying")) then
        if y > 0 and self.inst.components.inventoryitem then
            if not self.inst.umripples_falling then
                self.inst.umripples_falling = self.inst:DoPeriodicTask(FRAMES, CheckForY0)
            end
            return false
        else
            return true
        end
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
        if self.inst.components.inventoryitem ~= nil and not self.inst.components.inventoryitem:IsHeld() and not self.inst:HasTag("likewateroffducksback") then
            self.inst.components.inventoryitem:MakeMoistureAtLeast(TUNING.OCEAN_WETNESS)
        end

        if self.splash and (not self.inst.components.inventoryitem or not self.inst.components.inventoryitem:IsHeld()) then
            local splash = SpawnPrefab("splash_green")
            splash.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
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
    if self.inst.umripples_falling then
        self.inst.umripples_falling:Cancel()
        self.inst.umripples_falling = nil
    end
    if self.showing_effect then
        self.is_landed = false
        self.showing_effect = false

        self:SwitchToDefaultAnim()
    end
end

return Umripples