local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("bullkelp_root", function(inst)
	if not TheWorld.ismastersim then
		return
	end
    inst.components.weapon:SetOnAttack()
end)