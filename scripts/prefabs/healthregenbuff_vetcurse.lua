local function GetDuration(duration)
    -- Sync the buff tick rate with the game's tick rate.
    return math.floor(duration / FRAMES) * FRAMES
end

local function IsWarlyBuffed(target)
    return target:HasTag("warlybuffed") and (target:HasTag("vetcurse") and 1.8 or 2) or target:HasTag("vetcurse_wormwood") and .6 or target:HasTag("vetcurse") and .8 or 1
end

local function HealthOnTick(inst, target, data)
    local duration = GetDuration(data and data.duration or 1)
    if target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") then
        local delta = duration or 1
        if data and data.negative_value then
            delta = -duration or -1
        end
        target.components.health:DoDelta(delta, nil, inst.prefab)
    else
        inst.components.debuff:Stop()
    end
end

local function HealthOnAttached(inst, target, followsymbol, followoffset, data)
    local warlybuff = IsWarlyBuffed(target)
    local duration = GetDuration((data and data.duration and data.duration / 2 or 1) / warlybuff)

    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    inst.task = inst:DoPeriodicTask(duration or 1, HealthOnTick, nil, target, data)

    local newduration = ((duration * 10) + .01)
    inst.components.timer:StartTimer("regenover", newduration or 1)

    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function HealthOnTimerDone(inst, data)
    if data.name == "regenover" then inst.components.debuff:Stop() end
end

local function HealthOnExtended(inst, target, followsymbol, followoffset, data)
    local warlybuff = IsWarlyBuffed(target)
    local duration = GetDuration((data and data.duration and data.duration / 2 or 1) / warlybuff)
    local time_remaining = inst.components.timer:GetTimeLeft("regenover")
    if time_remaining then
        local oldduration = duration * 10
        local newduration = time_remaining + oldduration
        if newduration < oldduration * 4 or data and data.negative_value then
            local finalduration = time_remaining + oldduration
            inst.components.timer:SetTimeLeft("regenover", finalduration)
        else
            inst.components.timer:SetTimeLeft("regenover", oldduration * 4)
        end
    else
        inst.components.timer:StartTimer("regenover", duration * 10)
    end
end

