local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
	if inst.components.weapon then
		inst:AddComponent("tradable")
	end
end)