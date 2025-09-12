local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddPrefabPostInit("wurt", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.UM_GROSS_VEGGIE,   2)
    inst.components.foodaffinity:AddPrefabAffinity("rice_cooked",   1.33) -- prevents the negative stats, otherwise foodtypeaffinity would have suffice
end)