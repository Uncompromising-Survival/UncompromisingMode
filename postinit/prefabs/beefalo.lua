local env = env
GLOBAL.setfenv(1, GLOBAL)

local function OnRiderChanged(inst, data)
	local rider = inst.components.rideable ~= nil and inst.components.rideable:GetRider()

	if rider ~= nil and rider.components.skilltreeupdater ~= nil and rider.components.skilltreeupdater:IsActivated("wathgrithr_beefalo_3") then
		inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT
	else
		inst.components.combat.damagemultiplier = 1
	end
end

local function OnBrushed(inst)
    if inst.components.health:IsDead() then
        return
    end

    if numprizes > 0 and inst.components.domesticatable ~= nil then -- Ratios suggested to improve by 夢我夢中
        inst.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_BRUSHED_DOMESTICATION*(2/1.67), doer)
        inst.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_BRUSHED_OBEDIENCE*(10/4))
    end
end

-- Widow drops tusk guaranteed, there has to be some reason to use the tusk if you're using a beefalo, the brush is the most intuitive and should be better than it currently is.
env.AddPrefabPostInit("beefalo", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	if TUNING.DSTU.WATHGRITHR_REWORK == 1 then
		inst:ListenForEvent("riderchanged", OnRiderChanged)
	end
	
	
	inst.components.brushable:SetOnBrushed(OnBrushed)
end)