local function fn_health()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(HealthOnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.components.debuff:SetExtendedFn(HealthOnExtended)
    inst.components.debuff.keepondespawn = false

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", HealthOnTimerDone)

    return inst
end

local function SanityOnTick(inst, target, data)
    local duration = GetDuration(data and data.duration or 1)
    if target.components.health and not target.components.health:IsDead() and target.components.sanity and not target:HasTag("playerghost") then
        target.components.sanity:DoDelta(duration or 1, nil, inst.prefab)
    else
        inst.components.debuff:Stop()
    end
end

local function SanityOnAttached(inst, target, followsymbol, followoffset, data)
    local warlybuff = IsWarlyBuffed(target)
    local duration = GetDuration((data and data.duration and data.duration / 2 or 1) / warlybuff)

    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    inst.task = inst:DoPeriodicTask(duration or 1, SanityOnTick, nil, target, data)

    local newduration = ((duration * 10) + .01)
    inst.components.timer:StartTimer("regenover", newduration or 1)

    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function SanityOnTimerDone(inst, data)
    if data.name == "regenover" then inst.components.debuff:Stop() end
end

local function SanityOnExtended(inst, target, followsymbol, followoffset, data)
    local warlybuff = IsWarlyBuffed(target)
    local duration = GetDuration((data and data.duration and data.duration / 2 or 1) / warlybuff)
    local time_remaining = inst.components.timer:GetTimeLeft("regenover")
    if time_remaining then
        local oldduration = duration * 10
        local newduration = time_remaining + oldduration
        if newduration < oldduration * 4 then
            local finalduration = time_remaining + oldduration
            inst.components.timer:SetTimeLeft("regenover", finalduration)
        else
            inst.components.timer:SetTimeLeft("regenover", oldduration * 4)
        end
    else
        inst.components.timer:StartTimer("regenover", duration * 10)
    end
end

local function fn_sanity()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(SanityOnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.components.debuff:SetExtendedFn(SanityOnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", SanityOnTimerDone)

    return inst
end

local function HungerOnTick(inst, target, data)
    local duration = GetDuration(data and data.duration or 1)
    if target.components.health and not target.components.health:IsDead() and target.components.hunger and not target:HasTag("playerghost") then
        target.components.hunger:DoDelta(duration or 1, nil, inst.prefab)
    else
        inst.components.debuff:Stop()
    end
end

local function HungerOnAttached(inst, target, followsymbol, followoffset, data)
    local warlybuff = IsWarlyBuffed(target)
    local duration = GetDuration((data and data.duration and data.duration / 2 or 1) / warlybuff)

    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    inst.task = inst:DoPeriodicTask(duration or 1, HungerOnTick, nil, target, data)

    local newduration = ((duration * 10) + .01)
    inst.components.timer:StartTimer("regenover", newduration or 1)

    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function HungerOnTimerDone(inst, data)
    if data.name == "regenover" then inst.components.debuff:Stop() end
end

local function HungerOnExtended(inst, target, followsymbol, followoffset, data)
    local warlybuff = IsWarlyBuffed(target)
    local duration = GetDuration((data and data.duration and data.duration / 2 or 1) / warlybuff)
    local time_remaining = inst.components.timer:GetTimeLeft("regenover")
    if time_remaining then
        local oldduration = duration * 10
        local newduration = time_remaining + oldduration
        if newduration < oldduration * 4 then
            local finalduration = time_remaining + oldduration
            inst.components.timer:SetTimeLeft("regenover", finalduration)
        else
            inst.components.timer:SetTimeLeft("regenover", oldduration * 4)
        end
    else
        inst.components.timer:StartTimer("regenover", duration * 10)
    end
end

local function fn_hunger()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(HungerOnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.components.debuff:SetExtendedFn(HungerOnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", HungerOnTimerDone)

    return inst
end

local function HayfeverOnTick(inst, target, data)
    local intensity = data and data.intensity or -1
    if target.components.health and not target.components.health:IsDead()
        and target.components.UM_hayfever and target.components.UM_hayfever.enabled and not target:HasTag("playerghost") then
        target.components.UM_hayfever:DoDelta(intensity)
    else
        inst.components.debuff:Stop()
    end
end

local function HayfeverOnAttached(inst, target, followsymbol, followoffset, data)
    local duration = GetDuration(data and data.duration or 1)

    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    inst.task = inst:DoPeriodicTask(1, HayfeverOnTick, nil, target, data)

    inst.components.timer:StartTimer("regenover", duration or 1)

    inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
end

local function HayfeverOnTimerDone(inst, data)
    if data.name == "regenover" then inst.components.debuff:Stop() end
end

local function HayfeverOnExtended(inst, target, followsymbol, followoffset, data)
    local duration = GetDuration(data and data.duration or 1)
    local time_remaining = inst.components.timer:GetTimeLeft("regenover")
    if time_remaining then
        local oldduration = duration
        local newduration = time_remaining + oldduration
        if newduration < oldduration * 4 then
            local finalduration = time_remaining + oldduration
            inst.components.timer:SetTimeLeft("regenover", finalduration)
        else
            inst.components.timer:SetTimeLeft("regenover", oldduration * 4)
        end
    else
        inst.components.timer:StartTimer("regenover", duration)
    end
end

local function fn_hayfever()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(HayfeverOnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.components.debuff:SetExtendedFn(HayfeverOnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", HayfeverOnTimerDone)

    return inst
end

return Prefab("healthregenbuff_vetcurse", fn_health),
    Prefab("healthregenbuff_vetcurse_soul", fn_health),
    Prefab("healthregenbuff_vetcurse_walter_curse", fn_health),
    Prefab("sanityregenbuff_vetcurse", fn_sanity),
    Prefab("hungerregenbuff_vetcurse", fn_hunger),
    Prefab("hayfeverbuff", fn_hayfever)