local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local UpvalueHacker = require("tools/upvaluehacker")
env.AddPrefabPostInit("world", function(inst) -- AXE Assuming Max said this -> Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not _G.TheWorld.ismastersim then return end

    local SpewMiasma = UpvalueHacker.GetUpvalue(_G.Prefabs.cave_vent_rock.fn,"OnTimerDone","SpewMiasma")
   
    local _SpewHotSteam = UpvalueHacker.GetUpvalue(_G.Prefabs.cave_vent_rock.fn,"OnTimerDone","SpewHotSteam")
   
    local function SpewHotSteam(inst, is_populating, vent_type) -- Triggers both codes
        _SpewHotSteam(inst)
        -- Cancel existing timer before calling SpewMiasma to avoid duplicates
        -- Fixes a stack overflow crash -Deimos
        UMCommonFns.RestartTimer(inst, {name = "spew_miasma"})
        SpewMiasma(inst)
    end
    UpvalueHacker.SetUpvalue(_G.Prefabs.cave_vent_rock.fn, SpewHotSteam, "OnTimerDone","SpewHotSteam")
end)


