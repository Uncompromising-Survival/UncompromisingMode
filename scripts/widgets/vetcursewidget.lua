local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local easing = require "easing"

local Vetcursewidget = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "Vetcursewidget")
    --self:SetClickable(false)

    self.bg2 = self:AddChild(ImageButton("images/vetskull.xml", "vetskull.tex"))
    --[[self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)]]
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetPosition(880, -380, 0)
    self.bg2:SetScaleMode(0.01)
    self.bg2:SetScale(.33, .33, .33)
    self.bg2:SetTooltip(STRINGS.VETS_WIDGET)
    self:StartUpdating()
    self:Show()
    --self:RefreshTooltips()
    self.bg2:SetOnClick(function()
		self:Disable()
	    self:Hide()
	end)
end)

local skulls =
{
    {
        name = "wilson_vetcurse",
        --text = "\n - Die and die again, there's no limit!",
        text = "\n - Death does not become you!",
    },
    {
        name = "walter_vetcurse",
        text = "\n - I'm bleeding! Does anyone know first aid?!",
    },
    {
        name = "wortox_vetcurse",
        text = "\n - Souls of the fallen are back for revenge!",
    },
    {
        name = "shambler_target",
        text = "\n - You are being hunted.",
    },
    {
        name = "willow_vetcurse",
        text = "\n - 'Creates fires when stressed'.",
    },
    {
        name = "warly_vetcurse",
        text = "\n - Don't be a glutton!",
    },
    {
        name = "winky_vetcurse",
        text = "\n - Lose your stuff, lose your health.",
    },
    {
        name = "wickerbottom_vetcurse",
        text = "\n - Lack of sleep is hazardous for your health",
    },
    {
        name = "wixie_vetcurse",
        text = "\n - Krampus' may take notice of haenous deeds...",
    },
    {
        name = "woodie_vetcurse",
        text = "\n - The birds! The birds I tell you!",
    },
    {
        name = "wolfgang_vetcurse",
        text = "\n - Getting Hungry? Getting Weak.",
    },
    {
        name = "wanda_vetcurse",
        text = "\n - Shadows may be lurking anywhere...",
    },
    {
        name = "wathgrithr_vetcurse",
        text = "\n - Some enemies may rise to the challenge!",
    },
    {
        name = "wes_vetcurse",
        text = "\n - Life is harder without stat displays.",
    },
    {
        name = "wendy_vetcurse",
        text = "\n - Mental health, life or death.",
    },
}

--[[function Vetcursewidget:RefreshTooltips()
    local vet_text = ""

    vet_text = STRINGS.VETS_WIDGET

    if self.owner:HasTag("um_3_deaths") and self.owner:HasTag("wilson_vetcurse") then
        vet_text = vet_text .. "\n - The curse is thriving! 50% increased stat drain."
    elseif self.owner:HasTag("um_2_deaths") and self.owner:HasTag("wilson_vetcurse") then
        vet_text = vet_text .. "\n - The curse is strong. 40% increased stat drain."
    elseif self.owner:HasTag("um_1_deaths") and self.owner:HasTag("wilson_vetcurse") then
        vet_text = vet_text .. "\n - The curse is growing... 30% increased stat drain."
    elseif self.owner:HasTag("wilson_vetcurse") then
        vet_text = vet_text .. "\n - The curse has found you. 20% increased stat drain."
    end

    local old_text = vet_text
    for i, v in ipairs(skulls) do
        if self.owner:HasTag(v.name) then
            old_text = vet_text
            vet_text = old_text .. v.text
        end
    end

    self.bg2:SetTooltip(vet_text)
end]]

function Vetcursewidget:OnUpdate(dt)
    if self.owner:HasTag("vetcurse") then
        --self:RefreshTooltips()
        self:Show()
    else
        self:Hide()
    end
end

return Vetcursewidget
