local env = env
GLOBAL.setfenv(1, GLOBAL)
local UIAnim = require "widgets/uianim"
-----------------------------------------------------------------
local Text = require "widgets/text"
require("constants")

env.AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    local _OldUpdateToolTip = self.UpdateTooltip



    self.acid = self:AddChild(UIAnim())
    self.acid:GetAnimState():SetBank("acid_meter")
    self.acid:GetAnimState():SetBuild("acid_meter")
    self.acid:GetAnimState():PlayAnimation("idle")
    self.acid:Hide()
    self.acid:SetClickable(false)

    function self:UpdateTooltip()
        if self:GetDescriptionString() ~= nil then
            local str = self:GetDescriptionString()
            local mushroomcheck = nil --TheSim:FindFirstEntityWithTag("acidrain_mushroom")
            self:SetTooltip(str)
            if self.item:GetIsWet() and mushroomcheck ~= nil then
                self:SetTooltipColour(unpack(TUNING.DSTU.ACID_TEXT_COLOUR))
            else
                return _OldUpdateToolTip(self)
            end
        else
            return _OldUpdateToolTip(self)
        end
    end
end)

local ItemTile = require('widgets/itemtile')
local _SetPercent = ItemTile.SetPercent

function ItemTile:SetPercent(percent, ...)
    _SetPercent(self, percent, ...)

    if percent ~= nil and self.percent ~= nil and self.inst:HasTag("overchargeable") then
        if percent > 1 then
            self.percent:SetColour({ 1, 1, 0, 1 })
        elseif percent > 0.99 and percent < 1 then --exactly at 1 just to reset it but not to break the coloured percent mod
            self.percent:SetColour({ 1, 1, 1, 1 })
        end
    end
end

local __ctor = ItemTile._ctor

local function getframesymbol(durability)
    if durability > .75 then
        return "frame"
    elseif durability <= .75 and durability > .5 then
        return "frame-0"
    elseif durability <= .5 and durability > .25 then
        return "frame-1"
    else
        return "frame-2"
    end
end
function ItemTile._ctor(self, invitem, ...)
    __ctor(self, invitem, ...)
    print("_ctor")
    print(invitem)
    print(self.inst)
    if invitem.replica.minerologyable ~= nil and invitem.replica.minerologyable._enchantnum:value() ~= 0 then
        print("is minerologyable")
        self.gem_border = self:AddChild(UIAnim())
        self.gem_border:GetAnimState():SetBank("gem_meter")
        self.gem_border:GetAnimState():SetBuild("gem_meter")
        self.gem_border:GetAnimState():PlayAnimation("idle")
        self.gem_border:GetAnimState():AnimateWhilePaused(false)
        self.gem_border:SetClickable(false)
        print("durability", invitem.replica.minerologyable:GetDurabilityClient())
        print("symbol", getframesymbol(invitem.replica.minerologyable:GetDurabilityClient()))

        if invitem.replica.minerologyable._enchantnum:value() == 0 then
            self.gem_border:Hide()
        else
            self.gem_border:Show()
        end

        self.gem_border:GetAnimState():OverrideSymbol("frame", "gem_meter", getframesymbol(invitem.replica.minerologyable:GetDurabilityClient()))

        print("init gem_border", self.gem_border)
        self.inst:ListenForEvent("gemdurabilitychanged", function(inst)
            if inst.replica.minerologyable._enchantnum:value() == 0 then
                self.gem_border:Hide()
            else
                self.gem_border:Show()
            end

            print("gem durability changed", inst.replica.minerologyable:GetDurabilityClient())
            print("symbol", getframesymbol(inst.replica.minerologyable:GetDurabilityClient()))
            self.gem_border:GetAnimState():OverrideSymbol("frame", "gem_meter", getframesymbol(inst.replica.minerologyable:GetDurabilityClient()))
        end, invitem)
    end
end
