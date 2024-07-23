local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("lava_pond", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	inst:AddComponent("watersource")
end)
