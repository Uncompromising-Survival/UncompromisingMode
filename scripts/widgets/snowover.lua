local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"

local BGCOLOR = {0 / 255, 132 / 255, 0 / 255, 255 / 255}

local function MiniBlizzNear(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local miniblizzards = TheSim:FindEntities(x, y, z, 32, {"miniblizzard"})
    if #miniblizzards > 0 then
        return true
    end
end

local function IsInSnowstorm(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheWorld.state.iswinter and (TheWorld.net and TheWorld.net:HasTag("snowstormstartnet")
        or TheWorld:HasTag("snowstormstart") or MiniBlizzNear(inst)) and not IsUnderRainDomeAtXZ(x, z) or false
end

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

    self.dust = dustlayer
    self.dust:GetAnimState():SetAddColour(1, 1, 1, 1)
    self.dust:Hide()

    self.alphaquation = 0

    self.ambientlighting = TheWorld.components.ambientlighting
    self.camera = TheCamera
    self.brightness = 1

    self.blind = 1
    self.blindto = 1
    self.blindtime = .2

    self.fade = 0
    self.fadeto = 0
    self.fadetime = 3

    self.alpha = 0

    self:Hide()
    --self:StartUpdating()

    if owner then
        self.inst:ListenForEvent("gogglevision", function(owner, data) self:BlindTo(data and data.enabled and 0 or 1, TheFrontEnd:GetFadeLevel() >= 1) end, owner)
        --self.inst:ListenForEvent("seasontick", function(owner) return self:ToggleUpdating() end, owner)
        self.inst:ListenForEvent("snowover", function(owner, data)
            self:FadeTo(data and data.enabled and 1 or 0, TheFrontEnd:GetFadeLevel() >= 1)
        end, owner)
        if owner.components.playervision and owner.components.playervision:HasGoggleVision() then
            self:BlindTo(0, true)
        end
        if owner.GetSnowstormLevel then
            self:FadeTo(owner:GetSnowstormLevel(), true)
        end
    end
end)

function SnowOver:GetAlpha()
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
    if self.owner:GetSnowstormLevel() == 1 then
        self.alphaquation = equationdingus
    end
    if not (self.owner.components.playervision and self.owner.components.playervision:HasGoggleVision()) then
        self:BlindTo(math.clamp(1 - self.alphaquation, 0, 1), TheFrontEnd:GetFadeLevel() >= 1)
    end
end

function SnowOver:BlindTo(blindto, instant)
    blindto = math.clamp(blindto, 0, 1)
    if self.blindto ~= blindto then
        self.blindto = blindto
        if self.fade <= 0 and self.fadeto <= 0 then
            self.blind = blindto
        elseif instant and self.blind ~= blindto then
            self.blind = blindto
            self:ApplyLevels()
        end
    end
    if self.dust.shown then
        TheFocalPoint.SoundEmitter:SetParameter("snowstorm", "intensity", blindto < 1 and self.owner.components.playervision and self.owner.components.playervision:HasGoggleVision() and 0 or .5)
    end
end

function SnowOver:FadeTo(fadeto, instant)
    if self.owner and not (self.owner.player_classified and self.owner.player_classified.snowover:value()) then
        fadeto = 0
    end

    fadeto = math.clamp(fadeto, 0, 1)
    if self.fadeto ~= fadeto then
        if self.fadeto <= 0 then
            self:StartUpdating()
        elseif fadeto <= 0 and self.fade <= 0 then
            self:StopUpdating()
        end
        self.fadeto = fadeto
    end
    if instant and (fadeto > 0 or self.fade > 0) then
        self:OnUpdate(math.huge)
    end
end

function SnowOver:ApplyLevels()
    self.alpha = math.max(0, self.fade * 1.5 - .5) * self.blind
    if self.alpha > 0 then
        local c = self.brightness
        self.bg:GetAnimState():SetMultColour(c, c, c, math.clamp(self.alpha, 0, .7))
        --self.letterbox:SetMultColour(BGCOLOR[1] * c, BGCOLOR[2] * c, BGCOLOR[3] * c, BGCOLOR[4] * self.alpha)
        if not self.shown then
            self:Show()
        end
    elseif self.shown then
        self:Hide()
    end

    if self.fade > 0 then
        local k = Lerp(1, .7, self.brightness)
        local f = self.alpha * (1 - k) + math.min(1, self.fade * 1.5) * k
        local c = .15 + .85 * self.brightness
        self.dust:GetAnimState():SetMultColour(c, c, c, math.clamp(f, 0, self.owner.components.playervision and self.owner.components.playervision:HasGoggleVision() and .3 or .7 - math.clamp(self.alphaquation, 0, .4)))
        if not self.dust.shown then
            self.dust:Show()
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/together/sandstorm", "snowstorm", self.fade)
            TheFocalPoint.SoundEmitter:SetParameter("snowstorm", "intensity", self.blindto < 1 and 0 or .5)
        else
            TheFocalPoint.SoundEmitter:SetVolume("snowstorm", self.fade)
        end
    elseif self.dust.shown then
        self.dust:Hide()
        TheFocalPoint.SoundEmitter:KillSound("snowstorm")
    end
end

function SnowOver:OnUpdate(dt)
    if TheNet:IsServerPaused() then return end
    self:GetAlpha()
    local dirty = false
    if self.blindto < self.blind then
        self.blind = math.max(self.blindto, self.blind - dt / self.blindtime)
        dirty = true
    elseif self.blindto > self.blind then
        self.blind = math.min(self.blindto, self.blind + dt / self.blindtime)
        dirty = true
    end

    if self.fadeto < self.fade then
        self.fade = math.max(self.fadeto, self.fade - dt / self.fadetime)
        dirty = true
    elseif self.fadeto > self.fade then
        self.fade = math.min(self.fadeto, self.fade + dt / self.fadetime)
        dirty = true
    end

    if self.ambientlighting then
        local brightness = math.clamp(self.ambientlighting:GetVisualAmbientValue() * 1.4, 0, 1)
        if brightness < self.brightness then
            self.brightness = math.max(brightness, self.brightness - dt)
            dirty = true
        elseif brightness > self.brightness then
            self.brightness = math.min(brightness, self.brightness + dt)
            dirty = true
        end
    end

    if dirty then
        self:ApplyLevels()
    end

    if self.shown then
        local s = 1
        if self.camera then
            s = Remap(math.clamp(self.camera:GetDistance(), self.camera.mindist, self.camera.maxdist), self.camera.mindist, self.camera.maxdist, 1, 0)
            s = self.minscale + (self.maxscale - self.minscale) * s * s
        end
        s = s * (3 - self.alpha * 2)
        self.bg:SetScale(s, s, s)
    end

    if self.fade <= 0 and self.fadeto <= 0 then
        self.blind = self.blindto
        if self.alphaquation > 0 then
            self.alphaquation = 0
        end
        self:StopUpdating()
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