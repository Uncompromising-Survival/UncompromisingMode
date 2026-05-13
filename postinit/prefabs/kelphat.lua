local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("kelphat", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:AddComponent("heater")
	inst.components.heater:SetThermics(false, true)
	inst.components.heater.equippedheat = TUNING.WATERMELON_COOLER

	inst.components.equippable.equippedmoisture = 0.5
	inst.components.equippable.maxequippedmoisture = 32 -- Meter reading rounds up, so set 1 below
	
	inst:AddComponent("insulator")
	inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
	inst.components.insulator:SetSummer()
end)