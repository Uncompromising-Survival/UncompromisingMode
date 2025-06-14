local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")
local UIAnimButton = require("widgets/uianimbutton")
local Widget = require("widgets/widget")

AddClassPostConstruct("screens/playerinfopopupscreen", function(self, owner)
	if self.root and self.root.bg and owner and owner:HasTag("vetcurse") then
		local um_vetskull_string = owner:HasTag("clockmaker") and STRINGS.UI.HUD.UM_VETSKULL.WANDA or self.owner:HasTag("mime") and STRINGS.UI.HUD.UM_VETSKULL.WES or STRINGS.UI.HUD.UM_VETSKULL.DEFAULT
		
		self.vetcurseskull = self.root:AddChild(ImageButton("images/vetskull.xml", "vetskull.tex"))
		self.vetcurseskull:SetScale(0.15, 0.15)
		self.vetcurseskull:SetPosition(-4.65, 260, 0)
		self.vetcurseskull:SetHoverText(um_vetskull_string, { offset_y = 60 })
	end
	
	--[[local OldOnControl = self.OnControl
	function self:OnControl(control, down, ...)
		if control == CONTROL_MOVE_UP then
			if self.vetcurseskull and not self.vetcurseskull.focus then
				self.vetcurseskull:SetHoverText(STRINGS.VETS_WIDGET, { offset_y = 20 })
				return true
			end
		end
		
		if OldOnControl then
			return OldOnControl(self, control, down, ...)
		end
	end]]
end)