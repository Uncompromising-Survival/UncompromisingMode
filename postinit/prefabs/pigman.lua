local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")

local RETARGET_MUST_TAGS = {"_combat", "player"}
local RETARGET_CANT_TAGS = {"playerghost"}

env.AddSimPostInit(function()
    local _SetNormalPig = UMUpvalueHacker.TryGetUpvalue(Prefabs.pigman.fn, "SetNormalPig")
    if _SetNormalPig then
        local function SetNormalPig(inst, ...)
            local ret = _SetNormalPig(inst, ...)
            local combat = inst.components.combat
            local _Retarget = combat.targetfn
            combat:SetRetargetFunction(combat.retargetperiod, function(_inst, ...)
                if _inst:HasTag("NPC_contestant") or _inst.components.minigame_spectator then return _Retarget(_inst, ...) end
                return not _inst:IsInLimbo() and FindEntity(_inst, TUNING.PIG_TARGET_DIST, function(guy)
                    return guy.userid and table.contains(inst.remembered_threats, guy.userid) and guy:IsInLight() and inst.components.combat:CanTarget(guy)
                end, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS) or _Retarget(_inst, ...)
            end)
            return ret
        end
        UMUpvalueHacker.SetUpvalue(Prefabs.pigman.fn, SetNormalPig, "SetNormalPig")
    end
end)

local function IsPig(inst)
    return inst:HasTag("pig") and not (inst.franken or inst:HasTag("werepig"))
end

local function SetShouldAggroStuff(inst)
    local combat = inst.components.combat
    if combat then
        local _ShouldAggroFn = combat.shouldaggrofn
        combat:SetShouldAggroFn(function(_inst, target, ...)
            if IsPig(_inst) and IsPig(target) then return false end
            if _ShouldAggroFn then return _ShouldAggroFn(_inst, target, ...) end
            return true
        end)
    end
end

local _AcceptTest
local function AcceptTest(inst, item, ...)
    if inst.components.eater:CanEat(item) then
        local foodtype = item.components.edible.foodtype
        if foodtype == FOODTYPE.UM_HORRIBLE_VEGGIE then
            local last_eat_time = inst.components.eater:TimeSinceLastEating()
            return (last_eat_time == nil or
                    last_eat_time >= TUNING.PIG_MIN_POOP_PERIOD)
                    and (inst.components.inventory == nil or
                    not inst.components.inventory:Has(item.prefab, 1))
        end
    end
    return _AcceptTest and _AcceptTest(inst, item, ...)
end

local function OnNewTarget_Remember(inst, data)
    local userid = data and data.target and data.target.isplayer and not (inst.franken or inst:HasTag("werepig")) and data.target.userid
    if userid then
        if table.contains(inst.remembered_threats, userid) then
            local strtbl = STRINGS["PIG_REMEMBER_THREAT"]
            if strtbl then
                local strid = math.random(#strtbl)
                inst.components.talker:Chatter("PIG_REMEMBER_THREAT", strid)
            end
        else
            table.insert(inst.remembered_threats, userid)
        end
    end
end

local _OnSave
local function OnSave(inst, data, ...)
    data.remembered_threats = inst.remembered_threats and next(inst.remembered_threats) and inst.remembered_threats or nil
    return _OnSave and _OnSave(inst, data, ...)
end

local _OnLoad
local function OnLoad(inst, data, ...)
    if data and data.remembered_threats then
        inst.remembered_threats = data.remembered_threats
    end
    return _OnLoad and _OnLoad(inst, data, ...)
end

env.AddPrefabPostInit("pigman", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.remembered_threats = {}

    SetShouldAggroStuff(inst)

    local trader = inst.components.trader
    if trader then
        if not _AcceptTest then
            _AcceptTest = trader.test
        end
        trader:SetAcceptTest(AcceptTest)
    end

    inst.components.eater:SetCanEatVeggieHorrible() -- Can eat UM_HORRIBLE_VEGGIE

    inst:ListenForEvent("newcombattarget", OnNewTarget_Remember)

    if not _OnSave then
        _OnSave = inst.OnSave
    end
    inst.OnSave = OnSave
    if not _OnLoad then
        _OnLoad = inst.OnLoad
    end
    inst.OnLoad = OnLoad
end)

env.AddPrefabPostInit("pigguard", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    SetShouldAggroStuff(inst)
end)

env.AddPrefabPostInit("pigking_pigguard", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    SetShouldAggroStuff(inst)

    --[[
    local _setnormalfn = inst.components.werebeast.onsetnormalfn

    inst.components.werebeast:SetOnNormalFn(function(_inst)
        print("Deleting remembered threats of king guard")
        if _inst.remembered_threats then
            _inst.components.combat:DropTarget()
            _inst.remembered_threats = {}
            _inst.components.combat:DropTarget()
        end
        _setnormalfn(_inst)
    end)
    ]]
end)