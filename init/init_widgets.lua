local env = env
GLOBAL.setfenv(1, GLOBAL)

local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")
local UIAnimButton = require("widgets/uianimbutton")
local Widget = require("widgets/widget")

env.AddClassPostConstruct("screens/playerinfopopupscreen", function(self, owner)
    if self.root and self.root.bg and owner and owner:HasTag("vetcurse") then
        local um_vetskull_string = string.upper(owner.prefab)

        self.vetcurseskull = self.root:AddChild(Image("images/vetskull.xml", "vetskull.tex"))
        self.vetcurseskull:SetScale(0.15, 0.15)
        self.vetcurseskull:SetPosition(-4.65, 260, 0)
        self.vetcurseskull:SetHoverText((STRINGS.UI.HUD.UM_VETSKULL[um_vetskull_string] or STRINGS.UI.HUD.UM_VETSKULL.DEFAULT) .. STRINGS.UI.HUD.UM_VETSKULL_VETSITEMS, { offset_y = 60 })
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

--player hud thingys
local MineralLogbookPopupScreen = require("screens/redux/minerallogbookpopupscreen")
local PlayerHud = require("screens/playerhud")
function PlayerHud:OpenMineralLogbookScreen()
    self:CloseMineralLogbookScreen()
    self.minerallogbookscreen = MineralLogbookPopupScreen(self.owner)
    self:OpenScreenUnderPause(self.minerallogbookscreen)
    return true
end

function PlayerHud:CloseMineralLogbookScreen()
    if self.minerallogbookscreen ~= nil then
        if self.minerallogbookscreen.inst:IsValid() then
            TheFrontEnd:PopScreen(self.minerallogbookscreen)
        end
        self.minerallogbookscreen = nil
    end
end

--popup registry

local mineral_logbook = PopupManagerWidget()

mineral_logbook.id = "MINERAL_LOGBOOK"
mineral_logbook.fn = function(inst, show)
    if inst.HUD then
        if not show then
            inst.HUD:CloseMineralLogbookScreen()
        elseif not inst.HUD:OpenMineralLogbookScreen() then
            POPUPS.MINERAL_LOGBOOK:Close(inst)
        end
    end
end
env.AddPopup(mineral_logbook)
