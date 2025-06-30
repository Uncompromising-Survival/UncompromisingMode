local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
--local UpvalueHacker = require("tools/upvaluehacker")
--local _OnHealthDelta = UpvalueHacker.GetUpvalue(Prefabs.walter.master_postinit, "OnHealthDelta")

--local timeleft = inst.components.timer:GetTimeLeft("um_walterpenalty_passiveheal")
--local health_drain = (1 - inst.components.health:GetPercentWithPenalty()) * TUNING.WALTER_SANITY_HEALTH_DRAIN * inst._sanity_damage_protection:Get()

local function VetCurseMaxSanityLoss(inst, data)
    if inst:HasTag("vetcurse") then
        local sanitypenalty = math.min((((data.damageresolved or data.damage) * 0.5) / TUNING.WALTER_SANITY) * inst._sanity_damage_protection:Get() + inst.components.sanity:GetPenaltyPercent(), .75)
		inst.components.sanity:AddSanityPenalty(inst, sanitypenalty)
		if not inst.components.timer:TimerExists("um_walterpenalty_passiveheal") then
			inst.components.timer:StartTimer("um_walterpenalty_passiveheal", TUNING.TOTAL_DAY_TIME)
		--[[else
			inst.components.timer:SetTimeLeft("um_walterpenalty_passiveheal", timeleft + health_drain)]]--
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

env.AddPrefabPostInit("walter", function(inst) 
	if not TheWorld.ismastersim then
		return
	end
	inst:ListenForEvent("attacked", VetCurseMaxSanityLoss)
    --inst:RemoveEventCallback("healthdelta",_OnHealthDelta)
    --UpvalueHacker.SetUpvalue(Prefabs.walter.master_postinit, OnHealthDelta, "OnHealthDelta")
	inst:ListenForEvent("timerdone", OnPenaltyTimerDone) --Question is, am I replacing OnAttacked and OnTimerDone? I dunno! -C
end)