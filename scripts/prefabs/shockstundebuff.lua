local UpvalueHacker = require("tools/upvaluehacker")
local OldHitRecoverDelay = CommonHandlers.HitRecoveryDelay
CommonHandlers.HitRecoveryDelay = function(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
    if inst.um_forcestundebuff then
        inst.um_forcestundebuff = nil
        return false
    end
    return OldHitRecoverDelay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
end

local Oldhit_recovery_delay = UpvalueHacker.GetUpvalue(CommonHandlers.OnAttacked, "onattacked", "hit_recovery_delay")
if Oldhit_recovery_delay then
    local function hit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
        if inst.um_forcestundebuff then
            inst.um_forcestundebuff = nil
            return false
        end
        return Oldhit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
    end
    UpvalueHacker.SetUpvalue(CommonHandlers.OnAttacked, hit_recovery_delay, "onattacked", "hit_recovery_delay")
end

local minotaur = require("stategraphs/SGminotaur") -- This needs to be patched on Klei's side.
local minotaurattackedeventhandler = minotaur.events["attacked"]
if minotaurattackedeventhandler then
    local Oldhit_recovery_delay_minotaur = UpvalueHacker.GetUpvalue(minotaurattackedeventhandler.fn, "hit_recovery_delay")
    local option = 1
    if not Oldhit_recovery_delay_minotaur then
        Oldhit_recovery_delay_minotaur = UpvalueHacker.GetUpvalue(minotaurattackedeventhandler.fn, "_OldAttackedEvent", "hit_recovery_delay")
        option = 2
    end
    if Oldhit_recovery_delay_minotaur then
        local function hit_recovery_delay(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
            if inst.um_forcestundebuff then
                inst.um_forcestundebuff = nil
                return false
            end
            return Oldhit_recovery_delay_minotaur(inst, delay, max_hitreacts, skip_cooldown_fn, ...)
        end
        if option == 1 then
            UpvalueHacker.SetUpvalue(minotaurattackedeventhandler.fn, hit_recovery_delay, "hit_recovery_delay")
        else
            UpvalueHacker.SetUpvalue(minotaurattackedeventhandler.fn, hit_recovery_delay, "_OldAttackedEvent", "hit_recovery_delay")
        end
    end
end

local removetaglist = {"busy", "hit", "attack", "nointerrupt", "nohit", "jumping", "notiredhit", "moving"}
local function OhCrap(inst, target)
    if not (target.components.health and target.components.health:IsDead()) and not target:HasTag("playerghost") then
        SpawnPrefab("electricchargedfx"):SetTarget(target)
        target.components.health:DoDelta(-2, nil, "Electricity")
        if target.brain then
            target.brain:Stop()
        end
        if target.sg and target.sg.currentstate and target.sg.currentstate.name ~= "shield_start" and target.sg.currentstate.name ~= "shield" then
            for _, tag in pairs(removetaglist) do
                if target.sg:HasStateTag(tag) then
                    target.sg:RemoveStateTag(tag)
                end
            end
            if not target.sg:HasStateTag("caninterrupt") then
                target.sg:AddStateTag("caninterrupt")
            end
            target.um_forcestundebuff = true
        end
        target:PushEvent("attacked", {attacker = target.shock_owner or nil, damage = 2})
        if target.components.combat and target.components.combat.laststartattacktime then
            target.components.combat.laststartattacktime = target.components.combat.laststartattacktime + 0.2 --This apparently resets the targets attack timer making it a true "stun"
        end
    else
        inst.components.debuff:Stop()
    end
end

local function OnAttached(inst, target)
    if not target:HasTag("electricstunimmune") then
        target:AddDebuff("shockstundebuffimmunity", "shockstundebuffimmunity")
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst.task = inst:DoPeriodicTask(0.2, OhCrap, nil, target)
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        SpawnPrefab("electricchargedfx"):SetTarget(target)
    else
        inst.components.debuff:Stop()
    end
end

local function OnRemoved(inst, target)
    if target.brain and not (target.components.health and target.components.health:IsDead()) then
        target.brain:Start()
    end
    if target.shock_owner then
        target.shock_owner = nil
    end
end

local function OnTimerDone(inst, data)
    if data.name == "stunover" then
        inst.components.debuff:Stop()
        if inst.task ~= nil then
            inst.task:Cancel()
        end
    end
end

local function OnExtended(inst, target)
    --[[if not target:HasTag("electricstunimmune") then
    inst.components.timer:StopTimer("stunover")
    inst.components.timer:StartTimer("stunover", 1.2)
    inst.task:Cancel()
    inst.task = inst:DoPeriodicTask(0.2, OhCrap, nil, target)
    end]]
end

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
    inst.components.debuff:SetDetachedFn(OnRemoved)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("stunover", 1.2)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("shockstundebuff", fn)