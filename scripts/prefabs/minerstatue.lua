local assets =
{
    Asset("ANIM", "anim/minerstatue.zip"),
    Asset("MINIMAP_IMAGE", "statue_ruins"),
}

local prefabs =
{
    "nightmarefuel",
    "collapse_small",
    "thulecite",
}

local MAX_LIGHT_ON_FRAME = 15
local MAX_LIGHT_OFF_FRAME = 30

local function OnUpdateLight(inst, dframes)
    local frame = inst._lightframe:value() + dframes
    if frame >= inst._lightmaxframe then
        inst._lightframe:set_local(inst._lightmaxframe)
        inst._lighttask:Cancel()
        inst._lighttask = nil
    else
        inst._lightframe:set_local(frame)
    end

    local k = frame / inst._lightmaxframe
    inst.Light:SetRadius(inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k))

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._lightradius1:value() > 0 or frame < inst._lightmaxframe)
    end
end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    inst._lightmaxframe = inst._lightradius1:value() > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
    OnUpdateLight(inst, 0)
end

local function DoFx(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 2, 1)
    end
    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 1.5, 1)
    end
end

local function fade_to(inst, rad, instant)
    rad = rad or 0
    if inst._lightradius1:value() ~= rad then
        local k = inst._lightframe:value() / inst._lightmaxframe
        local radius = inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k)
        local minradius0 = math.min(inst._lightradius0:value(), inst._lightradius1:value())
        local maxradius0 = math.max(inst._lightradius0:value(), inst._lightradius1:value())
        if radius > rad then
            inst._lightradius0:set(radius > minradius0 and maxradius0 or minradius0)
        else
            inst._lightradius0:set(radius < maxradius0 and minradius0 or maxradius0)
        end
        local maxframe = rad > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
        inst._lightradius1:set(rad)
        inst._lightframe:set(
            instant and
            (rad > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME) or
            math.max(0, math.floor((radius - inst._lightradius0:value()) / (rad - inst._lightradius0:value()) * maxframe + .5))
        )
        OnLightDirty(inst)
    end
end

local function ShowWorkState(inst, worker, workleft)
    --NOTE: worker is nil when called from ShowPhaseState
    inst.AnimState:PlayAnimation(
        ((workleft < TUNING.MARBLEPILLAR_MINE / 3 and "idle_low") or
            (workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 and "idle_med") or
            "idle_full"
        ) .. (inst._suffix or ""),
        true
    )
end

local function OnWorkFinished(inst, worker)
    inst.components.lootdropper:DropLoot(inst:GetPosition())

    local fx = SpawnAt("collapse_small", inst)
    fx:SetMaterial("rock")

    if TheWorld.state.isnightmarewild and
        TryLuckRoll(worker, TUNING.STATUERUINS_SPAWN_NIGHTMARE_CHANCE, LuckFormulas.StatueSpawnNightmare) then
        SpawnAt(TryLuckRoll(worker, .5, LuckFormulas.TerrorbeakSpawn) and "nightmarebeak" or "crawlingnightmare", inst)
    end

    inst:Remove()
end

local function ShowPhaseState(inst, phase, instant)
    inst._phasetask = nil

    if phase == "wild" then
        fade_to(inst, 4, instant)

        if inst._suffix == nil then
            inst._suffix = "_shadow"
            if not instant then
                DoFx(inst)
            end
        end

        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    else
        fade_to(inst, (phase == "warn" or phase == "dawn") and 2 or 0, instant)

        if inst._suffix ~= nil then
            inst._suffix = nil
            if not instant then
                DoFx(inst)
            end
        end

        inst.AnimState:ClearBloomEffectHandle()
    end

    ShowWorkState(inst, nil, inst.components.workable.workleft)
end

local function OnNightmarePhaseChanged(inst, phase, instant)
    if inst._phasetask ~= nil then
        inst._phasetask:Cancel()
    end
    if instant or inst:IsAsleep() then
        ShowPhaseState(inst, phase, true)
    else
        inst._phasetask = inst:DoTaskInTime(math.random() * 2, ShowPhaseState, phase)
    end
end


local function OnEntitySleep(inst)
    if inst._phasetask ~= nil then
        inst._phasetask:Cancel()
        ShowPhaseState(inst, TheWorld.state.nightmarephase, true)
    end
end


local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.66)

    inst.AnimState:SetBank("minerstatue")
    inst.AnimState:SetBuild("minerstatue")


    inst.MiniMapEntity:SetIcon("statue_ruins.png")

    inst:AddTag("cavedweller")
    inst:AddTag("structure")
    inst:AddTag("statue")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.9)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "ruins_statue._lightframe", "lightdirty")
    inst._lightradius0 = net_tinybyte(inst.GUID, "ruins_statue._lightradius0", "lightdirty")
    inst._lightradius1 = net_tinybyte(inst.GUID, "ruins_statue._lightradius1", "lightdirty")
    inst._lightmaxframe = MAX_LIGHT_OFF_FRAME
    inst._lightframe:set(inst._lightmaxframe)
    inst._lighttask = nil

    inst:SetPrefabNameOverride("ancient_statue")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(ShowWorkState)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    inst:DoTaskInTime(0, function() --for setpiece.
        ShowWorkState(inst, nil, inst.components.workable.workleft)
    end)

    inst:AddComponent("lootdropper")

    inst:WatchWorldState("nightmarephase", OnNightmarePhaseChanged)
    OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase, true)

    MakeHauntableWork(inst)
    MakeRoseTarget_CreateFuel_IncreasedHorror(inst)

    inst.OnEntitySleep = OnEntitySleep

    return inst
end

local function nogem()
    local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('statue_ruins_no_gem')

    return inst
end


return Prefab("ruins_statue_miner", function() return nogem() end, assets, prefabs)
