local env = env
GLOBAL.setfenv(1, GLOBAL)

local _ShouldSummonAllies
local function ShouldSummonAllies(inst, ...)
    if inst.um_cantsummonallies then return false end
    if _ShouldSummonAllies then return _ShouldSummonAllies(inst, ...) end
end

local _OnSave
local function OnSave(inst, data, ...)
    data.um_cantsummonallies = inst.um_cantsummonallies
    if _OnSave then return _OnSave(inst, data, ...) end
end

local _OnLoad
local function OnLoad(inst, data, ...)
    if data and data.um_cantsummonallies then
        inst.um_cantsummonallies = true

        -- Stop the constructer-started timer. We shouldn't have loaded one.
        inst.components.timer:StopTimer("resetallysummon")
    end
    if _OnLoad then return _OnLoad(inst, data, ...) end
end

env.AddPrefabPostInit("molebat", function(inst)
    if not TheWorld.ismastersim then return end

    _ShouldSummonAllies = inst.ShouldSummonAllies
    inst.ShouldSummonAllies = ShouldSummonAllies

    _OnSave = inst.OnSave
    inst.OnSave = OnSave
    _OnLoad = inst.OnLoad
    inst.OnLoad = OnLoad
    if inst.components.lootdropper then
        inst.components.lootdropper:SetLoot({"batnose", "monstersmallmeat"})
    end
end)
