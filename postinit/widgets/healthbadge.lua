local env = env
GLOBAL.setfenv(1, GLOBAL)

local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Badge = require "widgets/badge"


local ICE_SHIELD_COLOUR = { 0.2, 0.3, 1, 0.5 } --less transparent than WX's
local HealthBadge = require "widgets/healthbadge"
function HealthBadge:AddIceShield()
    if self.iceshield == nil then
        self.iceshieldpercent = 0
        self.iceshield = self.circleframe:AddChild(UIAnim())
        self.iceshield:GetAnimState():SetBank("status_meter")
        self.iceshield:GetAnimState():SetBuild("status_meter")
        self.iceshield:GetAnimState():PlayAnimation("anim")
        self.iceshield:GetAnimState():SetMultColour(unpack(ICE_SHIELD_COLOUR))
        self.iceshield:SetClickable(false)
        self.iceshield:GetAnimState():AnimateWhilePaused(false)
        self.iceshield:GetAnimState():SetPercent("anim", 1)

        self.iceshieldnum = self:AddChild(Text(BODYTEXTFONT, 33))
        self.iceshieldnum:SetHAlign(ANCHOR_MIDDLE)
        self.iceshieldnum:SetPosition(3, -10, 0)
        self.iceshieldnum:SetScale(.8, .8)
        self.iceshieldnum:SetColour(unpack(ICE_SHIELD_COLOUR))
        self.iceshieldnum:Hide()

        self.iceshield.inst:ListenForEvent("iceshield.health_dirty", function(inst, data)
            local maxhealth = self.owner.ice_shield_maxhealth:value()
            local currenthealth = self.owner.ice_shield_health:value()

            if maxhealth > 0 then
                self.iceshieldcurrent = currenthealth
                self:SetIceShieldPercent(currenthealth / maxhealth)
            end

            self:UpdateIceShieldNums()
        end, self.owner)
    end
end

function HealthBadge:UpdateIceShieldNums()
    if self.iceshield and self.iceshieldpercent > 0 then
        self.iceshieldnum:SetScale(.8, .8)
        self.iceshieldnum:SetPosition(3, 10, 0)

        if self.iceshieldnum.shown then
            self.iceshieldnum:Show()
            self.iceshieldnum:SetString(tostring(self.iceshieldcurrent))
        end
    else
        self.iceshieldnum:Hide()
    end
end

local _OnGainFocus = HealthBadge.OnGainFocus
function HealthBadge:OnGainFocus()
    _OnGainFocus(self)
    if self.iceshieldpercent and self.iceshieldpercent > 0 then
        self.iceshieldnum:Show()
    end
end

local _OnLoseFocus = HealthBadge.OnLoseFocus
function HealthBadge:OnLoseFocus()
    _OnLoseFocus(self)
    if self.iceshieldnum then
        self.iceshieldnum:Hide()
    end
end

function HealthBadge:SetIceShieldPercent(percent)
    if self.iceshield ~= nil then
        self.iceshieldpercent = percent
        self.iceshield:GetAnimState():SetPercent("anim", 1 - percent)
    end
end

local _ctor = HealthBadge._ctor
function HealthBadge:_ctor(owner, art, iconbuild)
    _ctor(self, owner, art, iconbuild)
    self:AddIceShield()
end
