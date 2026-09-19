local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local UMUpvalueHacker = require("tools/um_upvaluehacker")
env.AddSimPostInit(function()
    local SpewMiasma = UMUpvalueHacker.TryGetUpvalue(Prefabs.cave_vent_rock.fn, "OnTimerDone", "SpewMiasma")
    local _SpewHotSteam = UMUpvalueHacker.TryGetUpvalue(Prefabs.cave_vent_rock.fn, "OnTimerDone", "SpewHotSteam")
    if _SpewHotSteam then
        local function SpewHotSteam(inst, ...) -- Triggers both codes
            _SpewHotSteam(inst, ...)
            -- Cancel existing timer before calling SpewMiasma to avoid duplicates
            -- Fixes a stack overflow crash -Deimos
            UMCommonFns.RestartTimer(inst, {name = "spew_miasma"})
            SpewMiasma(inst)
        end
        UMUpvalueHacker.SetUpvalue(Prefabs.cave_vent_rock.fn, SpewHotSteam, "OnTimerDone","SpewHotSteam")
    end
end)


