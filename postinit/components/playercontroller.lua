local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------

env.AddComponentPostInit("playercontroller", function(self)
    --[[local _GetActionButtonAction = self.GetActionButtonAction
    function self:GetActionButtonAction(...) --By Summerrr, I didn't do anything lool -C
        local actbuttonaction = _GetActionButtonAction(self, ...)
        local action = actbuttonaction and actbuttonaction.action
        local inventory = self.inst.components.inventory
        local tool = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) --You spotted some silly stuff down there too, Max!! TY!!! -C
        if actbuttonaction and action == ACTIONS.PICK and tool and tool:HasTag(ACTIONS.SCYTHE.id.."_tool") then 
            return BufferedAction(self.inst, actbuttonaction.target, ACTIONS.SCYTHE, action ~= ACTIONS.SMOTHER and tool or nil)
        end
        return actbuttonaction
    end]]

    local _RefreshReticule = self.RefreshReticule
    function self:RefreshReticule(item, ...)
        if item and self.reticule and item ~= self.reticule.inst then return end -- Attempt at fixing an issue related to AOETargeting with another item, and an item enabling its AOETargeting.
        return _RefreshReticule(self, item, ...)
    end
end)
