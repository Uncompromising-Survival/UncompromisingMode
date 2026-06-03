local env = env
GLOBAL.setfenv(1, GLOBAL)

local trade_prefabs = {"coontail", "hambat", "tentaclespots"}
if TUNING.DSTU.LONGPIG then
	table.insert(trade_prefabs, "reviver")
end
for i,v in ipairs(trade_prefabs) do
	env.AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then return end

		if not inst.components.tradable then
			inst:AddComponent("tradable")
		end

		if v == "coontail" then
			inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT
		else
			inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT*2
		end
	end)
end