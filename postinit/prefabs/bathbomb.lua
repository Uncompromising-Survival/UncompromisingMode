local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("bathbomb", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	inst.components.perishable:SetPerishTime(8*60*30*1.5)
end)