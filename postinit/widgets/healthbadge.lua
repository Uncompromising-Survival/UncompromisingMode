local env = env
GLOBAL.setfenv(1, GLOBAL)

local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Badge = require "widgets/badge"

local function GetModName(modname) -- modinfo's modname and internal modname is different.
    for _, knownmodname in ipairs(KnownModIndex:GetModsToLoad()) do
        if KnownModIndex:GetModInfo(knownmodname).name == modname then
            return knownmodname
        end
    end
end

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
        self.iceshieldnum:SetColour(0.2, 0.5, 1, 0.75)
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
    local has_wxshield = self.wxshieldanimnum ~= nil
    local has_combinedstatus = GetModName("Combined Status")

    if self.iceshield and self.iceshieldpercent > 0 then
        if not has_combinedstatus then
            self.num:SetScale(has_wxshield and .6 or .8, has_wxshield and .6 or .8)
            self.num:SetPosition(3, has_wxshield and 15 or 10, 0)
        end
        if has_wxshield then
            if not has_combinedstatus then
                self.num:SetScale(.6, .6)
                self.wxshieldanimnum:SetScale(.6, .6)
            end

            self.iceshieldnum:SetScale(.6, .6)
            self.iceshieldnum:SetPosition(3, 5, 0)
        end

        if self.num.shown then
            self.iceshieldnum:Show()
            self.iceshieldnum:SetString(tostring(self.iceshieldcurrent))
        end
    else
        if not has_combinedstatus then
            if has_wxshield then
                self.num:SetScale(.8, .8)
                self.num:SetPosition(3, 10, 0)
            else
                self.num:SetScale(1, 1)
                self.num:SetPosition(3, 0, 0)
            end
        end
        self.iceshieldnum:Hide()
    end
end

local _OnGainFocus = HealthBadge.OnGainFocus
function HealthBadge:OnGainFocus()
    _OnGainFocus(self)
    self:UpdateIceShieldNums()

    if self.iceshieldpercent and self.iceshieldpercent > 0 then
        self.iceshieldnum:Show()
    end
    if self.penaltynum and self.penaltypercent > 0 then
        self.penaltynum:Show()
    end

    local has_combinedstatus = GetModName("Combined Status")

    if self.focus and has_combinedstatus then
        self.iceshieldnum:Hide()
    end
end

local _OnLoseFocus = HealthBadge.OnLoseFocus
function HealthBadge:OnLoseFocus()
    _OnLoseFocus(self)
    local has_combinedstatus = GetModName("Combined Status")

    if self.iceshieldnum then
        if has_combinedstatus and not self.focus then
            self.iceshieldnum:Show()
        else 
            self.iceshieldnum:Hide()
        end
    end
    if self.penaltynum then
        self.penaltynum:Hide()
    end
end

function HealthBadge:SetIceShieldPercent(percent)
    if self.iceshield ~= nil then
        self.iceshieldpercent = percent
        self.iceshield:GetAnimState():SetPercent("anim", 1 - percent)
    end
end

local _SetPercent = HealthBadge.SetPercent
function HealthBadge:SetPercent(val, max, penaltypercent, ...)
    _SetPercent(self, val, max, penaltypercent, ...)
    self.penaltypercent = penaltypercent
    self.penaltynum:SetString("-" .. tostring(penaltypercent * 100) .. "%")

    if self.topperanim ~= nil then
        if penaltypercent < 0.25 then
            self.topperanim:GetAnimState():SetMultColour(0.25, 0.25, 0.25, 1)
        else
            self.topperanim:GetAnimState():SetMultColour(0, 0, 0, 1)
        end
    end
end

local _ctor = HealthBadge._ctor
function HealthBadge:_ctor(owner, art, iconbuild)
    _ctor(self, owner, art, iconbuild)
    self:AddIceShield()

    self.penaltynum = self:AddChild(Text(BODYTEXTFONT, 33))
    self.penaltynum:SetHAlign(ANCHOR_MIDDLE)
    self.penaltynum:SetScale(.5, .5)
    self.penaltynum:SetPosition(3, 35, 0)
    self.penaltynum:SetColour(1, 0.2, 0.2, 1)

    self.penaltynum:Hide()
end
