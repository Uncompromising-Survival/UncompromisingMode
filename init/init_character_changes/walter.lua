local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
--local UpvalueHacker = require("tools/upvaluehacker")
--local _OnHealthDelta = UpvalueHacker.GetUpvalue(Prefabs.walter.master_postinit, "OnHealthDelta")

--local timeleft = inst.components.timer:GetTimeLeft("um_walterpenalty_passiveheal")
--local health_drain = (1 - inst.components.health:GetPercentWithPenalty()) * TUNING.WALTER_SANITY_HEALTH_DRAIN * inst._sanity_damage_protection:Get()

local function VetCurseMaxSanityLoss(inst, data)
    local overtime = data and data.overtime or nil
    local amount = data.amount < 0 and data.amount -- you can do "overtime and 0" if freezing/overheating shouldn't count
    local sanitypenalty = amount and math.min(((math.abs(amount) * (overtime and 0.25 or 0.5)) / TUNING.WALTER_SANITY) * inst._sanity_damage_protection:Get() + inst.components.sanity:GetPenaltyPercent(), .75) or nil
    if sanitypenalty then
        inst.components.sanity:AddSanityPenalty(inst, sanitypenalty) --Basically, 1/4 of the sanity damage due to health loss.
        if not inst.components.timer:TimerExists("um_walterpenalty_passiveheal") then
            inst.components.timer:StartTimer("um_walterpenalty_passiveheal", TUNING.TOTAL_DAY_TIME)
        elseif inst.components.timer:IsPaused("um_walterpenalty_passiveheal") then
            inst.components.timer:ResumeTimer("um_walterpenalty_passiveheal")
        else
            inst.components.timer:SetTimeLeft("um_walterpenalty_passiveheal", TUNING.TOTAL_DAY_TIME)
        end
    end
    --_OnHealthDelta(inst,data)
end

local function OnPenaltyTimerDone(inst)
    local takethepenaltyaway = inst.components.sanity:GetPenaltyPercent() - .1
    inst.components.sanity:AddSanityPenalty(inst, math.max(takethepenaltyaway, 0))
    if inst.components.sanity:GetPenaltyPercent() ~= 0 then
        inst.components.timer:StartTimer("um_walterpenalty_passiveheal", TUNING.TOTAL_DAY_TIME)
    end
    inst.components.talker:Say(GetString(inst, "UM_WALTER_PENALTY_HEAL"))
end

local function ToggleUniqueVetCurse(inst, toggle)
    if toggle then
        inst:ListenForEvent("healthdelta", VetCurseMaxSanityLoss)
        inst:ListenForEvent("timerdone", OnPenaltyTimerDone)
    else
        inst:RemoveEventCallback("healthdelta", VetCurseMaxSanityLoss)
        inst:RemoveEventCallback("timerdone", OnPenaltyTimerDone)
    end
end

local _OnSave
local function OnSave(inst, data, ...)
    local penalty = inst.components.sanity:GetPenaltyPercent()
    if inst:HasTag("vetcurse") and penalty and penalty > 0 then
        data.um_walter_penalty = penalty
    end
    return _OnSave and _OnSave(inst, data, ...)
end

local _OnLoad
local function OnLoad(inst, data, ...)
    if data and data.um_walter_penalty then
        inst.components.sanity:AddSanityPenalty(inst, data.um_walter_penalty)
    end
    return _OnLoad and _OnLoad(inst, data, ...)
end

env.AddPrefabPostInit("walter", function(inst)
    if not TheWorld.ismastersim then return end
    if not _OnSave then
        _OnSave = inst.OnSave
    end
    inst.OnSave = OnSave
    if not _OnLoad then
        _OnLoad = inst.OnLoad
    end
    inst.OnLoad = OnLoad
    inst.UMToggleUniqueVetCurse = ToggleUniqueVetCurse
end)