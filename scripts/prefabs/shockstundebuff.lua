local UpvalueHacker = require("tools/upvaluehacker")
local _HitRecoverDelay = CommonHandlers.HitRecoveryDelay
CommonHandlers.HitRecoveryDelay = function(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
    if inst.um_forcestundebuff then return false end
    return _HitRecoverDelay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
end

local _hit_recovery_delay = UpvalueHacker.GetUpvalue(CommonHandlers.OnAttacked, "onattacked", "hit_recovery_delay")
if _hit_recovery_delay then
    local function hit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
        if inst.um_forcestundebuff then return false end
        return _hit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
    end
    UpvalueHacker.SetUpvalue(CommonHandlers.OnAttacked, hit_recovery_delay, "onattacked", "hit_recovery_delay")
end

local removetaglist = {"busy", "hit", "attack", "nointerrupt", "nohit", "jumping", "notiredhit"}
local function OhCrap(inst, target, attacker)
    if not (target.components.health and target.components.health:IsDead()) and not target:HasTag("playerghost") then
        SpawnPrefab("electricchargedfx"):SetTarget(target)
        --target.components.health:DoDelta(-2, nil, "Electricity")
        if target.brain then target.brain:Stop() end
        if target.components.locomotor then target.components.locomotor:Stop() end
        if target.sg and target.sg.currentstate and target.sg.currentstate.name ~= "shield_start" and target.sg.currentstate.name ~= "shield"
            and not target.sg:HasAnyStateTag("electrocute", "channeling") then
            for _, tag in pairs(removetaglist) do
                if target.sg:HasStateTag(tag) then target.sg:RemoveStateTag(tag) end
            end
            if not target.sg:HasStateTag("caninterrupt") then target.sg:AddStateTag("caninterrupt") end
            if not target.um_forcestundebuff then target.um_forcestundebuff = true end
        end
        if not target:HasTag("forcestunned") then target:AddTag("forcestunned") end
        target:PushEvent("attacked", {attacker = attacker, damage = 0, stimuli = "soul"})
        if target.components.combat then
            --[[if target.components.combat.laststartattacktime then
                target.components.combat.laststartattacktime = target.components.combat.laststartattacktime + .2 -- This apparently resets the targets attack timer making it a true "stun".
            end]]
            if target.components.combat.hurtsound then
                target.SoundEmitter:PlaySound(target.components.combat.hurtsound)
            end
        end
    else
        inst.components.debuff:Stop()
    end
end

local _CalcEntityElectrocuteDuration = CalcEntityElectrocuteDuration
function CalcEntityElectrocuteDuration(inst, override, ...)
    local val = _CalcEntityElectrocuteDuration(inst, override, ...)
    if inst:HasTag("extended_shock_duration") then val = val * 2.5 end
    return val
end

local function OnAttached(inst, target, followsymbol, followoffset, data)
    if not target:HasTag("electricstunimmune") then
        target:AddDebuff("shockstundebuffimmunity", "shockstundebuffimmunity")
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading

        if target.sg and target.sg:HasState("electrocute") and not IsEntityElectricImmune(target) then
            if not target:HasTag("extended_shock_duration") then target:AddTag("extended_shock_duration") end
            -- Force once again into elec. state because first hit runs it *before* this tag is added.
            target.sg:GoToState("electrocute")
        else -- Only do normal shockstundebuff if doesn't have a shock state, otherwise its handled by global CalcEntityElectrocuteDuration
			inst.task = inst:DoPeriodicTask(.2, OhCrap, nil, target, data and data.attacker)
		end
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
        SpawnPrefab("electricchargedfx"):SetTarget(target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
    if target and target:IsValid() then
        if target:HasTag("extended_shock_duration") then target:RemoveTag("extended_shock_duration") end
        if target.brain and not (target.components.health and target.components.health:IsDead()) then target.brain:Start() end
        if target:HasTag("forcestunned") then target:RemoveTag("forcestunned") end
        if target.um_forcestundebuff then target.um_forcestundebuff = nil end
    end
    inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "stunover" then
        inst.components.debuff:Stop()
        if inst.task then inst.task:Cancel() end
    end
end

--[[local function OnExtended(inst, target)
    if not target:HasTag("electricstunimmune") then
        inst.components.timer:StopTimer("stunover")
        inst.components.timer:StartTimer("stunover", 1.2)
        inst.task:Cancel()
        inst.task = inst:DoPeriodicTask(0.2, OhCrap, nil, target)
    end
end]]

local function fn()
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
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    --inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("stunover", 1.2)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("shockstundebuff", fn)