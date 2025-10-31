-- All character changes
AddPlayerPostInit(function(inst)
	inst:AddComponent("uncompromising_lungs")
	--inst:AddComponent("firerain")



	-- Terrorized
	inst.terror_immunity = net_smallbyte(inst.GUID, "terror_immunity", "terror_immunitydirty")
	inst.nightterror   =   net_smallbyte(inst.GUID, "nightterror", "nightterrordirty")
	if not TheWorld.ismastersim then
		return
	end
	inst:AddComponent("terrorized")
	
end)
