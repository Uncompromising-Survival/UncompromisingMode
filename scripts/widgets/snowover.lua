local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"

local BGCOLOR = {0 / 255, 132 / 255, 0 / 255, 255 / 255}

local SnowOver = Class(Widget, function(self, owner, dustlayer)
    self.owner = owner
    Widget._ctor(self, "SnowOver")
    self:UpdateWhilePaused(false)

    self:SetClickable(false)

    self.minscale = .9 --min scale supported by art size
    self.maxscale = 1.20625 --defaults to 1 based on camera [15, 50] (default 30)

    self.bg = self:AddChild(Widget("blind_root"))
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.bg = self.bg:AddChild(UIAnim())
    self.bg:GetAnimState():SetBank("sand_over")
    self.bg:GetAnimState():SetBuild("sand_over")
    self.bg:GetAnimState():PlayAnimation("blind_loop", true)
    self.bg:GetAnimState():SetAddColour(1, 1, 1, 1)
    self.bg:GetAnimState():AnimateWhilePaused(false)
    --self.bg:SetTint(1,1,1,.8)

    self.bg2 = dustlayer
    self.bg2:GetAnimState():SetAddColour(1, 1, 1, 1)
    self.bg2:Show()

    self:Hide()
    self:OnUpdate(0)
    self:StartUpdating()

    if owner then
        --self.owner:ListenForEvent("snowon", function(owner) return self:SnowOn() end, owner)
        self.owner:ListenForEvent("snowoff", function(owner) return self:SnowOn() end, owner)
        --self.owner:ListenForEvent("checksnowvision", function(owner) return self:VisionCheck() end, owner)
        --self.owner:DoTaskInTime(0.1, function() return self:SnowOn() end)
        --self.owner:DoTaskInTime(0.1, function() return self:VisionCheck() end)
        --self.inst:ListenForEvent("weathertick", function(owner) return self:SnowOn() end, owner)
        self.inst:ListenForEvent("seasontick", function(owner) return self:ToggleUpdating() end, owner)
        --self.owner:ListenForEvent("weathertick", function(owner) return self:SnowOn() end, owner)
        --self:ListenForEvent("weathertick", function(owner) return self:SnowOn() end, owner)
        --self:SnowOn()
    end
end)

--[[
function SnowOver:VisionCheck()
    if self.owner.components.playervision ~= nil then
        if self.bg.shown and
            self.owner.components.playervision:HasGoggleVision() then
            self.bg:GetAnimState():SetMultColour(1, 1, 1, 0)
        elseif self.changed ~= nil then
            self.bg:GetAnimState():SetMultColour(1, 1, 1, self.changed)
        end
    end
end
--]]

local function MiniBlizzNear(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local miniblizzards = TheSim:FindEntities(x, y, z, 32, {"miniblizzard"})
    if #miniblizzards > 0 then
        return true
    end
end

function SnowOver:OnUpdate(dt)
    if TheNet:IsServerPaused() then return end
    local x, y, z = self.owner.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 7, {"wall"})
    local suppressorNearby1 = .25 * #ents
    local ents2 = TheSim:FindEntities(x, y, z, 9, {"fire"})
    local suppressorNearby2 = .6 * #ents2
    local ents3 = TheSim:FindEntities(x, y, z, 6, {"shelter"})
    local suppressorNearby3 = .15 * #ents3
    local ents4 = TheSim:FindEntities(x, y, z, 10, {"snowstorm_protection_high"})
    local suppressorNearby4 = .8 * #ents4

    local equationdingus = suppressorNearby1 + suppressorNearby2 + suppressorNearby3 + suppressorNearby4
    local localizedblizz = MiniBlizzNear(self.owner)
    if TheWorld.state.iswinter and (localizedblizz or (TheWorld.net and TheWorld.net:HasTag("snowstormstartnet")) or TheWorld:HasTag("snowstormstart")) then
        if not self.alphaquation then
            self.alphaquation = 0
        elseif self.alphaquation <= equationdingus then
            self.alphaquation = self.alphaquation + .01
        elseif self.alphaquation >= equationdingus then
            self.alphaquation = self.alphaquation - .01
        end
    else
        if not self.alphaquation then
            self.alphaquation = 0
        elseif self.alphaquation > 0 then
            self.alphaquation = self.alphaquation - .001
        end
    end

    if TheWorld.state.iswinter and ((TheWorld.net and TheWorld.net:HasTag("snowstormstartnet")) or TheWorld:HasTag("snowstormstart") or localizedblizz) and not IsUnderRainDomeAtXZ(x, z) then
        if not self.changed then
            self.changed = .01
        elseif self.changed <= .7 then
            self.changed = math.clamp(self.changed + .001, 0, .7)

            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/together/sandstorm", "snowstorm")
            TheFocalPoint.SoundEmitter:SetParameter("snowstorm", "intensity", self.changed)
        end
        self:Show()
    else
        if not self.changed then
            self.changed = 0
        elseif self.changed >= 0 then
            self.changed = math.clamp(self.changed - .001, 0, .7)

            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/together/sandstorm", "snowstorm")
            TheFocalPoint.SoundEmitter:SetParameter("snowstorm", "intensity", self.changed)

            --self.blindto < 1 and 0 or .5)

            self:Show()
        elseif self.changed <= 0 then
            self:Hide()
            TheFocalPoint.SoundEmitter:KillSound("snowstorm")
        end
    end

    if self.owner.components.playervision then
        if self.bg.shown and self.owner.components.playervision:HasGoggleVision() then
            self.bg:GetAnimState():SetMultColour(1, 1, 1, --[[self.changed > .15 and .15 - self.alphaquation or self.changed - self.alphaquation]] 0)
            self.bg2:GetAnimState():SetMultColour(1, 1, 1, math.clamp(self.changed, 0, .3))
        elseif self.changed then
            self.bg:GetAnimState():SetMultColour(1, 1, 1, self.changed - self.alphaquation)
            self.bg2:GetAnimState():SetMultColour(1, 1, 1, self.changed)
        end
    end
end

function SnowOver:SnowOn()
    if TheWorld.state.iswinter then
        self:StartUpdating()
    else
        self:Hide()
        TheFocalPoint.SoundEmitter:KillSound("snowstorm")
        self:StopUpdating()
    end
end

function SnowOver:ToggleUpdating()
    if TheWorld.state.iswinter then
        self:StartUpdating()
    else
        self:Hide()
        TheFocalPoint.SoundEmitter:KillSound("snowstorm")
        self:StopUpdating()
    end
end

return SnowOver