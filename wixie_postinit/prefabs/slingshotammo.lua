local env = env
GLOBAL.setfenv(1, GLOBAL)

local basic =
{
	"slingshotammo_rock",
	"slingshotammo_gold",
	"slingshotammo_marble",
	"slingshotammo_poop",
	"trinket_1",
}

for i, v in ipairs(basic) do
	env.AddPrefabPostInit(v, function(inst)
		inst:AddTag("wixieammo_basic")
		
		if not TheWorld.ismastersim then
			return
		end
	
		if inst.components.edible ~= nil then
			inst.components.edible.hungervalue = 0
		end
	end)
end

local special =
{
	"slingshotammo_thulecite",
	"slingshotammo_freeze",
	"slingshotammo_slow",
}

for i, v in ipairs(special) do
	env.AddPrefabPostInit(v, function(inst)
		inst:AddTag("wixieammo_special")
		
		if not TheWorld.ismastersim then
			return
		end
	
		if inst.components.edible ~= nil then
			inst.components.edible.hungervalue = 0
		end
	end)
end