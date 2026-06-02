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

--[[local ignoredactions = {ACTIONS.LOOKAT, ACTIONS.WALKTO}
local function CheckActions(doer, target)
    local actions = doer.components.playeractionpicker and doer.components.playeractionpicker:GetSceneActions(target, true)
    local count = 0
    if actions then
        for k, v in pairs(actions) do
            if not table.contains(ignoredactions, v.action) then
                count = count + 1
            end
        end
    end
    return count >= 1
end]]

local UpvalueHacker = require("tools/upvaluehacker")
env.AddSimPostInit(function()
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local --[[POINT,]] EQUIPPED = --[[COMPONENT_ACTIONS.POINT,]] COMPONENT_ACTIONS.EQUIPPED
        if EQUIPPED then
            local _EQUIPPED_spellcaster_fn = EQUIPPED["spellcaster"]
            if _EQUIPPED_spellcaster_fn then
                EQUIPPED["spellcaster"] = function(inst, doer, target, actions, right, ...)
                    --[[if inst:HasTag("um_checksceneactions") and doer.components.playercontroller
                        and not doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) and CheckActions(doer, target) then return end]]
                    if CantCastOnTarget(inst, target, true) then return end
                    return _EQUIPPED_spellcaster_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
    end
end)