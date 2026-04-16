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

env.AddPrefabPostInit("beefalo", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	if TUNING.DSTU.WATHGRITHR_REWORK.ENABLED then
		inst:ListenForEvent("riderchanged", OnRiderChanged)
	end
end)
