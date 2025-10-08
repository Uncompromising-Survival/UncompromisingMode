local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------

env.AddComponentPostInit("playercontroller", function(self) --By Summerrr, I didn't do anything lool -C
    local _GetActionButtonAction = self.GetActionButtonAction
    function self:GetActionButtonAction(...)
        local bufferedAction = _GetActionButtonAction(self, ...)
        local action = bufferedAction ~= nil and bufferedAction.action or nil
        local inventory = self.inst.components.inventory
        local tool = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil --You spotted some silly stuff down there too, Max!! TY!!! -C
        if bufferedAction ~= nil and action ~= nil and action.id == ACTIONS.PICK.id and tool ~= nil and tool:HasTag(ACTIONS.SCYTHE.id.."_tool") then 
            return BufferedAction(self.inst, bufferedAction.target, ACTIONS.SCYTHE, action ~= ACTIONS.SMOTHER and tool or nil)
        end
        return bufferedAction
    end
end)