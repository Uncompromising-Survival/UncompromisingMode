local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local easing = require "easing"

local function AlphaGoal(self)
	if self.nightterror == 1 then
		return 1
	else
		return self.immunity
	end

end

local NightTerrorWidget = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "Nightterrorwidget")
	self.swirl = self:AddChild(UIAnim())
	self.swirl:GetAnimState():SetBank("atrium_gate_overload_fx")
    self.swirl:GetAnimState():SetBuild("atrium_gate_overload_fx")
	self.swirl:GetAnimState():PlayAnimation("idle_loop",true)
    --[[self.swirl:SetVAnchor(ANCHOR_MIDDLE)
    self.swirl:SetHAnchor(ANCHOR_MIDDLE)
    self.swirl:SetPosition(860, 180, 0)]]
    self.swirl:SetScaleMode(0.01)
    self.swirl:SetScale(.2, .2, .2)
    self:StartUpdating()
    
	self.alpha = 0
	self.immunity = 0
	self.nightterror = 1 -- will eventually not be nil
	
    owner:ListenForEvent("terror_immunitydirty",function(owner,data)
        self.immunity = owner.terror_immunity:value()
    end)     
    owner:ListenForEvent("nightterrordirty",function(owner,data)
        self.nightterror = owner.nightterror:value()
		if self.nightterror == 1 then
			self:Hide()
		else
			self.alpha = 1
			self:Show()
		end
    end)  

end)

function NightTerrorWidget:OnUpdate(dt)
	-- if self.alpha > AlphaGoal(self) then
		-- self.alpha = self.alpha - 0.005
	-- elseif AlphaGoal(self) < self.alpha then
		-- self.alpha = self.alpha + 0.005
	-- end
	if self.alpha > AlphaGoal(self) then
		self.alpha = self.alpha - 0.005
	elseif AlphaGoal(self) > self.alpha then
		self.alpha = self.alpha + 0.005
	end
	
	self.swirl:GetAnimState():SetMultColour(1, 1, 1, 1-self.alpha)
end

return NightTerrorWidget
