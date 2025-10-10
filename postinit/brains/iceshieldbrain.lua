local env = env
GLOBAL.setfenv(1, GLOBAL)


local BrainCommon = require("brains/braincommon")
local UpvalueHacker = require("tools/upvaluehacker")

local _ShouldTriggerPanic = UpvalueHacker.GetUpvalue(BrainCommon.PanicTrigger, "ShouldTriggerPanic")

local function ShouldTriggerPanic(inst)
    return _ShouldTriggerPanic(inst) and not inst:HasTag("ice_shielded")
end

UpvalueHacker.SetUpvalue(BrainCommon.PanicTrigger, ShouldTriggerPanic, "ShouldTriggerPanic")