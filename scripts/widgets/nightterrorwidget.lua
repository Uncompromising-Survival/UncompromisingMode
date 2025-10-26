local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local easing = require "easing"

local NightTerrorWidget = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "Nightterrorwidget")
	self.swirl = self:AddChild(UIAnim())
	self.swirl:GetAnimState():SetBank("atrium_gate_overload_fx")
    self.swirl:GetAnimState():SetBuild("atrium_gate_overload_fx")
	self.swirl:GetAnimState():PlayAnimation("idle_loop",true)
    self.swirl:SetVAnchor(ANCHOR_MIDDLE)
    self.swirl:SetHAnchor(ANCHOR_MIDDLE)
    self.swirl:SetPosition(870, 110, 0)
    self.swirl:SetScaleMode(0.01)
    self.swirl:SetScale(.33, .33, .33)
    self.swirl:SetTooltip(STRINGS.VETS_WIDGET)
    self:StartUpdating()
    self:Show()
end)

function NightTerrorWidget:OnUpdate(dt)
    self:Show()
end

return NightTerrorWidget
