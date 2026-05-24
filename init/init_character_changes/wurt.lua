local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")
-----------------------------------------------------------------



env.AddPrefabPostInit("wurt", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.UM_HORRIBLE_VEGGIE,   2)
    inst.components.foodaffinity:AddPrefabAffinity("rice_cooked",   1.33) -- prevents the negative stats, otherwise foodtypeaffinity would have suffice

	local WURT_PATHFINDER_TILES = UpvalueHacker.GetUpvalue(_G.Prefabs.wurt.fn, "master_postinit", "WURT_PATHFINDER_TILES")

	local WURT_PATHFINDER_TILES_UM = {
        WORLD_TILES.UM_FLOODWATER,
        WORLD_TILES.UM_FLOODWATER_GROTTO,
        WORLD_TILES.UM_FLOODWATER_BROILING,
    }

	for _, tile in ipairs(WURT_PATHFINDER_TILES_UM) do
        --inst.components.locomotor:SetFasterOnGroundTile(tile, true)
		table.insert(WURT_PATHFINDER_TILES, tile)
    end


end)