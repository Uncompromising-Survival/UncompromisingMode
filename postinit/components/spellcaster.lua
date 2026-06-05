local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

-- This is used to stop deconstruction on targets you really don't want deconstructed without stopping other magic (e.g., reskin_tool).
local function CantCastOnTarget(inst, target, client)
    local cancastonrecipes
    if not client then
        local spellcaster = inst.components.spellcaster
        cancastonrecipes = spellcaster and spellcaster.canuseontargets and spellcaster.canonlyuseonrecipes
    end
    return (client and inst:HasTag("castonrecipes") or cancastonrecipes) and target:HasTag("um_nodeconstruct")
end

env.AddComponentPostInit("spellcaster", function(self)
    local _CanCast = self.CanCast
    function self:CanCast(doer, target, ...)
        if CantCastOnTarget(self.inst, target) then return false end
        return _CanCast(self, doer, target, ...)
    end
end)

local UpvalueHacker = require("tools/upvaluehacker")
env.AddSimPostInit(function()
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local POINT, EQUIPPED = COMPONENT_ACTIONS.POINT, COMPONENT_ACTIONS.EQUIPPED
        if POINT then
            local _POINT_spellcaster_fn = POINT["spellcaster"]
            if _POINT_spellcaster_fn then
                POINT["spellcaster"] = function(inst, doer, pos, actions, right, target, ...)
                    --[[if inst.um_cantcastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and inst:um_cantcastontarget(doer, pos, target, UMCommonFns.CanOverrideAction(doer.components.playeractionpicker and doer.components.playeractionpicker:GetPointSpecialActions(pos, nil, true))) then return end]]
					if inst.um_cantcastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and inst:um_cantcastontarget(doer, pos, target, UMCommonFns.HasRightClickAction(inst, doer, pos, target)) then return end
                    return _POINT_spellcaster_fn(inst, doer, pos, actions, right, target, ...)
                end
            end
        end
        if EQUIPPED then
            local _EQUIPPED_spellcaster_fn = EQUIPPED["spellcaster"]
            if _EQUIPPED_spellcaster_fn then
                EQUIPPED["spellcaster"] = function(inst, doer, target, actions, right, ...)
                    --[[if inst.um_cantcastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and inst:um_cantcastontarget(doer, nil, target, doer.components.playeractionpicker and UMCommonFns.CanOverrideAction(doer.components.playeractionpicker:GetSceneActions(target, true), target ~= doer and doer.components.playeractionpicker:GetSceneActions(target))) then return end]]
					if inst.um_cantcastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and inst:um_cantcastontarget(doer, nil, target, UMCommonFns.HasRightClickAction(inst, doer, nil, target)) then return end
                    if CantCastOnTarget(inst, target, true) then return end
                    return _EQUIPPED_spellcaster_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
    end
end)