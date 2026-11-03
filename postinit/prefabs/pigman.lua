local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")

local RETARGET_MUST_TAGS = {"_combat", "player"}
local RETARGET_CANT_TAGS = {"playerghost"}

local NormalKeepTargetFn
local NormalRetargetFn
env.AddPrefabPostInit("world", function(world)
    if not world.ismastersim then return end
    local _SetNormalPig = UMUpvalueHacker.TryGetUpvalue(Prefabs.pigman.fn, "SetNormalPig")
    if _SetNormalPig then
        NormalKeepTargetFn = UMUpvalueHacker.TryGetUpvalue(_SetNormalPig, "NormalKeepTargetFn")
        local _NormalRetargetFn = UMUpvalueHacker.TryGetUpvalue(_SetNormalPig, "NormalRetargetFn")
        if _NormalRetargetFn then
            local _IsFranken = UMUpvalueHacker.TryGetUpvalue(_NormalRetargetFn, "IsFranken")
            if _IsFranken then
                local function IsFranken(dude, inst, ...)
                    return inst.um_pkguard and dude.franken or _IsFranken(dude, inst, ...)
                end
                UMUpvalueHacker.SetUpvalue(_NormalRetargetFn, IsFranken, "IsFranken")
            end
            NormalRetargetFn = function(inst, ...)
                if inst:HasTag("NPC_contestant") or inst.components.minigame_spectator then return _NormalRetargetFn(inst, ...) end
                return not inst:IsInLimbo() and FindEntity(inst, TUNING.PIG_TARGET_DIST, function(guy)
                    return guy.userid and table.contains(inst.um_remembered_threats, guy.userid) and guy:IsInLight() and inst.components.combat:CanTarget(guy)
                end, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS) or _NormalRetargetFn(inst, ...)
            end
            UMUpvalueHacker.SetUpvalue(_SetNormalPig, NormalRetargetFn, "NormalRetargetFn")
        end
    end
end)

local function IsNonWerePig(inst)
    return inst:HasTag("pig") and not (inst.franken or inst:HasTag("werepig"))
end

local function SetShouldAggroStuff(inst)
    local combat = inst.components.combat
    if combat then
        local _ShouldAggroFn = combat.shouldaggrofn
        combat:SetShouldAggroFn(function(_inst, target, ...)
            if IsNonWerePig(_inst) and IsNonWerePig(target) then return false end
            if _ShouldAggroFn then return _ShouldAggroFn(_inst, target, ...) end
            return true
        end)
    end
end

local MAX_TARGET_SHARES = 15
local SHARE_TARGET_DIST = 30

local function OnNewTarget_Remember(inst, data)
    local userid = data and data.target and data.target.isplayer and not (inst.franken or inst:HasTag("werepig")) and data.target.userid
    if userid then
        if table.contains(inst.um_remembered_threats, userid) then
            local strtbl = STRINGS.PIG_REMEMBER_THREAT
            if strtbl then
                local strid = math.random(#strtbl)
                inst.components.talker:Chatter("PIG_REMEMBER_THREAT", strid)
            end
            if inst.um_pkguard then inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, IsNonWerePig, MAX_TARGET_SHARES) end
        else
            table.insert(inst.um_remembered_threats, userid)
        end
    end
end

