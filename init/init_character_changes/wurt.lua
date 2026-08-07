local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")
-----------------------------------------------------------------



env.AddPrefabPostInit("wurt", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	--inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.UM_HORRIBLE_VEGGIE, 2)
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

local lunar_merms = {
    "mermguard_lunar",
    "merm_lunar",
}

for _, prefab in ipairs(lunar_merms) do
	env.AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end

		local _OnChangedLeaderLunar = inst.components.follower.OnChangedLeader

		local function OnChangedLeaderLunar(inst, new_leader, prev_leader, ...)
			if TUNING.DSTU.MERMTWEAKS then
				return
			else
				return _OnChangedLeaderLunar(inst, new_leader, prev_leader, ...)
			end
		end

		inst.components.follower.OnChangedLeader = OnChangedLeaderLunar

		--Infinite merms followers feel too convenient, if I can just make lunar merms have a huge loyalty time and loyalty per food... -CB
		--local loyalty_max = (isguard and TUNING.MERM_GUARD_LOYALTY_MAXTIME) or TUNING.MERM_LOYALTY_MAXTIME
		--local loyalty_time = item.components.edible:GetHunger() * loyalty_per_hunger
		--inst.components.follower.maxfollowtime = loyalty_max
		--inst.components.follower:AddLoyaltyTime(loyalty_time)

	end)
end