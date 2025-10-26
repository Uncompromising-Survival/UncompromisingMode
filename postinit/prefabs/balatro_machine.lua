local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddPrefabPostInit("balatro_machine", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	-- Postinit for later
end)
