local env = env
GLOBAL.setfenv(1, GLOBAL)

local BrainCommon = require("brains/braincommon")
local UpvalueHacker = require("tools/upvaluehacker")

local _ShouldTriggerPanic = UpvalueHacker.GetUpvalue(BrainCommon.PanicTrigger, "ShouldTriggerPanic")

local function ShouldTriggerPanic(inst, ...)
    local takingfiredamage
    local health = inst.components.health
    if inst:HasTag("ice_shielded") and health and health.takingfiredamage then
        takingfiredamage = inst.components.health.takingfiredamage
        health.takingfiredamage = false
    end
    local ret = _ShouldTriggerPanic(inst, ...)
    if takingfiredamage then health.takingfiredamage = takingfiredamage end
    return ret
end

UpvalueHacker.SetUpvalue(BrainCommon.PanicTrigger, ShouldTriggerPanic, "ShouldTriggerPanic")