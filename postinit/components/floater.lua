if not GLOBAL.TheNet:GetIsServer() then return end

AddComponentPostInit("floater", function(self)
	--[[local _ShouldShowEffect = self.ShouldShowEffect
	
	function self:ShouldShowEffect()
		local pos_x, pos_y, pos_z = self.inst.Transform:GetWorldPosition()
		local current_tile = TheWorld.Map:GetTileAtPoint(pos_x, 0, pos_z)
		if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO or current_tile == WORLD_TILES.UM_FLOODWATER_BROILING then
			return true
		else
			return _ShouldShowEffect(self)
		end
		return
	end]]
end)
