local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------

env.AddComponentPostInit("playercontroller", function(self) --By Summerrr, I didn't do anything lool -C
    local _GetActionButtonAction = self.GetActionButtonAction
    function self:GetActionButtonAction(...)
        local actbuttonaction = _GetActionButtonAction(self, ...)
        local action = actbuttonaction and actbuttonaction.action
        local inventory = self.inst.components.inventory
        local tool = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) --You spotted some silly stuff down there too, Max!! TY!!! -C
        if actbuttonaction and action and action.id == ACTIONS.PICK.id and tool and tool:HasTag(ACTIONS.SCYTHE.id.."_tool") then 
            return BufferedAction(self.inst, actbuttonaction.target, ACTIONS.SCYTHE, action ~= ACTIONS.SMOTHER and tool or nil)
        end
        return actbuttonaction
    end
end)