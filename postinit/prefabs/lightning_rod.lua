local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("lightning_rod", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    -- Expose function to allow other sources to charge it
    local onlightning = UpvalueHacker.GetUpvalue(Prefabs.lightning_rod.fn, "onlightning")
    inst.onlightningfn = onlightning
end)


