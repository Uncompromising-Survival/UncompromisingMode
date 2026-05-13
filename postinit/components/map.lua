local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("world", function(inst)
	local Map = getmetatable(inst.Map).__index
	local _IsDeployPointClear = Map.IsDeployPointClear
	Map.IsDeployPointClear = function(Map, pt, inst, min_spacing, min_spacing_sq_fn, near_other_fn, check_player, custom_ignore_tags)
		
		if pt ~= nil and pt.x ~= nil then
			local x = pt.x
			local z = pt.z
			
			local portaboat = TheSim:FindEntities(x, 0, z, 4, {"portableraft"})
			if portaboat ~= nil and #portaboat > 0 then
				return false
			end
		end

		return _IsDeployPointClear(Map, pt, inst, min_spacing, min_spacing_sq_fn, near_other_fn, check_player, custom_ignore_tags)
	end

	-- AXE Postinit placing functions, tell them to not allow building on floodwaters...
	local _CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint
	Map.CanDeployRecipeAtPoint = function(Map,pt, recipe, rot,...)
		if pt ~= nil and pt.x ~= nil then
			local tile = Map.GetTileAtPoint(Map,pt.x, pt.y, pt.z)
			if tile == WORLD_TILES.UM_FLOODWATER or tile == WORLD_TILES.UM_FLOODWATER_GROTTO then
				return false
			end
		end

		return _CanDeployRecipeAtPoint(Map,pt, recipe, rot,...)
	end

	local _CanPlantAtPoint = Map.CanPlantAtPoint
	Map.CanPlantAtPoint = function(Map,x, y, z)
		if x then
			local tile = Map.GetTileAtPoint(Map,x,y,z)
			if tile == WORLD_TILES.UM_FLOODWATER or tile == WORLD_TILES.UM_FLOODWATER_GROTTO then
				return false
			end
		end

		return _CanPlantAtPoint(Map,x, y, z)
	end

	local _CanDeployPlantAtPoint = Map.CanDeployPlantAtPoint
	Map.CanDeployPlantAtPoint = function(Map,pt, inst, mouseover)
		if pt and pt.x then
			local tile = Map.GetTileAtPoint(Map,pt.x,pt.y,pt.z)
			if tile == WORLD_TILES.UM_FLOODWATER or tile == WORLD_TILES.UM_FLOODWATER_GROTTO then
				return false
			end
		end

		return _CanDeployPlantAtPoint(Map,pt, inst, mouseover)
	end

	local _CanDeployAtPoint = Map.CanDeployAtPoint
	Map.CanDeployAtPoint= function(Map,pt, inst, mouseover)
		if pt and pt.x then
			local tile = Map.GetTileAtPoint(Map,pt.x,pt.y,pt.z)
			if tile == WORLD_TILES.UM_FLOODWATER or tile == WORLD_TILES.UM_FLOODWATER_GROTTO then
				return false
			end
		end

		return _CanDeployAtPoint(Map,pt, inst, mouseover)
	end

		
end)