do
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

    local _OnNormal
    local function OnNormal(inst, ...)
        local ret = _OnNormal and _OnNormal(inst, ...)
        inst.um_remembered_threats = {}
        return ret
    end

    local _OnSave
    local function OnSave(inst, data, ...)
        data.um_remembered_threats = inst.um_remembered_threats and next(inst.um_remembered_threats) and inst.um_remembered_threats or nil
        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.um_remembered_threats then
            inst.um_remembered_threats = data.um_remembered_threats
        end
        return _OnLoad and _OnLoad(inst, data, ...)
    end

    env.AddPrefabPostInit("pigman", function(inst)
        if not TheWorld.ismastersim then return end

        inst.um_remembered_threats = {}

        SetShouldAggroStuff(inst)

        local werebeast = inst.components.werebeast
        if werebeast then
            if not _OnNormal then
                _OnNormal = werebeast.onsetnormalfn
            end
            werebeast:SetOnNormalFn(OnNormal)
        end

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
end

do
    local guardbrain = require("brains/pigguard_pigkingbrain")

    local function OnPKGuardNormal(inst)
        inst:SetBrain(guardbrain)
        local combat = inst.components.combat
        local _KeepTargetFn = combat.keeptargetfn
        combat:SetKeepTargetFunction(function(_inst, target, ...)
            if _inst.um_pkguard then
                return NormalKeepTargetFn and NormalKeepTargetFn(_inst, target, ...)
            end
            return _KeepTargetFn(_inst, target, ...)
        end)
        local _Retarget = combat.targetfn
        combat:SetRetargetFunction(combat.retargetperiod, function(_inst, ...)
            if _inst.um_pkguard then
                return NormalRetargetFn and NormalRetargetFn(_inst, ...)
            end
            return _Retarget(_inst, ...)
        end)
    end

    local _OnNormal
    local function OnNormal(inst, ...)
        local ret = _OnNormal and _OnNormal(inst, ...)
        inst.um_remembered_threats = {}
        inst:UMOnPKGuardNormal()
        return ret
    end

    local function SetPKGuard(inst)
        inst.um_pkguard = true
        inst:AddTag("um_pkguard")
        inst.um_remembered_threats = {}

        if not inst:HasTag("werepig") then inst:UMOnPKGuardNormal() end

        local werebeast = inst.components.werebeast
        if werebeast then
            if not _OnNormal then
                _OnNormal = werebeast.onsetnormalfn
            end
            werebeast:SetOnNormalFn(OnNormal)
        end

        inst:ListenForEvent("newcombattarget", OnNewTarget_Remember)
    end

    local _OnSave
    local function OnSave(inst, data, ...)
        if inst.um_pkguard then
            data.um_pkguard = inst.um_pkguard
            data.um_remembered_threats = inst.um_remembered_threats and next(inst.um_remembered_threats) and inst.um_remembered_threats or nil
        end
        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.um_pkguard then
            inst:UMSetPKGuard()
            if data.um_remembered_threats then inst.um_remembered_threats = data.um_remembered_threats end
        end
        return _OnLoad and _OnLoad(inst, data, ...)
    end

    env.AddPrefabPostInit("pigguard", function(inst)
        if not TheWorld.ismastersim then return end

        SetShouldAggroStuff(inst)

        inst.UMOnPKGuardNormal = OnPKGuardNormal
        inst.UMSetPKGuard = SetPKGuard

        if not _OnSave then
            _OnSave = inst.OnSave
        end
        inst.OnSave = OnSave
        if not _OnLoad then
            _OnLoad = inst.OnLoad
        end
        inst.OnLoad = OnLoad
    end)
end

do
    local _OnFinish
    local function OnFinish(inst, worker, ...)
        local _Remove = inst.Remove
        inst.Remove = function() end
        local ret = _OnFinish and _OnFinish(inst, worker, ...)
        if _Remove then inst.Remove = _Remove end
        inst:UMSetDemolished(true)
        return ret
    end

    local _OnSpawned
    local function OnSpawned(inst, child, ...)
        if child.UMSetPKGuard then child:UMSetPKGuard() end
        return _OnSpawned and _OnSpawned(inst, child, ...)
    end

    local function SetDemolished(inst, toggle)
        inst.um_demolished = toggle
        local spawner = inst.components.spawner
        if toggle then
            inst.Physics:ClearCollisionMask()
            inst:Hide()
            inst.components.fueled:InitializeFuelLevel(0)
            local timer = inst.components.timer
            if timer and not timer:TimerExists("um_rebuild") then
                timer:StartTimer("um_rebuild", 60 * 12)
            end
            if spawner then
                local spawner_child = spawner and not spawner:IsOccupied() and spawner.child and spawner.child:IsValid() and spawner.child
                if spawner_child then
                    spawner_child:PushEvent("detachchild")
                    local homeseeker = spawner_child.components.homeseeker
                    local home = homeseeker and homeseeker:GetHome()
                    if home then homeseeker.onhomeremoved(home) end
                end
                spawner:CancelSpawning()
            end
        else
            inst:Show()
            MakeObstaclePhysics(inst, .33)
            inst.components.workable:SetWorkLeft(4)
            if spawner then spawner:SpawnWithDelay(0) end
        end
    end

    local function Rebuild(inst, data)
        if data and data.name == "um_rebuild" then
            SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:UMSetDemolished()
        end
    end

    local function SetPKTorch(inst)
        inst.um_pktorch = true
        inst:AddTag("um_pktorch")

        local workable = inst.components.workable
        if workable then
            if not _OnFinish then
                _OnFinish = workable.onfinish
            end
            workable:SetOnFinishCallback(OnFinish)
        end

        local spawner = inst.components.spawner
        if spawner then
            if not _OnSpawned then
                _OnSpawned = spawner.onspawnedfn
            end
            spawner:SetOnSpawnedFn(OnSpawned)
        end

        inst.UMSetDemolished = SetDemolished

        inst:ListenForEvent("timerdone", Rebuild)
    end

    local _OnSave
    local function OnSave(inst, data, ...)
        if inst.um_pktorch then
            data.um_pktorch = inst.um_pktorch
            data.um_demolished = inst.um_demolished
        end
        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.um_pktorch then
            inst:UMSetPKTorch()
            if data.um_demolished then inst:UMSetDemolished(true) end
        end
        return _OnLoad and _OnLoad(inst, data, ...)
    end

    env.AddPrefabPostInit("pigtorch", function(inst)
        if not TheWorld.ismastersim then return end

        if not inst.components.timer then
            inst:AddComponent("timer")
        end

        inst.UMSetPKTorch = SetPKTorch

        if not _OnSave then
            _OnSave = inst.OnSave
        end
        inst.OnSave = OnSave
        if not _OnLoad then
            _OnLoad = inst.OnLoad
        end
        inst.OnLoad = OnLoad
    end)
end