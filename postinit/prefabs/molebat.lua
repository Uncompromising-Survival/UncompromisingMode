local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local _ShouldSummonAllies
local function ShouldSummonAllies(inst, ...)
    if inst.um_cantsummonallies then return false end
    return _ShouldSummonAllies and  _ShouldSummonAllies(inst, ...)
end

local _OnSave
local function OnSave(inst, data, ...)
    data.um_cantsummonallies = inst.um_cantsummonallies
    return _OnSave and _OnSave(inst, data, ...)
end

local _OnLoad
local function OnLoad(inst, data, ...)
    if data and data.um_cantsummonallies then
        inst.um_cantsummonallies = true

        -- Stop the constructer-started timer. We shouldn't have loaded one.
        inst.components.timer:StopTimer("resetallysummon")
    end
    return _OnLoad and _OnLoad(inst, data, ...)
end

env.AddPrefabPostInit("molebat", function(inst)
    if not TheWorld.ismastersim then return end

    if not _ShouldSummonAllies then
        _ShouldSummonAllies = inst.ShouldSummonAllies
    end
    inst.ShouldSummonAllies = ShouldSummonAllies

    if not _OnSave then
        _OnSave = inst.OnSave
    end
    inst.OnSave = OnSave
    if not _OnLoad then
        _OnLoad = inst.OnLoad
    end
    inst.OnLoad = OnLoad

    if inst.components.lootdropper then
        inst.components.lootdropper:SetLoot({"batnose", "monstersmallmeat"})
    end
end)
