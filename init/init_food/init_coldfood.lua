local EDIBLES = 
{
	"ice",
	"blueamulet",
	"icestaff",
	"um_ghost_pepper_item",
	"um_ice_tail",
	"um_ice_sicle",
	"bluegem",
	"um_rimeweed_itemvine",
	"um_rimeweed_itemflower",
	"rimeweed_whip",
	"um_hat_rime",
	"um_rimeweed_tequila",
	"um_rimeweed_spagett",
	"um_ghost_fajita",
}

GLOBAL.FOODTYPE.COLDFOOD = "COLDFOOD"
table.insert(GLOBAL.FOODGROUP.OMNI.types,GLOBAL.FOODTYPE.COLDFOOD)

local function AddEdibles(prefab)
	AddPrefabPostInit(prefab, function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		if not inst.components.edible then
			inst:AddComponent("edible")
		end
		inst.components.edible.secondaryfoodtype = GLOBAL.FOODTYPE.COLDFOOD
		if not inst.components.edible.foodtype then
			inst.components.edible.foodtype = GLOBAL.FOODTYPE.ELEMENTAL
		end
	end)
end

for k, v in pairs(EDIBLES) do
	AddEdibles(v)
end