local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("world", function(inst)
	local Map = getmetatable(inst.Map).__index

	if Map.TileRendersOver == nil then
		local tiledefs = require("worldtiledefs")
		local RenderTileOrder = {}
		for i, v in ipairs(tiledefs.ground) do RenderTileOrder[v[1]] = i end
		function Map:TileRendersOver(tile1, tile2)
			return (RenderTileOrder[tile1] or 0) > (RenderTileOrder[tile2] or 0)
		end
	end

	if Map.IsUMLavaTile == nil then
		function Map:IsUMLavaTile(tile)
			return UM_LAVA_TILES[tile] ~= nil
		end
	end

	if Map.GetClosestTileDist == nil then
		function Map:GetClosestTileDist(x, y, z, tile, radius)
			x, y = self:GetTileXYAtPoint(x, y, z)
			for r = 1, radius do
				if tile == self:GetTile(x - r, y) or tile == self:GetTile(x + r, y) or tile == self:GetTile(x, y - r) or tile == self:GetTile(x, y + r) then
					return r
				end
				for i = 1, r - 1 do
					if tile == self:GetTile(x + r, y + i) or tile == self:GetTile(x + r, y - i) or tile == self:GetTile(x - r, y + i) or tile == self:GetTile(x - r, y - i)
						or tile == self:GetTile(x + i, y + r) or tile == self:GetTile(x + i, y - r) or tile == self:GetTile(x - i, y + r) or tile == self:GetTile(x - i, y - r)
					then
						return math.sqrt(r * r + i * i)
					end
				end
				if tile == self:GetTile(x + r, y + r) or tile == self:GetTile(x + r, y - r) or tile == self:GetTile(x - r, y + r) or tile == self:GetTile(x - r, y - r) then
					return math.sqrt(2) * r
				end
			end
			return math.huge
		end
	end

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