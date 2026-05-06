local env = env
GLOBAL.setfenv(1, GLOBAL)

-- This is an attempt at manually fixing an issue when people are checked for insulation
-- scrimbles

env.AddComponentPostInit("inventoryitem", function(self)
	--[[local _trytosink = self.TryToSink
	
	local function ShouldEntitySink(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		local current_tile = TheWorld.Map:GetTileAtPoint(x,y,z)
		if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO or current_tile == WORLD_TILES.UM_FLOODWATER_BROILING then
			return true
		end	
	end
	function self:TryToSink()
		_trytosink(self)
		if ShouldEntitySink(self.inst) and self.sinks then
			self.inst:DoTaskInTime(0, SinkEntity)
		end
	end]]
end)
