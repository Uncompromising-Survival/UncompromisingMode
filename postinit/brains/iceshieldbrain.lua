local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local BrainCommon = require("brains/braincommon")

local _ShouldTriggerPanic = UMUpvalueHacker.GetUpvalue(BrainCommon.PanicTrigger, "ShouldTriggerPanic")
local function ShouldTriggerPanic(inst, ...)
    local takingfiredamage
    local health = inst.components.health
    if inst:HasTag("ice_shielded") and health and health.takingfiredamage then
        takingfiredamage = health.takingfiredamage
        health.takingfiredamage = false
    end
    local ret = _ShouldTriggerPanic(inst, ...)
    if takingfiredamage then health.takingfiredamage = takingfiredamage end
    return ret
end

UMUpvalueHacker.SetUpvalue(BrainCommon.PanicTrigger, ShouldTriggerPanic, "ShouldTriggerPanic")