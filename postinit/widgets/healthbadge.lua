local env = env
GLOBAL.setfenv(1, GLOBAL)

local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local function GetModName(modname) -- modinfo's modname and internal modname is different.
    local savedata = KnownModIndex.savedata
    if savedata and savedata.known_mods then
        for knownmodname, moddata in pairs(savedata.known_mods) do
            if KnownModIndex:GetModInfo(knownmodname).name == modname and (KnownModIndex:IsModEnabled(knownmodname) or KnownModIndex:IsModForceEnabled(knownmodname)
                or KnownModIndex:IsModTempEnabled(knownmodname)) and not KnownModIndex:IsModTempDisabled(knownmodname) then
                return knownmodname
            end
        end
    end
end

local ICE_SHIELD_COLOUR = {.2, .3, 1, .5} --less transparent than WX's

env.AddClassPostConstruct("widgets/healthbadge", function(self, owner)
    function self:AddIceShield()
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
            self.iceshieldnum:SetColour(.2, .5, 1, .75)
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

    function self:SetIceShieldPercent(percent)
        if self.iceshield then
            self.iceshieldpercent = percent
            self.iceshield:GetAnimState():SetPercent("anim", 1 - percent)
        end
    end

    function self:UpdateIceShieldNums()
        local has_wxshield = self.wxshieldanimnum ~= nil
        local has_combinedstatus = GetModName("Combined Status")
        if not self.iceshield then return end
        if self.iceshieldpercent > 0 then
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

    self:AddIceShield()

    local _OnGainFocus = self.OnGainFocus
    function self:OnGainFocus(...)
        _OnGainFocus(self, ...)
        self:UpdateIceShieldNums()

        if self.iceshieldpercent and self.iceshieldpercent > 0 then
            self.iceshieldnum:Show()
        end

        local has_combinedstatus = GetModName("Combined Status")

        if self.iceshieldnum and self.focus and has_combinedstatus then
            self.iceshieldnum:Hide()
        end
    end

    local _OnLoseFocus = self.OnLoseFocus
    function self:OnLoseFocus(...)
        _OnLoseFocus(self, ...)
        local has_combinedstatus = GetModName("Combined Status")

        if self.iceshieldnum then
            if has_combinedstatus and not self.focus then
                self.iceshieldnum:Show()
            else 
                self.iceshieldnum:Hide()
            end
        end
    end

    if TUNING.DSTU.UI_HEALTHPENALTY_GREY then
        local _SetPercent = self.SetPercent
        function self:SetPercent(val, max, penaltypercent, ...)
            _SetPercent(self, val, max, penaltypercent, ...)

            if self.topperanim then
                if penaltypercent < .25 then
                    self.topperanim:GetAnimState():SetMultColour(.2, .2, .2, 1)
                else
                    self.topperanim:GetAnimState():SetMultColour(0, 0, 0, 1)
                end
            end
        end
    end
end)