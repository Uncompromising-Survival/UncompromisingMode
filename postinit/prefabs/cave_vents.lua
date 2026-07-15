local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local UpvalueHacker = require("tools/upvaluehacker")
env.AddSimPostInit(function()
    local SpewMiasma = UpvalueHacker.GetUpvalue(Prefabs.cave_vent_rock.fn, "OnTimerDone", "SpewMiasma")
    local _SpewHotSteam = UpvalueHacker.GetUpvalue(Prefabs.cave_vent_rock.fn, "OnTimerDone", "SpewHotSteam")
    local function SpewHotSteam(inst, ...) -- Triggers both codes
        _SpewHotSteam(inst, ...)
        -- Cancel existing timer before calling SpewMiasma to avoid duplicates
        -- Fixes a stack overflow crash -Deimos
        UMCommonFns.RestartTimer(inst, {name = "spew_miasma"})
        SpewMiasma(inst)
    end
    UpvalueHacker.SetUpvalue(Prefabs.cave_vent_rock.fn, SpewHotSteam, "OnTimerDone","SpewHotSteam")
end)


