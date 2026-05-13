local env = env
GLOBAL.setfenv(1, GLOBAL)


local moonmutables = {

	["reeds"] = {name = "reeds", result = "um_reeds_lunar"},
	["bee"] = {name = "bee", result = "um_bee_moon"},
	["killerbee"] = {name = "killerbee", result = "um_bee_moon"},
	["beehive"] = {name = "beehive", result = "um_beehive_moon"},
	["wasphive"] = {name = "wasphive", result = "um_beehive_moon"},
	["tentacle"] = {name = "tentacle", result = "um_tentacle_moon"},
	["red_mushroom"] = {name = "red_mushroom", result = "um_mushroom_moon"},
	["blue_mushroom"] = {name = "blue_mushroom", result = "um_mushroom_moon"},
	["green_mushroom"] = {name = "green_mushroom", result = "um_mushroom_moon"},
	--["spider_trapdoor_hooded"] = {result = "spider_moon"}, -- AXE Local functions required, do not do this here.
	--["spider_trapdoor"] = {result = "spider_moon"}, -- AXE Local functions required, do not do this here.
	-- ["um_buttery_fly"] = {result = "moonbutterfly"}, -- AXE Local functions required, do not do this here.
}

for i,v in pairs(moonmutables) do
	env.AddPrefabPostInit(v.name, function(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		inst:AddComponent("halloweenmoonmutable")
		inst.components.halloweenmoonmutable:SetPrefabMutated(v.result)

	end)
end