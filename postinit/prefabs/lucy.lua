local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("lucy", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local __oncontainerownerchanged = inst._oncontainerownerchanged
	
	
	inst._oncontainerownerchanged = function(container)
		__oncontainerownerchanged(inst, container)
	end
end)


-- Fix when return home, remember, Lucy is jumping off the forge when you try to modify her