local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------

--[[env.AddComponentPostInit("playercontroller", function(self) --By Summerrr, I didn't do anything lool -C
    local _GetActionButtonAction = self.GetActionButtonAction
    function self:GetActionButtonAction(...)
        local actbuttonaction = _GetActionButtonAction(self, ...)
        local action = actbuttonaction and actbuttonaction.action
        local inventory = self.inst.components.inventory
        local tool = inventory and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) --You spotted some silly stuff down there too, Max!! TY!!! -C
        if actbuttonaction and action == ACTIONS.PICK and tool and tool:HasTag(ACTIONS.SCYTHE.id.."_tool") then
            return BufferedAction(self.inst, actbuttonaction.target, ACTIONS.SCYTHE, action ~= ACTIONS.SMOTHER and tool or nil)
        end
        return actbuttonaction
    end
end)]]

--[[Patching OnEquip/OnUnequip (local fns in components/playercontroller.lua)because they skip all reticule cleanup whenever the currently active reticule's item also has a spellbook component aka the antlionstaff, it has both reticule and spellbook, so its reticule never gets torn down through the normal vanilla flow path

This exempts just that one guard condition for this item, the rest of the reticule cleanup logic is still intact, so it should be safe to do this]]

--[[local UpvalueHacker = require("tools/upvaluehacker")

local _OnEquip
local function OnEquip(inst, data, ...)
    return _OnEquip and _OnEquip(inst, data, ...)
end

local _OnUnequip
local function OnUnequip(inst, data, ...)
    return _OnUnequip and _OnUnequip(inst, data, ...)
end

env.AddComponentPostInit("playercontroller", function(self)
    if not _OnEquip then
        _OnEquip = UpvalueHacker.GetUpvalue(self.Activate, "OnEquip")
        UpvalueHacker.SetUpvalue(self.Activate, OnEquip, "OnEquip")
        _OnUnequip = UpvalueHacker.GetUpvalue(self.Activate, "OnUnequip")
        UpvalueHacker.SetUpvalue(self.Activate, OnUnequip, "OnUnequip")
    end
end)]]