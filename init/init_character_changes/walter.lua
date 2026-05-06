local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
--local UpvalueHacker = require("tools/upvaluehacker")
--local _OnHealthDelta = UpvalueHacker.GetUpvalue(Prefabs.walter.master_postinit, "OnHealthDelta")

--local timeleft = inst.components.timer:GetTimeLeft("um_walterpenalty_passiveheal")
--local health_drain = (1 - inst.components.health:GetPercentWithPenalty()) * TUNING.WALTER_SANITY_HEALTH_DRAIN * inst._sanity_damage_protection:Get()


local function VetCurseMaxSanityLoss(inst, data)
    if inst:HasTag("vetcurse") then
        local overtime = data and data.overtime or nil
        local amount = data.amount < 0 and data.amount or 0 -- you can do "overtime and 0" if freezing/overheating shouldn't count
        local sanitypenalty = math.min(((math.abs(amount) * (overtime and 0.25 or 0.5)) / TUNING.WALTER_SANITY) * inst._sanity_damage_protection:Get() + inst.components.sanity:GetPenaltyPercent(), .75)
        inst.components.sanity:AddSanityPenalty(inst, sanitypenalty) --Basically, 1/4 of the sanity damage due to health loss.
        if not inst.components.timer:TimerExists("um_walterpenalty_passiveheal") then
            inst.components.timer:StartTimer("um_walterpenalty_passiveheal", TUNING.TOTAL_DAY_TIME)
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
end

local function ToggleUniqueVetCurse(inst, toggle)
    if toggle then
        inst:ListenForEvent("healthdelta", VetCurseMaxSanityLoss)
        --inst:ListenForEvent("attacked", VetCurseMaxSanityLoss)
        --UpvalueHacker.SetUpvalue(Prefabs.walter.master_postinit, OnHealthDelta, "OnHealthDelta")
        inst:ListenForEvent("timerdone", OnPenaltyTimerDone)
    else
        inst:RemoveEventCallback("healthdelta", VetCurseMaxSanityLoss)
        inst:RemoveEventCallback("timerdone", OnPenaltyTimerDone)
    end
end

env.AddPrefabPostInit("walter", function(inst)
    if not TheWorld.ismastersim then return end
    inst.UMToggleUniqueVetCurse = ToggleUniqueVetCurse
end)