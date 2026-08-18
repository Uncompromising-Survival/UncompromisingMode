local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

--env.AddComponentPostInit("spellcaster", function(self) end)

local UpvalueHacker = require("tools/upvaluehacker")
env.AddSimPostInit(function()
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local POINT, EQUIPPED = COMPONENT_ACTIONS.POINT, COMPONENT_ACTIONS.EQUIPPED
        if POINT then
            local _POINT_spellcaster_fn = POINT["spellcaster"]
            if _POINT_spellcaster_fn then
                POINT["spellcaster"] = function(inst, doer, pos, actions, right, target, ...)
                    if inst.um_cancastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and not inst:um_cancastontarget(doer, pos, target, UMCommonFns.HasRightClickAction(inst, doer, pos, target)) then return end
                    return _POINT_spellcaster_fn(inst, doer, pos, actions, right, target, ...)
                end
            end
        end
        if EQUIPPED then
            local _EQUIPPED_spellcaster_fn = EQUIPPED["spellcaster"]
            if _EQUIPPED_spellcaster_fn then
                EQUIPPED["spellcaster"] = function(inst, doer, target, actions, right, ...)
                    if inst.um_cancastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and not inst:um_cancastontarget(doer, nil, target, UMCommonFns.HasRightClickAction(inst, doer, nil, target)) then return end
                    return _EQUIPPED_spellcaster_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
    end
end)