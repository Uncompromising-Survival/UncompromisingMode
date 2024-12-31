local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
local env = env
GLOBAL.setfenv(1, GLOBAL)


env.AddPrefabPostInit("mushgnome_spawner", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	local TEST_FREQUENCY = 1
	UpvalueHacker.SetUpvalue(Prefabs.mushgnome_spawner.fn, TEST_FREQUENCY, "on_entity_wake", "StartTesting", "TEST_FREQUENCY")
	UpvalueHacker.SetUpvalue(Prefabs.mushgnome_spawner.fn, TEST_FREQUENCY, "StartTesting", "TEST_FREQUENCY")


	--return inst
end)
