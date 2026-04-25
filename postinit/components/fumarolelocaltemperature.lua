-- AXE The purpose of this file is to increase the capabilities of the native fumarolelocaltemperature component.
-- It is desireable that it also treat the magma caves as a region to increase temperature.
-- Adding the "fumarolearea" tag to magma caves areas is a bad option, it will force the geothermites to spawn there as well as 
-- a side-effect. Instead, modifying GetTile to also include Magma Caves is a better option.
if not GLOBAL.TheNet:GetIsServer() then return end

local UpvalueHacker = require("tools/upvaluehacker")

AddComponentPostInit("fumarolelocaltemperature", function(self)
	-- Extremely unlikely that someone will also need this too. Postiniting the function will also make the tile call happen twice, let's just
	-- not do that and instead redefine the function.

	local TILE_SEARCH_HALF_SIZE = 4
	local _world = TheWorld
	local _map = _world.Map
	local _cachetemperature = UpvalueHacker.GetUpvalue(self.GetTemperatureAtXZ, "_cachetemperature") -- Grab it from the old one.
	local _state = _world.state
	self.GetTemperatureAtXZ = function(self,x,z)
		local tx, ty = _map:GetTileCoordsAtPoint(x, 0, z)
		local index = _cachetemperature:GetIndex(tx, ty)
		local temp_perc = _cachetemperature:GetDataAtIndex(index)
		local _currenttemperature = self:GetTemperature()
		if not temp_perc then
			local num_fumarole = 0
			local tile_area = 0

			for off_tx = -TILE_SEARCH_HALF_SIZE, TILE_SEARCH_HALF_SIZE do
				for off_ty = -TILE_SEARCH_HALF_SIZE, TILE_SEARCH_HALF_SIZE do
					local ptx, pty = tx + off_tx, ty + off_ty
					if not TileGroupManager:IsImpassableTile(_map:GetTile(ptx, pty)) then
						tile_area = tile_area + 1
						if _map:NodeAtTileHasTag(ptx, pty, "fumarolearea") or _map:NodeAtTileHasTag(ptx, pty, "magmacaves") then
							num_fumarole = num_fumarole + 1
						end
					end
				end
			end
			temp_perc = num_fumarole == 0 and 0 or num_fumarole / tile_area
			_cachetemperature:SetDataAtIndex(index, temp_perc)
		end
		
		return temp_perc ~= 0 and Lerp(_state.temperature, _currenttemperature, temp_perc) or nil

	end
end)