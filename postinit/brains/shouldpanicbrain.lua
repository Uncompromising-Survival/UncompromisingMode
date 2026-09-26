local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local BrainCommon = require("brains/braincommon")

local _ShouldTriggerPanic = UMUpvalueHacker.TryGetUpvalue(BrainCommon.PanicTrigger, "ShouldTriggerPanic")
if _ShouldTriggerPanic then
    local function ShouldTriggerPanic(inst, ...)
        local takingfiredamage
        local health = inst.components.health
        if (inst.brain and inst.brain.um_nofirepanic or inst:HasAnyTag("ice_shielded")) and health and health.takingfiredamage then
            takingfiredamage = health.takingfiredamage
            health.takingfiredamage = false
        end
        local ret = _ShouldTriggerPanic(inst, ...)
        if takingfiredamage then health.takingfiredamage = takingfiredamage end
        return ret
    end
    UMUpvalueHacker.SetUpvalue(BrainCommon.PanicTrigger, ShouldTriggerPanic, "ShouldTriggerPanic")
end

local NO_FIREPANIC_LIST = {"spiderqueen", "knight", "bishop", "rook", "uncompromising_pawn"}
for _, name in pairs(NO_FIREPANIC_LIST) do
    env.AddBrainPostInit(name.."brain", function(self)
        self.um_nofirepanic = true
    end)
end